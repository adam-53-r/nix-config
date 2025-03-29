{
  config,
  pkgs,
  lib,
  ...  
}: let 
in {

  services.nextcloud = {
    enable = true;
    hostName = "${config.networking.hostName}.tail6743b5.ts.net";
    config.dbtype = "sqlite";
    # settings = {
    #   config_is_read_only = true;
    # };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  environment.persistence = {
    "/persist" = {
      directories = [
        {
          directory = "${config.services.nextcloud.home}";
          user = "nextcloud";
          group = "nextcloud";
          mode = "u=rwx,g=rx,o=";
        }
      ];
    };
  };
}
