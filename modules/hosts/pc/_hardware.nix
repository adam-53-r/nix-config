# pc hardware: AMD cpu+gpu desktop, luks+btrfs on nvme (layout owned by
# diskoBtrfs), limine boot with a Windows chainload entry.
# Plain NixOS module (underscore file: skipped by import-tree), imported by
# pcConfiguration in ./default.nix.
{
  config,
  lib,
  ...
}: {
  boot = {
    initrd = {
      availableKernelModules = ["ahci" "xhci_pci" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" "nvme" "usbhid" "usb_storage"];
      kernelModules = ["amdgpu"];
      # Unlock the luks root with a FIDO2 key, falling back to the passphrase.
      luks.devices."pc" = {
        crypttabExtraOpts = ["fido2-device=auto"];
        allowDiscards = true;
      };
    };

    loader = {
      efi.canTouchEfiVariables = true;
      limine.extraEntries = ''
        /Windows
          protocol: efi
          path: uuid(e126e23c-49f9-4264-abff-18506d70a3af):/EFI/Microsoft/Boot/bootmgfw.efi
      '';
    };
  };

  # WARNING: nvme enumeration has drifted since install — the live /boot is on
  # nvme0n1 today. This device is only used when disko FORMATS the disk;
  # double-check it before ever running disko against this machine.
  disko.devices.disk.main.device = lib.mkForce "/dev/nvme1n1";

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
  hardware.amdgpu = {
    initrd.enable = true;
    opencl.enable = true;
    overdrive = {
      enable = true;
      # Full sysfs power-state API (voltage curve, power limit) for LACT —
      # the conservative nixpkgs default (0xfffd7fff) blocks some of it.
      ppfeaturemask = "0xffffffff";
    };
  };
  services.lact.enable = true;
}
