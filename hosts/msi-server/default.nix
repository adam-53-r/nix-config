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
    ../common/optional/docker.nix
    ../common/optional/ecryptfs.nix
    ../common/optional/fail2ban.nix
    ../common/optional/gns3-server.nix
    ../common/optional/libvirtd.nix
    ../common/optional/lxd.nix
    ../common/optional/mysql.nix
    ../common/optional/tailscale-exit-node.nix
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

  # Lid settings
  # services.logind = {
  #   lidSwitch = "suspend";
  #   lidSwitchExternalPower = "lock";
  # };

  system.stateVersion = "25.05";
}