{
  flake.homeModules.homeDrawio = {pkgs, ...}: {
    home.packages = [pkgs.drawio];
    home.persistence."/persist".directories = [".config/draw.io"];
  };
}
