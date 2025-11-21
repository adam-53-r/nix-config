{
  pkgs,
  config,
  ...
}: {
  home.packages = [pkgs.bitwarden-desktop];
  home.persistence = {
    "/persist/${config.home.homeDirectory}".directories = [".config/Bitwarden"];
  };
}
