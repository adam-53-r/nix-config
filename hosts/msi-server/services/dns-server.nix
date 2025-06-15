{pkgs, ...}: {
  services.bind = {
    enable = true;
    listenOn = ["100.86.227.101"];
    ipv4Only = true;
    extraOptions = ''
      allow-recursion { any; };
      allow-query { any; };
      dnssec-validation no;
    '';
    cacheNetworks = [ "any" ];
    zones = {
      "arm53.xyz" = {
        master = true;
        file = pkgs.writeText "arm53.xyz.db" ''
          $ORIGIN arm53.xyz.
          $TTL 2h

          @               SOA     ns1 hostmaster (
                                          2018111111 ; Serial
                                          8h         ; Refresh
                                          30m        ; Retry
                                          1w         ; Expire
                                          1h )       ; Negative Cache TTL
                          NS      ns1

          dash            A       100.86.227.101
          ns1             A       100.86.227.101
        '';
      };
    };
  };
}
