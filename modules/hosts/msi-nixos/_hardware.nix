# msi-nixos hardware: MSI laptop, Intel CPU + hybrid Intel/NVIDIA graphics
# (PRIME sync by default; the on-the-go specialisation flips to offload +
# fine-grained power management for battery). Encrypted ephemeral btrfs on
# the nvme (diskoBtrfs; flags set in default.nix), booted via GRUB with
# cryptodisk + os-prober.
{
  config,
  lib,
  ...
}: {
  boot = {
    initrd = {
      availableKernelModules = ["ahci" "xhci_pci" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" "nvme" "usbhid" "usb_storage"];
      kernelModules = ["kvm-intel"];
    };
    kernelModules = ["kvm-intel"];
    kernelParams = ["acpi_osi=!" "acpi_osi=\"Windows 2009\""];
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
    device = lib.mkForce "/dev/nvme0n1";
  };

  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 16384;
      randomEncryption.enable = true;
    }
  ];

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  nixpkgs.hostPlatform.system = "x86_64-linux";

  hardware.graphics.enable = true;

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental; saving all VRAM to /tmp on
    # suspend. Off in the default (docked) configuration.
    powerManagement.enable = false;
    # Fine-grained power management (turns off GPU when not in use).
    powerManagement.finegrained = false;

    # NVidia open source kernel module (Turing+; not nouveau).
    open = true;

    # nvidia-settings menu.
    nvidiaSettings = true;

    package = config.boot.kernelPackages.nvidiaPackages.production;
  };

  hardware.nvidia.prime = {
    sync.enable = true;
    # Make sure to use the correct Bus ID values for your system!
    intelBusId = "PCI:00:02:0";
    nvidiaBusId = "PCI:01:00:0";
  };

  specialisation = {
    on-the-go.configuration = {
      system.nixos.tags = ["on-the-go"];
      hardware.nvidia = {
        powerManagement = {
          enable = lib.mkForce true;
          finegrained = lib.mkForce true;
        };
        prime = {
          sync.enable = lib.mkForce false;
          offload = {
            enable = lib.mkForce true;
            enableOffloadCmd = lib.mkForce true;
          };
        };
      };
    };
  };
}
