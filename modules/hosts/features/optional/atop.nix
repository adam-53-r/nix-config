# Historical per-process resource logging (atop), for post-mortem diagnosis
# of IO/CPU stalls that host-level Prometheus metrics can't attribute to a
# specific process. Complements globalNodeExporter's pressure/btrfs/diskstats
# collectors, which cover host-wide trends but not per-process attribution.
{...}: {
  flake.nixosModules.optionalAtop = {pkgs, ...}: {
    key = "mynix#nixosModules.optionalAtop";

    environment.systemPackages = [pkgs.atop];

    systemd.services.atop-logger = {
      description = "atop process/system activity recorder";
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        ExecStart = "${pkgs.bash}/bin/bash -c 'exec ${pkgs.atop}/bin/atop -w /var/log/atop/atop_$(date +%%Y%%m%%d) 15'";
        Restart = "always";
        RuntimeMaxSec = 86400; # roll to a new dated file about once a day
      };
    };

    # `d` (not just directory creation) also makes systemd-tmpfiles-clean
    # prune files older than 14d on its regular timer.
    systemd.tmpfiles.rules = ["d /var/log/atop 0750 root root 14d"];

    environment.persistence."/persist".directories = ["/var/log/atop"];
  };
}
