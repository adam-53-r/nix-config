{
  pkgs,
  config,
  ...
}: {
  home.packages = [pkgs.wine];
  home.persistence = {
    "/persist/${config.home.homeDirectory}".directories = [".wine"];
  };
}