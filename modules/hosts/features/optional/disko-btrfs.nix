{inputs, ...}: {
  flake.nixosModules.diskoBtrfs = {
    lib,
    pkgs,
    config,
    ...
  }: let
    cfg = config.hardware.disko-btrfs;
    hostname = config.networking.hostName;

    btrfsContent = {
      type = "btrfs";
      extraArgs = ["-f"];
      subvolumes = {
        "/root" = {
          mountpoint = "/";
          mountOptions = ["compress=zstd" "noatime"] ++ cfg.extraMountOptions;
        };
        "/nix" = {
          mountpoint = "/nix";
          mountOptions = ["compress=zstd" "noatime"] ++ cfg.extraMountOptions;
        };
        "/persist" = {
          mountpoint = "/persist";
          mountOptions = ["compress=zstd" "noatime"] ++ cfg.extraMountOptions;
        };
        "/swap" =
          {
            mountpoint = "/swap";
            mountOptions = ["noatime"] ++ cfg.extraMountOptions;
          }
          # Its own subvolume with no compression and no snapshots, which is
          # what btrfs requires of a swapfile; `btrfs filesystem mkswapfile`
          # (which disko calls) also sets NOCOW. disko derives the swapDevices
          # entry from this, so nothing else needs to declare it.
          // lib.optionalAttrs (cfg.swapFileSize != null) {
            swap.swapfile.size = cfg.swapFileSize;
          };

        "/root-blank" = {};
        "/snapshots" = {};
        "/snapshots/root" = {};
        "/snapshots/persist" = {};
        "/snapshots/pre-wipe" = {};
      };
    };

    mainPartitionContent =
      if cfg.encrypted
      then {
        type = "luks";
        name = "${hostname}";
        content = btrfsContent;
      }
      else btrfsContent;

    devicePath =
      if cfg.encrypted
      then "/dev/mapper/${hostname}"
      else "/dev/disk/by-partlabel/disk-main-${hostname}";

    wipeScript = ''
      mkdir /tmp -p
      MNTPOINT=$(mktemp -d)
      (
        mount -t btrfs -o subvol=/ ${devicePath} "$MNTPOINT"
        trap 'umount "$MNTPOINT"' EXIT

        echo "Creating needed directories"
        mkdir -p "$MNTPOINT"/persist/var/log \
                 "$MNTPOINT"/persist/var/lib/nixos \
                 "$MNTPOINT"/persist/var/lib/systemd

        if [ -e "$MNTPOINT/persist/dont-wipe" ]; then
          echo "Skipping wipe"
        else
          # Snapshot the outgoing root BEFORE wiping it, so files that were
          # only on / (unclean shutdown, forgot to move to /persist) stay
          # recoverable. Pre-existing installs may lack the subvolume.
          mkdir -p "$MNTPOINT/snapshots"
          if ! btrfs subvolume show "$MNTPOINT/snapshots/pre-wipe" >/dev/null 2>&1; then
            btrfs subvolume create "$MNTPOINT/snapshots/pre-wipe"
          fi
          echo "Snapshotting root before wipe"
          btrfs subvolume snapshot -r "$MNTPOINT/root" \
            "$MNTPOINT/snapshots/pre-wipe/$(date +%Y-%m-%d_%H-%M-%S)"
          echo "Pruning pre-wipe snapshots (keeping ${toString cfg.preWipeSnapshotCount})"
          for old in $(ls -1 "$MNTPOINT/snapshots/pre-wipe" | sort | head -n -${toString cfg.preWipeSnapshotCount}); do
            btrfs subvolume delete "$MNTPOINT/snapshots/pre-wipe/$old"
          done
          echo "Cleaning root subvolume"
          btrfs subvolume delete -R "$MNTPOINT/root"
          echo "Restoring blank subvolume"
          btrfs subvolume snapshot "$MNTPOINT/root-blank" "$MNTPOINT/root"
        fi
      )
    '';

    useSystemdInitrd = config.boot.initrd.systemd.enable;
    escapedHostname = lib.strings.escapeC ["-"] hostname;
    escapedPartName = lib.strings.escapeC ["-"] "disk-main-${hostname}";

    deviceUnit =
      if cfg.encrypted
      then "dev-mapper-${escapedHostname}.device"
      else "dev-disk-by\\x2dpartlabel-${escapedPartName}.device";
  in {
    key = "mynix#nixosModules.diskoBtrfs";
    imports = [
      inputs.disko.nixosModules.disko
    ];

    options.hardware.disko-btrfs = {
      encrypted = lib.mkEnableOption "LUKS encryption for the main partition";
      ephemeral = lib.mkEnableOption "ephemeral root via btrfs snapshot rollback (impermanence)";
      preWipeSnapshotCount = lib.mkOption {
        type = lib.types.ints.positive;
        default = 5;
        description = "How many pre-wipe root snapshots (taken in the initrd just before the ephemeral-root rollback) to keep in /snapshots/pre-wipe.";
      };
      swapFileSize = lib.mkOption {
        type = lib.types.nullOr (lib.types.strMatching "^([0-9]+[KMGTP])?$");
        default = null;
        example = "36G";
        description = "Size of a swapfile to create on the /swap subvolume (e.g. \"36G\"), or null for no swapfile. Size it at or above RAM if the host should be able to hibernate.";
      };
      extraMountOptions = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        example = ["nodiscard"];
        description = "Extra mount options appended to every btrfs subvolume (e.g. nodiscard on SSDs that rely on fstrim.timer instead of continuous discard).";
      };
    };

    config = {
      disko.devices.disk.main = {
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              name = "BOOT";
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["umask=0077"];
              };
            };

            "${hostname}" = {
              size = "100%";
              content = mainPartitionContent;
            };
          };
        };
      };

      fileSystems."/nix".neededForBoot = true;
      fileSystems."/persist".neededForBoot = true;

      boot.initrd = lib.mkIf cfg.ephemeral {
        supportedFilesystems = ["btrfs"];
        postDeviceCommands = lib.mkIf (!useSystemdInitrd) (lib.mkBefore wipeScript);
        systemd.services.restore-root = lib.mkIf useSystemdInitrd {
          description = "Rollback btrfs rootfs";
          wantedBy = ["initrd.target"];
          requires = [deviceUnit];
          after = [
            deviceUnit
            "systemd-cryptsetup@${escapedPartName}.service"
            # Required on any host that hibernates. A successful resume never
            # returns from systemd-hibernate-resume.service, since the
            # restored kernel takes over, so ordering after it is what keeps
            # the rollback from discarding the root subvolume the hibernation
            # image expects to wake up onto. Without it the two race, and
            # losing that race means resuming into a freshly blanked /.
            # Ordering against a unit that does not exist is a no-op, so this
            # costs nothing on hosts that never hibernate.
            "systemd-hibernate-resume.service"
          ];
          before = ["sysroot.mount"];
          unitConfig.DefaultDependencies = "no";
          serviceConfig.Type = "oneshot";
          script = wipeScript;
        };
      };
    };
  };
}
