{pkgs, config, ...}: {
  home.packages = with pkgs; [drawio];

  home.persistence = {
    "/persist/${config.home.homeDirectory}".directories = [".config/draw.io"];
  };
}
