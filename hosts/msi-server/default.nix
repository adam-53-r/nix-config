{
  lib,
  inputs,
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix

    ../common/global
    ../common/users/adamr

    ../common/optional/quietboot.nix
    ../common/optional/ecryptfs.nix
    ../common/optional/fail2ban.nix
    ../common/optional/gns3-server.nix
    ../common/optional/mysql.nix
    ../common/optional/tailscale-exit-node.nix
    ../common/optional/wireguard-server.nix
    ../common/optional/nextcloud.nix
    ../common/optional/plex.nix
    ../common/optional/docker.nix
    ../common/optional/libvirtd.nix
    # ../common/optional/virtualbox.nix
    # ../common/optional/vmware.nix

    inputs.nix-minecraft.nixosModules.minecraft-servers
  ];


  networking = {
    hostName = "msi-server";
  };

  powerManagement.powertop.enable = true;

  programs = {
    adb.enable = true;
    dconf.enable = true;
    fish.enable = true;
  };

  networking.networkmanager.enable = lib.mkForce false;
  networking.enableIPv6 = false;
  networking = {
    vlans = {
      servers-vlan = {
        id = 2;
        interface = "enp2s0";
      };
    };
    bridges = {
      br-servers-vlan = {
        interfaces = [
          "servers-vlan"
        ];
      };
    };
    interfaces = {
      enp2s0.useDHCP = false;
      servers-vlan.useDHCP = false;
      br-servers-vlan = {
        ipv4 = {
          addresses = [
            {
              address = "192.168.2.10";
              prefixLength = 24;
            }
          ];
        };
      };
    };
    defaultGateway = {
      address = "192.168.2.1";
      interface = "br-servers-vlan";
    };
    nameservers = ["192.168.2.1"];
  };
  
  networking.wireguard.interfaces.wg0 = {
    generatePrivateKeyFile = lib.mkForce false;
    privateKeyFile = config.sops.secrets.wg-priv-key.path;
  };

  services.nextcloud = {
    config.adminpassFile = config.sops.secrets.nextcloud-admin-passwd.path;
    https = true;
    home = "/DATA/msi-server/nextcloud";
  };

  services.nginx.virtualHosts.${config.services.nextcloud.hostName} = {
    # forceSSL = true;
    addSSL = true;
    sslCertificate = config.sops.secrets.cert-file.path;
    sslCertificateKey = config.sops.secrets.key-file.path;
  };

  systemd.services.nginx.requires = [
    "DATA.mount"
  ];

  sops.secrets = {
    wg-priv-key.sopsFile = ./secrets.json;
    nextcloud-admin-passwd.sopsFile = ./secrets.json;
    cert-file = {
      format = "binary";
      sopsFile = ./cert-file.sops;
      owner = "nginx";
    };
    key-file = {
      format = "binary";
      sopsFile = ./key-file.sops;
      owner = "nginx";
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

   services.minecraft-servers = {
    enable = true;
    eula = true;
    openFirewall = true;
    servers.vanilla = {
      enable = true;
      jvmOpts = "-Xmx4G -Xms2G";

      # Specify the custom minecraft server package
      package = pkgs.inputs.nix-minecraft.vanillaServers.vanilla-1_21_5;
    };
  }; 

  networking.nat = {
    enable = true;
    # Use "ve-*" when using nftables instead of iptables
    internalInterfaces = ["ve-+"];
    externalInterface = "br-servers-vlan";
    # Lazy IPv6 connectivity for the container
    # enableIPv6 = true;
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
    config = { config, pkgs, lib, ... }: {
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

  system.stateVersion = "25.05";
}
