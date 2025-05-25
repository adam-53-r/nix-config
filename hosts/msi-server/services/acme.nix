{
  config,
  ...  
}: let
  inherit (config.networking) hostName;
in {
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
      "${hostName}.arm53.xyz" = {};
      "nextcloud.arm53.xyz" = {};
      "cache.arm53.xyz" = {};
      "hydra.arm53.xyz" = {};
      "metrics.arm53.xyz" = {};
    };
  };
}
