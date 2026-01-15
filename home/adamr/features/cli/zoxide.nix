{
  config,
  pkgs,
  ...
}: {
  # Modern cd command replacement with intelligent directory jumping
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  home.persistence."/persist/${config.home.homeDirectory}".directories = [
    ".local/share/zoxide"
  ];
}
