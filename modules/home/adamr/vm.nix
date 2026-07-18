# Per-host home profile: adamr on the throwaway vm test host.
#
# Mirrors home/adamr/oci.nix: ephemeral root (disko-btrfs rollback wipes
# /home on reboot) so home persistence is enabled here. Deliberately minimal
# (no desktop/workstation extras) — vm exists to sanity-check the shared
# modules (userAdamr, impermanence, disko, home-manager wiring) before they
# get trusted on a real host.
{self, ...}: {
  flake.homeModules."adamr@vm" = {...}: {
    imports = [self.homeModules.adamrHome];

    myPersistence.enable = true;
  };
}
