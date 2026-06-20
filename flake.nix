{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Per-user environment management. Pin to the release branch matching
    # nixpkgs (26.05) and follow our nixpkgs to avoid version drift.
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secret management via age/ssh host keys (used by the global sops module).
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Opt-in persistence; pairs with the ephemeral btrfs root rollback so that
    # only explicitly listed paths survive a reboot.
    impermanence.url = "github:nix-community/impermanence";

    # Declarative remote deployment. Inputs must live in flake.nix (they're
    # resolved before module evaluation); the `deploy` output and the per-host
    # node definitions live in modules/deploy.nix. Follow our nixpkgs to keep
    # the closure small.
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake {inherit inputs;} (inputs.import-tree ./modules);
}
