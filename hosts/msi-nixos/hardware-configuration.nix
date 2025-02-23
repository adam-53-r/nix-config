{
  config,
  lib,
  pkgs,
  modulesPath,
  inputs,
  ...
}: let
  hostname = config.networking.hostName;
  # PRIMARYUSBID = "3F32-27F5";
  # BACKUPUSBID = "3F32-27F5";
in {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-gpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    inputs.nixos-hardware.nixosModules.common-pc-laptop

    ../common/optional/ephemeral-encrypted-btrfs.nix
  ];

  boot = {
    initrd = {
      availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" "nvme" "usbhid" "usb_storage" ];
      kernelModules = [ "kvm-intel" ];
      # postDeviceCommands = pkgs.lib.mkBefore ''
      #   mkdir -m 0755 -p /key
      #   sleep 2 # To make sure the usb key has been loaded
      #   mount -n -t vfat -o ro `findfs UUID=${PRIMARYUSBID}` /key || mount -n -t vfat -o ro `findfs UUID=${BACKUPUSBID}` /key
      # '';
    };
    kernelModules = [ "kvm-intel" ];
    kernelParams = ["acpi_osi=!" "acpi_osi=\"Windows 2009\""];
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
    device = lib.mkForce "/dev/nvme1n1";
  };

  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 8196;
      randomEncryption.enable = true;
    }
  ];

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  nixpkgs.hostPlatform.system = "x86_64-linux";

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
    # of just the bare essentials.
    powerManagement.enable = false;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = true;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
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
      # environment.systemPackages = [
      #   (pkgs.writeShellScriptBin "nvidia-offload" ''
      #     export __NV_PRIME_RENDER_OFFLOAD=1
      #     export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
      #     export __GLX_VENDOR_LIBRARY_NAME=nvidia
      #     export __VK_LAYER_NV_optimus=NVIDIA_only
      #     exec "$@"
      #   '')
      # ];
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
