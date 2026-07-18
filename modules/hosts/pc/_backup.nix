# Restic backups of /persist to msi-server's rest-server.
{config, ...}: {
  services.restic.backups.persist = {
    exclude = [
      "/persist/home/adamr/.local/share/Steam/steamapps/common"
      "/persist/home/adamr/.local/share/Steam/steamapps/shadercache"
    ];
    passwordFile = config.sops.secrets."restic/repo-passwd".path;
    environmentFile = config.sops.templates."restic-server-auth".path;
  };

  sops.secrets = {
    "restic/repo-passwd".sopsFile = ./secrets.json;
    "restic/rest-auth/pc".sopsFile = ./secrets.json;
  };

  sops.templates."restic-server-auth".content = ''
    RESTIC_REST_USERNAME=pc
    RESTIC_REST_PASSWORD=${config.sops.placeholder."restic/rest-auth/pc"}
  '';
}
