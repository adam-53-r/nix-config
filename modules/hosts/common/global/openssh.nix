# Hardened OpenSSH defaults shared by every host.
# Ported from msi-server `common/global/openssh.nix`. The cross-host
# `knownHosts` map was dropped: it relied on per-host `ssh_host_*.pub` files
# committed under each host dir, which the dendritic layout does not have.
{...}: {
  flake.nixosModules.globalOpenssh = {
    lib,
    config,
    ...
  }: let
    # Sops needs access to the host key before /persist is mounted, so when
    # opt-in persistence is enabled we store the key directly under /persist.
    hasOptinPersistence = config.environment.persistence ? "/persist";
  in {
    services.openssh = {
      enable = true;
      settings = {
        # Harden: keys only, no root password login.
        PasswordAuthentication = false;
        PermitRootLogin = "prohibit-password";

        # Automatically remove stale sockets
        StreamLocalBindUnlink = "yes";
        # Allow forwarding ports to everywhere
        GatewayPorts = "clientspecified";
        AcceptEnv = ["WAYLAND_DISPLAY"];
        X11Forwarding = true;
      };

      hostKeys = [
        {
          path = "${lib.optionalString hasOptinPersistence "/persist"}/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];
    };

    # Passwordless sudo when SSH'ing with keys.
    security.pam.sshAgentAuth = {
      enable = true;
      authorizedKeysFiles = ["/etc/ssh/authorized_keys.d/%u"];
    };
  };
}
