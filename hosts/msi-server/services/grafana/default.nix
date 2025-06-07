{config, ...}: {
  sops.secrets = {
    grafana-adamr-password = {
      sopsFile = ../../secrets.json;
      owner = "grafana";
    };
    # grafana-mail-password = {
    #   sopsFile = ../../secrets.yaml;
    #   owner = "grafana";
    # };
  };

  services = {
    grafana = {
      enable = true;
      settings = {
        server.http_port = 3001;
        users.default_theme = "system";
        dashboards.default_home_dashboard_path = "${./dashboards}/hosts.json";
        security = {
          admin_user = "adamr";
          admin_email = "hi@arm53.xyz";
          admin_password = "$__file{${config.sops.secrets.grafana-adamr-password.path}}";
          cookie_secure = true;
        };
        "auth.anonymous" = {
          enabled = true;
        };
        # smtp = rec {
        #   enabled = true;
        #   host = "mail.m7.rs:465";
        #   from_address = user;
        #   user = config.mailserver.loginAccounts."grafana@m7.rs".name;
        #   password = "$__file{${config.sops.secrets.grafana-mail-password.path}}";
        # };
      };
      provision = {
        enable = true;
        dashboards.settings.providers = [{
          options.path = ./dashboards;
        }];
        datasources.settings = {
          apiVersion = 1;
          datasources = [
            {
              name = "Prometheus";
              type = "prometheus";
              access = "proxy";
              url = "https://metrics.arm53.xyz";
              isDefault = true;
            }
          ];
        };
      };
    };
    nginx.virtualHosts = {
      "dash.arm53.xyz" = let
        port = config.services.grafana.settings.server.http_port;
      in {
        forceSSL = true;
        useACMEHost = "dash.arm53.xyz";
        locations."/".proxyPass = "http://localhost:${toString port}";
      };
    };
  };
}
