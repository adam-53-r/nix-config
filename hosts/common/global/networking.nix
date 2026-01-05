{pkgs, ...}: {
  # Enable nftables (better and newer firewall but may give compatibility issues)
  networking.nftables.enable = true;

  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";
    plugins = with pkgs; [
      networkmanager-openvpn
    ];
  };

  # Ensure group exists
  users.groups.networkmanager = {};

  # Allow udp port 67 for serving DHCP
  networking.firewall.allowedUDPPorts = [67];

  environment.persistence = {
    "/persist".directories = ["/etc/NetworkManager/system-connections/"];
  };
}
