{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.pcHardware = {
    config,
    lib,
    pkgs,
    modulesPath,
    ...
  }: {
    imports = [
      (modulesPath + "/profiles/qemu-guest.nix")
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

    fileSystems."/" = {
      device = "/dev/disk/by-uuid/fa80f459-1087-4231-b4ad-a6c92da369f6";
      fsType = "btrfs";
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/6B5C-3681";
      fsType = "vfat";
      options = ["fmask=0022" "dmask=0022"];
    };

    swapDevices = [];

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  };
}
