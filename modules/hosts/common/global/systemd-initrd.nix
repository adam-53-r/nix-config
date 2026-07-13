# Use the systemd-based initrd, shared by every host.
# This also switches the ephemeral-root rollback in disko-btrfs to
# its systemd `restore-root` service path (instead of postDeviceCommands),
# matching msi-server.
{...}: {
  flake.nixosModules.globalSystemdInitrd = {...}: {
    key = "mynix#nixosModules.globalSystemdInitrd";
    boot.initrd.systemd.enable = true;
  };
}
