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

      # adamr account + per-host home-manager wiring (account/password/persist
      # live in the user module, not inline here).
      self.nixosModules.userAdamr

      # Optional server features that make sense on an internet-facing VM.
      self.nixosModules.optionalNginx
      self.nixosModules.optionalFail2ban

      # Minecraft Extremo 2 modpack server.
      self.nixosModules.ociMinecraft
    ];

    networking.hostName = "oci";

    # No sops-encrypted user password secret on this host yet; rely on ssh-key
    # login + passwordless wheel sudo. Flip this off once a secrets file exists.
    disable-user-sops = true;

    environment.systemPackages = with pkgs; [
      vim
      helix
    ];

    system.stateVersion = "26.05";
  };
}
