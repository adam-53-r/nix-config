# avalon hardware: MSI GS65 Stealth 8SF — Coffee Lake i7-8750H with hybrid
# Intel UHD 630 (Gen9.5) / RTX 2070 Max-Q (Turing) graphics, 32G RAM, LUKS +
# btrfs on the internal nvme (layout owned by diskoBtrfs), limine + secure
# boot (optionalSecureBoot).
# Plain NixOS module (underscore file: skipped by import-tree), imported by
# avalonConfiguration in ./default.nix.
{
  config,
  lib,
  ...
}: {
  boot = {
    initrd = {
      # Bare metal, so no virtio_* entries.
      availableKernelModules = ["ahci" "xhci_pci" "nvme" "sd_mod" "sr_mod" "usbhid" "usb_storage"];
      kernelModules = ["kvm-intel"];

      # Unlock the luks root with a FIDO2 key, falling back to the passphrase.
      luks.devices."avalon" = {
        crypttabExtraOpts = ["fido2-device=auto"];
        # Required for fstrim.timer to reach the SSD at all: without it
        # dm-crypt swallows every discard, so nodiscard mounts plus a trim
        # timer silently trim nothing.
        allowDiscards = true;
        # Don't bounce IO through dm-crypt's kernel workqueues: on NVMe they
        # add queueing latency under bulk writes (same reasoning as pc).
        bypassWorkqueues = true;
      };
    };

    # Boot is limine + sbctl (optionalSecureBoot). GRUB's enableCryptodisk and
    # os-prober have no role here: diskoBtrfs puts /boot on its own unencrypted
    # ESP, and this is a single-boot install with no other OS to probe.
    loader.efi.canTouchEfiVariables = true;

    # Deliberately empty. The previous configuration carried acpi_osi=! plus
    # acpi_osi="Windows 2009", which makes the firmware answer _OSI as though
    # it were Windows 7. It was there for one symptom: the wifi did not come
    # back from hibernation, the radio stayed powered off.
    #
    # That does not reproduce here, and it looks to have been a consequence of
    # a suspend path that never completed rather than a firmware fault.
    # NVreg_PreserveVideoMemoryAllocations was set while nothing drove the
    # driver's procfs suspend interface, so every attempt aborted part way
    # through the device walk with nv_pmops_suspend returning -EIO. With the
    # kernel suspend notifier doing that work instead (see `open` above), a
    # full hibernate and resume returns wlan0 with its addresses intact.
    #
    # If it recurs, `lspci -nnk -s 00:14.3` picks the lever: gone from the bus
    # means the firmware did not restore the device's power resource and the
    # _OSI override is the fix; present but soft-blocked is rfkill state, which
    # TLP owns here (see _power.nix).
    kernelParams = [];
  };

  disko.devices.disk.main.device = lib.mkForce "/dev/nvme0n1";

  # Stable, colon-free names for the two GPUs.
  #
  # Hyprland's AQ_DRM_DEVICES is a *colon-separated* list, and every
  # /dev/dri/by-path name contains colons (pci-0000:00:02.0-card), so passing
  # by-path entries makes aquamarine split them into nonsense
  # ("/dev/dri/by-path/pci-0000", "00", "02.0-card"), find no GPUs, and abort
  # with `CBackend::create() failed!` — i.e. no session at all.
  #
  # Raw cardN is not usable either: on this machine the nvidia card enumerates
  # as card0 and the iGPU as card1, and that order is probe-dependent. Hence
  # these symlinks, keyed off the fixed PCI addresses, which is what the
  # session references.
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="card[0-9]*", KERNELS=="0000:00:02.0", SYMLINK+="dri/igpu"
    SUBSYSTEM=="drm", KERNEL=="card[0-9]*", KERNELS=="0000:01:00.0", SYMLINK+="dri/dgpu"

    # The touchpad is an I2C HID Synaptics (CUST0001:00 06CB:CDAD), but psmouse
    # also probes a phantom "PS/2 Synaptics TouchPad" for the same hardware.
    # libinput classifies that phantom as a *mouse*, which is enough to trip
    # any "disable touchpad when a mouse is connected" policy — see the
    # matching dconf override in the adamr@avalon home profile.
    SUBSYSTEM=="input", ATTRS{name}=="PS/2 Synaptics TouchPad", ENV{LIBINPUT_IGNORE_DEVICE}="1"
  '';

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  nixpkgs.hostPlatform.system = "x86_64-linux";

  hardware.graphics.enable = true;

  # nixos-hardware's Intel GPU defaults target Gen12+; UHD 630 is Gen9.5, so
  # OpenCL needs the legacy compute runtime or it simply won't load.
  #
  # mediaRuntime is deliberately left at the Gen12+ default: the Gen8-11 one
  # (intel-media-sdk) is EOL and marked insecure in nixpkgs, and it is not on
  # the path that matters here, since hardware video decode goes through VA-API
  # (iHD), which does not need MediaSDK. The cost is no QSV transcoding, in
  # exchange for not allowlisting an unmaintained media parser.
  #
  # vaapiDriver is left at null (installs both iHD and i965) so
  # LIBVA_DRIVER_NAME can pick either without a rebuild — see adamr@avalon,
  # which defaults the session to iHD.
  hardware.intelgpu.computeRuntime = "legacy";

  hardware.nvidia = {
    modesetting.enable = true;

    # Turing, so the open kernel modules are the supported path. They also
    # enable powerManagement.kernelSuspendNotifier on 595+, which handles
    # suspend/resume in-kernel rather than through the nvidia-suspend and
    # nvidia-resume systemd services.
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.production;

    # Preserve VRAM allocations across suspend/hibernate. Together with the
    # kernel suspend notifier above, this is what makes closing the lid safe.
    powerManagement.enable = true;
    # RTD3: NVreg_DynamicPowerManagement=0x02, i.e. ask the dGPU to power
    # itself down whenever nothing is using it. Requires offload (asserted
    # upstream) and is mutually exclusive with prime sync.
    #
    # RTD3 does not work on this chassis, for firmware reasons rather than
    # driver ones, so this is enabled on principle and saves nothing. The
    # driver wants the _PR3 ACPI method (D3cold power resources) on the PCIe
    # root port above the GPU, and the GS65's DSDT does not provide it:
    # \_SB.PCI0.PEG0 declares only _ADR and _PRT, its PEGP child only _ADR,
    # and the only _PR3 methods in the table belong to XDCI and the
    # Thunderbolt VOL0/VOL1/VOL2 devices. The ACPI node for 0000:00:01.0
    # correspondingly exposes power_resources_D0/D2/D3hot and no
    # power_resources_D3cold, and the driver reports "Runtime D3 status: Not
    # supported" with Video Memory Active on either module flavor. Note that
    # d3cold_allowed = 1 on the GPU is not evidence against this; it is the
    # kernel's permission flag, not a platform capability.
    #
    # The `battery-saver` specialisation below is the only real off switch.
    powerManagement.finegrained = true;

    prime = {
      # Offload rather than sync: under sync the dGPU renders the whole
      # desktop and never idles, which is the wrong trade on battery.
      #
      # enableOffloadCmd (the `nvidia-offload <cmd>` wrapper) is intentionally
      # not set here — nixos-hardware ties it to offload.enable, which is what
      # lets the battery-saver specialisation force offload off without
      # tripping the "offload command requires offloading" assertion.
      offload.enable = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # Adds a `battery-saver` boot entry (nixos-hardware) that blacklists nvidia
  # and removes the dGPU from the PCI bus outright, for long unplugged
  # sessions. Since RTD3 is unavailable here (see above), this is the only way
  # to actually stop powering the card.
  #
  # On the GS65 the HDMI and mini-DP outputs are wired to the dGPU, so external
  # displays do not work in that specialisation; the default generation keeps
  # them working.
  hardware.nvidia.primeBatterySaverSpecialisation = true;
}
