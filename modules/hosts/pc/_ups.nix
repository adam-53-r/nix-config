# NUT for the USB UPS. upsd and upsmon share the nut-admin credential; on main
# both pointed at the unrelated adamr-wg-password secret (copy-paste) while the
# actual nut/nut-admin secret sat unused — fixed to use the right one.
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
      passwordFile = config.sops.secrets."nut/nut-admin".path;
      upsmon = "primary";
    };

    # section: The upsmon daemon configuration: upsmon.conf
    upsmon.monitor."UPS-1" = {
      system = "UPS-1@localhost";
      powerValue = 1;
      user = "nut-admin";
      passwordFile = config.sops.secrets."nut/nut-admin".path;
      type = "primary";
    };
  };

  sops.secrets."nut/nut-admin".sopsFile = ./secrets.json;
}
