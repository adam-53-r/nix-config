# Optional nginx reverse proxy with TLS + metrics, adapted from msi-server
# `common/optional/nginx.nix`.
#
# Adaptations for the OCI cloud VM:
#  - The uWSGI emperor block was dropped; it existed only to serve the
#    nextcloud/cgit vassals which are not ported here.
#  - msi-server used `useACMEHost` pointing at a cert provisioned by a
#    DNS-challenge service that is not ported here. We instead use `enableACME`
#    so the vhost requests its own HTTP-01 certificate. For it to issue, a
#    public DNS record for `${hostName}.arm53.xyz` must point at the VM and
#    ports 80/443 must be reachable; until then ACME keeps retrying without
#    blocking boot.
{...}: {
  flake.nixosModules.optionalNginx = {config, ...}: let
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
          enableACME = true;
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
    };

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
  };
}
