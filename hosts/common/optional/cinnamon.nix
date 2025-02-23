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

  # programs.dconf.profiles.user = {
  #   databases = [{
  #     lockAll = true;
  #     settings = {
  #       "org/nemo/preferences" = {
  #         show-hidden-files = true;
  #       };
  #     };
  #   }];
  # };

  services.tlp.enable = lib.mkForce false;
  services.speechd.enable = lib.mkForce true;
}