{
  lib,
  ...
}: {
  nix = {
    sshServe = {
      enable = true;
      keys = lib.splitString "\n" (builtins.readFile ../../../home/adamr/ssh.pub);
      protocol = "ssh";
      write = true;
    };
    settings.trusted-users = ["nix-ssh"];
  };
}
