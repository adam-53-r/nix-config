{
  lib,
  config,
  ...
}: let
  inherit (config.networking) hostName;
in {
  services = {
    nginx = {
      enable = true;
      recommendedTlsSettings = true;
      recommendedProxySettings = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      clientMaxBodySize = "300m";
      statusPage = true;

      virtualHosts."${hostName}.arm53.xyz" = {
        default = true;
        forceSSL = true;
        useACMEHost = "${hostName}.arm53.xyz";
        locations."/metrics" = {
          proxyPass = "http://localhost:${toString config.services.prometheus.exporters.nginx.port}/metrics";
        };
      };
    };

    prometheus.exporters.nginx.enable = true;
    prometheus.exporters.nginxlog = {
      enable = true;
      group = "nginx";
      settings.namespaces = [
        {
          name = "filelogger";
          source.files = ["/var/log/nginx/access.log"];
          format = "$remote_addr - $remote_user [$time_local] \"$request\" $status $body_bytes_sent \"$http_referer\" \"$http_user_agent\"";
        }
      ];
    };

    uwsgi = {
      enable = true;
      user = "nginx";
      group = "nginx";
      plugins = ["cgi"];
      instance = {
        type = "emperor";
        vassals = lib.mkBefore {};
      };
    };
  };
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
