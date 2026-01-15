{
  pkgs,
  config,
  ...
}: {
  home.packages = with pkgs; [remmina];
  home.persistence."/persist/${config.home.homeDirectory}".directories = [
    ".config/remmina"
    ".local/share/remmina"
  ];
}
