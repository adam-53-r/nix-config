{
  config,
  lib,
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
    certs = let
      hosts = [
        "${hostName}"
      ];
    in
      lib.genAttrs (map (host: "${host}.arm53.xyz") hosts) (_: {});
  };
}
