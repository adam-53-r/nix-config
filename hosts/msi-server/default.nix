{
  lib,
  inputs,
  config,
  ...
}: {
  imports = [
    ./hardware-configuration.nix

    ../common/global
    ../common/users/adamr

    ../common/optional/quietboot.nix
    ../common/optional/docker.nix
    ../common/optional/ecryptfs.nix
    ../common/optional/fail2ban.nix
    ../common/optional/gns3-server.nix
    ../common/optional/libvirtd.nix
    # ../common/optional/lxd.nix
    ../common/optional/mysql.nix
    ../common/optional/tailscale-exit-node.nix
    # ../common/optional/sftpgo.nix
    ../common/optional/wireguard-server.nix
  ];

  networking = {
    hostName = "msi-server";
  };

  powerManagement.powertop.enable = true;
  programs = {
    # light.enable = true;
    adb.enable = true;
    dconf.enable = true;
    fish.enable = true;
  };

  networking.wireguard.interfaces.wg0 = {
    generatePrivateKeyFile = lib.mkForce false;
    privateKeyFile = config.sops.secrets.wg-priv-key.path;
  };

  sops.secrets.wg-priv-key = {
    sopsFile = ./secrets.json;
  };

  system.stateVersion = "25.05";
}