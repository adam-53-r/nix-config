{
  config,
  ...
}: {
  sops.secrets = {
    nextcloud-admin-passwd.sopsFile = ./secrets.json;
    cert-file = {
      format = "binary";
      sopsFile = ./cert-file.sops;
      owner = "nginx";
    };
    key-file = {
      format = "binary";
      sopsFile = ./key-file.sops;
      owner = "nginx";
    };
  };
  
  services.nextcloud = {
    config.adminpassFile = config.sops.secrets.nextcloud-admin-passwd.path;
    https = true;
    home = "/DATA/msi-server/nextcloud";
  };

  services.nginx.virtualHosts.${config.services.nextcloud.hostName} = {
    # forceSSL = true;
    addSSL = true;
    sslCertificate = config.sops.secrets.cert-file.path;
    sslCertificateKey = config.sops.secrets.key-file.path;
  };

  systemd.services.nginx.requires = [
    "DATA.mount"
  ];
}
