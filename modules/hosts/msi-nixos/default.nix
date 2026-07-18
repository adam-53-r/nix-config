# The msi-nixos host: MSI laptop running the same Hyprland (uwsm) desktop as
# pc, on an encrypted ephemeral btrfs root behind GRUB+cryptodisk.
{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.msiNixosConfiguration = {
    config,
    pkgs,
    lib,
    ...
  }: {
    key = "mynix#nixosModules.msiNixosConfiguration";

    imports = [
      inputs.nixos-hardware.nixosModules.common-cpu-intel
      inputs.nixos-hardware.nixosModules.common-gpu-intel
      inputs.nixos-hardware.nixosModules.common-pc-ssd
      inputs.nixos-hardware.nixosModules.common-pc-laptop

      self.nixosModules.desktopBase
      self.nixosModules.diskoBtrfs
      self.nixosModules.optionalQuietboot
      self.nixosModules.optionalTlp
      self.nixosModules.optionalWireshark
      self.nixosModules.optionalSteam
      self.nixosModules.optionalLibvirtd
      self.nixosModules.optionalDocker
      self.nixosModules.optionalGns3Server
      self.nixosModules.userAdamr

      ./_hardware.nix
    ];

    networking.hostName = "msi-nixos";

    hardware.disko-btrfs = {
      encrypted = true;
      ephemeral = true;
      # TRIM via fstrim.timer (common-pc-ssd), not continuous discard.
      extraMountOptions = ["nodiscard"];
    };

    # Unlock the LUKS root with the YubiKey (password stays as fallback).
    boot.initrd.luks.devices."msi-nixos" = {
      crypttabExtraOpts = ["fido2-device=auto"];
    };

    # brightnessctl replaces main's programs.light, since removed from
    # nixpkgs (unmaintained); the hyprland brightness binds already use it.
    environment.systemPackages = [pkgs.hostctl pkgs.brightnessctl];
    environment.etc.hosts.mode = "0644";

    # The cinnamon/desktop stack enables power-profiles-daemon by default on
    # current nixpkgs, which refuses to coexist with TLP — TLP wins here.
    services.power-profiles-daemon.enable = lib.mkForce false;

    boot = {
      kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_latest;
      binfmt.emulatedSystems = [
        "aarch64-linux"
        "i686-linux"
      ];
    };

    # On a battery-powered laptop powertop's boot-time auto-tune is wanted
    # (unlike the desktops); TLP's USB_AUTOSUSPEND=0 + the kernel param keep
    # the YubiKey exempt from it.
    powerManagement.powertop.enable = true;

    hardware.bluetooth.powerOnBoot = false;

    # Lid settings
    services.logind.settings.Login = {
      lidSwitch = "suspend";
      lidSwitchExternalPower = "lock";
    };

    services.displayManager.defaultSession = "hyprland-uwsm";

    # gpg-agent as ssh-agent on this host (pc leaves it off).
    programs.gnupg.agent.enableSSHSupport = true;

    system.stateVersion = "25.05";
  };
}
