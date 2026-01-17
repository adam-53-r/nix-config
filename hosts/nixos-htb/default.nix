{
  pkgs,
  inputs,
  lib,
  config,
  ...
}: {
  imports = [
    ./hardware-configuration.nix

    ../common/global
    ../common/users/adamr

    ../common/optional/quietboot.nix
    ../common/optional/sddm.nix
    ../common/optional/cinnamon.nix
    ../common/optional/pipewire.nix
    ../common/optional/tlp.nix
    ../common/optional/wireshark.nix
    ../common/optional/x11-no-suspend.nix
    ../common/optional/docker.nix
  ];

  networking = {
    hostName = "nixos-htb";
  };

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_latest;
  };

  users.users.adamr = {
    hashedPasswordFile = lib.mkForce config.sops.secrets.adamr-htb-password.path;
  };

  sops.secrets = lib.mkForce {
    adamr-htb-password = {
      sopsFile = ./secrets.json;
      neededForUsers = true;
    };
  };

  services.spice-vdagentd.enable = true;
  services.qemuGuest.enable = true;

  powerManagement.powertop.enable = true;
  programs = {
    adb.enable = true;
    dconf.enable = true;
    fish.enable = true;
  };

  services.displayManager.defaultSession = "cinnamon";

  system.stateVersion = "25.05";
}
