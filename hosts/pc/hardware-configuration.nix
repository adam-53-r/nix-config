{
  config,
  lib,
  inputs,
  ...
}: {
  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-ssd

    ../common/optional/btrfs.nix
    ../common/optional/encrypted.nix
    ../common/optional/ephemeral.nix
    ../common/optional/quietboot.nix
    ../common/optional/secure-boot.nix
    ../common/optional/snapshots.nix
  ];

  boot = {
    initrd = {
      availableKernelModules = ["ahci" "xhci_pci" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" "nvme" "usbhid" "usb_storage"];
      kernelModules = ["kvm-intel" "amdgpu"];
    };
    kernelModules = ["kvm-intel"];
    extraModulePackages = [];
    loader = {
      efi = {
        canTouchEfiVariables = true;
      };
      # grub = {
      #   enable = true;
      #   efiSupport = true;
      #   enableCryptodisk = true;
      #   device = "nodev";
      #   useOSProber = true;
      #   timeoutStyle = "menu";
      # };
    };
  };

  boot.loader.limine.extraEntries = ''
    /Windows
      protocol: efi
      path: uuid(e126e23c-49f9-4264-abff-18506d70a3af):/EFI/Microsoft/Boot/bootmgfw.efi
  '';

  disko.devices.disk.main = {
    device = lib.mkForce "/dev/nvme1n1";
  };

  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 32768;
      randomEncryption.enable = true;
    }
  ];

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  nixpkgs.hostPlatform.system = "x86_64-linux";

  hardware.graphics.enable = true;
  services.xserver.videoDrivers = ["amdgpu"];
  services.lact.enable = true;
}
