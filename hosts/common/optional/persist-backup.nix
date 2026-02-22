{config, lib, ...}: {
  services.restic.backups.persist = {
      repository = "rest:https://restic.arm53.xyz/${config.networking.hostName}/persist";
      paths = lib.mkDefault [
        "/persist/"
      ];
      exclude = lib.mkDefault (throw "Must set excludes for restic.");
      extraBackupArgs = lib.mkDefault ["--one-file-system"];
      timerConfig = lib.mkDefault {
        OnCalendar = "Sat *-*-* 09:00:00";
        Persistent = true;
      };
      pruneOpts = lib.mkDefault [
        "--keep-last 5"
      ];
      passwordFile = lib.mkDefault (throw "Must set password file for restic.");
      environmentFile = lib.mkDefault (throw "Must set env file for restic.");
  };
}
