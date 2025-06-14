{pkgs, ...}: {
  services.dnsmasq.enable = false;
  services.bind = {
    enable = true;
    zones = {
      "arm53.xyz" = {
        master = true;
        file = pkgs.writeText "arm53.xyz" ''
          $ORIGIN arm53.xyz.
          $TTL    1h
          @            IN      SOA     ns1 hostmaster (
                                           1    ; Serial
                                           3h   ; Refresh
                                           1h   ; Retry
                                           1w   ; Expire
                                           1h)  ; Negative Cache TTL
                          IN      NS     ns1
                          
          dash            IN      A      100.86.227.101
          ns1             IN      A      100.86.227.101
        '';
      };
    };
  };
}
