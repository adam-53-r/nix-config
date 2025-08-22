{
  services.prometheus.exporters = {
    mikrotik = {
      enable = false;
      configuration = {
        devices = [
          {
            name = "R1";
            address = "192.168.2.1";
            user = "prometheus";
            password = "1234";
          }
        ];
        features = {
          bgp = true;
          dhcp = true;
          dhcpv6 = true;
          dhcpl = true;
          routes = true;
          pools = true;
          optics = true;
        };
      };
    };
  };
}
