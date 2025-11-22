{
  lib,
  pkgs,
  ...
}: {
  services.tailscale = {
    enable = true;
    useRoutingFeatures = lib.mkDefault "client";
    package = pkgs.tailscale;
  };
  networking.firewall.allowedUDPPorts = [41641]; # Facilitate firewall punching

  environment.persistence = {
    "/persist".directories = ["/var/lib/tailscale"];
  };
}
