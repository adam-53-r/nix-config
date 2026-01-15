{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.hytale-server;
in {
  options.services.hytale-server = {
    enable = mkEnableOption "Hytale Dedicated Server";

    dataDir = mkOption {
      type = types.path;
      description = "Directory to store game server.";
      default = "/var/lib/hytale";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to open ports in the firewall for the server.
      '';
    };

    bind = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = ''
        Address the Hytale Server binds to.
      '';
    };

    port = mkOption {
      type = types.int;
      default = 5520;
      description = ''
        Standard udp port for server traffic, defaults to 5520/udp.
      '';
    };

    extraFlags = mkOption {
      type = types.str;
      description = "Extra commandline options when launching game server.";
      default = "";
      example = "--backup --allow-op";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.hytale-server = let
      # steamcmd = "${cfg.steamcmdPackage}/bin/steamcmd";
      # steam-run = "${pkgs.steam-run}/bin/steam-run";
      java = pkgs.temurin-bin-25;
    in {
      description = "Hytale Dedicated Server";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      path = [java];

      serviceConfig = {
        TimeoutSec = "15min";
        ExecStart = "${java}/bin/java -jar ${cfg.dataDir}/Server/HytaleServer.jar --assets Assets.zip -b ${cfg.bind}:${toString cfg.port} ${cfg.extraFlags}";
        Restart = "always";
        User = "hytale";
        WorkingDirectory = cfg.dataDir;
      };
    };

    users.users.hytale = {
      description = "Hytale server service user";
      home = cfg.dataDir;
      createHome = true;
      isSystemUser = true;
      group = "hytale";
    };
    users.groups.hytale = {};

    networking.firewall = mkIf cfg.openFirewall {
      allowedUDPPorts = [
        cfg.port
      ];
    };
  };
}
