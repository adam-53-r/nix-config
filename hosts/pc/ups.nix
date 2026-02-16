{config, ...}: {
  power.ups = {
    enable = true;
    mode = "standalone";
    ups."UPS-1" = {
      port = "auto";
      driver = "usbhid-ups";
    };

    # section: The upsd daemon access control; upsd.conf
    upsd = {
      listen = [
        {
          address = "127.0.0.1";
          port = 3493;
        }
        {
          address = "::1";
          port = 3493;
        }
      ];
    };

    # section: Users that can access upsd. The upsd daemon user
    # declarations. upsd.users
    users."nut-admin" = {
      passwordFile = config.sops.secrets.adamr-wg-password.path;
      upsmon = "primary";
    };

    # section: The upsmon daemon configuration: upsmon.conf
    upsmon.monitor."UPS-1" = {
      system = "UPS-1@localhost";
      powerValue = 1;
      user = "nut-admin";
      passwordFile = config.sops.secrets.adamr-wg-password.path;
      type = "primary";
    };
  };

  sops.secrets = {
    "nut/nut-admin".sopsFile = ./secrets.json;
  };
}
