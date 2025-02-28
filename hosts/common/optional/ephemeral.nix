{
  lib,
  config,
  inputs,
  ...
}: let
  hostname = config.networking.hostName;
  encrypted = config.disko.devices.disk.main.content.partitions."${hostname}".content.type == "luks";
  # disk-main-vm-tests == /dev/vda2
  partName = "disk-main-${hostname}";
  # mount -t btrfs -o subvol=/ /dev/disk/by-partlabel/${partName} "$MNTPOINT"
  # mount -t btrfs -o subvol=/ /dev/mapper/${hostname} "$MNTPOINT"
  wipeScript = ''
    mkdir /tmp -p
    MNTPOINT=$(mktemp -d)
    (
      mount -t btrfs -o subvol=/ ${if encrypted then "/dev/mapper/${hostname}" else "/dev/disk/by-partlabel/${partName}"} "$MNTPOINT"
      trap 'umount "$MNTPOINT"' EXIT

      echo "Creating needed directories"
      mkdir -p "$MNTPOINT"/persist/var/{log,lib/{nixos,systemd}}
      if [ -e "$MNTPOINT/persist/dont-wipe" ]; then
        echo "Skipping wipe"
      else
        echo "Cleaning root subvolume"
        btrfs subvolume list -o "$MNTPOINT/root" | cut -f9 -d ' ' | sort |
        while read -r subvolume; do
          btrfs subvolume delete "$MNTPOINT/$subvolume"
        done && btrfs subvolume delete "$MNTPOINT/root"

        echo "Restoring blank subvolume"
        btrfs subvolume snapshot "$MNTPOINT/root-blank" "$MNTPOINT/root"
      fi
    )
  '';
  phase1Systemd = config.boot.initrd.systemd.enable;
in {
  boot.initrd = {
    supportedFilesystems = ["btrfs"];
    postDeviceCommands = lib.mkIf (!phase1Systemd) (lib.mkBefore wipeScript);
    systemd.services.restore-root = lib.mkIf phase1Systemd {
      description = "Rollback btrfs rootfs";
      wantedBy = ["initrd.target"];
      # requires = ["dev-disk-by\\x2dpartlabel-${lib.strings.escapeC ["-"] partName}.device"];
      requires = if encrypted
        then ["dev-mapper-${lib.strings.escapeC ["-"] hostname}.device"]
        else ["dev-disk-by\\x2dpartlabel-${lib.strings.escapeC ["-"] partName}.device"];
      after = [
        # "dev-disk-by\\x2dpartlabel-${lib.strings.escapeC ["-"] partName}.device"
        (if encrypted
        then "dev-mapper-${lib.strings.escapeC ["-"] hostname}.device"
        else "dev-disk-by\\x2dpartlabel-${lib.strings.escapeC ["-"] partName}.device")
        "systemd-cryptsetup@${lib.strings.escapeC ["-"] partName}.service"
      ];
      before = ["sysroot.mount"];
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      script = wipeScript;
    };
  };
}