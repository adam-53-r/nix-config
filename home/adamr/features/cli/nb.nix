{
  pkgs,
  config,
  lib,
  ...
}: {
  home.packages = [pkgs.nb];
  home.persistence = {
    "/persist".directories = [".nb"];
  };
}
