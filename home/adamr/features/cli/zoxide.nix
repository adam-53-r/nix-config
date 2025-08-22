{config, pkgs, ...}:
{
  # Modern cd command replacement with intelligent directory jumping
  home.packages = with pkgs; [ zoxide ];
  home.persistence."/persist/${config.home.homeDirectory}".directories = [
    ".local/share/zoxide"
  ];
}
