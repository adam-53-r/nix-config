{
  config,
  ...
}: {
  sops.secrets = {
    openvpn-windscribe = {
      format = "binary";
      sopsFile = ./windscribe.ovpn.sops;
    };
    windscribe-credentials = {
      format = "binary";
      sopsFile = ./windscribe-credentials.sops;
    };
  };

  containers.windscribe-vpn = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.100.10";
    localAddress = "192.168.100.11";
    enableTun = true;
    ephemeral = true;
    bindMounts = {
      "/root/windscribe.ovpn" = {
        hostPath = config.sops.secrets.openvpn-windscribe.path;
        isReadOnly = true;
      };
      "/root/windscribe-credentials.txt" = {
        hostPath = config.sops.secrets.windscribe-credentials.path;
        isReadOnly = true;
      };
    };
    config = { ... }: {
      system.stateVersion = "25.05";

      networking.useHostResolvConf = false;
      services.resolved.enable = true;

      services.openvpn.servers = {
        windscribe = {
          config = ''
            config /root/windscribe.ovpn
            auth-user-pass /root/windscribe-credentials.txt
          '';
          autoStart = true;
        };
      };      
    };
  };
}
