# msi-server hardware: Intel laptop-turned-server booting systemd-boot from
# /dev/sda (diskoBtrfs layout, ephemeral, unencrypted), with the bulk storage
# on a separate btrfs disk labelled DATA — which also hosts /nix (mkForce
# overriding diskoBtrfs's nix subvolume mount).
{
  config,
  lib,
  pkgs,
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
      # Most btrfs options are filesystem-wide and come from whichever subvolume
      # mounts first (/nix, in the initrd), so autodefrag here never applied.
      options = ["compress=zstd" "noatime"];
    };
    "/nix" = {
      device = lib.mkForce "/dev/disk/by-label/DATA";
    };
  };

  services.btrfs.autoScrub = {
    enable = true;
    interval = "*-*-01 02:00:00";
  };
  # The module's 1d accuracy would let a night-time scrub drift into the day.
  systemd.timers = {
    btrfs-scrub-DATA.timerConfig.AccuracySec = lib.mkForce "1h";
    "btrfs-scrub--".timerConfig.AccuracySec = lib.mkForce "1h";
  };

  services.smartd.enable = true;

  # The IronWolf ships with SCT error recovery disabled, so a bad sector could
  # stall it past the 30s SCSI timeout instead of btrfs repairing it from the
  # mirror. The setting is lost on power cycle.
  systemd.services.hdd-scterc = {
    description = "Limit HDD error recovery time to 7s";
    wantedBy = ["multi-user.target"];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.smartmontools}/bin/smartctl -q errorsonly -l scterc,70,70 /dev/disk/by-id/ata-ST4000VN006-3CW104_*
    '';
  };

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  nixpkgs.hostPlatform.system = "x86_64-linux";
}
