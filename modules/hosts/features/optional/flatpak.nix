# Flatpak, with its installation directory persisted — on main /var/lib/flatpak
# was never in the persist list, so installed flatpaks silently vanished on
# every reboot of the ephemeral root.
{
  flake.nixosModules.optionalFlatpak = {
    key = "mynix#nixosModules.optionalFlatpak";

    services.flatpak.enable = true;

    environment.persistence = {
      "/persist".directories = ["/var/lib/flatpak"];
    };
  };
}
