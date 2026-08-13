# blacksite lab infrastructure: the things that make the toolbox usable —
# Kali-compatible wordlist paths, a metasploit database, and a set of
# deliberately-vulnerable practice targets to point the tools at.
#
# Plain NixOS module (underscore file: skipped by import-tree), imported by
# blacksiteConfiguration in ./default.nix.
{
  pkgs,
  lib,
  config,
  ...
}: let
  # Every walkthrough, tool default and cheatsheet in this space hardcodes
  # Kali's /usr/share/wordlists. The `wordlists` package (from the toolbox's
  # workflow category) symlink-joins rockyou/seclists/nmap/wfuzz under
  # share/wordlists, so pointing the FHS path at the system profile gives
  # `-w /usr/share/wordlists/rockyou.txt` for free without patching any tool.
  fhsWordlists = "/run/current-system/sw/share/wordlists";

  # Practice targets, deliberately vulnerable by design. All three bind to
  # loopback ONLY: they exist to be attacked from inside this VM, and an
  # unauthenticated-RCE sandbox reachable from the LAN would be a real hole in
  # the surrounding network rather than a lesson.
  targets = {
    juice-shop = {
      image = "bkimminich/juice-shop:latest";
      port = 3000;
      containerPort = 3000;
      blurb = "OWASP Juice Shop — modern JS webapp, ~100 challenges";
    };
    dvwa = {
      image = "vulnerables/web-dvwa:latest";
      port = 8080;
      containerPort = 80;
      blurb = "Damn Vulnerable Web App — classic PHP, adjustable difficulty";
    };
    webgoat = {
      image = "webgoat/webgoat:latest";
      port = 8081;
      containerPort = 8080;
      blurb = "OWASP WebGoat — guided lessons, JVM";
    };
  };

  # Read (never defined here), so there's no self-reference: the unit names the
  # helper drives come from the same place systemd gets them.
  backend = config.virtualisation.oci-containers.backend;
  unitOf = name: "${backend}-${name}.service";
  systemctl = lib.getExe' pkgs.systemd "systemctl";

  url = t: "http://127.0.0.1:${toString t.port}";

  # A small front-end over systemctl, so the target list, ports and unit names
  # live in one place (here) instead of in notes that go stale. `sudo` is
  # resolved from PATH on purpose — it must be the setuid wrapper in
  # /run/wrappers/bin, not a store path.
  lab = pkgs.writeShellScriptBin "lab" ''
    set -u

    unit_for() {
      case "$1" in
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList
      (name: _: "      ${name}) echo ${unitOf name} ;;")
      targets)}
        *)
          echo "lab: unknown target '$1' (have: ${lib.concatStringsSep ", " (lib.attrNames targets)})" >&2
          return 1
          ;;
      esac
    }

    usage() {
      cat <<'EOF'
    lab — blacksite practice targets

      lab list               each target, its URL, and whether it is running
      lab up   <target|all>  start a target (pulls the image on first run)
      lab down <target|all>  stop a target
      lab wordlists          print the wordlist directory

    targets:
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList
      (name: t: "  ${name} — ${t.blurb}\n      ${url t}")
      targets)}

    They listen on loopback only: attack them from inside this VM.
    EOF
    }

    act() {
      action="$1"
      shift
      if [ "$#" -eq 0 ]; then
        echo "lab: which target? (${lib.concatStringsSep ", " (lib.attrNames targets)}, all)" >&2
        exit 2
      fi
      if [ "$1" = all ]; then
        set -- ${lib.concatStringsSep " " (lib.attrNames targets)}
      fi
      for t in "$@"; do
        unit=$(unit_for "$t") || exit 1
        sudo ${systemctl} "$action" "$unit"
      done
    }

    case "''${1-}" in
      list)
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList
      (name: t: ''printf '%-12s %-24s %s\n' ${name} ${url t} "$(${systemctl} is-active ${unitOf name} || true)"'')
      targets)}
        ;;
      up)
        shift
        act start "$@"
        ;;
      down)
        shift
        act stop "$@"
        ;;
      wordlists)
        echo ${fhsWordlists}
        ;;
      *)
        usage
        ;;
    esac
  '';
in {
  environment.systemPackages = [lab];

  virtualisation.oci-containers.containers =
    lib.mapAttrs (_name: t: {
      inherit (t) image;
      ports = ["127.0.0.1:${toString t.port}:${toString t.containerPort}"];
      # On demand only. autoStart would make every boot depend on a registry
      # pull, and a lab box is often offline or on a lab-only network.
      autoStart = false;
    })
    targets;

  # Kali muscle memory: /usr/share/wordlists and /usr/share/seclists.
  # L+ replaces whatever is there, so these follow system profile changes.
  systemd.tmpfiles.rules = [
    "L+ /usr/share/wordlists - - - - ${fhsWordlists}"
    "L+ /usr/share/seclists - - - - ${fhsWordlists}/seclists"
  ];

  # metasploit runs without a database, but loses hosts/services/loot tracking
  # and db_nmap — most of what makes a long session bearable. The schema
  # still has to be created once with `sudo msfdb init`; postgres itself is all
  # this module can usefully declare, since msf keeps its own credentials in
  # ~/.msf4/database.yml.
  services.postgresql.enable = true;

  environment.persistence."/persist".directories = [
    # The msf database (hosts, services, loot, notes) across ephemeral reboots.
    "/var/lib/postgresql"
  ];

  # Raise inotify limits: ghidra, burpsuite and the JVM targets together blow
  # through the defaults on a box this busy.
  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 1024;
  };
}
