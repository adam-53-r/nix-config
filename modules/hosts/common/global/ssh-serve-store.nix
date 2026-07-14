# Serve this host's nix store over SSH (nix-serve style, via nix.sshServe),
# so other hosts (e.g. msi-server) can substitute/remote-build against it.
# Shared by every host, like on main; keys match userAdamr's authorized_keys.
{...}: {
  flake.nixosModules.globalSshServe = {...}: {
    key = "mynix#nixosModules.globalSshServe";
    nix = {
      sshServe = {
        enable = true;
        keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPvzQgNgw4EvEdpACjxlxKAJJl2sa8bvohMkh4mKUqja cardno:31_859_120"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgSs2wJGphaoUPS+VAu0QTJfvQ1P99AIYSc94V9WIEV cardno:30_548_977"
        ];
        protocol = "ssh";
        write = true;
      };
      settings.trusted-users = ["nix-ssh"];
    };
  };
}
