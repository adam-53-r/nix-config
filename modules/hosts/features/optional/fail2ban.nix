# Optional fail2ban to throttle brute-force attempts on a public host.
# Ported from msi-server `common/optional/fail2ban.nix`. Especially relevant on
# an internet-facing cloud VM. Tailscale CGNAT range is whitelisted.
{...}: {
  flake.nixosModules.optionalFail2ban = {...}: {
    services.fail2ban = {
      enable = true;
      ignoreIP = [
        # Ignore Tailscale IPs
        "100.64.0.0/10"
      ];
    };
  };
}
