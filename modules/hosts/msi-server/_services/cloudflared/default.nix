{config, ...}: {
  sops.secrets = {
    cloudflared-certificate = {
      format = "binary";
      sopsFile = ./cloudflare-certificate.pem.sops;
    };
    cloudflared-credentials = {
      format = "binary";
      sopsFile = ./cloudflared-credentials.json.sops;
    };
  };

  services = {
    cloudflared = {
      enable = true;
      certificateFile = config.sops.secrets.cloudflared-certificate.path;
      tunnels = {
        "msi_server" = {
          credentialsFile = config.sops.secrets.cloudflared-credentials.path;
          default = "http_status:404";
        };
      };
    };
  };
}
