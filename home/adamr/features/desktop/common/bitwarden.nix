{
  pkgs,
  config,
  ...
}: {
  home.packages = [pkgs.bitwarden-desktop];
  home.persistence = {
    "/persist".directories = [".config/Bitwarden"];
  };
}
