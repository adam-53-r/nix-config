{
  pkgs,
  ...
}: {
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";
    plugins = with pkgs; [
      networkmanager-openvpn
    ];
  };

  # Ensure group exists
  users.groups.networkmanager = {};

  environment.persistence = {
    "/persist".directories = ["/etc/NetworkManager/system-connections/"];
  };
}