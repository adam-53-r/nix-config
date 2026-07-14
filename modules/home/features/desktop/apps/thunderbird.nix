{
  flake.homeModules.homeThunderbird = {pkgs, ...}: {
    home.packages = [pkgs.thunderbird-latest];
    home.persistence."/persist".directories = [".thunderbird"];
  };
}
