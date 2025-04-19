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
    ../common/users/dani

    ../common/optional/quietboot.nix
    ../common/optional/sddm.nix
    ../common/optional/cinnamon.nix
    ../common/optional/pipewire.nix
    ../common/optional/tlp.nix
    ../common/optional/cups.nix
    ../common/optional/wireshark.nix
    ../common/optional/x11-no-suspend.nix
    ../common/optional/gns3-client.nix
    ../common/optional/steam.nix
    ../common/optional/libvirtd.nix
    ../common/optional/ecryptfs.nix
    ../common/optional/docker.nix
    ../common/optional/hyprland.nix
    # ../common/optional/virtualbox.nix
    # ../common/optional/vmware.nix
  ];

  networking = {
    hostName = "danix";
  };

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_latest;
    binfmt.emulatedSystems = [
      "aarch64-linux"
      "i686-linux"
    ];
  };

  powerManagement.powertop.enable = true;
  programs = {
    # light.enable = true;
    adb.enable = true;
    dconf.enable = true;
    fish.enable = true;
  };

  # Lid settings
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "lock";
  };

  services.displayManager.defaultSession = "cinnamon";

  system.stateVersion = "25.05";
}
