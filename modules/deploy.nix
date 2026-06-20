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
