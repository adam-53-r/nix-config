# WireGuard server end of the adamr road-warrior tunnel (the pc host is the
# client peer). The private key is generated on-host unless the host overrides
# privateKeyFile (msi-server pins it to a sops secret).
{
  flake.nixosModules.optionalWireguardServer = {
    lib,
    config,
    ...
  }: {
    key = "mynix#nixosModules.optionalWireguardServer";

    networking.firewall = {
      allowedUDPPorts = [51820];
    };

    networking.wireguard.interfaces = {
      wg0 = {
        # The server's end of the tunnel interface.
        ips = ["10.100.0.1/24"];

        # The port that WireGuard listens to. Must be accessible by the client.
        listenPort = 51820;

        generatePrivateKeyFile = lib.mkDefault true;

        peers = [
          {
            name = "adamr";
            # Public key of the peer (not a file path).
            publicKey = "JJ3rsP23WSOlcHxV9SvCIjD5GdtVU3mvgvHPzE881i4=";
            presharedKeyFile = config.sops.secrets.adamr-wg-password.path;
            # IPs assigned to this peer within the tunnel subnet.
            allowedIPs = ["10.100.0.2/32"];
          }
        ];
      };
    };

    sops.secrets = {
      adamr-wg-password = {
        sopsFile = ../../common/users/secrets.json;
      };
    };
  };
}
