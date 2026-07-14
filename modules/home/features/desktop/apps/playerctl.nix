# playerctld so media keys always target the most recent player.
{
  flake.homeModules.homePlayerctl = {pkgs, ...}: {
    home.packages = [pkgs.playerctl];
    services.playerctld.enable = true;
  };
}
