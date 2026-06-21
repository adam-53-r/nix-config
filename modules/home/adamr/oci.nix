# Per-host home profile: adamr on the oci VM.
#
# This is the per-user-per-host layer (mirrors home/adamr/<host>.nix on main).
# The oci root filesystem is ephemeral (disko-btrfs rollback wipes /home on
# reboot), so enable home persistence here. Host-specific home tweaks would also
# go in this file.
{self, ...}: {
  flake.homeModules."adamr-oci" = {...}: {
    imports = [self.homeModules.adamrHome];

    # Ephemeral root → keep the colocated stateful dirs across reboots.
    myPersistence.enable = true;
  };
}
