{
  pkgs,
  config,
  ...
}: let
  hostname = config.services.nextcloud.hostName;
in {
  sops.secrets = {
    nextcloud-admin-passwd.sopsFile = ./secrets.json;
    nextcloud-exporter-token = {
      sopsFile = ./secrets.json;
      owner = config.services.prometheus.exporters.nextcloud.user;
      group = config.services.prometheus.exporters.nextcloud.group;
    };
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud34;
    https = true;
    hostName = "nextcloud.arm53.xyz";
    home = "/DATA/msi-server/nextcloud";
    database.createLocally = true;
    config = {
      dbtype = "mysql";
      adminpassFile = config.sops.secrets.nextcloud-admin-passwd.path;
    };
    settings = {
      "mysql.utf8mb4" = true;
      overwriteprotocol = "https";
      # Heavy background jobs run 01:00-05:00 UTC.
      maintenance_window_start = 1;
    };
  };

  services.nginx.virtualHosts.${hostname} = {
    forceSSL = true;
    useACMEHost = "${config.services.nextcloud.hostName}";
    locations."/metrics" = {
      proxyPass = "http://localhost:${toString config.services.prometheus.exporters.nextcloud.port}";
      extraConfig = ''
        allow 127.0.0.1;
        allow ::1;
        allow 100.64.0.0/10;
        allow fd7a:115c:a1e0::/48;
        deny all;
      '';
    };
  };

  services.prometheus.exporters.nextcloud = {
    enable = true;
    tokenFile = config.sops.secrets.nextcloud-exporter-token.path;
    url = "https://${hostname}";
    listenAddress = "127.0.0.1";
  };

  systemd.services.nginx.requires = [
    "DATA.mount"
  ];
}
