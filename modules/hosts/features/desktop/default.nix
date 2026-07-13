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
  };
}
