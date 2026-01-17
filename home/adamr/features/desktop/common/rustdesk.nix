{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs.stable; [rustdesk];

  home.persistence."/persist".directories = [
    ".config/rustdesk"
  ];
}
