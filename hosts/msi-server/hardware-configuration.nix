{
  config,
  lib,
  pkgs,
  modulesPath,
  inputs,
  ...
}: let
  hostname = config.networking.hostName;
in {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-gpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-ssd

    ../common/optional/btrfs.nix
    ../common/optional/ephemeral.nix
  ];

  boot = {
    initrd = {
      availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" "nvme" "usbhid" "usb_storage" ];
      kernelModules = [ "kvm-intel" ];
    };
    kernelModules = [ "kvm-intel" ];
    kernelParams = [];
    extraModulePackages = [ ];
    loader = {
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
  };

  disko.devices.disk.main = {
    device = lib.mkForce "/dev/sda";
  };

  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 8196;
    }
  ];


  fileSystems = {
    "/persist/DATA" = {
      device = "/dev/disk/by-label/DATA";
      fsType = "btrfs";
      options = [ "compress=zstd" "discard=async" "autodefrag" ];
    };
  };


  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  nixpkgs.hostPlatform.system = "x86_64-linux";
}
