# This file (and the global directory) holds config that I use on all hosts
{
  inputs,
  outputs,
  ...
}: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.disko.nixosModules.disko
    ./acme.nix
    ./fish.nix
    ./nvim.nix
    ./locale.nix
    ./nix.nix
    ./openssh.nix
    ./podman.nix
    ./sops.nix
    ./ssh-serve-store.nix
    ./systemd-initrd.nix
    ./tailscale.nix
    ./nix-ld.nix
    ./prometheus-node-exporter.nix
    ./kdeconnect.nix
    ./upower.nix
    ./networking.nix
    ./keymap.nix
    ./optin-persistence.nix
    ./mtr.nix
    # ./auto-upgrade.nix
  ] ++ (builtins.attrValues outputs.nixosModules);

  home-manager.useGlobalPkgs = true;
  home-manager.extraSpecialArgs = {
    inherit inputs outputs;
  };

  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config = {
      allowUnfree = true;
    };
  };

  hardware.enableRedistributableFirmware = true;
  networking.domain = "arm53.xyz";

  # # Increase open file limit for sudoers
  security.pam.loginLimits = [
    {
      domain = "@wheel";
      item = "nofile";
      type = "soft";
      value = "524288";
    }
    {
      domain = "@wheel";
      item = "nofile";
      type = "hard";
      value = "1048576";
    }
  ];

  # Cleanup stuff included by default
  services.speechd.enable = false;
}