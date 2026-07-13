# Firewall ports for KDE Connect (the app itself is a home-manager feature).
{
  flake.nixosModules.desktopKdeconnect = {
    key = "mynix#nixosModules.desktopKdeconnect";

    networking.firewall = {
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
      allowedUDPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
    };
  };
}
