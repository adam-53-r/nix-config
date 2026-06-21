# GnuPG + agent, shared optional home feature.
#
# This is NOT identity (the signing key fingerprint lives in adamr's identity
# profile); it's the generic gpg/gpg-agent setup any user could want. The agent
# doubles as the ssh auth agent for hardware-token keys. Persistence for ~/.gnupg
# is colocated here (mode 0700, which gpg requires) and only takes effect when
# myPersistence.enable is set.
{...}: {
  flake.homeModules.homeGpg = {
    pkgs,
    config,
    ...
  }: {
    programs.gpg = {
      enable = true;
      settings.trust-model = "tofu+pgp";
      # Hardware token brings its own CCID stack; disable gpg's internal one.
      scdaemonSettings.disable-ccid = true;
    };

    services.gpg-agent = {
      enable = true;
      enableSshSupport = true;
      enableExtraSocket = true;
      # Headless box: curses pinentry works over an ssh session.
      pinentry.package = pkgs.pinentry-curses;
      defaultCacheTtl = 10800;
      defaultCacheTtlSsh = 10800;
    };

    # SSH does not autostart gpg-agent; nudge it on login so the agent socket
    # exists for git/ssh on first use.
    programs.fish.loginShellInit = "gpgconf --launch gpg-agent";

    # gpg refuses to use ~/.gnupg unless it is mode 0700.
    home.persistence."/persist".directories = [
      {
        directory = ".gnupg";
        mode = "0700";
      }
    ];
  };
}
