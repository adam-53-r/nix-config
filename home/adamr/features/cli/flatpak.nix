{config, pkgs, ...}:
{
  home.persistence."/persist/${config.home.homeDirectory}".directories = [
    ".local/share/flatpak"
  ];
}
