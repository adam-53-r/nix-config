{pkgs, ...}: {
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    extraPackages = with pkgs; [
      glow
      ouch
    ];
    plugins = {
      inherit (pkgs.yaziPlugins) git ouch lsar glow diff piper mount;
    };
    flavors = {
      inherit (pkgs.yaziPlugins) nord;
    };
    theme = {
      flavor.dark = "nord";
    };
  };
}
