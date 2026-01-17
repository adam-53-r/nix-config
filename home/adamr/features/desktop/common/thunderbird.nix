{
  pkgs,
  config,
  ...
}: {
  home.packages = with pkgs; [thunderbird-latest];
  home.persistence."/persist".directories = [
    ".thunderbird"
  ];
}
