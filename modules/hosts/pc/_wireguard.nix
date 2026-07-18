# Wireguard tunnel to msi-server. NetworkManager must not touch the interface.
{config, ...}: {
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

  sops.secrets = {
    wg-priv-key.sopsFile = ./secrets.json;
    adamr-wg-password.sopsFile = ../common/users/secrets.json;
  };
}
