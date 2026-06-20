# Prometheus node exporter, reachable only over Tailscale, shared by every host.
# Ported from msi-server `common/global/prometheus-node-exporter.nix`.
{...}: {
  flake.nixosModules.globalNodeExporter = {config, ...}: {
    services.prometheus.exporters.node = {
      enable = true;
      enabledCollectors = ["systemd"];
    };
    # Only expose the metrics port on the Tailscale interface, never the
    # public internet.
    networking.firewall.interfaces."${config.services.tailscale.interfaceName}" = {
      allowedTCPPorts = [config.services.prometheus.exporters.node.port];
    };
  };
}
