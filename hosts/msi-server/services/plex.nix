{config, ...}: {
  services.plex = {
    enable = true;
    openFirewall = true;
    accelerationDevices = ["/dev/dri/renderD128"];
  };
  environment.persistence = {
    "/persist".directories = [config.services.plex.dataDir];
  };
  services.nginx.virtualHosts."plex.arm53.xyz" = {
    forceSSL = true;
    useACMEHost = "plex.arm53.xyz";
    locations."/".proxyPass = "http://localhost:32400";
  };
}
