{
  flake.homeModules.homeVscodium = {pkgs, ...}: {
    home.packages = [pkgs.vscodium];
    home.persistence."/persist".directories = [
      ".vscode-oss"
      ".config/VSCodium"
    ];
  };
}
