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
