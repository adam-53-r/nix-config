{
  self,
  inputs,
  ...
}: let
  # Must stay on the SAME nixpkgs generation as the rest of the flake (just a
  # different `system`), not nixpkgs-stable: for a cross-arch build (aarch64
  # target on an x86_64 host) disko force-overrides nixpkgs.hostPlatform on the
  # in-VM install config with this pkgs' stdenv.hostPlatform. Mixing that with
  # the main unstable-based module tree causes infinite recursion.
  #
  # Separately, disko passes `pkgs.aggregateModules [...]` (a `buildEnv`
  # symlink-merge of the kernel + module derivations, named "kernel-modules")
  # as vmTools' `kernel` argument. Since nixpkgs-unstable's vmTools computes the
  # boot image filename from `kernel.target`, and buildEnv outputs don't carry
  # that attribute, it throws. The real kernel image is still reachable at the
  # merged output's root (buildEnv preserves the underlying kernel's files), so
  # we just need to tell vmTools the filename explicitly to skip that lookup.
  x86Pkgs = import inputs.nixpkgs {
    system = "x86_64-linux";
    overlays = [
      (final: prev: {
        vmTools = prev.vmTools.override {
          kernelImage = prev.linuxPackages.kernel.target;
        };
      })
    ];
  };
in {
  flake.nixosModules.ociHardware = {
    config,
    lib,
    pkgs,
    modulesPath,
    ...
  }: {
    key = "mynix#nixosModules.ociHardware";
    imports = [
      (modulesPath + "/profiles/qemu-guest.nix")
      self.nixosModules.diskoBtrfs
      self.nixosModules.ociRuntime
    ];

    boot.initrd.availableKernelModules = ["xhci_pci" "virtio_pci" "virtio_blk" "sr_mod"];
    boot.initrd.kernelModules = [];
    boot.kernelModules = [];
    boot.extraModulePackages = [];

    boot.loader = {
      efi.canTouchEfiVariables = false;
      grub = {
        enable = true;
        efiSupport = true;
        device = "nodev";
      };
    };

    hardware.disko-btrfs = {
      encrypted = false;
      ephemeral = true;
    };
    disko.devices.disk.main.device = "/dev/sda";
    disko.devices.disk.main.imageSize = "8G";
    disko.imageBuilder.pkgs = x86Pkgs;
    disko.imageBuilder.kernelPackages = x86Pkgs.linuxPackages;
    disko.imageBuilder.enableBinfmt = true;

    swapDevices = [];
    hardware.enableRedistributableFirmware = true;
    nixpkgs.hostPlatform = "aarch64-linux";
  };
}
