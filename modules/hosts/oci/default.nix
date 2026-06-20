{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.ociConfiguration = {
    pkgs,
    lib,
    ...
  }: {
    imports = [
      self.nixosModules.ociHardware

      # Shared baseline (nix, ssh hardening, fish, tailscale, podman, sops,
      # opt-in persistence, node-exporter, home-manager, ...), ported from the
      # msi-server config and adapted for a headless cloud VM.
      self.nixosModules.globalDefaults

      # Optional server features that make sense on an internet-facing VM.
      self.nixosModules.optionalNginx
      self.nixosModules.optionalFail2ban
    ];

    # Hostname mirrors msi-server's explicit hostname. NOTE: the disko-btrfs
    # module derives its partition label (disk-main-oci) and the ephemeral
    # rollback device path from this value, so changing it requires rebuilding
    # the OCI image / reinstalling rather than a plain switch.
    networking.hostName = "oci";

    environment.systemPackages = with pkgs; [
      vim
      helix
    ];

    users.users.adamr = {
      isNormalUser = true;
      group = "users";
      # wheel: passwordless sudo (via ssh agent auth) + raised nofile limits +
      # nix trusted-user, all configured in the global baseline.
      extraGroups = ["wheel"];
      shell = pkgs.fish;
      initialPassword = "Admin1234";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPvzQgNgw4EvEdpACjxlxKAJJl2sa8bvohMkh4mKUqja cardno:31_859_120"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgSs2wJGphaoUPS+VAu0QTJfvQ1P99AIYSc94V9WIEV cardno:30_548_977"
      ];
    };
    users.users.root = {
      initialPassword = "Admin1234";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPvzQgNgw4EvEdpACjxlxKAJJl2sa8bvohMkh4mKUqja cardno:31_859_120"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgSs2wJGphaoUPS+VAu0QTJfvQ1P99AIYSc94V9WIEV cardno:30_548_977"
      ];
    };

    system.stateVersion = "26.05";
  };
}
