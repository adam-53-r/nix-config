{
  pkgs,
  lib,
  config,
  ...
}: {
  services.xserver = {
    enable = true;
    displayManager.startx.enable = true;
    desktopManager.cinnamon = {
      enable = true;
    };
  };
  services.cinnamon.apps.enable = true;
  services.power-profiles-daemon.enable = false;
}
