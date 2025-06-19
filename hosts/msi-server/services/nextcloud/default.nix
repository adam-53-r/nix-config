{config, ...}: let
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
    https = true;
    hostName = "nextcloud.arm53.xyz";
    home = "/DATA/msi-server/nextcloud";
    config = {
      dbtype = "sqlite";
      adminpassFile = config.sops.secrets.nextcloud-admin-passwd.path;
    };
  };

  services.nginx.virtualHosts.${hostname} = {
    forceSSL = true;
    useACMEHost = "${config.services.nextcloud.hostName}";
    locations."/metrics" = {
      proxyPass = "http://localhost:${toString config.services.prometheus.exporters.nextcloud.port}";
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
