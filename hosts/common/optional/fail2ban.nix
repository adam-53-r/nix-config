{
  services.fail2ban = {
    enable = true;
    ignoreIP = [
      # Ignore Tailscale IPs
      "100.64.0.0/10"
    ];
  };
}
