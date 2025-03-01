{
  lib,
  pkgs,
  ...
}: let 
  # First port of the range allocated to devices telnet console
  console_start_port_range = 2000;
  # Last port of the range allocated to devices telnet console
  console_end_port_range = 2100;
  # First port of the range allocated to communication between devices. You need two port by link
  udp_start_port_range = 10000;
  # Last port of the range allocated to communication between devices. You need two port by link
  udp_end_port_range = 10100;
in {
  services.gns3-server = {
    enable = true;
    vpcs.enable = true;
    ubridge.enable = true;
    dynamips.enable = true;
    settings = {
      Server = {
        host = "0.0.0.0";
        port = 3080;
        inherit console_start_port_range;
        inherit console_end_port_range;
        inherit udp_start_port_range;
        inherit udp_end_port_range;
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      3080
    ];
    allowedTCPPortRanges = [
      {
        from = console_start_port_range;
        to = console_end_port_range;
      }
      {
        from = udp_start_port_range;
        to = udp_end_port_range;
      }
    ];
  };

  # Make sure ubridge exists
  users.groups.ubridge = {};

  # security.wrappers.ubridge = {
  #   source = "${pkgs.ubridge}/bin/ubridge";
  #   capabilities = "cap_net_admin,cap_net_raw+ep";
  #   owner = "root";
  #   group = "ubridge";
  #   permissions = lib.mkForce "u+rx,g+rx,o+r";
  # };

  environment.persistence = {
    "/persist" = {
      directories = [
        {
          directory = "/var/lib/gns3";
          user = "gns3";
          group = "gns3";
        }
      ];
    };
  };

}