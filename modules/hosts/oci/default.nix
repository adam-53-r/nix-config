{
  self,
  inputs,
  ...
}: let
  # Must stay on the SAME nixpkgs generation as the rest of the flake (just a
  # different `system`), not nixpkgs-stable: for a cross-arch build (aarch64
  # target on an x86_64 host) disko force-overrides nixpkgs.hostPlatform on the
  # in-VM install config with this pkgs' stdenv.hostPlatform. Mixing that with
  # the main unstable-based module tree causes infinite recursion.
  #
  # Separately, disko passes `pkgs.aggregateModules [...]` (a `buildEnv`
  # symlink-merge of the kernel + module derivations, named "kernel-modules")
  # as vmTools' `kernel` argument. Since nixpkgs-unstable's vmTools computes the
  # boot image filename from `kernel.target`, and buildEnv outputs don't carry
  # that attribute, it throws. The real kernel image is still reachable at the
  # merged output's root (buildEnv preserves the underlying kernel's files), so
  # we just need to tell vmTools the filename explicitly to skip that lookup.
  x86Pkgs = import inputs.nixpkgs {
    system = "x86_64-linux";
    overlays = [
      (final: prev: {
        vmTools = prev.vmTools.override {
          kernelImage = prev.linuxPackages.kernel.target;
        };
      })
    ];
  };
in {
  flake.nixosModules.ociConfiguration = {
    pkgs,
    lib,
    ...
  }: {
    key = "mynix#nixosModules.ociConfiguration";
    imports = [
      self.nixosModules.diskoBtrfs
      self.nixosModules.ociRuntime

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

      # Hytale dedicated server.
      self.nixosModules.ociHytale

      ./_hardware.nix
    ];

    _module.args.ociX86Pkgs = x86Pkgs;

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
