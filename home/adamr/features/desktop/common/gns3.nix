{
  pkgs,
  config,
  ...
}: {
  home.packages = with pkgs; [gns3-gui];

  home.persistence."/persist".directories = [
    ".config/GNS3"
    "GNS3"
  ];
}
