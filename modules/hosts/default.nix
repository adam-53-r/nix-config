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
    blacksite = inputs.nixpkgs.lib.nixosSystem {
      modules = [
        self.nixosModules.blacksiteConfiguration
      ];
    };
    bebop = inputs.nixpkgs.lib.nixosSystem {
      modules = [
        self.nixosModules.bebopConfiguration
      ];
    };
    msi-server = inputs.nixpkgs.lib.nixosSystem {
      modules = [
        self.nixosModules.msiServerConfiguration
      ];
    };
    avalon = inputs.nixpkgs.lib.nixosSystem {
      modules = [
        self.nixosModules.avalonConfiguration
      ];
    };
    wsl = inputs.nixpkgs.lib.nixosSystem {
      modules = [
        self.nixosModules.wslConfiguration
      ];
    };
  };
}
