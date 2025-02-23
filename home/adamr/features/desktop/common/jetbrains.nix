{pkgs, config, ...}: {
  home.packages = with pkgs; [
    jetbrains.clion
    jetbrains.rust-rover
    jetbrains.webstorm
  ];

  home.persistence."/persist/${config.home.homeDirectory}".directories = [
    ".config/JetBrains"
  ];
}
