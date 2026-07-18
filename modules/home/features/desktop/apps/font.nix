# Font selection for the fontProfiles options.
{
  flake.homeModules.homeFont = {pkgs, ...}: {
    fontProfiles = {
      enable = true;
      monospace = {
        name = "FiraMono Nerd Font";
        package = pkgs.nerd-fonts.fira-mono;
      };
      regular = {
        name = "Fira Sans";
        package = pkgs.fira;
      };
    };
  };
}
