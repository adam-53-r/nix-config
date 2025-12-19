{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.nixos-wsl.nixosModules.default

    ../common/global
    ../common/users/adamr
  ];

  wsl = {
    enable = true;
    defaultUser = "adamr";
    interop.includePath = false;
  };

  networking = {
    hostName = "wsl";
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

  programs = {
    adb.enable = true;
    dconf.enable = true;
    fish.enable = true;
  };

  # programs.gnupg.agent = {
  #   enable = true;
  #   # enableSSHSupport = true;
  # };

  nixpkgs.hostPlatform.system = "x86_64-linux";
  system.stateVersion = "25.05";
}
