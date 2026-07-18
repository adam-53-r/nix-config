# OCI disk live-resize

The `oci` host image is built at ~8GB (the disko image-builder size), but the
OCI block/boot volume is provisioned larger (e.g. 50GB). The `100%` partition
size in `disko-btrfs.nix` only applies at **image-build time**, so a running
instance does not auto-fill the volume. Grow it online — no reboot needed.

Layout: plain btrfs (`encrypted = false`), GPT partition **1** = 1G ESP,
partition **2** = main btrfs (`disk-main-oci`). The btrfs root is mounted, so
the whole operation is online.

```sh
# 1. confirm the device + partition number
lsblk
readlink -f /dev/disk/by-partlabel/disk-main-oci    # e.g. -> /dev/sda2

# 2. grow the partition to fill the volume. growpart relocates the GPT backup
#    header, which is still sitting at the old 8GB mark.
nix shell nixpkgs#cloud-utils nixpkgs#gptfdisk
sgdisk -e /dev/sda        # move secondary GPT header to end of disk
growpart /dev/sda 2       # grow partition 2 in place (also updates the kernel)

# 3. grow the btrfs filesystem online, on the mounted root
btrfs filesystem resize max /

# verify
btrfs filesystem usage /
df -h /
```

## Notes

- Use the real device/partnum from step 1. `/dev/sda` is typical for an OCI
  paravirtualized boot volume, but confirm — it could be `/dev/vda`. Partition
  **2** is the main one; partition 1 is the ESP.
- **Ephemeral root is safe here.** The rollback only recreates the `/root`
  subvolume; the partition and btrfs filesystem size live below the subvolume
  layer, so the resize persists across reboots.
- Nothing in the repo needs changing for this. To make a freshly built *image*
  larger from the start, bump the disko `imageSize` instead.
