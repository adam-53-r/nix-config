# Neovim available system-wide, shared by every host.
{...}: {
  flake.nixosModules.globalNvim = {...}: {
    key = "mynix#nixosModules.globalNvim";
    programs.neovim.enable = true;
  };
}
