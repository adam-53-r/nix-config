{
  self,
  inputs,
  ...
}: let
  # Per-target-arch deploy-rs `lib.activate`, keeping the overlay workaround
  # from main: pin the deploy-rs *binary* to the one already cached in
  # nixpkgs for that system, while still using `lib` from the deploy-rs
  # overlay, avoiding a from-source build of deploy-rs for every arch.
  activateNixosFor = system: let
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
  in
    deployPkgs.deploy-rs.lib.activate.nixos;

  mkNode = {
    hostname,
    system,
    sshUser ? "root",
  }: hostConfig: {
    inherit hostname sshUser;
    profiles.system = {
      user = "root";
      path = (activateNixosFor system) hostConfig;
    };
  };
in {
  flake.deploy = {
    sshOpts = ["-A"];
    nodes = {
      oci =
        mkNode {
          hostname = "oci";
          system = "aarch64-linux";
        }
        self.nixosConfigurations.oci;
      pc =
        mkNode {
          hostname = "pc";
          system = "x86_64-linux";
        }
        self.nixosConfigurations.pc;
      msi-server =
        mkNode {
          hostname = "msi-server";
          system = "x86_64-linux";
        }
        self.nixosConfigurations.msi-server;
    };
  };
}
