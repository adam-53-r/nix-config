{
  pkgs,
  config,
  ...
}: {
  home.packages = [pkgs.awscli2];
  home.persistence = {
    "/persist/${config.home.homeDirectory}".directories = [".aws"];
  };
}
