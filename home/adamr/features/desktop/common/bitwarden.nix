{
  pkgs,
  config,
  ...
}: {
  home.packages = [pkgs.bitwarden];
  home.persistence = {
    "/persist/${config.home.homeDirectory}".directories = [".config/Bitwarden"];
  };
}