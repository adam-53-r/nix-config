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
      # GUI hosts (gtk.enable) get a graphical prompt; headless hosts fall back
      # to a curses prompt that still works over an ssh session.
      #
      # Not pinentry-gnome3: it does not draw its own window, it asks gcr's
      # org.gnome.keyring.SystemPrompter to. Without gnome-keyring running that
      # name is only activatable, and pinentry silently falls back to curses on
      # its controlling tty — which for a non-interactive caller is a terminal
      # nobody is watching, so signing appears to hang and then fails with
      # "Timeout" while the PIN retry counter stays untouched. pinentry-qt
      # opens its own window and needs no session daemon (Qt is already here
      # for sddm).
      pinentry.package =
        if config.gtk.enable
        then pkgs.pinentry-qt
        else pkgs.pinentry-curses;
      noAllowExternalCache = true;
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

    # Link /run/user/$UID/gnupg to ~/.gnupg-sockets so the ssh `net` match
    # block (homeSsh) can forward the agent socket without needing to know
    # the UID ahead of time.
    systemd.user.services.link-gnupg-sockets = {
      Unit.Description = "link gnupg sockets from /run to /home";
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.coreutils}/bin/ln -Tfs /run/user/%U/gnupg %h/.gnupg-sockets";
        ExecStop = "${pkgs.coreutils}/bin/rm $HOME/.gnupg-sockets";
        RemainAfterExit = true;
      };
      Install.WantedBy = ["default.target"];
    };
  };
}
