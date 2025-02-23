{pkgs, config, ...}: {
  home.packages = with pkgs; [vscodium];

  home.persistence."/persist/${config.home.homeDirectory}".directories = [
    ".vscode-oss"
    ".config/VSCodium"
  ];
}
