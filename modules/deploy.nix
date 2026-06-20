# deploy-rs configuration, ported from the main-branch flake.nix `deploy`
# output. Adapted to the dendritic layout: the flake input is declared in
# flake.nix (inputs can't be added from a module), while the `deploy` output and
# the node definitions live here as their own flake-parts module instead of
# inline in flake.nix.
#
# Adaptations for the OCI host:
#  - Only the `oci` node is defined; the main-branch nodes (msi-server, pc, …)
#    don't exist on this branch.
#  - The target is aarch64-linux, so we use the aarch64-linux deploy-rs lib (the
#    activation script runs on the target). main built for x86_64-linux.
#  - The `deployPkgs` overlay workaround from main is kept: it pins the deploy-rs
#    *binary* to the one already in nixpkgs (cached) while still using the lib
#    from the deploy-rs flake, avoiding a from-source build of deploy-rs.
#  - hostname is "oci" (resolved via Tailscale). For the initial setup, override
#    the address on the command line, e.g.
#    `deploy --hostname <ip-or-tailscale-name> .#oci`.
{
  self,
  inputs,
  ...
}: let
  system = "aarch64-linux";
  deployPkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [
      inputs.deploy-rs.overlays.default
      (_self: super: {
        deploy-rs = {
          inherit (inputs.nixpkgs.legacyPackages.${system}) deploy-rs;
          lib = super.deploy-rs.lib;
        };
      })
    ];
  };
  activate-nixos = deployPkgs.deploy-rs.lib.activate.nixos;
in {
  flake.deploy = {
    sshOpts = ["-A"];
    nodes.oci = {
      hostname = "oci";
      sshUser = "root";
      profiles.system = {
        user = "root";
        path = activate-nixos self.nixosConfigurations.oci;
      };
    };
  };
}
