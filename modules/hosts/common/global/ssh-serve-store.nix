# Serve this host's nix store over SSH (nix-serve style, via nix.sshServe),
# so other hosts (e.g. msi-server) can substitute/remote-build against it.
# Shared by every host; keys are pulled straight from the host's own openssh
# server config (userAdamr's authorized_keys) so the two never drift apart.
{...}: {
  flake.nixosModules.globalSshServe = {config, ...}: {
    key = "mynix#nixosModules.globalSshServe";
    nix = {
      sshServe = {
        enable = true;
        keys = config.users.users.adamr.openssh.authorizedKeys.keys;
        protocol = "ssh";
        write = true;
      };
      settings.trusted-users = ["nix-ssh"];
    };
  };
}
