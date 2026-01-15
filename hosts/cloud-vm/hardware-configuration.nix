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
    "${modulesPath}/virtualisation/amazon-image.nix"

    ../common/optional/btrfs.nix
    ../common/optional/ephemeral.nix
  ];

  ec2.hvm = true;
  formatConfigs.amazon = {...}: {
    virtualisation.diskSize = 16 * 1024;
  };

  boot = {
    initrd = {
      availableKernelModules = ["ahci" "xhci_pci" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" "nvme" "usbhid" "usb_storage"];
      kernelModules = ["kvm-intel"];
      supportedFilesystems = {
        btrfs = true;
      };
    };
    kernelModules = ["kvm-intel"];
    # kernelParams = [];
    # extraModulePackages = [];
    # loader = {
    #   efi = {
    #     canTouchEfiVariables = true;
    #   };
    #   systemd-boot.enable = true;
    # };
  };

  disko.devices.disk.main = {
    device = lib.mkForce "/dev/nvme0n1";
  };

  fileSystems = {
    "/" = {
      fsType = lib.mkForce "btrfs";
      device = lib.mkForce "/dev/disk/by-partlabel/disk-main-${config.networking.hostName}";
      # label = lib.mkForce null;
    };
    # "/boot" = lib.mkForce (lib.mkIf (config.virtualisation.azureImage.vmGeneration == "v2") {
    #   device = "/dev/disk/by-label/ESP";
    #   fsType = "vfat";
    # });
  };

  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 2048;
    }
  ];

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  nixpkgs.hostPlatform.system = "x86_64-linux";
}
