{pkgs, ...}: {
  services.restic.server = {
    enable = true;
    dataDir = "/DATA/msi-server/restic-server";
    listenAddress = "127.0.0.1:8090";
    appendOnly = false;
    prometheus = true;
    privateRepos = true;
  };
  services.nginx.virtualHosts."restic.arm53.xyz" = {
    forceSSL = true;
    useACMEHost = "restic.arm53.xyz";
    locations."/".proxyPass = "http://localhost:8090";
  };
  users.users.restic.packages = [pkgs.apacheHttpd];
}
