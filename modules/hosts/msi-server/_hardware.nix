# msi-server hardware: Intel laptop-turned-server booting systemd-boot from
# /dev/sda (diskoBtrfs layout, ephemeral, unencrypted), with the bulk storage
# on a separate btrfs disk labelled DATA — which also hosts /nix (mkForce
# overriding diskoBtrfs's nix subvolume mount).
{
  config,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd = {
      availableKernelModules = ["ahci" "xhci_pci" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" "nvme" "usbhid" "usb_storage"];
      kernelModules = ["kvm-intel"];
    };
    kernelModules = ["kvm-intel"];
    kernelParams = [];
    extraModulePackages = [];
    loader = {
      efi = {
        canTouchEfiVariables = true;
      };
      systemd-boot.enable = true;
    };
  };

  disko.devices.disk.main = {
    device = lib.mkForce "/dev/sda";
  };

  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 16384;
    }
  ];

  fileSystems = {
    "/DATA" = {
      device = "/dev/disk/by-label/DATA";
      fsType = "btrfs";
      options = ["compress=zstd" "autodefrag"];
    };
    "/nix" = {
      device = lib.mkForce "/dev/disk/by-label/DATA";
    };
  };

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  nixpkgs.hostPlatform.system = "x86_64-linux";
}
