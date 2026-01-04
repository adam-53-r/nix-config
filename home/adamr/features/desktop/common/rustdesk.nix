{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs.stable; [rustdesk];

  home.persistence."/persist/${config.home.homeDirectory}".directories = [
    ".config/rustdesk"
  ];
}
