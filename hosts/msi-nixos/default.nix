{
  config,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix

    ../common/global
    ../common/users/adamr

    ../common/optional/quietboot.nix
    ../common/optional/sddm.nix
    ../common/optional/cinnamon.nix
    ../common/optional/pipewire.nix
    ../common/optional/tlp.nix
    ../common/optional/cups.nix
    ../common/optional/wireshark.nix
    ../common/optional/x11-no-suspend.nix
    ../common/optional/gns3-client.nix
    ../common/optional/steam.nix
    ../common/optional/libvirtd.nix
    ../common/optional/ecryptfs.nix
    ../common/optional/docker.nix
    # ../common/optional/virtualbox.nix
  ];

  networking = {
    hostName = "msi-nixos";
  };

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_latest;
    binfmt.emulatedSystems = [
      "aarch64-linux"
      "i686-linux"
    ];
  };

  virtualisation.vmware.host.enable = true;

  powerManagement.powertop.enable = true;
  programs = {
    # light.enable = true;
    adb.enable = true;
    dconf.enable = true;
    fish.enable = true;
  };

  # Lid settings
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "lock";
  };

  hardware.graphics.enable = true;

  services.displayManager.defaultSession = "cinnamon";

  networking.firewall = {
    allowedUDPPorts = [ 51820 ]; # Clients and peers can use the same port, see listenport
  };
  # Enable WireGuard
  networking.wireguard.interfaces = {
    # "wg0" is the network interface name. You can name the interface arbitrarily.
    wg0 = {
      # Determines the IP address and subnet of the client's end of the tunnel interface.
      ips = [ "10.100.0.2/24" ];
      listenPort = 51820; # to match firewall allowedUDPPorts (without this wg uses random port numbers)

      # Path to the private key file.
      #
      # Note: The private key can also be included inline via the privateKey option,
      # but this makes the private key world-readable; thus, using privateKeyFile is
      # recommended.
      # privateKeyFile = "path to private key file";
      privateKeyFile = config.sops.secrets.wg-priv-key.path;

      peers = [
        {
          name = "msi-server";
          # Public key of the server (not a file path).
          publicKey = "qXYdI/rZvLmafb+TdIY+TTOOSeF7oIMkYwjrzCnqYmc=";
          presharedKeyFile = config.sops.secrets.adamr-wg-password.path;

          # Forward all the traffic via VPN.
          # allowedIPs = [ "0.0.0.0/0" ];
          # Or forward only particular subnets
          allowedIPs = [ "10.100.0.1/32" ];

          # Set this to the server IP and port.
          endpoint = "msi-server:51820"; # ToDo: route to endpoint not automatically configured https://wiki.archlinux.org/index.php/WireGuard#Loop_routing https://discourse.nixos.org/t/solved-minimal-firewall-setup-for-wireguard-client/7577

          # Send keepalives every 25 seconds. Important to keep NAT tables alive.
          persistentKeepalive = 25;
        }
      ];
    };
  };

  sops.secrets = {
    wg-priv-key = {
      sopsFile = ./secrets.json;
    };
    adamr-wg-password = {
      sopsFile = ../common/secrets.json;
    };
  };

  system.stateVersion = "25.05";
}