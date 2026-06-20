# Opt-in persistence via impermanence, shared by every host.
# Ported from msi-server `common/global/optin-persistence.nix`. This defines the
# non-hardware part of persistence: it imports impermanence, lists the baseline
# state dirs to keep, and ensures each user's /persist home exists with correct
# ownership. It pairs with the ephemeral btrfs root rollback already configured
# for the OCI host (hardware.disko-btrfs.ephemeral = true).
{...}: {
  flake.nixosModules.globalPersistence = {
    lib,
    inputs,
    config,
    pkgs,
    ...
  }: {
    imports = [inputs.impermanence.nixosModules.impermanence];

    environment.persistence = {
      "/persist" = {
        files = [
          "/etc/machine-id"
        ];
        directories = [
          "/var/lib/systemd"
          "/var/lib/nixos"
          "/var/log"
          "/srv"
        ];
      };
    };

    programs.fuse.userAllowOther = true;

    environment.systemPackages = [
      pkgs.fuse
    ];

    system.activationScripts.persistent-dirs.text = let
      mkHomePersist = user:
        lib.optionalString user.createHome ''
          mkdir -p /persist/${user.home}
          chown ${user.name}:${user.group} /persist/${user.home}
          chmod ${user.homeMode} /persist/${user.home}
        '';
      users = lib.attrValues config.users.users;
    in
      lib.concatLines (map mkHomePersist users);
  };
}
