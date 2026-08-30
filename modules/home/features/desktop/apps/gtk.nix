# GTK theming (icons/cursor/font follow the colorscheme mode) and xsettingsd
# so X11/XWayland apps pick the same look up.
#
# On main xsettingsd was enabled with its settings left as a TODO, so no config
# file was generated and the service failed at every login — the settings below
# complete it. (The generated materia gtk.theme experiment was dead code and
# was dropped.)
{
  flake.homeModules.homeGtk = {
    config,
    pkgs,
    lib,
    ...
  }: {
    gtk = {
      enable = true;
      font = {
        inherit (config.fontProfiles.regular) name size;
      };
      # Plain GTK3 apps (and Qt via the gtk3 platform theme) don't honor the
      # portal's prefer-dark; they need an actual dark theme name. adw-gtk3
      # ports the libadwaita look to GTK3 so everything matches.
      colorScheme = config.colorscheme.mode;
      theme = {
        name =
          if config.colorscheme.mode == "dark"
          then "adw-gtk3-dark"
          else "adw-gtk3";
        package = pkgs.adw-gtk3;
      };
      iconTheme = {
        name = "Papirus-${
          if config.colorscheme.mode == "dark"
          then "Dark"
          else "Light"
        }";
        package = pkgs.papirus-icon-theme;
      };
    };

    home.pointerCursor = {
      # Setting the other keys used to be enough to turn cursor generation on;
      # that inference is deprecated and now warns on every evaluation.
      enable = true;
      package = pkgs.apple-cursor;
      name = "macOS";
      size = 24;
    };

    services.xsettingsd = {
      enable = true;
      settings =
        {
          "Net/IconThemeName" = config.gtk.iconTheme.name;
          "Gtk/FontName" = "${config.gtk.font.name} ${toString config.gtk.font.size}";
          "Gtk/CursorThemeName" = config.home.pointerCursor.name;
          "Gtk/CursorThemeSize" = config.home.pointerCursor.size;
        }
        // lib.optionalAttrs (config.gtk.theme != null) {
          "Net/ThemeName" = config.gtk.theme.name;
        };
    };

    # xsettingsd needs an X server, and on a Wayland session that means
    # XWayland, which is not listening yet when graphical-session.target is
    # reached. The service loses the race and exits 1 with "Unable to open
    # connection to X server", so it has to be allowed to try again; there is
    # no target that means "XWayland is up".
    #
    # home-manager's own module sets Restart = "on-abort", which covers a
    # signal but not a clean non-zero exit, so it never retried. mkForce is
    # required to replace it. The burst is raised because the default of five
    # tries in ten seconds is spent before the socket appears.
    systemd.user.services.xsettingsd = {
      Unit = {
        StartLimitIntervalSec = 60;
        StartLimitBurst = 10;
      };
      Service = {
        Restart = lib.mkForce "on-failure";
        RestartSec = 2;
      };
    };

    # GTK3 under Wayland reads the theme name from gsettings, not settings.ini.
    dconf.settings."org/gnome/desktop/interface".gtk-theme = config.gtk.theme.name;

    xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gtk];
  };
}
