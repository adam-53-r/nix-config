{config, lib, ...}: {
  services.restic.backups.persist = {
      repository = "rest:https://restic.arm53.xyz/${config.networking.hostName}/persist";
      paths = lib.mkDefault [
        "/persist/"
      ];
      exclude = lib.mkDefault (throw "Must set excludes for restic.");
      extraBackupArgs = ["--one-file-system"];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
      };
      pruneOpts = [
        "--keep-last 5"
      ];
      passwordFile = lib.mkDefault (throw "Must set password file for restic.");
      environmentFile = lib.mkDefault (throw "Must set env file for restic.");
  };
}
