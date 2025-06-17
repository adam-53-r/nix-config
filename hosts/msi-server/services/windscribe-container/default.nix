{config, ...}: {
  sops.secrets = {
    openvpn-windscribe-staticip = {
      format = "binary";
      sopsFile = ./windscribe-staticip.ovpn.sops;
    };
    windscribe-credentials-staticip = {
      format = "binary";
      sopsFile = ./windscribe-credentials-staticip.sops;
    };
    openvpn-windscribe = {
      format = "binary";
      sopsFile = ./windscribe.ovpn.sops;
    };
    windscribe-credentials = {
      format = "binary";
      sopsFile = ./windscribe-credentials.sops;
    };
  };

  containers.windscribe-static-ip-vpn = let
    config-file = "/run/secrets/windscribe.ovpn";
    credentials-file = "/run/secrets/windscribe-credentials.txt";
  in {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.100.2";
    localAddress = "192.168.100.1";
    enableTun = true;
    ephemeral = true;
    bindMounts = {
      "${config-file}" = {
        hostPath = config.sops.secrets.openvpn-windscribe-staticip.path;
        isReadOnly = true;
      };
      "${credentials-file}" = {
        hostPath = config.sops.secrets.windscribe-credentials-staticip.path;
        isReadOnly = true;
      };
    };
    config = {...}: {
      system.stateVersion = "25.05";

      networking.useHostResolvConf = false;
      services.resolved.enable = true;

      services.openvpn.servers = {
        windscribe = {
          config = ''
            config ${config-file}
            auth-user-pass ${credentials-file}
          '';
          autoStart = true;
        };
      };
    };
  };

  containers.windscribe-vpn = let
    config-file = "/run/secrets/windscribe.ovpn";
    credentials-file = "/run/secrets/windscribe-credentials.txt";
  in {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.101.2";
    localAddress = "192.168.101.1";
    enableTun = true;
    ephemeral = true;
    bindMounts = {
      "${config-file}" = {
        hostPath = config.sops.secrets.openvpn-windscribe.path;
        isReadOnly = true;
      };
      "${credentials-file}" = {
        hostPath = config.sops.secrets.windscribe-credentials.path;
        isReadOnly = true;
      };
    };
    config = {...}: {
      system.stateVersion = "25.05";

      networking.useHostResolvConf = false;
      services.resolved.enable = true;

      services.openvpn.servers = {
        windscribe = {
          config = ''
            config ${config-file}
            auth-user-pass ${credentials-file}
          '';
          autoStart = true;
        };
      };
    };
  };
}
