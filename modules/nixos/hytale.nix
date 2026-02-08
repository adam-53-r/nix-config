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
    systemd = let
      systemctl = "${pkgs.systemd}/bin/systemctl";
      # steamcmd = "${cfg.steamcmdPackage}/bin/steamcmd";
      # steam-run = "${pkgs.steam-run}/bin/steam-run";
      java = pkgs.temurin-bin-25;
      hytale-updater = pkgs.writeShellApplication {
        name = "hytale-update";

        # Runtime deps added to PATH automatically
        runtimeInputs = with pkgs; [
          bash
          coreutils
          util-linux # flock
          unzip
        ];

        text = builtins.readFile ./hytale-update.sh;
      };
    in {
      timers.hytale-server-maintenance = {
        description = "Timer to check for Hyale Server updates";
        timerConfig = {
          OnCalendar = "*-*-* 03:00:00";
          Unit = "hytale-server-maintenance.service";
        };
        wantedBy = ["timers.target"];
      };

      services = {
        hytale-server-maintenance = {
          description = "Hytale Server maintenance";
          wants = ["network-online.target"];
          after = ["network-online.target"];
          serviceConfig = {
            Type = "oneshot";
            TimeoutStartSec = "15min";
            ExecStart = [
              "${systemctl} stop hytale-server.service"
              # The - prefix makes the update step “best-effort”: if it fails, the unit continues to the restart. (You’ll still see the failure in logs.)
              "-${systemctl} start hytale-server-update.service"
              "${systemctl} start hytale-server.service"
            ];
            NoNewPrivileges = "true";
            PrivateTmp = "true";
            ProtectHome = "true";
            ProtectSystem = "strict";
          };
        };

        hytale-server-update = {
          description = "Checks for Hyale Server updates and applies them when available";
          unitConfig = {
            # RefuseManualStart = true;
          };
          serviceConfig = {
            Type = "oneshot";
            WorkingDirectory = cfg.dataDir;
            User = "hytale";
            Group = "hytale";
            TimeoutStartSec = "15min";
            # Restart = "always";
            ExecStart = "${hytale-updater}/bin/hytale-update --server-dir ${cfg.dataDir}";
          };
        };

        hytale-server = {
          description = "Hytale Dedicated Server";
          wantedBy = ["multi-user.target"];
          after = ["network.target"];
          path = [java];

          serviceConfig = {
            TimeoutSec = "15min";
            ExecStart = "${java}/bin/java -jar ./HytaleServer.jar --assets ../Assets.zip -b ${cfg.bind}:${toString cfg.port} ${cfg.extraFlags}";
            Restart = "always";
            User = "hytale";
            WorkingDirectory = "${cfg.dataDir}/Server";
          };
        };
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
