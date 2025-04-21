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
    ../common/optional/docker.nix
    ../common/optional/ecryptfs.nix
    ../common/optional/fail2ban.nix
    ../common/optional/gns3-server.nix
    ../common/optional/libvirtd.nix
    # ../common/optional/lxd.nix
    ../common/optional/mysql.nix
    ../common/optional/tailscale-exit-node.nix
    ../common/optional/wireguard-server.nix
    ../common/optional/nextcloud.nix
    ../common/optional/plex.nix

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
      sopsFile = ./cert-file;
      owner = "nginx";
    };
    key-file = {
      format = "binary";
      sopsFile = ./key-file;
      owner = "nginx";
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

  system.stateVersion = "25.05";
}
