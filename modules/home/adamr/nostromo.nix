# Per-host home profile: adamr on the nostromo home server. Headless — the
# host-agnostic base plus syncthing; state persists (the host has /persist).
{self, ...}: {
  flake.homeModules."adamr@nostromo" = {pkgs, ...}: {
    imports = [
      self.homeModules.adamrHome
    ];

    myPersistence.enable = true;

    home.packages = [
      pkgs.latest.claude-code
    ];

    services.syncthing.enable = true;
    home.persistence."/persist".directories = [".local/state/syncthing"];
  };
}
