{ config, ... }: {
  services.plex = {
    enable = true;
    openFirewall = true;
    accelerationDevices = ["/dev/dri/renderD128"];
  };
  environment.persistence = {
    "/persist".directories = [config.services.plex.dataDir];
  };
}
