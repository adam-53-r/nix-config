# The msi-server host: headless home server on the servers VLAN, running the
# self-hosted stack (nginx-fronted services, monitoring, game servers) with an
# ephemeral btrfs root and the heavy state on the DATA disk.
{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.msiServerConfiguration = {
    config,
    pkgs,
    lib,
    ...
  }: {
    key = "mynix#nixosModules.msiServerConfiguration";

    imports = [
      inputs.nixos-hardware.nixosModules.common-cpu-intel
      inputs.nixos-hardware.nixosModules.common-gpu-intel
      inputs.nixos-hardware.nixosModules.common-pc-ssd

      self.nixosModules.globalDefaults
      self.nixosModules.diskoBtrfs
      self.nixosModules.optionalQuietboot
      self.nixosModules.optionalWireguardServer
      self.nixosModules.optionalDocker
      self.nixosModules.optionalLibvirtd
      self.nixosModules.optionalSnapshots
      self.nixosModules.optionalPersistBackup
      self.nixosModules.userAdamr

      # Service-stack foundations used across ./_services
      self.nixosModules.optionalNginx
      self.nixosModules.optionalMysql
      self.nixosModules.optionalFail2ban
      self.nixosModules.optionalGns3Server
      self.nixosModules.optionalTailscaleExitNode
      self.nixosModules.hytaleServer

      ./_hardware.nix
      ./_services
    ];

    # The prometheus service scrapes every host in the flake; plain modules in
    # ./_services can't see `self`, so hand them the host list as a module arg.
    _module.args.mynixHostNames = builtins.attrNames self.nixosConfigurations;

    networking.hostName = "msi-server";

    hardware.disko-btrfs.ephemeral = true;

    networking.hosts = {
      "127.0.0.1" = lib.attrNames config.services.nginx.virtualHosts;
    };

    boot.binfmt.emulatedSystems = [
      "aarch64-linux"
      "i686-linux"
    ];

    powerManagement.powertop.enable = true;

    programs.dconf.enable = true;

    boot.kernel.sysctl = {
      "net.ipv6.conf.br-servers-vlan.accept_ra" = 2;
    };

    # Static bridge over the servers VLAN instead of NetworkManager.
    networking.networkmanager.enable = lib.mkForce false;
    networking.enableIPv6 = true;
    networking = {
      vlans = {
        servers-vlan = {
          id = 2;
          interface = "enp1s0";
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
        enp1s0.useDHCP = false;
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
          ipv6 = {
            addresses = [
              {
                address = "fd16:a5f8:258:2::10";
                prefixLength = 64;
              }
              {
                address = "2001:470:c98d:2::10";
                prefixLength = 64;
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

      # NAT for ve-* interfaces of systemd-nspawn containers (windscribe VPNs).
      nat = {
        enable = true;
        # "ve-*" when using nftables instead of iptables
        internalInterfaces = ["ve-+"];
        externalInterface = "br-servers-vlan";
      };
    };

    sops.secrets = {
      wg-priv-key.sopsFile = ./secrets.json;
      "restic/rest/msi-server".sopsFile = ./secrets.json;
      "restic/repo-passwd".sopsFile = ./secrets.json;
    };

    # The server tunnel key comes from sops, not generated on-host.
    networking.wireguard.interfaces.wg0 = {
      generatePrivateKeyFile = lib.mkForce false;
      privateKeyFile = config.sops.secrets.wg-priv-key.path;
    };

    networking.firewall.allowedTCPPorts = [80 443];

    # Shared accounts for the game servers (ark banner greets in Catalan) and
    # dani; all reuse the identity-free cliBase home profile.
    users.users = let
      ark = {
        isNormalUser = true;
        shell = pkgs.fish;
        extraGroups = [
          "ark"
        ];
        openssh.authorizedKeys.keys = config.users.users.adamr.openssh.authorizedKeys.keys;
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
        openssh.authorizedKeys.keys =
          [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMbA2PdNtIl2r8R1s8ALMCz5nU8kdM6FlO4Ernhwl2FC danielflorialopez@protonmail.com"
            "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDP/WQIuo12hyPxsyC5igAf36nPW+ZIDpyc4HlQ412/P2jzoKL97ldhhLkWi1RgkZ/EhuOqDMTiPZbdxCDoKe9Lm5wf4Lyieqaxpx0RudIOkvPnyGoLNc63kXNjBZD9Yis7XOHefCZ4BhQvGVxlXZBFDDUv1kXKc/XDPOl3Jko0zWHgu9xxxNnfj1sIrjoOIqCP2AAFjHQhj5cNqDUMVu/0vzMnXfAprD4krFVtqPkc0ubncx9r8NmgaFbz8qQsLWcYHiKTrpXc0SSPKPG1rJDL7ljxPKTdXMXooO/ekFlkM6hlR1bfnTlNekdKbojYz5g38x+6x6f6cd8ECCZRoL8w1YqubwLm4cmVlq9BmLWGQuTcCHMd8XyUUkH5EeIDT56acLGJ/pM35sadfYmTcYXbjYnXRsIwCeCMjiB3VkGMBjaANwFkqH14SbjmP2NIumpVy5zyhA+3VWAJYBK6mZ2ClqrMx1DZS78GKWGB8B6Z0QzqgyqtduJ9yuT16Bp+nHE= dani@danipc"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFl1pxusQs9UHyeRJ11qvvxR/PEsoWgtibQPpd67Yzn5 dani@fedora"
          ]
          ++ config.users.users.adamr.openssh.authorizedKeys.keys;
        packages = [pkgs.home-manager];
      };
    };

    home-manager.users = {
      dani = self.homeModules.cliBase;
      ark = self.homeModules.cliBase;
      pau = self.homeModules.cliBase;
      marti = self.homeModules.cliBase;
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
      # snapshotInterval/cleanupInterval inherited from optionalSnapshots (hourly).
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

    sops.templates."restic-server-auth".content = ''
      RESTIC_REST_USERNAME=msi-server
      RESTIC_REST_PASSWORD=${config.sops.placeholder."restic/rest/msi-server"}
    '';

    services.restic.backups.persist = {
      exclude = [];
      passwordFile = config.sops.secrets."restic/repo-passwd".path;
      environmentFile = config.sops.templates."restic-server-auth".path;
    };

    system.stateVersion = "25.05";
  };
}
