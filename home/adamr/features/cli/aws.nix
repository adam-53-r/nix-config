{
  pkgs,
  config,
  ...
}: {
  home.packages = [pkgs.awscli2];
  home.persistence = {
    "/persist".directories = [".aws"];
  };
}
