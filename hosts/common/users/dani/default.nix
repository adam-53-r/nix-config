{
  pkgs,
  config,
  lib,
  ...
}: let
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in {
  users.mutableUsers = false;
  users.users.dani = {
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
      # "i2c"
      # "minecraft"
      # "mysql"
    ];

    hashedPasswordFile = config.sops.secrets.dani-password.path;

    openssh.authorizedKeys.keys = lib.splitString "\n" (builtins.readFile ../../../../home/dani/ssh.pub);
    packages = [pkgs.home-manager];
  };

  sops.secrets.dani-password = {
    sopsFile = ../../secrets.json;
    neededForUsers = true;
  };

  home-manager = {
    users.dani = import ../../../../home/dani/${config.networking.hostName}.nix;
    backupFileExtension = "hm.bak";
  };

  # security.pam.services = {
  #   swaylock = {};
  # };
}