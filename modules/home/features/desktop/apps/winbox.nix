# WinBox 4 forced onto XWayland (Qt xcb) — the native wayland path misbehaves.
{
  flake.homeModules.homeWinbox = {
    lib,
    pkgs,
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
    xdg.desktopEntries.winbox4 = {
      name = "WinBox 4";
      genericName = "MikroTik Router Configuration";
      comment = "Configure MikroTik routers using WinBox 4";
      exec = "${winbox4-xcb}/bin/winbox4";
      terminal = false;
      type = "Application";
      categories = ["Network" "Utility"];
      icon = "network-workgroup";
    };
    home.persistence."/persist".directories = [".local/share/MikroTik"];
  };
}
