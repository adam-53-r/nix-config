# VNC server for the wayland session; loopback only, started on demand.
{
  flake.homeModules.homeWayvnc = {
    services.wayvnc = {
      enable = true;
      autoStart = false;
      settings = {
        address = "127.0.0.1";
        port = 5901;
      };
    };
  };
}
