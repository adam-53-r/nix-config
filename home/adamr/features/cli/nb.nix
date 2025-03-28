{
  pkgs,
  config,
  lib,
  ...
}: {
  home.packages = [pkgs.nb];
  home.persistence = {
    "/persist/${config.home.homeDirectory}".directories = [".nb"];
  };
}