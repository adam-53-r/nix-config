{
  flake.homeModules.homeBitwarden = {pkgs, ...}: {
    home.packages = [pkgs.bitwarden-desktop];
    home.persistence."/persist".directories = [".config/Bitwarden"];
  };
}
