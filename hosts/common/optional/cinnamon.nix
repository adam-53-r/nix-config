{
  pkgs,
  lib,
  config,
  ...
}: {
  services.xserver = {
    enable = true;
    tty = lib.mkForce 2;
    displayManager.startx.enable = true;
    desktopManager.cinnamon = {
      enable = true;
    };
  };
  services.cinnamon.apps.enable = true;
  services.speechd.enable = lib.mkForce true;
  services.power-profiles-daemon.enable = false;
}
