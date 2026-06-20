# mtr network diagnostic tool, shared by every host.
{...}: {
  flake.nixosModules.globalMtr = {...}: {
    programs.mtr.enable = true;
  };
}
