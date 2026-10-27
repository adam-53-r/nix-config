{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations = {
    normandy = inputs.nixpkgs.lib.nixosSystem {
      modules = [
        self.nixosModules.normandyConfiguration
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
