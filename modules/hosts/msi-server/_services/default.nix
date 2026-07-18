# msi-server's service stack. Plain NixOS modules (the _services dir is
# skipped by import-tree); the optional feature modules they build on
# (nginx, mysql, fail2ban, gns3-server, tailscale-exit-node) are imported in
# the host's default.nix where `self` is in scope.
{...}: {
  imports = [
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
    ./zammad.nix
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
