{
  lib,
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
    ../common/optional/wireguard-server.nix
    ../common/optional/docker.nix
    ../common/optional/libvirtd.nix
    # ../common/optional/virtualbox.nix
    # ../common/optional/vmware.nix

    ./services
  ];

  networking = {
    hostName = "msi-server";
    hosts = {
      "127.0.0.1" = lib.attrNames config.services.nginx.virtualHosts;
    };
  };

  boot = {
    binfmt.emulatedSystems = [
      "aarch64-linux"
      "i686-linux"
    ];
  };

  powerManagement.powertop.enable = true;

  programs = {
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

    # Enabling nat for ve-* interfaces for systemd-nspawn containers
    nat = {
      enable = true;
      # Use "ve-*" when using nftables instead of iptables
      internalInterfaces = ["ve-+"];
      externalInterface = "br-servers-vlan";
      # Lazy IPv6 connectivity for the container
      # enableIPv6 = true;
    };
  };

  sops.secrets = {
    wg-priv-key.sopsFile = ./secrets.json;
  };

  networking.wireguard.interfaces.wg0 = {
    generatePrivateKeyFile = lib.mkForce false;
    privateKeyFile = config.sops.secrets.wg-priv-key.path;
  };

  networking.firewall.allowedTCPPorts = [80 443];

  # Users for Ark Server
  users.users = let
    ark = {
      isNormalUser = true;
      shell = pkgs.fish;
      extraGroups = [
        "ark"
      ];
      openssh.authorizedKeys.keys = lib.splitString "\n" (builtins.readFile ../../home/adamr/ssh.pub);
      packages = [pkgs.home-manager];
    };
    pau = ark;
    marti = ark;
  in {
    inherit ark marti pau;
    dani = {
      isNormalUser = true;
      shell = pkgs.fish;
      extraGroups = [
        "libvirtd"
        "podman"
      ];

      openssh.authorizedKeys.keys = lib.splitString "\n" (builtins.readFile ../../home/dani/ssh.pub + "\n" + builtins.readFile ../../home/adamr/ssh.pub);
      packages = [pkgs.home-manager];
    };
  };

  home-manager = let
    hm =
      import ../../home/adamr/${config.networking.hostName}_no_persistance.nix;
    dani = hm;
    ark = hm;
    pau = hm;
    marti = hm;
  in {
    users = {
      inherit dani ark marti pau;
    };
    backupFileExtension = "hm.bak";
  };

  services.openssh.extraConfig = ''
    Match User ark
      Banner /etc/ark_ssh_banner
  '';

  environment.etc.ark_ssh_banner.text = ''
    Entra a la sessio de byobu amb `byobu-tmux a` o creala amb `byobu-tmux`.
  '';

  environment.persistence = {
    "/persist".directories = map (user: "/home/" + user) ["dani" "ark" "pau" "marti"];
  };

  users.groups = {
    ark = {};
  };

  environment.systemPackages = [
    pkgs.tmux
    pkgs.byobu
  ];

  services.snapper = {
    snapshotInterval = "*-*-* *:00,20,40:00";
    configs = {
      DATA = {
        SUBVOLUME = "/DATA";
        ALLOW_GROUPS = ["wheel"];
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        TIMELINE_LIMIT_HOURLY = 3;
        TIMELINE_LIMIT_DAILY = 10;
        TIMELINE_LIMIT_WEEKLY = 7;
        TIMELINE_LIMIT_MONTHLY = 5;
        TIMELINE_LIMIT_QUARTERLY = 0;
        TIMELINE_LIMIT_YEARLY = 0;
      };
    };
  };

  system.stateVersion = "25.05";
}
