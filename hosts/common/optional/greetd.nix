{
  pkgs,
  lib,
  config,
  ...
}: let
  homeCfgs = config.home-manager.users;
  homeSharePaths = lib.mapAttrsToList (_: v: "${v.home.path}/share") homeCfgs;
  vars = ''XDG_DATA_DIRS="$XDG_DATA_DIRS:${lib.concatStringsSep ":" homeSharePaths}" GTK_USE_PORTAL=0'';

  adamrCfg = homeCfgs.adamr;

  sway-kiosk = command: "${lib.getExe pkgs.sway} --unsupported-gpu --config ${pkgs.writeText "kiosk.config" ''
    output * bg #000000 solid_color
    xwayland disable
    input "type:touchpad" {
      tap enabled
    }
    exec '${vars} ${command}; ${pkgs.sway}/bin/swaymsg exit'
  ''}";
in {
  users.extraUsers.greeter = {
    # For caching and such
    home = "/tmp/greeter-home";
    createHome = true;
  };

  programs.regreet = {
    enable = true;
    iconTheme = adamrCfg.gtk.iconTheme;
    theme = adamrCfg.gtk.theme;
    font = adamrCfg.fontProfiles.regular;
    cursorTheme = {
      inherit (adamrCfg.gtk.cursorTheme) name package;
    };
    settings.background = {
      path = adamrCfg.wallpaper;
      fit = "Cover";
    };
  };
  services.greetd = {
    enable = true;
    settings.default_session.command = sway-kiosk (lib.getExe config.programs.regreet.package);
  };
}
