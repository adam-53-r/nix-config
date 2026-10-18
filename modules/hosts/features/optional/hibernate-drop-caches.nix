# Drop the page cache right before hibernating. Otherwise the kernel has to
# shrink memory down to /sys/power/image_size itself, and with zram's high
# swappiness it does that by compressing app memory into zram instead of
# dropping cache, which took 9-26s on pc. The cache is in the image for
# nothing anyway: it gets read back from disk either way.
{
  flake.nixosModules.optionalHibernateDropCaches = {
    key = "mynix#nixosModules.optionalHibernateDropCaches";

    systemd.services.hibernate-drop-caches = {
      description = "Drop the page cache before hibernating";
      wantedBy = ["systemd-hibernate.service"];
      before = ["systemd-hibernate.service"];
      # Same reason as plymouth-hibernate: the sleep units are
      # DefaultDependencies=no themselves.
      unitConfig.DefaultDependencies = false;
      serviceConfig.Type = "oneshot";
      script = ''
        sync
        echo 1 > /proc/sys/vm/drop_caches
      '';
    };
  };
}
