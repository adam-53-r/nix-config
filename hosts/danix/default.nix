{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix

    ../common/global
    ../common/users/dani
    ../common/users/adamr

    ../common/optional/quietboot.nix
    ../common/optional/sddm.nix
    ../common/optional/cinnamon.nix
    ../common/optional/pipewire.nix
    ../common/optional/tlp.nix
    ../common/optional/cups.nix
    ../common/optional/wireshark.nix
    ../common/optional/x11-no-suspend.nix
    ../common/optional/gns3.nix
    ../common/optional/steam.nix
    ../common/optional/libvirtd.nix
    ../common/optional/ecryptfs.nix
    ../common/optional/docker.nix
    ../common/optional/hyprland.nix
    # ../common/optional/virtualbox.nix
    # ../common/optional/vmware.nix
  ];

  disable-user-sops = true;

  users.users.adamr = {
    hashedPasswordFile = config.sops.secrets.adamr-password.path;
  };

  sops.secrets = {
    adamr-password = {
      sopsFile = ./secrets.json;
      neededForUsers = true;
    };
  };

  networking = {
    hostName = "danix";
    domain = lib.mkForce "tail4bc4b5.ts.net";
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

  # SDDM theme
  # Adding the sddm theme package
  environment.systemPackages = [
    (
      pkgs.catppuccin-sddm.override {
        # flavor = "mocha";
        # font  = "Noto Sans";
        # fontSize = "9";
        # background = "${./wallpaper.png}";
        # loginBackground = true;
      }
    )
  ];
  # Setting up the theme with the required dependencies
  services.displayManager.sddm = lib.mkForce {
    enable = true;
    wayland.enable = true;
    package = pkgs.kdePackages.sddm;
    theme = "catppuccin-mocha";
    extraPackages = with pkgs.kdePackages; [
      breeze-icons
      kirigami
      plasma5support
      qtsvg
      qtvirtualkeyboard
    ];
  };

  system.stateVersion = "25.05";
}
