{
  lib,
  config,
  ...
}: let
  local-hosts =
    builtins.attrNames config.services.nginx.virtualHosts
    ++ [
      "dns.arm53.xyz"
    ];
in {
  services.unbound = {
    enable = true;
    resolveLocalQueries = false;
    enableRootTrustAnchor = false;
    settings = {
      server = {
        interface = ["100.86.227.101"];
        # verbosity = 1;
        access-control = ["100.64.0.0/10 allow"];
        local-data = lib.map (host: "\"${host}. A 100.86.227.101\"") local-hosts;
      };
      forward-zone = [
        {
          name = ".";
          # Router already implements DoH
          forward-addr = "192.168.2.1";
        }
      ];
      remote-control.control-enable = true;
    };
  };

  # services.prometheus.exporters.unbound = {
  #   enable = true;
  #   listenAddress = "100.86.227.101";
  # };
}
