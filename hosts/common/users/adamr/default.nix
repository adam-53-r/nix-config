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
      "tss"
      "render"
      "ubridge"
      "video"
      "wheel"
      "wireshark"
      "vboxusers"
      "mysql"
      "gns3"
      "minecraft"
    ];

    hashedPasswordFile = lib.mkIf (!config.disable-user-sops) config.sops.secrets.adamr-password.path;

    openssh.authorizedKeys.keys = lib.splitString "\n" (builtins.readFile ../../../../home/adamr/ssh.pub);
    packages = [pkgs.home-manager];
  };

  sops.secrets = lib.mkIf (!config.disable-user-sops) {
    adamr-password = {
      sopsFile = ../../secrets.json;
      neededForUsers = true;
    };
  };

  home-manager = {
    users.adamr = import ../../../../home/adamr/${config.networking.hostName}.nix;
    backupFileExtension = "hm.bak";
  };

  # security.pam.services = {
  #   swaylock = {};
  # };
}
