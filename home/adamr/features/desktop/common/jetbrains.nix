{
  pkgs,
  config,
  ...
}: {
  home.packages = with pkgs.stable; [
    jetbrains.clion
    jetbrains.rust-rover
    jetbrains.webstorm
  ];

  home.persistence."/persist/${config.home.homeDirectory}".directories = [
    ".config/JetBrains"
  ];
}
