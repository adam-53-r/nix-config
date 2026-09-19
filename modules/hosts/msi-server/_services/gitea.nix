{
  config,
  pkgs,
  ...
}: let
  domain = "git.arm53.xyz";
  port = 3300;
  dataDir = "/DATA/msi-server/gitea";
in {
  # sops.secrets.couchdb-admin-passwd = {
  #   sopsFile = ./secrets.json;
  #   owner = config.services.couchdb.user;
  #   group = config.services.couchdb.group;
  # };

  services.gitea = {
    enable = true;
    stateDir = dataDir;
    settings.server = {
      HTTP_ADDR = "127.0.0.1";
      HTTP_PORT = port;
      DOMAIN = domain;
      SSH_PORT = 2222;
    };
  };

  systemd.services.gitea = {
    after = ["DATA.mount"];
    requires = ["DATA.mount"];
  };

  services.nginx.virtualHosts.${domain} = {
    forceSSL = true;
    useACMEHost = domain;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString port}";
    };
  };
}
