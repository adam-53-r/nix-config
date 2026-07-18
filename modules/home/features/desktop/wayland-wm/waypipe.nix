# Waypipe sockets for running remote wayland apps over SSH (client side) and
# exposing local apps to remote hosts (server side).
#
# The client unit needs WAYLAND_DISPLAY, which uwsm only exports into the
# systemd user environment right before graphical-session.target activates —
# on main the unit had no ordering and raced it, failing at every login.
# After= + ConditionEnvironment + Restart is the same recipe home-manager uses
# for waybar.
{
  flake.homeModules.homeWaypipe = {
    pkgs,
    lib,
    ...
  }: {
    home.packages = [pkgs.waypipe];
    systemd.user.services = {
      waypipe-client = {
        Unit = {
          Description = "Runs waypipe on startup to support SSH forwarding";
          After = ["graphical-session.target"];
          ConditionEnvironment = "WAYLAND_DISPLAY";
        };
        Service = {
          ExecStartPre = "${lib.getExe' pkgs.coreutils "mkdir"} %h/.waypipe -p";
          ExecStart = "${lib.getExe pkgs.waypipe} --socket %h/.waypipe/client.sock client";
          ExecStopPost = "${lib.getExe' pkgs.coreutils "rm"} -f %h/.waypipe/client.sock";
          Restart = "on-failure";
          RestartSec = 2;
        };
        Install.WantedBy = ["graphical-session.target"];
      };
      waypipe-server = {
        Unit.Description = "Runs waypipe on startup to support SSH forwarding";
        Service = {
          Type = "simple";
          ExecStartPre = "${lib.getExe' pkgs.coreutils "mkdir"} %h/.waypipe -p";
          ExecStart = "${lib.getExe pkgs.waypipe} --socket %h/.waypipe/server.sock --title-prefix '[%H] ' --login-shell --display wayland-waypipe server -- ${lib.getExe' pkgs.coreutils "sleep"} infinity";
          ExecStopPost = "${lib.getExe' pkgs.coreutils "rm"} -f %h/.waypipe/server.sock %t/wayland-waypipe";
        };
        Install.WantedBy = ["default.target"];
      };
    };
  };
}
