{
  services.zammad = {
    enable = true;
  };

  services.nginx.virtualHosts."zammad.arm53.xyz" = {
    forceSSL = true;
    useACMEHost = "zammad.arm53.xyz";
    locations."/".proxyPass = "http://localhost:3000";
  };
}
