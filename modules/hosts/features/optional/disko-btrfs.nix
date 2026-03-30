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
          mountOptions = ["compress=zstd" "discard=async" "autodefrag"];
        };
        "/nix" = {
          mountpoint = "/nix";
          mountOptions = ["compress=zstd" "noatime" "discard=async" "autodefrag"];
        };
        "/persist" = {
          mountpoint = "/persist";
          mountOptions = ["compress=zstd" "discard=async" "autodefrag"];
        };
        "/swap" = {
          mountpoint = "/swap";
          mountOptions = ["noatime"];
        };

        "/root-blank" = {};
        "/snapshots" = {};
        "/snapshots/root" = {};
        "/snapshots/persist" = {};
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
    imports = [
      inputs.disko.nixosModules.disko
    ];

    options.hardware.disko-btrfs = {
      encrypted = lib.mkEnableOption "LUKS encryption for the main partition";
      ephemeral = lib.mkEnableOption "ephemeral root via btrfs snapshot rollback (impermanence)";
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
