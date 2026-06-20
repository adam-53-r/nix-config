# Locale / timezone defaults, shared by every host.
# Ported from msi-server `common/global/locale.nix`. The `location.provider =
# geoclue2` line was dropped: a headless cloud VM has no need for geolocation
# and it would pull in geoclue unnecessarily.
{...}: {
  flake.nixosModules.globalLocale = {lib, ...}: {
    i18n = {
      defaultLocale = lib.mkDefault "en_US.UTF-8";
      extraLocaleSettings = {
        LC_ADDRESS = "en_US.UTF-8";
        LC_IDENTIFICATION = "en_US.UTF-8";
        LC_MEASUREMENT = "en_US.UTF-8";
        LC_MONETARY = "en_US.UTF-8";
        LC_NAME = "en_US.UTF-8";
        LC_NUMERIC = "en_US.UTF-8";
        LC_PAPER = "en_US.UTF-8";
        LC_TELEPHONE = "en_US.UTF-8";
        LC_TIME = "en_US.UTF-8";
      };
      supportedLocales = lib.mkDefault [
        "en_US.UTF-8/UTF-8"
        "es_ES.UTF-8/UTF-8"
      ];
    };
    time.timeZone = lib.mkDefault "Europe/Madrid";
  };
}
