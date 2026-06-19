{
  self,
  inputs,
  ...
}: {
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

    swapDevices = [];
    hardware.enableRedistributableFirmware = true;
    nixpkgs.hostPlatform = "aarch64-linux";
  };
}
