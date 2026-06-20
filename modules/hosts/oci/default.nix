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
      # opt-in persistence, node-exporter, home-manager, ...), 
      self.nixosModules.globalDefaults

      # Optional server features that make sense on an internet-facing VM.
      self.nixosModules.optionalNginx
      self.nixosModules.optionalFail2ban
    ];

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
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPvzQgNgw4EvEdpACjxlxKAJJl2sa8bvohMkh4mKUqja cardno:31_859_120"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgSs2wJGphaoUPS+VAu0QTJfvQ1P99AIYSc94V9WIEV cardno:30_548_977"
      ];
    };
    users.users.root = {
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPvzQgNgw4EvEdpACjxlxKAJJl2sa8bvohMkh4mKUqja cardno:31_859_120"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgSs2wJGphaoUPS+VAu0QTJfvQ1P99AIYSc94V9WIEV cardno:30_548_977"
      ];
    };

    system.stateVersion = "26.05";
  };
}
