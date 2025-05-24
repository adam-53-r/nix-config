{
  config,
  ...  
}: {
  sops.secrets = {
    cloudflare-token.sopsFile = ../secrets.json;
  };
  
  security.acme = {
    defaults = {
      dnsProvider = "cloudflare";
      environmentFile = config.sops.secrets.cloudflare-token.path;
      group = config.services.nginx.group;
    };
    certs = {
      "nextcloud.arm53.xyz" = {};
      "cache.arm53.xyz" = {};
      "hydra.arm53.xyz" = {};
    };
  };
}
