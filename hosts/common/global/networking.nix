{
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";

  # Ensure group exists
  users.groups.networkmanager = {};

  environment.persistence = {
    "/persist".directories = ["/etc/NetworkManager/system-connections/"];
  };
}