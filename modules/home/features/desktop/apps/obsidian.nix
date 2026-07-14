{
  flake.homeModules.homeObsidian = {pkgs, ...}: {
    home.packages = [pkgs.obsidian];
    home.persistence."/persist".directories = [".config/obsidian/"];
  };
}
