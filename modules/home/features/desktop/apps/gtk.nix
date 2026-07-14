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

    xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gtk];
  };
}
