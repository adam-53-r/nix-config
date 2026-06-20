# Automatic upgrade scaffolding, shared by every host.
# Ported from msi-server `common/global/auto-upgrade.nix`. Left disabled by
# default (as upstream) — the hydra job / flake ref still point at the user's
# infra and would need adjusting before enabling on the OCI host.
{...}: {
  flake.nixosModules.globalAutoUpgrade = {config, ...}: {
    system.autoUpgrade = {
      enable = false;
      flake = "github:adam-53-r/nix-config#${config.networking.hostName}";
      operation = "boot";
      runGarbageCollection = true;
      dates = "*-*-* *:*10,5:00";
      allowReboot = true;
      rebootWindow = {
        lower = "00:00";
        upper = "23:00";
      };
    };
  };
}
