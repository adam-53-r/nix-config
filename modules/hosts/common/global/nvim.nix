# Neovim available system-wide, shared by every host.
{...}: {
  flake.nixosModules.globalNvim = {...}: {
    programs.neovim.enable = true;
  };
}
