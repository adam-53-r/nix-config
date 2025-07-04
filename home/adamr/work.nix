{lib, ...}: {
  imports = [
    ./global
    ./features/productivity
    ./features/pass
  ];
  home.persistence = lib.mkForce {};
  targets.genericLinux.enable = true;
  programs.git.includes = [{path = "local.conf";}];
  programs.ssh.includes = ["local.conf"];
  services.gpg-agent.enable = lib.mkForce false;
  nix = {
    settings = {
      extra-substituters = lib.mkForce [];
      extra-trusted-public-keys = lib.mkForce [];
    };
  };
}
/*
Add these lines to '/etc/nix/nix.conf':

extra-experimental-features = nix-command flakes ca-derivations
build-users-group = nixbld
trusted-users = root adamr
*/

