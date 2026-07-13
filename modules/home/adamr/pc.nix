# Per-host home profile: adamr on the pc desktop.
# Desktop feature imports land here as they are ported (hyprland, wayland-wm,
# apps, games, productivity, pass).
{self, ...}: {
  flake.homeModules."adamr@pc" = {...}: {
    imports = [self.homeModules.adamrHome];

    # Ephemeral root → keep the colocated stateful dirs across reboots.
    myPersistence.enable = true;
  };
}
