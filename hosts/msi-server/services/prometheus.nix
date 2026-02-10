{
  config,
  outputs,
  lib,
  ...
}: let
  hosts = lib.attrNames outputs.nixosConfigurations;
in {
  services = {
    prometheus = {
      enable = true;
      globalConfig = {
        # Scrape a bit more frequently
        scrape_interval = "30s";
        scrape_timeout = "30s";
      };
      enableReload = true;
      retentionTime = "2y";
      scrapeConfigs = [
        {
          job_name = "hydra";
          scheme = "https";
          static_configs = [{targets = ["hydra.arm53.xyz"];}];
        }
        {
          job_name = "prometheus";
          scheme = "https";
          static_configs = [{targets = ["metrics.arm53.xyz"];}];
        }
        {
          job_name = "nginx";
          scheme = "https";
          static_configs = [{targets = ["msi-server.arm53.xyz"];}];
        }
        # {
        #   job_name = "unbound";
        #   scheme = "http";
        #   static_configs = [{targets = ["dns.arm53.xyz:9167"]; labels.instance = "unbound";}];
        # }
        # {
        #   job_name = "mikrotik";
        #   scheme = "http";
        #   static_configs = [{targets = ["localhost:9436"]; labels.instance = "R1";}];
        # }
        {
          job_name = "nextcloud";
          scheme = "https";
          static_configs = [{targets = ["nextcloud.arm53.xyz"];}];
        }
        {
          job_name = "restic-server";
          scheme = "https";
          static_configs = [{targets = ["restic.arm53.xyz"];}];
          basic_auth = {
            username = "metrics";
            password_file = config.sops.secrets."restic-servers-users/metrics".path;
          };
        }
        {
          job_name = "hosts";
          scheme = "http";
          static_configs =
            map (hostname: {
              targets = ["${hostname}:${toString config.services.prometheus.exporters.node.port}"];
              labels.instance = hostname;
            })
            hosts;
        }
      ];
      extraFlags = let
        prometheus = config.services.prometheus.package;
      in [
        # Custom consoles
        "--web.console.templates=${prometheus}/etc/prometheus/consoles"
        "--web.console.libraries=${prometheus}/etc/prometheus/console_libraries"
      ];
    };
    nginx.virtualHosts = {
      "metrics.arm53.xyz" = {
        forceSSL = true;
        useACMEHost = "metrics.arm53.xyz";
        locations."/".proxyPass = "http://localhost:${toString config.services.prometheus.port}";
      };
    };
  };

  environment.persistence = {
    "/persist".directories = ["/var/lib/prometheus2"];
  };

  sops.secrets."restic-servers-users/metrics" = {
    owner = "prometheus";
    group = "prometheus";
    sopsFile = ./secrets.json;
  };
}
