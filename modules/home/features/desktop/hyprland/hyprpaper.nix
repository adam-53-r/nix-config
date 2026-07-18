# Wallpaper daemon; paints config.wallpaper on every configured monitor.
{
  flake.homeModules.homeHyprpaper = {
    lib,
    config,
    ...
  }: {
    services.hyprpaper = {
      enable = true;
      settings = {
        ipc = true;
        splash = false;
        wallpaper = lib.forEach config.monitors (m: {
          monitor = m.name;
          path = "${config.wallpaper}";
        });
      };
    };
  };
}
