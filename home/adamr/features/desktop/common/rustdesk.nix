{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [rustdesk];

  home.persistence."/persist/${config.home.homeDirectory}".directories = [
    ".config/rustdesk"
  ];
}
