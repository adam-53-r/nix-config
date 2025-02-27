{
  pkgs,
  inputs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix

    ../common/global
    ../common/users/adamr

    ../common/optional/quietboot.nix
  ];

  networking = {
    hostName = "vm-tests";
  };

  users.users.adamr = {
    hashedPasswordFile = lib.mkForce null;
    initialHashedPassword = "$y$j9T$lgLih3qHgZnQSSV.Cfk0T1$/BM.PW5.2dc/1yu4069/wF845WW95YBYRpGrSnxPba3";
  };

  powerManagement.powertop.enable = true;
  programs = {
    adb.enable = true;
    dconf.enable = true;
    fish.enable = true;
  };

  system.stateVersion = "25.05";
}