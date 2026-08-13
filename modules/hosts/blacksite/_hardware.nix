# blacksite hardware: a QEMU/KVM guest on pc, single virtio disk, ephemeral
# btrfs root (layout owned by diskoBtrfs).
# Plain NixOS module (underscore file: skipped by import-tree), imported by
# blacksiteConfiguration in ./default.nix.
{
  lib,
  pkgs,
  config,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.initrd.availableKernelModules = [
    "ahci"
    "xhci_pci"
    "virtio_pci"
    "virtio_scsi"
    "virtio_blk"
    "sd_mod"
    "sr_mod"
  ];

  # systemd-boot rather than the GRUB-with-cryptodisk the encrypted hosts need:
  # nothing here is encrypted, so there's no reason to carry GRUB's complexity.
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    timeout = 1;
  };

  hardware.disko-btrfs = {
    # Unencrypted on purpose: the image is expected to live on an already
    # encrypted host filesystem, and a second LUKS prompt here would mean typing
    # a passphrase into the virt-manager console on every single boot. Nothing
    # of value should live in this VM anyway — that's the whole premise.
    encrypted = false;
    # Wiped every boot; anything worth keeping goes in /persist (see ./_lab.nix)
    # or in the home dirs adamr@blacksite persists. Deliberate for a lab box:
    # tools scribble everywhere, and a clean root each boot is a feature.
    ephemeral = true;
  };

  disko.devices.disk.main = {
    device = "/dev/vda";
    # Only used by the `diskoImages` build (the qcow2 is sparse, so this is a
    # ceiling, not an allocation). ghidra + burpsuite + the wordlists make the
    # closure alone several GB, and lab work fills disks fast.
    imageSize = "80G";
  };

  # disko builds that image inside a vmTools VM, and hands vmTools the
  # `aggregateModules` symlink-merge (named "kernel-modules") as its `kernel`
  # argument. nixpkgs-unstable's vmTools derives the boot image filename from
  # `kernel.target`, which a buildEnv output does not carry, so the image build
  # throws instead. The merged output *does* still contain the real kernel image
  # at its root, so naming the file explicitly is all that's needed. Same
  # workaround as the oci host's cross-arch image build — the long version of
  # this note is in modules/hosts/oci/default.nix.
  disko.imageBuilder.pkgs = pkgs.extend (_final: prev: {
    vmTools = prev.vmTools.override {
      kernelImage = config.boot.kernelPackages.kernel.target;
    };
  });

  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 8192;
    }
  ];

  # Clipboard sharing, dynamic resolution in virt-manager, and graceful
  # shutdown/introspection from the host.
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
