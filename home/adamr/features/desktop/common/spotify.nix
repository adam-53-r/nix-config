{
  pkgs,
  config,
  ...
}: {
  home.packages = with pkgs; [spotify];
  home.persistence."/persist/${config.home.homeDirectory}".directories = [
    # ".config/GNS3"
    # "GNS3"
  ];
}
