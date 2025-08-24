{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.satisfactory-server;
in {
  options.services.satisfactory-server = {
    enable = mkEnableOption "Satisfactory Dedicated Server";

    steamcmdPackage = mkOption {
      type = types.package;
      default = pkgs.steamcmd;
      defaultText = "pkgs.steamcmd";
      description = ''
        The package implementing SteamCMD
      '';
    };

    dataDir = mkOption {
      type = types.path;
      description = "Directory to store game server";
      default = "/var/lib/satisfactory";
    };

    launchOptions = mkOption {
      type = types.str;
      description = "Launch options to use.";
      default = "";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to open ports in the firewall for the server
      '';
    };

    standardPort = mkOption {
      type = types.int;
      default = 7777;
      description = ''
        Standard udp & tcp port for Server traffic, HTTPS API, Game traffic and Lightweight Query API, defaults to 7777/tcp/udp
        See: https://satisfactory.wiki.gg/wiki/Dedicated_servers#Port_Forwarding_and_Firewall_Settings
      '';
    };

    reliablePort = mkOption {
      type = types.int;
      default = 8888;
      description = ''
        Reliable tcp port for Game traffic and Reliable messaging, defaults to 8888/tcp
        See: https://satisfactory.wiki.gg/wiki/Dedicated_servers#Port_Forwarding_and_Firewall_Settings
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.services.satisfactory-server = let
      steamcmd = "${cfg.steamcmdPackage}/bin/steamcmd";
      steam-run = "${pkgs.steam-run}/bin/steam-run";
    in {
      description = "Satisfactory Dedicated Server";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];

      serviceConfig = {
        TimeoutSec = "15min";
        ExecStart = "${steam-run} ${cfg.dataDir}/FactoryServer.sh -Port=${toString cfg.standardPort} -ReliablePort=${toString cfg.reliablePort} ${cfg.launchOptions}";
        Restart = "always";
        User = "satisfactory";
        WorkingDirectory = cfg.dataDir;
      };

      preStart = ''
        ${steamcmd} +force_install_dir "${cfg.dataDir}" +login anonymous +app_update 1690800 validate +quit
      '';
    };

    users.users.satisfactory = {
      description = "Satisfactory server service user";
      home = cfg.dataDir;
      createHome = true;
      isSystemUser = true;
      group = "satisfactory";
    };
    users.groups.satisfactory = {};

    networking.firewall = mkIf cfg.openFirewall {
      allowedUDPPorts = [
        cfg.standardPort
      ];
      allowedTCPPorts = [
        cfg.standardPort
        cfg.reliablePort
      ];
    };
  };
}
