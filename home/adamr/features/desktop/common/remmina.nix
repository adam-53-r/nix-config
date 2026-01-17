{
  pkgs,
  config,
  ...
}: {
  home.packages = with pkgs; [remmina];
  home.persistence."/persist".directories = [
    ".config/remmina"
    ".local/share/remmina"
  ];
}
