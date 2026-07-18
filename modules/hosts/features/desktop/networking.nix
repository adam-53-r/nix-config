# Desktop networking: NetworkManager (iwd wifi backend, openvpn plugin) with
# systemd-resolved as the single DNS owner, and persistence for saved
# connections.
{
  flake.nixosModules.desktopNetworking = {pkgs, ...}: {
    key = "mynix#nixosModules.desktopNetworking";

    networking.networkmanager = {
      enable = true;
      wifi.backend = "iwd";
      dns = "systemd-resolved";
      plugins = with pkgs; [
        networkmanager-openvpn
      ];
    };
    services.resolved.enable = true;

    # Ensure group exists
    users.groups.networkmanager = {};

    # Allow udp port 67 for serving DHCP
    networking.firewall.allowedUDPPorts = [67];

    environment.persistence = {
      "/persist".directories = ["/etc/NetworkManager/system-connections/"];
    };
  };
}
