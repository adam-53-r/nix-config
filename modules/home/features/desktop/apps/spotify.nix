{
  flake.homeModules.homeSpotify = {pkgs, ...}: {
    home.packages = [pkgs.spotify];
    home.persistence."/persist".directories = [".config/spotify"];
  };
}
