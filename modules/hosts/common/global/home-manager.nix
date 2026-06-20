# home-manager NixOS integration scaffolding, shared by every host.
# Ported from the home-manager wiring in msi-server `common/global/default.nix`.
# No per-user home configurations are defined here: the msi-server home configs
# are desktop-oriented and intentionally omitted on the headless OCI VM. This
# only sets up the module so a host can add `home-manager.users.<name>` later.
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
