{pkgs, config, ...}: {
  home.packages = with pkgs; [gns3-gui];

  home.persistence."/persist/${config.home.homeDirectory}".directories = [
    ".config/GNS3"
  ];
}
