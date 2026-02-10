{...}: {
  imports = [
    ../../common/optional/nginx.nix
    ../../common/optional/mysql.nix
    ../../common/optional/fail2ban.nix
    ../../common/optional/gns3-server.nix
    ../../common/optional/tailscale-exit-node.nix

    ./dns-server.nix
    ./acme.nix
    ./windscribe-container
    ./nextcloud
    ./binary-cache.nix
    ./prometheus.nix
    ./grafana
    ./cloudflared
    ./jellyfin.nix
    ./loki.nix
    ./alloy.nix
    ./exporters.nix
    ./restic-server.nix
    # TODO: fix hydra, does not compile
    # ./hydra
    # ./minecraft-server.nix
    # ./plex.nix
    # ./satisfactory.nix
  ];

  services.hytale-server = {
    enable = true;
    dataDir = "/DATA/msi-server/hytale";
    openFirewall = true;
  };
}
