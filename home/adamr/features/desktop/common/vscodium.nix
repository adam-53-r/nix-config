{
  pkgs,
  config,
  ...
}: {
  home.packages = with pkgs; [vscodium];

  home.persistence."/persist".directories = [
    ".vscode-oss"
    ".config/VSCodium"
  ];
}
