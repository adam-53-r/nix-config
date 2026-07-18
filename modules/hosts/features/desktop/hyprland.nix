# Hyprland compositor, launched through UWSM (systemd-managed session).
# The system owns the compositor package; home-manager only renders config
# (wayland.windowManager.hyprland.package = null on the home side).
{
  flake.nixosModules.desktopHyprland = {pkgs, ...}: {
    key = "mynix#nixosModules.desktopHyprland";

    programs = {
      hyprland = {
        enable = true;
        withUWSM = true;
        xwayland.enable = true;
      };
      uwsm.enable = true;
      hyprlock.enable = true;
    };

    environment.systemPackages = with pkgs; [
      wofi
      wofi-emoji
      wl-clipboard
    ];
  };
}
