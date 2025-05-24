{
  config,
  pkgs,
  ...
}: {
  sops.secrets.nix-serve-secret-key-file = {
    sopsFile = ../secrets.json;
  };

  services = {
    nix-serve = {
      enable = true;
      secretKeyFile = config.sops.secrets.nix-serve-secret-key-file.path;
      package = pkgs.nix-serve;
    };
    nginx.virtualHosts."cache.arm53.xyz" = {
      forceSSL = true;
      sslCertificate = "/var/lib/acme/cache.arm53.xyz/cert.pem";
      sslCertificateKey = "/var/lib/acme/cache.arm53.xyz/key.pem";
      locations."/".extraConfig = ''
        proxy_pass http://localhost:${toString config.services.nix-serve.port};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      '';
    };
  };
}
