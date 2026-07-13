# Global nix daemon settings, shared by every host.
{inputs, ...}: {
  flake.nixosModules.globalNix = {lib, ...}: let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    key = "mynix#nixosModules.globalNix";
    nix = {
      settings = {
        extra-substituters = lib.mkAfter [
          "https://cache.arm53.xyz"
        ];
        trusted-public-keys = [
          "cache.arm53.xyz:GEscuhzZqqKd7b3xFFk3AjKAJoYCGVcTimTYq56mcH8="
        ];
        trusted-users = [
          "root"
          "@wheel"
        ];
        auto-optimise-store = lib.mkDefault true;
        experimental-features = [
          "nix-command"
          "flakes"
          "ca-derivations"
        ];
        warn-dirty = false;
        system-features = [
          "kvm"
          "big-parallel"
          "nixos-test"
        ];
        flake-registry = ""; # Disable global flake registry
      };
      gc = {
        automatic = true;
        dates = "weekly";
        # Keep the last few days of generations
        options = "--delete-older-than 3d";
      };

      # Opinionated: disable channels
      channel.enable = false;

      # Add each flake input as a registry entry and nix_path entry
      registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    };
  };
}
