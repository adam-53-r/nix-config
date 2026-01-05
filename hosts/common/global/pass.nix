{lib, ...}: {
  # To-do: test this with cinnamon, maybe it breaks something idk
  services.passSecretService.enable = true;
  # Disabling gnome-keyring as it conflicts with pass secret service
  services.gnome.gnome-keyring.enable = lib.mkForce false;
}
