{
  pkgs,
  config,
  lib,
  ...
}: let
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in {
  users.mutableUsers = false;
  users.users.adamr = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = ifTheyExist [
      "audio"
      "deluge"
      "dialout"
      "docker"
      "git"
      "libvirtd"
      "lxd"
      "network"
      "networkmanager"
      "plugdev"
      "podman"
      "render"
      "ubridge"
      "video"
      "wheel"
      "wireshark"
      "vboxusers"
      "mysql"
    ];

    hashedPasswordFile = lib.mkDefault config.sops.secrets.adamr-password.path;

    openssh.authorizedKeys.keys = lib.splitString "\n" (builtins.readFile ../../../../home/adamr/ssh.pub);
    packages = [pkgs.home-manager];
  };

  sops.secrets.adamr-password = {
    sopsFile = ../../secrets.json;
    neededForUsers = true;
  };

  home-manager = {
    users.adamr = import ../../../../home/adamr/${config.networking.hostName}.nix;
    backupFileExtension = "hm.bak";
  };

  # security.pam.services = {
  #   swaylock = {};
  # };
}