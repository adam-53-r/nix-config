{
  pkgs,
  inputs,
  lib,
  config,
  options,
  ...
}: with lib; {
  imports = [
    ./hardware-configuration.nix

    ../common/global
    ../common/users/adamr

    ../common/optional/quietboot.nix
  ];

  networking = {
    hostName = "vm-tests";
  };

  disable-user-sops = true;

  users.users.adamr = {
    initialHashedPassword = "$y$j9T$lgLih3qHgZnQSSV.Cfk0T1$/BM.PW5.2dc/1yu4069/wF845WW95YBYRpGrSnxPba3";
  };

  powerManagement.powertop.enable = true;
  programs = {
    adb.enable = true;
    dconf.enable = true;
    fish.enable = true;
  };

  networking.firewall = {
    allowedUDPPorts = [ 51821 ]; # Clients and peers can use the same port, see listenport
  };
  # Enable WireGuard
  networking.wireguard.interfaces = {
    # "wg0" is the network interface name. You can name the interface arbitrarily.
    wg-tests = {
      # Determines the IP address and subnet of the client's end of the tunnel interface.
      ips = [ "10.69.69.2/24" ];
      listenPort = 51821; # to match firewall allowedUDPPorts (without this wg uses random port numbers)

      # Path to the private key file.
      #
      # Note: The private key can also be included inline via the privateKey option,
      # but this makes the private key world-readable; thus, using privateKeyFile is
      # recommended.
      privateKeyFile = config.sops.secrets.wg-priv-key.path;

      peers = [
        {
          name = "msi-nixos";
          # Public key of the server (not a file path).
          publicKey = "iXKNESRze59Kamc6xXRujBwc4Xq+kAHMZc1wSalxfC0=";
          presharedKeyFile = config.sops.secrets.wg-priv-key.path;
          # Forward all the traffic via VPN.
          # allowedIPs = [ "0.0.0.0/0" ];
          # Or forward only particular subnets
          allowedIPs = [ "10.69.69.1/32" ];

          # Set this to the server IP and port.
          endpoint = "192.168.122.1:51821"; # ToDo: route to endpoint not automatically configured https://wiki.archlinux.org/index.php/WireGuard#Loop_routing https://discourse.nixos.org/t/solved-minimal-firewall-setup-for-wireguard-client/7577

          # Send keepalives every 25 seconds. Important to keep NAT tables alive.
          persistentKeepalive = 25;
        }
      ];
    };
  };

  sops.secrets = {
    wg-priv-key = {
      sopsFile = ./secrets.json;
      # neededForUsers = true;
    };
  };

  system.stateVersion = "25.05";
}