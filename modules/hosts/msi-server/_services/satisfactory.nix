{config, ...}: {
  services.satisfactory-server = {
    enable = true;
    openFirewall = true;
    dataDir = "/DATA/msi-server/satisfactory";
    standardPort = 7878;
    reliablePort = 8787;
  };
}
