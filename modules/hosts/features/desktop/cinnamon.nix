# Cinnamon as fallback desktop session (Hyprland is the default; this keeps a
# conventional DE available from the SDDM session picker).
{
  flake.nixosModules.desktopCinnamon = {
    key = "mynix#nixosModules.desktopCinnamon";

    services.xserver.desktopManager.cinnamon.enable = true;
    services.cinnamon.apps.enable = true;
  };
}
