{config, ...}: let
  port = 5000;
in {
  # Same name:base64 key format as nix-serve used, so clients keep trusting it.
  sops.secrets.nix-serve-secret-key-file = {
    sopsFile = ../secrets.json;
  };

  services = {
    harmonia.cache = {
      enable = true;
      signKeyPaths = [config.sops.secrets.nix-serve-secret-key-file.path];
      settings = {
        bind = "127.0.0.1:${toString port}";
        # What nix-serve advertised.
        priority = 30;
      };
    };
    nginx.virtualHosts."cache.arm53.xyz" = {
      forceSSL = true;
      useACMEHost = "cache.arm53.xyz";
      locations."/".extraConfig = ''
        proxy_pass http://127.0.0.1:${toString port};
        proxy_set_header Host $host;
        proxy_redirect http:// https://;
        proxy_http_version 1.1;
        # Stream large NARs instead of spooling them to disk first.
        proxy_buffering off;
      '';
    };
  };
}
