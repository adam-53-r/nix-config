# Gaming aggregate: steam (+gamescope session), prism launcher, mangohud.
{self, ...}: {
  flake.homeModules.homeGames = {pkgs, ...}: {
    imports = [
      self.homeModules.homeSteam
      self.homeModules.homePrismLauncher
      self.homeModules.homeMangohud
    ];

    home.packages = [pkgs.gamescope];
    home.persistence."/persist".directories = ["Games"];
  };
}
