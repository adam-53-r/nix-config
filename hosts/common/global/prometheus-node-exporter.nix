{config, ...}: {
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = ["systemd"];
  };
  networking.firewall.interfaces."${config.services.tailscale.interfaceName}" = {
    allowedTCPPorts = [config.services.prometheus.exporters.node.port];
  };
}
