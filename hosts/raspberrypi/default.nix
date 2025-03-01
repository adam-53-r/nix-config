{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix

    ../common/global
    ../common/users/adamr
  ];

  networking = {
    hostName = "raspberrypi";
  };

  powerManagement.powertop.enable = true;
  programs = {
    dconf.enable = true;
    fish.enable = true;
  };

  system.stateVersion = "25.05";
}