{pkgs, ...}: {
  services.jellyfin = {
    enable = true;
    dataDir = "/DATA/msi-server/jellyfin";
  };
  services.nginx.virtualHosts."jlf.arm53.xyz" = {
    forceSSL = true;
    useACMEHost = "jlf.arm53.xyz";
    locations."/".proxyPass = "http://localhost:8096";
  };
  environment.systemPackages = [
    pkgs.jellyfin
    pkgs.jellyfin-web
    pkgs.jellyfin-ffmpeg
  ];
}
