# Baseline for physical desktop workstations: everything a graphical machine
# needs on top of globalDefaults. Per-host bits (hardware, disko, users,
# session choice) live in the host directory.
{self, ...}: {
  flake.nixosModules.desktopBase = {
    key = "mynix#nixosModules.desktopBase";

    imports = [
      self.nixosModules.globalDefaults

      self.nixosModules.desktopSddm
      self.nixosModules.desktopHyprland
      self.nixosModules.desktopCinnamon
      self.nixosModules.desktopPipewire
      self.nixosModules.desktopPrinting
      self.nixosModules.desktopNetworking
      self.nixosModules.desktopKeyd
      self.nixosModules.desktopYubikey
      self.nixosModules.desktopTpm
      self.nixosModules.desktopKdeconnect
      self.nixosModules.desktopPass
    ];

    programs.dconf.enable = true;

    services.upower.enable = true;

    # Geoclue location service — gammastep's night light reads its location
    # from it (main enabled this globally via locale.nix; only desktops
    # actually consume it).
    location.provider = "geoclue2";

    # bitwarden-desktop on unstable still bundles an EOL electron; accept it
    # until upstream bumps (revisit whenever this list grows).
    nixpkgs.config.permittedInsecurePackages = [
      "electron-39.8.10"
    ];
  };
}
