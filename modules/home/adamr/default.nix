# adamr's host-agnostic home profile: the identity-free cliBase plus the shared
# optional features adamr actually uses (gpg-agent/smartcard, ssh, gh) and the
# personal identity layer. Per-host profiles (e.g. adamr@oci) import this and add
# host-specific bits like enabling persistence.
{self, ...}: {
  flake.homeModules.adamrHome = {...}: {
    imports = [
      self.homeModules.cliBase
      self.homeModules.homeGpg
      self.homeModules.homeSsh
      self.homeModules.homeGh
      self.homeModules.adamrIdentity

      # Reusable option modules (colorscheme, fonts, monitors, wallpaper, …).
      # Pure option declarations with lazy defaults — harmless on headless
      # hosts, required wherever desktop features read config.colorscheme etc.
      self.homeModules.homeColors
      self.homeModules.homeFonts
      self.homeModules.homeMonitors
      self.homeModules.homeWallpaper
      self.homeModules.homeXpo
      self.homeModules.homePassSecretService
    ];

    home.username = "adamr";
    home.homeDirectory = "/home/adamr";

    # Restart changed user units on home-manager switch.
    systemd.user.startServices = "sd-switch";

    # Allow unfree flakes with command-line tools (nix shell nixpkgs#…).
    home.file.".config/nixpkgs/config.nix".text = ''
      {
        allowUnfree = true;
      }
    '';
  };
}
