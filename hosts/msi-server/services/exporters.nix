{pkgs, ...}: {
  services.prometheus.exporters = {
    snmp = let
      snmpYml =
        pkgs.writeText "snmp.yml"
        (builtins.readFile "${pkgs.prometheus-snmp-exporter.src}/snmp.yml");
    in {
      enable = true;
      listenAddress = "127.0.0.1";
      # TODO: make this bullshit work
      # configurationPath = /. + builtins.unsafeDiscardStringContext "${pkgs.prometheus-snmp-exporter.src}/snmp.yml";
      configurationPath = snmpYml;
    };
  };
}
