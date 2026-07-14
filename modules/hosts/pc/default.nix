# The pc host: AMD desktop workstation running Hyprland (uwsm) with Cinnamon
# as fallback, on an encrypted ephemeral btrfs root with limine secure boot.
{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.pcConfiguration = {
    config,
    pkgs,
    lib,
    ...
  }: {
    key = "mynix#nixosModules.pcConfiguration";

    imports = [
      inputs.nixos-hardware.nixosModules.common-cpu-amd
      inputs.nixos-hardware.nixosModules.common-pc-ssd

      self.nixosModules.desktopBase
      self.nixosModules.diskoBtrfs
      self.nixosModules.optionalQuietboot
      self.nixosModules.optionalSecureBoot
      self.nixosModules.optionalSnapshots
      self.nixosModules.optionalSteam
      self.nixosModules.optionalLibvirtd
      self.nixosModules.optionalDocker
      self.nixosModules.optionalWireshark
      self.nixosModules.optionalGns3Server
      self.nixosModules.optionalPersistBackup
      self.nixosModules.optionalFlatpak
      self.nixosModules.userAdamr

      ./_hardware.nix
      ./_ups.nix
      ./_ai.nix
    ];

    networking.hostName = "pc";

    hardware.disko-btrfs = {
      encrypted = true;
      ephemeral = true;
      # TRIM is handled by fstrim.timer (common-pc-ssd), not continuous discard.
      extraMountOptions = ["nodiscard"];
    };

    boot = {
      kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_latest;
      binfmt.emulatedSystems = [
        "aarch64-linux"
        "i686-linux"
      ];
      # Disable USB autosuspend so peripherals (YubiKey included) don't flake
      # out after going idle. (main did this via services.tlp.settings, which
      # also applies laptop-battery power heuristics this desktop doesn't want
      # — just the kernel param is ported here.)
      kernelParams = ["usbcore.autosuspend=-1"];
    };

    services.displayManager.defaultSession = "hyprland-uwsm";

    environment.systemPackages = with pkgs; [hostctl android-tools];
    environment.etc.hosts.mode = "0644";

    hardware.bluetooth.powerOnBoot = false;

    # Wireguard tunnel to msi-server (nm must not touch the interface).
    networking.networkmanager.unmanaged = [
      "msi-server"
    ];
    networking.firewall = {
      allowedUDPPorts = [51820]; # Clients and peers can use the same port, see listenport
    };
    networking.wireguard.interfaces = {
      msi-server = {
        # The client's end of the tunnel interface.
        ips = ["10.100.0.2/24"];
        listenPort = 51820; # to match firewall allowedUDPPorts (without this wg uses random port numbers)
        privateKeyFile = config.sops.secrets.wg-priv-key.path;

        peers = [
          {
            name = "msi-server";
            # Public key of the server (not a file path).
            publicKey = "qXYdI/rZvLmafb+TdIY+TTOOSeF7oIMkYwjrzCnqYmc=";
            presharedKeyFile = config.sops.secrets.adamr-wg-password.path;
            # Only forward the server's tunnel subnet.
            allowedIPs = ["10.100.0.1/32"];
            # Set this to the server IP and port.
            endpoint = "100.86.227.101:51820";
            # Keepalives keep the NAT mapping alive.
            persistentKeepalive = 25;
          }
        ];
      };
    };

    # QMK/vial keyboard flashing without root.
    hardware.keyboard.qmk.enable = true;
    services.udev.packages = [
      (pkgs.writeTextDir "etc/udev/rules.d/59-vial.rules" ''
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
      '')
    ];

    services.hardware.openrgb = {
      enable = true;
      motherboard = "amd";
      package = pkgs.openrgb-with-all-plugins;
    };

    services.restic.backups.persist = {
      exclude = [
        "/persist/home/adamr/.local/share/Steam/steamapps/common"
        "/persist/home/adamr/.local/share/Steam/steamapps/shadercache"
      ];
      passwordFile = config.sops.secrets."restic/repo-passwd".path;
      environmentFile = config.sops.templates."restic-server-auth".path;
    };

    sops.secrets = {
      wg-priv-key.sopsFile = ./secrets.json;
      adamr-wg-password.sopsFile = ../common/users/secrets.json;
      "restic/repo-passwd".sopsFile = ./secrets.json;
      "restic/rest-auth/pc".sopsFile = ./secrets.json;
    };

    sops.templates."restic-server-auth".content = ''
      RESTIC_REST_USERNAME=pc
      RESTIC_REST_PASSWORD=${config.sops.placeholder."restic/rest-auth/pc"}
    '';

    system.stateVersion = "25.05";
  };
}
