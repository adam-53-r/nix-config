{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";

    systems.url = "github:nix-systems/default-linux";

    # Wallpapers + colorscheme generation (pkgs.inputs.themes via the
    # flake-inputs overlay; used by the homeColors/homeWallpaper modules).
    # NOTE: must NOT follow our nixpkgs — the colorscheme generator changes
    # behaviour on unstable (demands a --prefer color for multi-hue
    # wallpapers); its own pinned nixpkgs reproduces main's colorschemes.
    themes = {
      url = "github:adam-53-r/themes";
      inputs.systems.follows = "systems";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
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

    # Hardware quirk modules (cpu microcode, ssd fstrim, ...).
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Declarative remote deployment. Inputs must live in flake.nix (they're
    # resolved before module evaluation); the `deploy` output and the per-host
    # node definitions live in modules/deploy.nix. Follow our nixpkgs to keep
    # the closure small.
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Minecraft server management (systemd hardening, dataDir, symlinks/files
    # for mods+configs, ...). Used by the oci host's Minecraft module.
    nix-minecraft = {
      url = "github:Infinidoge/nix-minecraft";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake {inherit inputs;} (inputs.import-tree ./modules);
}
