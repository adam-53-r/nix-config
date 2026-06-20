{
  self,
  inputs,
  ...
}: let
  x86Pkgs = import inputs.nixpkgs {system = "x86_64-linux";};
in {
  flake.nixosModules.ociHardware = {
    config,
    lib,
    pkgs,
    modulesPath,
    ...
  }: {
    imports = [
      (modulesPath + "/profiles/qemu-guest.nix")
      self.nixosModules.diskoBtrfs
      self.nixosModules.ociRuntime
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
    disko.imageBuilder.pkgs = x86Pkgs;
    disko.imageBuilder.kernelPackages = x86Pkgs.linuxPackages;
    disko.imageBuilder.enableBinfmt = true;

    swapDevices = [];
    hardware.enableRedistributableFirmware = true;
    nixpkgs.hostPlatform = "aarch64-linux";
  };
}
