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
    nostromo = inputs.nixpkgs.lib.nixosSystem {
      modules = [
        self.nixosModules.nostromoConfiguration
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
