# GNS3 server daemon reachable over the tailnet, with the console/UDP port
# ranges it allocates to emulated devices opened on the tailscale interface.
{self, ...}: {
  flake.nixosModules.optionalGns3Server = {config, ...}: let
    # First port of the range allocated to devices telnet console
    console_start_port_range = 2000;
    # Last port of the range allocated to devices telnet console
    console_end_port_range = 2100;
    # First port of the range allocated to communication between devices. You need two port by link
    udp_start_port_range = 10000;
    # Last port of the range allocated to communication between devices. You need two port by link
    udp_end_port_range = 10100;
  in {
    key = "mynix#nixosModules.optionalGns3Server";

    imports = [self.nixosModules.optionalGns3];

    services.gns3-server = {
      enable = true;
      vpcs.enable = true;
      ubridge.enable = true;
      dynamips.enable = true;
      settings.Server = {
        host = "0.0.0.0";
        port = 3080;
        inherit console_start_port_range;
        inherit console_end_port_range;
        inherit udp_start_port_range;
        inherit udp_end_port_range;
      };
    };

    networking.firewall.interfaces.${config.services.tailscale.interfaceName} = {
      allowedTCPPorts = [
        3080
      ];
      allowedTCPPortRanges = [
        {
          from = console_start_port_range;
          to = console_end_port_range;
        }
      ];
      allowedUDPPortRanges = [
        {
          from = udp_start_port_range;
          to = udp_end_port_range;
        }
      ];
    };
  };
}
