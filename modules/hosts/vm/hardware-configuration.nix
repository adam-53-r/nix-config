{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.vmHardware = {
    config,
    lib,
    pkgs,
    modulesPath,
    ...
  }: {
    imports = [
      (modulesPath + "/profiles/qemu-guest.nix")

      self.nixosModules.diskoBtrfs
    ];

    boot.initrd.availableKernelModules = ["ahci" "xhci_pci" "virtio_pci" "sr_mod" "virtio_blk"];
    boot.initrd.kernelModules = [];
    boot.kernelModules = ["kvm-amd"];
    boot.extraModulePackages = [];

    boot.loader = {
      efi = {
        canTouchEfiVariables = true;
      };
      grub = {
        enable = true;
        efiSupport = true;
        enableCryptodisk = true;
        device = "nodev";
        useOSProber = true;
        timeoutStyle = "menu";
      };
    };

    hardware.disko-btrfs = {
      encrypted = true;
      # ephemeral = true;
    };
    disko.devices.disk.main.device = "/dev/vda";

    swapDevices = [];

    hardware.enableRedistributableFirmware = true;
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  };
}
