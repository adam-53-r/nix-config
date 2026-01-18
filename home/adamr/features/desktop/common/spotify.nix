{
  pkgs,
  config,
  ...
}: {
  home.packages = with pkgs; [spotify];
  home.persistence."/persist".directories = [
    ".config/spotify"
  ];
}
