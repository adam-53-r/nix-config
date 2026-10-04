# Passphrase drill: every hour a wofi password prompt asks for a
# passphrase and checks it against a salted yescrypt hash, so it sticks.
# The hash lives outside the (public) repo; set it once with
# `password-train --set`.
{
  flake.homeModules.homePasswordTrain = {
    config,
    lib,
    pkgs,
    ...
  }: let
    stateDir = "${config.xdg.dataHome}/password-train";

    password-train = pkgs.writeShellApplication {
      name = "password-train";
      runtimeInputs = with pkgs; [
        config.programs.wofi.package
        mkpasswd
        libnotify
        procps
        coreutils
      ];
      text = ''
        state=${lib.escapeShellArg stateDir}
        hash_file="$state/hash"
        streak_file="$state/streak"

        ask() {
          wofi --dmenu --password --lines 1 --prompt "$1" </dev/null 2>/dev/null || true
        }

        if [ "''${1:-}" = "--set" ]; then
          pw=$(ask "new passphrase")
          [ -n "$pw" ] || exit 1
          [ "$(ask "repeat passphrase")" = "$pw" ] || {
            notify-send -a password-train -u critical "Passphrases don't match"
            exit 1
          }
          mkdir -p "$state"
          (umask 077 && printf '%s' "$pw" | mkpasswd -m yescrypt -s >"$hash_file")
          echo 0 >"$streak_file"
          notify-send -a password-train "Passphrase saved"
          exit 0
        fi

        [ -r "$hash_file" ] || {
          notify-send -a password-train "No passphrase set" "Run: password-train --set"
          exit 0
        }
        # The prompt can't show over the lock screen; don't pile up behind it.
        if pgrep -u "$(id -u)" -x swaylock >/dev/null; then exit 0; fi

        hash=$(<"$hash_file")
        streak=$(cat "$streak_file" 2>/dev/null || echo 0)

        for try in 1 2 3; do
          pw=$(ask "passphrase ($try/3)")
          [ -n "$pw" ] || exit 0 # cancelled
          if [ "$(printf '%s' "$pw" | mkpasswd -s -S "$hash")" = "$hash" ]; then
            [ "$try" = 1 ] && streak=$((streak + 1))
            echo "$streak" >"$streak_file"
            notify-send -a password-train -t 3000 "Good!" "Streak: $streak"
            exit 0
          fi
          streak=0
          echo 0 >"$streak_file"
          notify-send -a password-train -u critical -t 3000 "Bad :(" "Try again"
        done
      '';
    };
  in {
    home.packages = [password-train];

    systemd.user.services.password-train = {
      Unit = {
        Description = "Passphrase memory drill";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };
      Service = {
        Type = "oneshot";
        ExecStart = lib.getExe password-train;
      };
    };
    systemd.user.timers.password-train = {
      Unit = {
        Description = "Passphrase memory drill every hour";
        PartOf = ["graphical-session.target"];
      };
      Timer = {
        OnActiveSec = "1h";
        OnUnitInactiveSec = "1h";
      };
      Install.WantedBy = ["graphical-session.target"];
    };

    home.persistence."/persist".directories = [
      ".local/share/password-train"
    ];
  };
}
