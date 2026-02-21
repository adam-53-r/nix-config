{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix

    ../common/global
    ../common/users/adamr

    # ../common/optional/secure-boot.nix
    ../common/optional/quietboot.nix
    ../common/optional/sddm.nix
    ../common/optional/cinnamon.nix
    ../common/optional/hyprland.nix
    ../common/optional/pipewire.nix
    ../common/optional/tlp.nix
    ../common/optional/cups.nix
    ../common/optional/wireshark.nix
    ../common/optional/x11-no-suspend.nix
    ../common/optional/steam.nix
    ../common/optional/libvirtd.nix
    ../common/optional/docker.nix
    ../common/optional/virtualbox.nix
    # ../common/optional/vmware.nix
    ../common/optional/gns3.nix
    ../common/optional/gns3-server.nix
  ];

  networking = {
    hostName = "msi-nixos";
  };

  environment.systemPackages = [pkgs.hostctl];
  environment.etc.hosts.mode = "0644";

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_latest;
    binfmt.emulatedSystems = [
      "aarch64-linux"
      "i686-linux"
    ];
  };

  powerManagement.powertop.enable = true;
  programs = {
    light.enable = true;
    dconf.enable = true;
    fish.enable = true;
  };

  hardware.bluetooth.powerOnBoot = false;

  # Lid settings
  services.logind.settings.Login = {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "lock";
  };

  services.displayManager.defaultSession = "hyprland-uwsm";

  services.udev.packages = [pkgs.yubikey-manager];

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth = true;
  };

  security.pam.u2f = {
    enable = true;
    settings.cue = true;
    control = "sufficient";
  };

  services.pcscd.enable = true;

  # Configuration to use your Luks device
  boot.initrd.luks.devices = {
    "msi-nixos" = {
      crypttabExtraOpts = ["fido2-device=auto"];
    };
  };

  system.stateVersion = "25.05";
}
