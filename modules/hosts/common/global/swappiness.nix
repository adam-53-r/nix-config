# Default vm.swappiness, shared by every host.
{...}: {
  flake.nixosModules.globalSwappiness = {...}: {
    key = "mynix#nixosModules.globalSwappiness";
    boot.kernel.sysctl = {"vm.swappiness" = 60;};
  };
}
