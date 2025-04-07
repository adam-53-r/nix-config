{
  inputs,
  lib,
  pkgs,
  config,
  outputs,
  ...
}: {
  imports = [
      inputs.impermanence.homeManagerModules.impermanence
      ../features/cli
    ]
    ++ (builtins.attrValues outputs.homeManagerModules);

  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "ca-derivations"
      ];
      warn-dirty = false;
    };
  };

  systemd.user.startServices = "sd-switch";

  programs = {
    home-manager.enable = true;
    git = {
      enable = true;
      signing.format = "openpgp";
    };
  };

  home = {
    username = lib.mkDefault "kali";
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    stateVersion = lib.mkDefault "25.05";
    sessionPath = ["$HOME/.local/bin"];
    sessionVariables = {
      FLAKE = "$HOME/mynix";
    };

  };
}