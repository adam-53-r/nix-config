{config, ...}: {
  sops.secrets = {
    nextcloud-admin-passwd.sopsFile = ./secrets.json;
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

  services.nginx.virtualHosts.${config.services.nextcloud.hostName} = {
    forceSSL = true;
    useACMEHost = "${config.services.nextcloud.hostName}";
  };

  systemd.services.nginx.requires = [
    "DATA.mount"
  ];
}
