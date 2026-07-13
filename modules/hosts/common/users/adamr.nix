# adamr's user account + per-host home-manager wiring, as an optional import
# (mirrors hosts/common/users/adamr on the main branch). Hosts that want adamr
# import self.nixosModules.userAdamr instead of declaring the account inline, so
# user-specific concerns (groups, password, ssh keys, home profile) live here
# rather than in each host file.
#
# The home profile is selected by hostname: a host named "oci" gets
# self.homeModules."adamr@oci". root reuses the identity-free cliBase so admin
# work in a root shell shares the tooling without adamr's signing key/gh auth.
{self, ...}: {
  flake.nixosModules.userAdamr = {
    pkgs,
    lib,
    config,
    ...
  }: let
    # Drop groups that don't exist on this host (server hosts lack many of the
    # desktop ones) so the account doesn't fail to build.
    ifTheyExist = groups:
      builtins.filter (g: builtins.hasAttr g config.users.groups) groups;

    sshKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPvzQgNgw4EvEdpACjxlxKAJJl2sa8bvohMkh4mKUqja cardno:31_859_120"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgSs2wJGphaoUPS+VAu0QTJfvQ1P99AIYSc94V9WIEV cardno:30_548_977"
    ];
  in {
    key = "mynix#nixosModules.userAdamr";
    # Per-host opt-out of sops-managed user passwords (hosts without a secrets
    # file set this true; mirrors main's `disable-user-sops`).
    options.disable-user-sops = lib.mkEnableOption "disabling sops-managed user passwords";

    config = {
      users.mutableUsers = false;

      users.users.adamr = {
        isNormalUser = true;
        group = "users";
        shell = pkgs.fish;
        # wheel: passwordless sudo + raised limits + nix trusted-user (baseline).
        extraGroups =
          ["wheel"]
          ++ ifTheyExist [
            "audio"
            "video"
            "render"
            "dialout"
            "plugdev"
            "tss"
            "network"
            "networkmanager"
            "podman"
            "docker"
            "libvirtd"
            "wireshark"
            "ubridge"
            "gns3"
          ];
        hashedPasswordFile =
          lib.mkIf (!config.disable-user-sops) config.sops.secrets.adamr-password.path;
        openssh.authorizedKeys.keys = sshKeys;
        packages = [pkgs.home-manager];
      };

      # Allow adamr to ssh in as root for deploy/automation.
      users.users.root.openssh.authorizedKeys.keys = sshKeys;

      sops.secrets = lib.mkIf (!config.disable-user-sops) {
        adamr-password = {
          # Create this secrets file (and unset disable-user-sops) to enable a
          # password login. Until then hosts keep disable-user-sops = true.
          sopsFile = ./secrets.json;
          neededForUsers = true;
        };
      };

      # Per-host home profile for adamr, plus the shared tooling base for root.
      home-manager.users.adamr =
        self.homeModules."adamr@${config.networking.hostName}";
      home-manager.users.root = self.homeModules.cliBase;
    };
  };
}
