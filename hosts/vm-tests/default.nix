{
  config,
  inputs,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix

    ../common/global
    ../common/users/adamr

    ../common/optional/quietboot.nix
    ../common/optional/sddm.nix
    # ../common/optional/greetd.nix
    ../common/optional/cinnamon.nix
    ../common/optional/hyprland.nix
    ../common/optional/pipewire.nix
    ../common/optional/tlp.nix
    ../common/optional/cups.nix
    ../common/optional/wireshark.nix
    ../common/optional/x11-no-suspend.nix
    ../common/optional/gns3-client.nix
    # ../common/optional/steam.nix
    # ../common/optional/libvirtd.nix
    ../common/optional/ecryptfs.nix
    ../common/optional/docker.nix
    # ../common/optional/virtualbox.nix
    # ../common/optional/vmware.nix
  ];

  networking = {
    hostName = "vm-tests";
  };

  disable-user-sops = true;

  users.users.adamr = {
    initialHashedPassword = "$y$j9T$lgLih3qHgZnQSSV.Cfk0T1$/BM.PW5.2dc/1yu4069/wF845WW95YBYRpGrSnxPba3";
  };

  powerManagement.powertop.enable = true;
  programs = {
    # light.enable = true;
    adb.enable = true;
    dconf.enable = true;
    fish.enable = true;
  };

  services.displayManager.defaultSession = "hyprland-uwsm";

  system.stateVersion = "25.05";
}
