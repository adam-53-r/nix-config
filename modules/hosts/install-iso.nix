# Bootable install-media ISO. Not a real host (no nixosConfigurations entry,
# no persistence/disko/secrets) — just the stock nixpkgs installer profile
# plus an ssh key, enough to bootstrap a real install (nixos-anywhere, or
# `nixos-install` by hand).
#
# Built as a plain nixosSystem importing nixpkgs' own
# installer/cd-dvd/installation-cd-base.nix, same as every other host in
# hosts/default.nix — no nixos-generators needed, its formats (including
# install-iso) were upstreamed into nixpkgs itself.
#
# `hardware.enableAllHardware`, `networking.networkmanager.enable` and
# `services.openssh.enable` (with `PermitRootLogin = "yes"`) all already come
# from that profile, so they're not repeated here.
{inputs, ...}: {
  perSystem = {
    lib,
    system,
    ...
  }:
    lib.optionalAttrs (lib.hasSuffix "linux" system) {
      packages.install-iso = let
        sshKeys = lib.splitString "\n" (builtins.readFile ../home/adamr/ssh.pub);
        # Same well-known hash on both accounts: install media has nothing to
        # protect, this just beats an unauthenticated passwordless login over
        # ssh (nixpkgs' installer profile defaults nixos/root to no password
        # at all, only fine for local console access).
        installerPasswordHash = "$y$j9T$tRAkzHi9kpFVhiUg21FIQ0$mkHVaqB1A/Seq4NfGnZaBswCQNWQ/8FWPrVKR5Qo7zD";
      in
        (inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            "${toString inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-base.nix"
            {
              users.users.nixos = {
                initialHashedPassword = lib.mkForce installerPasswordHash;
                openssh.authorizedKeys.keys = sshKeys;
              };
              users.users.root = {
                initialHashedPassword = lib.mkForce installerPasswordHash;
                openssh.authorizedKeys.keys = sshKeys;
              };
              programs.fish.enable = true;
              # Lets sudo on the installer authenticate against a forwarded
              # ssh-agent key instead of the shared password.
              security.pam.sshAgentAuth.enable = true;
            }
          ];
        })
        .config
        .system
        .build
        .isoImage;
    };
}
