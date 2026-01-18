{lib, config, ...}: {
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = true;
      splash = false;
      # preload = "${config.wallpaper}";
      wallpaper = lib.forEach config.monitors (m: {
        monitor = m.name;
        path = "${config.wallpaper}";
      });
    };
  };
}
