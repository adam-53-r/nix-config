{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations = {
    pc = inputs.nixpkgs.lib.nixosSystem {
      modules = [
        self.nixosModules.pcConfiguration
      ];
    };
    vm = inputs.nixpkgs.lib.nixosSystem {
      modules = [
        self.nixosModules.vmConfiguration
      ];
    };
    oci = inputs.nixpkgs.lib.nixosSystem {
      modules = [
        self.nixosModules.ociConfiguration
      ];
    };
    msi-server = inputs.nixpkgs.lib.nixosSystem {
      modules = [
        self.nixosModules.msiServerConfiguration
      ];
    };
    msi-nixos = inputs.nixpkgs.lib.nixosSystem {
      modules = [
        self.nixosModules.msiNixosConfiguration
      ];
    };
    wsl = inputs.nixpkgs.lib.nixosSystem {
      modules = [
        self.nixosModules.wslConfiguration
      ];
    };
  };
}
