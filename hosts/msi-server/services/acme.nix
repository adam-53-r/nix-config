{
  config,
  ...  
}: {
  sops.secrets = {
    cloudflare-token.sopsFile = ../secrets.json;
  };
  
  security.acme.certs = {
    "nextcloud.arm53.xyz" = {
      dnsProvider = "cloudflare";
      environmentFile = config.sops.secrets.cloudflare-token.path;
      group = "nextcloud";
    };
  };
}
