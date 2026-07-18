# oci hardware: aarch64 Oracle Cloud free-tier VM, built as a disko image via
# imageBuilder cross-compiled from an x86_64 host.
# Plain NixOS module (underscore file: skipped by import-tree), imported by
# ociConfiguration in ./default.nix. `ociX86Pkgs` is handed in via
# `_module.args` from ./default.nix, since this plain module has no `inputs`
# closure of its own to build it from.
{
  modulesPath,
  ociX86Pkgs,
  ...
}: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.initrd.availableKernelModules = ["xhci_pci" "virtio_pci" "virtio_blk" "sr_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = [];
  boot.extraModulePackages = [];

  boot.loader = {
    efi.canTouchEfiVariables = false;
    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
    };
  };

  hardware.disko-btrfs = {
    encrypted = false;
    ephemeral = true;
  };
  disko.devices.disk.main.device = "/dev/sda";
  disko.devices.disk.main.imageSize = "8G";
  disko.imageBuilder.pkgs = ociX86Pkgs;
  disko.imageBuilder.kernelPackages = ociX86Pkgs.linuxPackages;
  disko.imageBuilder.enableBinfmt = true;

  swapDevices = [];
  hardware.enableRedistributableFirmware = true;
  nixpkgs.hostPlatform = "aarch64-linux";
}
