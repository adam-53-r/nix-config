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


  dconf.settings = {
    "org/cinnamon/desktop/background".picture-uri = "file://${artwork-pkg}/wallpapers/nix-wallpaper-binary-white.png";
  };

}