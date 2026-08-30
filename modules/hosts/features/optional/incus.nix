# Incus (the LXD fork) for full OS containers - a real init + userspace, as
# opposed to podman's single-process containers.
#
# On oci this exists to host a Debian userspace for software that only ships
# .deb packages and insists on owning systemd: CubeCoders AMP's `ampinstmgr`
# writes one systemd unit per game-server instance, so it needs systemd as PID
# 1 and a writable /etc/systemd/system. That rules out running it on NixOS
# directly (even via buildFHSEnv - /etc/systemd/system is read-only) and rules
# out Docker/Podman, which don't provide a real init.
#
# Incus asserts hard against the iptables firewall backend upstream, so any
# host importing this must be on nftables. oci already sets
# `networking.firewall.backend = "nftables"`; the assertion fires loudly rather
# than misbehaving quietly if that ever changes, so it is not forced here -
# flipping a host's whole firewall backend from a feature module would be a
# far bigger side effect than the feature itself.
{
  flake.nixosModules.optionalIncus = {
    key = "mynix#nixosModules.optionalIncus";

    virtualisation.incus = {
      enable = true;

      # Re-applied by incus-preseed.service on every activation, so a fresh (or
      # wiped) /var/lib/incus comes back fully initialised instead of needing a
      # manual `incus admin init`. Preseed creates and overwrites entities but
      # never deletes them, so it is safe to re-run.
      preseed = {
        storage_pools = [
          {
            name = "default";
            # `dir` rather than the btrfs driver: the root filesystem is
            # already btrfs, so container data still gets CoW/compression, and
            # `dir` avoids incus wanting to own a subvolume of its own.
            driver = "dir";
            config.source = "/var/lib/incus/storage-pools/default";
          }
        ];

        networks = [
          {
            name = "incusbr0";
            type = "bridge";
            config = {
              # 10.108/24 stays clear of podman's default 10.88/16 and of
              # tailscale's 100.64/10.
              "ipv4.address" = "10.108.0.1/24";
              "ipv4.nat" = "true";
              # oci's upstream is IPv4-only NAT; a ULA on the bridge would just
              # add route noise and give containers unreachable AAAA records.
              "ipv6.address" = "none";
            };
          }
        ];

        profiles = [
          {
            name = "default";
            devices = {
              eth0 = {
                name = "eth0";
                network = "incusbr0";
                type = "nic";
              };
              root = {
                path = "/";
                pool = "default";
                type = "disk";
              };
            };
          }
        ];
      };
    };

    # incus runs dnsmasq on the bridge to serve DHCP + DNS to containers; the
    # host firewall drops both without this.
    networking.firewall.trustedInterfaces = ["incusbr0"];

    # Container rootfs, images and the incus database all live here - without
    # this the ephemeral root wipes every container on reboot.
    environment.persistence = {
      "/persist".directories = ["/var/lib/incus"];
    };
  };
}
