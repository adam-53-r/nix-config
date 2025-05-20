{pkgs, ...}: {
  imports = [
    ./global
    ./features/desktop/cinnamon
    ./features/desktop/hyprland
    ./features/games
    ./features/productivity
    ./features/pass
  ];

  # Red
  wallpaper = pkgs.inputs.themes.wallpapers.kosmos-space-dark;

  monitors = [
    {
      name = "Virtual-1";
      width = 1920;
      height = 1080;
      workspace = "1";
      refreshRate = 60;
      primary = true;
    }
  ];

}
