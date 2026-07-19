# Snapper timeline snapshots for / and /persist. The mount-snapshots service
# creates and mounts the /snapshots/{root,persist,pre-wipe} subvolumes (kept
# outside the rolled-back root subvolume) before snapper needs them. Pre-wipe
# root snapshots (created by the diskoBtrfs initrd rollback, NOT snapper) are
# exposed read-only at /.pre-wipe. Requires the diskoBtrfs disk layout.
{
  flake.nixosModules.optionalSnapshots = {
    config,
    pkgs,
    ...
  }: {
    key = "mynix#nixosModules.optionalSnapshots";

    services.snapper = {
      # Hourly creation + hourly cleanup keeps the on-disk count close to the
      # TIMELINE_LIMIT_* totals (with the old 20-min interval and daily
      # cleanup, ~144 snapshots could pile up between cleanup runs).
      snapshotInterval = "hourly";
      cleanupInterval = "1h";
      # NOTE: snapshotRootOnBoot is intentionally NOT used. It runs in stage 2,
      # after the initrd restore-root service has already wiped /, so it only
      # ever captured the freshly-blanked root. The useful pre-wipe snapshot is
      # taken inside the initrd wipe script (see diskoBtrfs) into
      # /snapshots/pre-wipe, mounted read-only at /.pre-wipe below.
      configs = {
        # / is ephemeral (wiped every boot): hourly snapshots only matter for
        # the current session plus a short tail; long retention is pointless.
        root = {
          SUBVOLUME = "/";
          ALLOW_GROUPS = ["wheel"];
          TIMELINE_CREATE = true;
          TIMELINE_CLEANUP = true;
          TIMELINE_LIMIT_HOURLY = 12;
          TIMELINE_LIMIT_DAILY = 2;
          TIMELINE_LIMIT_WEEKLY = 0;
          TIMELINE_LIMIT_MONTHLY = 0;
          TIMELINE_LIMIT_QUARTERLY = 0;
          TIMELINE_LIMIT_YEARLY = 0;
          # Purge the "number"-algorithm snapshots the old snapshotRootOnBoot
          # setup accumulated (it never enabled NUMBER_CLEANUP, so they were
          # never deleted).
          NUMBER_CLEANUP = true;
          NUMBER_LIMIT = 5;
        };
        # /persist holds the real data: keep a classic decaying timeline.
        persist = {
          SUBVOLUME = "/persist";
          ALLOW_GROUPS = ["wheel"];
          TIMELINE_CREATE = true;
          TIMELINE_CLEANUP = true;
          TIMELINE_LIMIT_HOURLY = 12;
          TIMELINE_LIMIT_DAILY = 7;
          TIMELINE_LIMIT_WEEKLY = 3;
          TIMELINE_LIMIT_MONTHLY = 2;
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
      description = "Ensure .snapshots subvolumes exist and are mounted before snapper runs";
      wantedBy = ["multi-user.target"];
      # Root is rw, crypt devices are opened; run before snapper can fire
      after = ["systemd-remount-fs.service" "cryptsetup.target" "local-fs.target"];
      before = ["snapper-timeline.service" "snapper-cleanup.service"];

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
        ensure_subvol "/snapshots/pre-wipe"

        # Make the live mountpoints
        mkdir -p "/.snapshots" "/persist/.snapshots" "/.pre-wipe"

        # Mount helper: only mount if not already mounted
        mount_if_needed() {
          local subvol="$1"
          local target="$2"
          local extraopts="''${3:-}"
          if findmnt -rno SOURCE,TARGET "$target" >/dev/null 2>&1; then
            echo "[mount-snapshots] $target already mounted; skipping"
          else
            echo "[mount-snapshots] Mounting $subvol at $target"
            mount -t btrfs -o "subvol=$subvol,compress=zstd$extraopts" ${partition} "$target"
          fi
        }

        # Mount the subvolumes on the real root so Snapper sees them
        mount_if_needed "/snapshots/root" "/.snapshots"
        mount_if_needed "/snapshots/persist" "/persist/.snapshots"
        # Pre-wipe root snapshots (taken by the initrd rollback); read-only —
        # they are only written/pruned from the initrd.
        mount_if_needed "/snapshots/pre-wipe" "/.pre-wipe" ",ro"

        echo "[mount-snapshots] Done."
      '';
    };
  };
}
