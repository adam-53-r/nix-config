# YubiKey: FIDO2/U2F for login/sudo, smartcard daemon for the GPG identity,
# touch notifications and management tooling.
#
# `control = "sufficient"` means the key is an alternative to the password,
# never a requirement, so a lost key can't lock you out.
{
  flake.nixosModules.desktopYubikey = {pkgs, ...}: {
    key = "mynix#nixosModules.desktopYubikey";

    security.pam.services = {
      login.u2fAuth = true;
      sudo.u2fAuth = true;
    };
    security.pam.u2f = {
      enable = true;
      control = "sufficient";
      settings.cue = true;
    };

    # Smartcard daemon (GPG via YubiKey) + management tooling
    services.pcscd.enable = true;
    services.udev.packages = [pkgs.yubikey-manager];
    environment.systemPackages = [pkgs.yubikey-manager];

    programs.gnupg.agent.enable = true;
    programs.yubikey-touch-detector.enable = true;
  };
}
