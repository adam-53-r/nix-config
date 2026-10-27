# Tailnet only: the name is only in the tailnet unbound, and nginx denies everyone else.
{nowAndNext, ...}: let
  domain = "now.arm53.xyz";
  # Store paths all have mtime 1, so Last-Modified never changes between deploys.
  revalidate = ''
    add_header Cache-Control "no-cache" always;
    if_modified_since off;
  '';
in {
  services.nginx.virtualHosts.${domain} = {
    forceSSL = true;
    useACMEHost = domain;
    root = nowAndNext;
    extraConfig = ''
      allow 100.64.0.0/10;
      allow fd7a:115c:a1e0::/48;
      deny all;
    '';
    locations = {
      "/".extraConfig = revalidate;
      "/assets/".extraConfig = ''
        add_header Cache-Control "public, max-age=31536000, immutable" always;
      '';
    };
  };
}
