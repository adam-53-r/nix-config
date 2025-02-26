{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix

    ../common/global
    ../common/users/adamr

    ../common/optional/quietboot.nix
  ];

  networking = {
    hostName = "shitbox";
  };

  powerManagement.powertop.enable = true;
  programs = {
    # light.enable = true;
    adb.enable = true;
    dconf.enable = true;
    fish.enable = true;
  };

  # Lid settings
  # services.logind = {
  #   lidSwitch = "suspend";
  #   lidSwitchExternalPower = "lock";
  # };

  system.stateVersion = "25.05";
}