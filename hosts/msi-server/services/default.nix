{
  ...
}: {
  imports = [
    ../../common/optional/nginx.nix
    ../../common/optional/mysql.nix
    ../../common/optional/fail2ban.nix
    ../../common/optional/gns3-server.nix
    ../../common/optional/tailscale-exit-node.nix
    ../../common/optional/plex.nix

    ./acme.nix
    ./minecraft-server.nix
    ./windscribe-container
    ./nextcloud
    ./binary-cache.nix
    ./hydra
    ./prometheus.nix
    ./grafana
  ];
}
