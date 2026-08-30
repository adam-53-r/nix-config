# The avalon host: an MSI GS65 Stealth 8SF laptop configured as a portable
# dev machine.
#
# The configuration favours battery life, quiet running and surviving a closed
# lid over raw throughput. The dGPU is left to PRIME offload (_hardware.nix),
# power/thermal/battery-health policy lives in _power.nix, and the machine
# hibernates onto an encrypted swapfile rather than dying flat. The desktop is
# the same Hyprland (uwsm) session as pc, on an encrypted ephemeral btrfs root
# with limine + secure boot.
{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.avalonConfiguration = {
    pkgs,
    lib,
    ...
  }: {
    key = "mynix#nixosModules.avalonConfiguration";

    imports = [
      # common-cpu-intel already pulls in the Intel GPU module, so there is no
      # separate common-gpu-intel import here.
      inputs.nixos-hardware.nixosModules.common-cpu-intel
      # = common/gpu/nvidia/prime.nix: turns on PRIME offload and provides the
      # `primeBatterySaverSpecialisation` option used in _hardware.nix.
      inputs.nixos-hardware.nixosModules.common-gpu-nvidia
      inputs.nixos-hardware.nixosModules.common-pc-ssd
      inputs.nixos-hardware.nixosModules.common-pc-laptop

      self.nixosModules.desktopBase
      self.nixosModules.diskoBtrfs
      self.nixosModules.optionalQuietboot
      self.nixosModules.optionalPlymouthHibernate
      self.nixosModules.optionalSecureBoot
      self.nixosModules.optionalSnapshots
      self.nixosModules.optionalAtop
      self.nixosModules.optionalTlp
      self.nixosModules.optionalDocker
      self.nixosModules.optionalLibvirtd
      self.nixosModules.optionalWireshark
      self.nixosModules.userAdamr

      ./_hardware.nix
      ./_power.nix
    ];

    networking.hostName = "avalon";

    hardware.disko-btrfs = {
      encrypted = true;
      ephemeral = true;
      # TRIM via fstrim.timer (common-pc-ssd), not continuous discard. Note
      # that this only reaches the SSD because the LUKS device below sets
      # allowDiscards — without it dm-crypt swallows every discard.
      extraMountOptions = ["nodiscard"];
      # 32G of RAM plus headroom, so a full hibernation image always fits.
      # Lives on the dedicated /swap subvolume (no compression, no snapshots,
      # NOCOW) that diskoBtrfs already carves out.
      swapFileSize = "36G";
    };

    boot = {
      kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_latest;
      # Cross-building for the aarch64 oci host. No i686 entry: 32-bit
      # userland comes from multilib rather than qemu-user, so registering a
      # handler for it achieves nothing.
      binfmt.emulatedSystems = ["aarch64-linux"];
    };

    services.displayManager.defaultSession = "hyprland-uwsm";

    # Distinguish this host's login screen from pc's pixel_sakura.
    # `cyberpunk.conf` and `post-apocalyptic_hacker.conf` are the other dark
    # variants in the astronaut set.
    services.displayManager.sddm.astronaut-theme.config = lib.mkForce "black_hole.conf";

    # brightnessctl in place of programs.light, which nixpkgs has dropped; the
    # hyprland brightness binds and hypridle's dimming call it.
    environment.systemPackages = [pkgs.hostctl pkgs.brightnessctl];
    environment.etc.hosts.mode = "0644";

    # The desktop stack pulls in power-profiles-daemon by default, which
    # refuses to coexist with TLP. TLP wins here (see _power.nix).
    services.power-profiles-daemon.enable = lib.mkForce false;

    # gpg-agent as ssh-agent on this host (pc leaves it off).
    programs.gnupg.agent.enableSSHSupport = true;

    # Installed fresh on 26.11, so there is no legacy state to stay compatible
    # with. Not to be bumped afterwards.
    system.stateVersion = "26.11";
  };
}
