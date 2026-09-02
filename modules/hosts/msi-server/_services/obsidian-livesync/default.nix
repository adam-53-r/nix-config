# Backend for the Obsidian "Self-hosted LiveSync" plugin
# (https://github.com/vrtmrz/obsidian-livesync): a single-node CouchDB behind
# nginx. The plugin talks to CouchDB directly from Obsidian's renderer, so the
# settings below mirror upstream's provisioning script
# (utils/couchdb/provision.ts) rather than a stock CouchDB install.
{
  config,
  pkgs,
  ...
}: let
  domain = "livesync.arm53.xyz";
  port = 5984;
  adminUser = "admin";

  # The vault database the plugin replicates into. Must match the "Database
  # name" field in the plugin's remote settings.
  database = "obsidiannotes";

  # Obsidian is not a normal web origin: the desktop app loads from app://
  # and the mobile app from capacitor://, so both have to be allow-listed or
  # every request fails preflight.
  corsOrigins = "app://obsidian.md,capacitor://localhost,http://localhost";

  dataDir = "/DATA/msi-server/couchdb";
in {
  sops.secrets.couchdb-admin-passwd = {
    sopsFile = ./secrets.json;
    owner = config.services.couchdb.user;
    group = config.services.couchdb.group;
  };

  # `services.couchdb.adminPass` would render the password into the
  # world-readable store, so the [admins] section is injected as an
  # extraConfigFile instead — which is exactly what that option is for.
  #
  # Rotation gotcha: CouchDB replaces the plaintext password with a pbkdf2
  # hash on first start, writing it to the *last* file of the ini chain
  # (local.ini). That hash then shadows this one, so changing the secret also
  # means dropping the [admins] entry from ${dataDir}/local.ini and
  # restarting couchdb.service.
  sops.templates."couchdb-admins.ini" = {
    owner = config.services.couchdb.user;
    group = config.services.couchdb.group;
    mode = "0400";
    content = ''
      [admins]
      ${adminUser} = ${config.sops.placeholder.couchdb-admin-passwd}
    '';
  };

  services.couchdb = {
    enable = true;
    inherit adminUser port;
    bindAddress = "127.0.0.1";
    databaseDir = dataDir;
    viewIndexDir = dataDir;
    # CouchDB writes runtime config changes to the last file of the ini chain;
    # keep it beside the data instead of the ephemeral /var/lib default.
    configFile = "${dataDir}/local.ini";
    extraConfigFiles = [config.sops.templates."couchdb-admins.ini".path];

    extraConfig = {
      couchdb = {
        # Create _users/_replicator on boot; without this a fresh CouchDB 3
        # refuses every request until /_cluster_setup has been POSTed.
        single_node = true;
        max_document_size = 50000000;
      };
      chttpd = {
        require_valid_user = true;
        enable_cors = true;
        max_http_request_size = 4294967296;
      };
      chttpd_auth.require_valid_user = true;
      httpd."WWW-Authenticate" = ''Basic realm="couchdb"'';
      cors = {
        credentials = true;
        origins = corsOrigins;
        headers = "accept, authorization, content-type, origin, referer";
        methods = "GET, PUT, POST, HEAD, DELETE";
      };
      # Unauthenticated metrics on a loopback-only port, for prometheus below.
      prometheus.additional_port = true;
    };
  };

  systemd.services.couchdb = {
    after = ["DATA.mount"];
    requires = ["DATA.mount"];
  };

  # `single_node` bootstraps the system databases but not the vault one.
  systemd.services.couchdb-livesync-init = {
    description = "Create the Obsidian LiveSync database in CouchDB";
    after = ["couchdb.service"];
    requires = ["couchdb.service"];
    wantedBy = ["multi-user.target"];
    path = [pkgs.curl];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = config.services.couchdb.user;
      Group = config.services.couchdb.group;
    };

    script = ''
      base="http://127.0.0.1:${toString port}"
      auth="${adminUser}:$(cat ${config.sops.secrets.couchdb-admin-passwd.path})"

      # CouchDB binds its port before it can serve requests. /_up needs
      # credentials too, since require_valid_user_except_for_up is off.
      for _ in $(seq 1 60); do
        if curl -fsS -o /dev/null -u "$auth" "$base/_up"; then break; fi
        sleep 2
      done

      # 412 == the database already exists.
      code=$(curl -sS -o /dev/null -w '%{http_code}' -u "$auth" -X PUT "$base/${database}")
      case "$code" in
        201 | 202 | 412) echo "database ${database}: HTTP $code" ;;
        *)
          echo "creating database ${database} failed: HTTP $code" >&2
          exit 1
          ;;
      esac
    '';
  };

  services.nginx.virtualHosts.${domain} = {
    forceSSL = true;
    useACMEHost = domain;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString port}";
      extraConfig = ''
        # CouchDB long-polls /_changes; buffering stalls live sync.
        proxy_buffering off;
        proxy_read_timeout 600s;
      '';
    };
  };

  services.prometheus.scrapeConfigs = [
    {
      job_name = "couchdb";
      metrics_path = "/_node/_local/_prometheus";
      static_configs = [{targets = ["127.0.0.1:17986"];}];
    }
  ];
}
