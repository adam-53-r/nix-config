# Receiving end of R1's traffic capture for the Security Onion VM. R1 copies
# every forwarded packet to us as TZSP (mangle action=sniff-tzsp, see
# ~/Adam/mikrotik/R1-60-capture.rsc); tzsp-span strips the encapsulation and
# sends the frames out of span-in, so they arrive on span0 as if it were a
# mirror port. The VM itself (Security Onion's own Oracle Linux ISO) is
# managed by hand with virt-install, like the other libvirt guests, and takes
# span0 as a macvtap passthrough NIC.
#
# Not a bridge: docker turns on bridge-nf-call-iptables globally, and the
# per-bridge nf_call_* flags can only add to that, never opt out. Every
# mirrored frame would go through the forward chain and its IP sanity checks.
{
  lib,
  pkgs,
  ...
}: let
  port = 37008;
  routerAddress = "192.168.2.1";
  vmDir = "/DATA/msi-server/libvirt/security-onion";

  tzspSpan = pkgs.writers.writePython3Bin "tzsp-span" {} (builtins.readFile ./tzsp-span.py);
in {
  systemd.services.span-veth = {
    description = "veth pair carrying R1's mirrored traffic to span0";
    wantedBy = ["multi-user.target"];
    before = ["libvirtd.service" "tzsp-span.service"];
    path = [pkgs.iproute2];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      if ! ip link show dev span0 >/dev/null 2>&1; then
        ip link add span-in type veth peer name span0
      fi
      for dev in span-in span0; do
        ip link set dev "$dev" addrgenmode none mtu 9000 up
      done
    '';
  };

  systemd.services.tzsp-span = {
    description = "Replay R1's TZSP capture stream onto span0";
    wantedBy = ["multi-user.target"];
    requires = ["span-veth.service"];
    after = ["span-veth.service"];
    serviceConfig = {
      ExecStart = "${lib.getExe tzspSpan} ${toString port} span-in";
      Restart = "always";
      DynamicUser = true;
      AmbientCapabilities = ["CAP_NET_RAW"];
      CapabilityBoundingSet = ["CAP_NET_RAW"];
      PrivateDevices = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      RestrictAddressFamilies = ["AF_INET" "AF_PACKET"];
    };
  };

  # Room for tzsp-span's socket buffer to absorb bursts.
  boot.kernel.sysctl."net.core.rmem_max" = 16 * 1024 * 1024;

  networking.firewall.extraInputRules = ''
    iifname "br-servers-vlan" ip saddr ${routerAddress} udp dport ${toString port} accept
  '';

  # Own subvolume so the hourly /DATA snapper snapshots don't pin every
  # rewrite of the VM's Elasticsearch disk, and nocow for the image.
  systemd.tmpfiles.rules = [
    "v ${vmDir} 0711 root root -"
    "h ${vmDir} - - - - +C"
  ];
}
