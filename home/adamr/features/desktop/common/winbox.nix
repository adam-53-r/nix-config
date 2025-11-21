{
  lib,
  pkgs,
  config,
  ...
}: let
  winbox4-xcb = pkgs.writeShellScriptBin "winbox4" ''
    # Force Qt to use X11/XWayland
    export QT_QPA_PLATFORM=xcb

    # Run the real WinBox 4 binary
    exec ${lib.getExe pkgs.winbox4} "$@"
  '';
in {
  home.packages = [winbox4-xcb];
  # Desktop entry so it shows up in menus/launchers
  xdg.desktopEntries.winbox4 = {
    name = "WinBox 4";
    genericName = "MikroTik Router Configuration";
    comment = "Configure MikroTik routers using WinBox 4";
    exec = "${winbox4-xcb}/bin/winbox4";
    terminal = false;
    type = "Application";
    categories = ["Network" "Utility"];
    # Optional: pick any icon name from your icon theme, or adjust later
    icon = "network-workgroup";
  };
  home.persistence = {
    "/persist/${config.home.homeDirectory}".directories = [".local/share/Bitwarden"];
  };
}
