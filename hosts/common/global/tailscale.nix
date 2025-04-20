{
  lib,
  pkgs,
  ...
}: {
  services.tailscale = {
    enable = true;
    useRoutingFeatures = lib.mkDefault "client";
    package = pkgs.tailscale;
    # extraUpFlags = ["--login-server https://tailscale.m7.rs"];
  };
  networking.firewall.allowedUDPPorts = [41641]; # Facilitate firewall punching

  environment.persistence = {
    "/persist".directories = ["/var/lib/tailscale"];
  };
}
