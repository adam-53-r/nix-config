{inputs, ...}: {
  config = {
    # nix-systems/default-linux == ["aarch64-linux" "x86_64-linux"], which is
    # every platform this repo actually targets. Enumerating darwin here (the
    # flake-parts template default) is not just dead weight: nixpkgs 26.11
    # dropped x86_64-darwin outright, so evaluating perSystem for it throws.
    systems = import inputs.systems;
  };
}
