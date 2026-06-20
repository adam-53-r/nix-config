# nix-ld so dynamically-linked foreign binaries can run, shared by every host.
{...}: {
  flake.nixosModules.globalNixLd = {...}: {
    programs.nix-ld.enable = true;
  };
}
