{
  config,
  pkgs,
  ...
}: {
  services.snapper = {
    snapshotInterval = "*-*-* *:00,20,40:00";
    snapshotRootOnBoot = true;
    configs = {
      root = {
        SUBVOLUME = "/";
        ALLOW_GROUPS = ["wheel"];
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        TIMELINE_LIMIT_HOURLY = 3;
        TIMELINE_LIMIT_DAILY = 12;
        TIMELINE_LIMIT_WEEKLY = 3;
        TIMELINE_LIMIT_MONTHLY = 0;
        TIMELINE_LIMIT_QUARTERLY = 0;
        TIMELINE_LIMIT_YEARLY = 0;
      };
      persist = {
        SUBVOLUME = "/persist";
        ALLOW_GROUPS = ["wheel"];
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        TIMELINE_LIMIT_HOURLY = 3;
        TIMELINE_LIMIT_DAILY = 12;
        TIMELINE_LIMIT_WEEKLY = 3;
        TIMELINE_LIMIT_MONTHLY = 0;
        TIMELINE_LIMIT_QUARTERLY = 0;
        TIMELINE_LIMIT_YEARLY = 0;
      };
    };
  };

  systemd.services.mount-snapshots = let
    hostname = config.networking.hostName;
    encrypted = config.disko.devices.disk.main.content.partitions."${hostname}".content.type == "luks";
    partName = "disk-main-${hostname}";
    partition =
      if encrypted
      then "/dev/mapper/${hostname}"
      else "/dev/disk/by-partlabel/${partName}";
  in {
    description = "Ensure .snapshots subvolumes exist and are mounted before snapper-boot";
    wantedBy = ["multi-user.target"];
    # Root is rw, crypt devices are opened; run before snapper-boot
    after = ["systemd-remount-fs.service" "cryptsetup.target" "local-fs.target"];
    before = ["snapper-boot.service"];

    # We’ll call mount/btrfs directly; put them in PATH for simplicity
    path = with pkgs; [util-linux btrfs-progs coreutils gnugrep];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      set -euo pipefail

      # Temp-mount the top-level Btrfs (subvol=/) to create/check subvols
      MNTPOINT="$(mktemp -d /tmp/mksnaps.XXXXXX)"
      cleanup() { umount -q "$MNTPOINT" 2>/dev/null || true; rmdir "$MNTPOINT" 2>/dev/null || true; }
      trap cleanup EXIT

      echo "[mount-snapshots] Mounting top-level FS at $MNTPOINT"
      mount -t btrfs -o subvol=/ ${partition} "$MNTPOINT"

      # Desired subvolume layout:
      #   /snapshots/root     -> will be mounted at /.snapshots
      #   /snapshots/persist  -> will be mounted at /persist/.snapshots
      mkdir -p "$MNTPOINT/snapshots"

      ensure_subvol() {
        local path="$1"
        if ! btrfs subvolume show "$MNTPOINT$path" >/dev/null 2>&1; then
          echo "[mount-snapshots] Creating subvolume $path"
          btrfs subvolume create "$MNTPOINT$path"
        else
          echo "[mount-snapshots] Subvolume $path already exists"
        fi
      }

      ensure_subvol "/snapshots/root"
      ensure_subvol "/snapshots/persist"

      # Make the live mountpoints
      mkdir -p "/.snapshots" "/persist/.snapshots"

      # Mount helper: only mount if not already mounted
      mount_if_needed() {
        local subvol="$1"
        local target="$2"
        if findmnt -rno SOURCE,TARGET "$target" >/dev/null 2>&1; then
          echo "[mount-snapshots] $target already mounted; skipping"
        else
          echo "[mount-snapshots] Mounting $subvol at $target"
          mount -t btrfs -o "subvol=$subvol,compress=zstd,discard=async,autodefrag" ${partition} "$target"
        fi
      }

      # Mount the subvolumes on the real root so Snapper sees them
      mount_if_needed "/snapshots/root" "/.snapshots"
      mount_if_needed "/snapshots/persist" "/persist/.snapshots"

      echo "[mount-snapshots] Done."
    '';
  };
}
