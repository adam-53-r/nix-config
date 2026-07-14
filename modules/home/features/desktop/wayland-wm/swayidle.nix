# Idle management: lock the session after 10 minutes.
{
  flake.homeModules.homeSwayidle = {config, ...}: let
    swaylock = "${config.programs.swaylock.package}/bin/swaylock";
    lockTime = 10 * 60; # TODO: configurable desktop (10 min)/laptop (4 min)
  in {
    services.swayidle = {
      enable = true;
      timeouts = [
        {
          timeout = lockTime;
          command = "${swaylock} -i ${config.wallpaper} --daemonize --grace 15 --grace-no-mouse";
        }
      ];
    };
  };
}
