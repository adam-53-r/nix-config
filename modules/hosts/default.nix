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
  };
}
