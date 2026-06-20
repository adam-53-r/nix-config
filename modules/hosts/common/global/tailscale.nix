# Tailscale mesh VPN, shared by every host.
# Ported from msi-server `common/global/tailscale.nix`. Persisting
# /var/lib/tailscale keeps the node identity across ephemeral-root reboots.
{...}: {
  flake.nixosModules.globalTailscale = {
    lib,
    pkgs,
    ...
  }: {
    services.tailscale = {
      enable = true;
      useRoutingFeatures = lib.mkDefault "client";
      package = pkgs.tailscale;
    };
    networking.firewall.allowedUDPPorts = [41641]; # Facilitate NAT hole punching

    environment.persistence = {
      "/persist".directories = ["/var/lib/tailscale"];
    };
  };
}
