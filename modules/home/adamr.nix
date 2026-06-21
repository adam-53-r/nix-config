# adamr's personal home-manager profile: the cliBase tools/shell layer plus
# personal identity (git author + signing, gpg-agent/smartcard, ssh, gh).
# Keeping identity separate from cliBase means root can reuse cliBase without
# inheriting adamr's signing key, gpg-agent ssh support or gh credentials.
{self, ...}: {
  flake.homeModules.adamr = {
    pkgs,
    lib,
    config,
    ...
  }: let
    # OpenPGP key fingerprint backing both git commit signing and (via the
    # smartcard) ssh auth. The actual secret lives on the hardware token.
    signingKey = "586D801B64FDF09F4CE596F13068CD4BF2AB1986";
  in {
    imports = [self.homeModules.cliBase];

    home.username = lib.mkDefault "adamr";
    home.homeDirectory = lib.mkDefault "/home/adamr";

    ###########################################################################
    # Git identity + commit signing
    ###########################################################################
    programs.git = {
      settings = {
        user.name = "Adam Rkouni";
        user.email = lib.mkDefault "adam-53-r@protonmail.com";
        gpg.program = "${config.programs.gpg.package}/bin/gpg2";
      };
      signing = {
        format = "openpgp";
        key = signingKey;
        signByDefault = true;
      };
    };

    # Mirror git identity + signing into jujutsu.
    programs.jujutsu.settings = {
      user = {
        name = "Adam Rkouni";
        email = "adam-53-r@protonmail.com";
      };
      signing = {
        backend = "gpg";
        behaviour = "own";
        key = signingKey;
      };
    };

    ###########################################################################
    # GnuPG + agent (smartcard, doubles as the ssh auth agent)
    ###########################################################################
    programs.gpg = {
      enable = true;
      settings.trust-model = "tofu+pgp";
      # Hardware token uses its own CCID stack; disable gpg's internal one.
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

    ###########################################################################
    # SSH client + GitHub CLI
    ###########################################################################
    programs.ssh = {
      enable = true;
      # Opt out of the soon-to-be-removed implicit defaults; define our own.
      enableDefaultConfig = false;
      settings."*" = {
        AddKeysToAgent = "no";
        ForwardAgent = false;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
      };
    };

    programs.gh = {
      enable = true;
      settings = {
        version = "1";
        git_protocol = "ssh";
      };
    };
  };
}
