# Per-host home profile: adamr on the msi-server home server. Headless — the
# host-agnostic base plus syncthing; state persists (the host has /persist).
{self, ...}: {
  flake.homeModules."adamr@msi-server" = {
    imports = [
      self.homeModules.adamrHome
    ];

    myPersistence.enable = true;

    services.syncthing.enable = true;
    home.persistence."/persist".directories = [".local/state/syncthing"];
  };
}
