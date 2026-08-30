# CubeCoders AMP game-server panel, running inside the `amp` incus container
# (see optionalIncus for why it needs a full Debian userspace).
#
# The container itself is still provisioned imperatively via CubeCoders' own
# installer - `USE_ANSWERS=1 ... curl -fsSL https://getamp.sh | bash` - because
# AMP owns its own state (instances, licence activation) and there is no
# meaningful way to declare that from nix. What IS declared here is the only
# part the host is responsible for: letting the tailnet reach it.
#
# AMP is reachable via incus `proxy` devices bound to oci's tailscale address
# rather than 0.0.0.0, so nothing is exposed publicly and no Oracle security
# list rule is needed:
#   incus config device add amp panel proxy \
#     listen=tcp:<tailscale-ip>:8080 connect=tcp:127.0.0.1:8080
#   incus config device add amp sftp proxy \
#     listen=tcp:<tailscale-ip>:2223 connect=tcp:127.0.0.1:2223
#
# Those devices only get the packets to the host - the host firewall still has
# to admit them on the tailscale interface, which is what this module does.
{
  flake.nixosModules.ociAmp = {config, ...}: {
    key = "mynix#nixosModules.ociAmp";

    networking.firewall.interfaces."${config.services.tailscale.interfaceName}" = {
      allowedTCPPorts = [
        # AMP / ADS web panel
        8080
        # AMP's built-in SFTP server, for managing instance files
        2223
        # Minecraft port
        25565
      ];
      allowedUDPPorts = [
        # Minecraft port
        25565
      ];
    };
  };
}
