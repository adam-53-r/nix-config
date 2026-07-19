# The pc host: AMD desktop workstation running Hyprland (uwsm) with Cinnamon
# as fallback, on an encrypted ephemeral btrfs root with limine secure boot.
{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.pcConfiguration = {pkgs, ...}: {
    key = "mynix#nixosModules.pcConfiguration";

    imports = [
      inputs.nixos-hardware.nixosModules.common-cpu-amd
      inputs.nixos-hardware.nixosModules.common-pc-ssd

      self.nixosModules.desktopBase
      self.nixosModules.diskoBtrfs
      self.nixosModules.optionalQuietboot
      self.nixosModules.optionalSecureBoot
      self.nixosModules.optionalSnapshots
      self.nixosModules.optionalSteam
      self.nixosModules.optionalGamingPerf
      self.nixosModules.optionalLibvirtd
      self.nixosModules.optionalDocker
      self.nixosModules.optionalWireshark
      self.nixosModules.optionalGns3Server
      self.nixosModules.optionalPersistBackup
      self.nixosModules.optionalFlatpak
      self.nixosModules.optionalAtop
      self.nixosModules.userAdamr

      ./_hardware.nix
      ./_peripherals.nix
      ./_wireguard.nix
      ./_backup.nix
      ./_ups.nix
      ./_ai.nix
    ];

    networking.hostName = "pc";

    hardware.disko-btrfs = {
      encrypted = true;
      ephemeral = true;
      # TRIM is handled by fstrim.timer (common-pc-ssd), not continuous discard.
      extraMountOptions = ["nodiscard"];
    };

    boot = {
      kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_latest;
      binfmt.emulatedSystems = [
        "aarch64-linux"
        "i686-linux"
      ];
    };

    services.displayManager.defaultSession = "hyprland-uwsm";

    environment.systemPackages = with pkgs; [hostctl android-tools moonlight-qt];
    environment.etc.hosts.mode = "0644";

    system.stateVersion = "25.05";
  };
}
