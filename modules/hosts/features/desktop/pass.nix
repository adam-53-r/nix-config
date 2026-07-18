# The org.freedesktop.secrets provider is the home-manager pass-secret-service
# unit (homePassSecretService + the pass home feature); the system side only
# has to keep gnome-keyring from stealing the D-Bus name.
{
  flake.nixosModules.desktopPass = {lib, ...}: {
    key = "mynix#nixosModules.desktopPass";

    services.gnome.gnome-keyring.enable = lib.mkForce false;
  };
}
