{
  pkgs,
  config,
  ...
}: {
  home.packages = with pkgs; [drawio];

  home.persistence = {
    "/persist".directories = [".config/draw.io"];
  };
}
