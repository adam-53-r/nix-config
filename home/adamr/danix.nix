{
  pkgs,
  lib,
  ...
}: let
  artwork-pkg = builtins.fetchGit {
    url = "https://github.com/NixOS/nixos-artwork";
    rev = "33856d7837cb8ba76c4fc9e26f91a659066ee31f";
  };
in {
  imports = [
    ./global
    ./features/desktop/cinnamon
    ./features/desktop/hyprland
    ./features/games
  ];

  # Red
  wallpaper = pkgs.inputs.themes.wallpapers.cyberpunk-city-red;

  monitors = [
    {
      name = "HDMI-A-1";
      width = 2560;
      height = 1440;
      workspace = "1";
      primary = true;
      refreshRate = 75;
    }
    {
      name = "eDP-1";
      width = 2560;
      height = 1440;
      workspace = "1";
      position = "auto-right";
      refreshRate = 165;
    }
  ];

  wayland.windowManager.hyprland.settings.env = [
    "AQ_DRM_DEVICES,/dev/dri/card1"
    "LIBVA_DRIVER_NAME,nvidia"
    "__GLX_VENDOR_LIBRARY_NAME,nvidia"
    "NVD_BACKEND,direct"
  ];

  dconf.settings = {
    "org/cinnamon/desktop/background".picture-uri = "file://${artwork-pkg}/wallpapers/nix-wallpaper-binary-white.png";
  };
}
