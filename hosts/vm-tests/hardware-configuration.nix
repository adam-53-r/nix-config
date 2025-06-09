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
    (modulesPath + "/profiles/qemu-guest.nix")

    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-gpu-intel

    ../common/optional/btrfs.nix
    # ../common/optional/encrypted.nix
    ../common/optional/ephemeral.nix
  ];

  boot = {
    initrd = {
      availableKernelModules = ["ahci" "xhci_pci" "virtio_pci" "sr_mod" "virtio_blk"];
      kernelModules = ["kvm-intel"];
    };
    kernelModules = ["kvm-intel"];
    kernelParams = [];
    extraModulePackages = [];
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

  # fileSystems = {
  #   "/persist/DATA" = {
  #     device = "/dev/disk/by-partlabel/DATA";
  #     fsType = "btrfs";
  #     options = [ "compress=zstd" "discard=async" "autodefrag" "nofail"];
  #   };
  # };

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  nixpkgs.hostPlatform.system = "x86_64-linux";
}
