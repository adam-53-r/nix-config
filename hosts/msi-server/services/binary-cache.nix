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
      useACMEHost = "cache.arm53.xyz";
      locations."/".extraConfig = ''
        proxy_pass http://localhost:${toString config.services.nix-serve.port};
      '';
    };
  };
}
