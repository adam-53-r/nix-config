{
  pkgs,
  config,
  ...
}: {
  home.packages = with pkgs; [thunderbird-latest];
  home.persistence."/persist/${config.home.homeDirectory}".directories = [
    ".thunderbird"
  ];
}
