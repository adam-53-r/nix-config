# Aggregate for the wlroots/wayland desktop tooling shared by any wayland
# compositor session (hyprland today): bar, launcher, notifications, locking,
# clipboard history, OSD, night light, image viewer, remote windows.
{self, ...}: {
  flake.homeModules.homeWaylandWm = {pkgs, ...}: {
    imports = [
      self.homeModules.homeAlacritty
      self.homeModules.homeCliphist
      self.homeModules.homeGammastep
      self.homeModules.homeMako
      self.homeModules.homeQutebrowser
      self.homeModules.homeSwayidle
      self.homeModules.homeSwaylock
      self.homeModules.homeWaybar
      self.homeModules.homeWofi
      self.homeModules.homeImv
      self.homeModules.homeWaypipe
      self.homeModules.homeSwayosd
    ];

    xdg.mimeApps.enable = true;
    home.packages = with pkgs; [
      wf-recorder
      wl-clipboard
    ];

    home.sessionVariables = {
      MOZ_ENABLE_WAYLAND = 1;
      QT_QPA_PLATFORM = "wayland";
      LIBSEAT_BACKEND = "logind";
    };
  };
}
