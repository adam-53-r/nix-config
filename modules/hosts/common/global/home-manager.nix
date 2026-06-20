# home-manager NixOS integration scaffolding, shared by every host.
{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.globalHomeManager = {...}: {
    imports = [inputs.home-manager.nixosModules.home-manager];

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "hm.bak";
      extraSpecialArgs = {inherit inputs self;};
    };
  };
}
