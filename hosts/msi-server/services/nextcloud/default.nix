{
  config,
  ...
}: {
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
    sslCertificate = "/var/lib/acme/nextcloud.arm53.xyz/cert.pem";
    sslCertificateKey = "/var/lib/acme/nextcloud.arm53.xyz/key.pem";
  };

  systemd.services.nginx.requires = [
    "DATA.mount"
  ];

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
