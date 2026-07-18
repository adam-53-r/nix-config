# The wsl host: NixOS inside Windows WSL2 (work/interop shell). No disk,
# bootloader or persistence concerns — WSL owns the kernel and rootfs.
{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.wslConfiguration = {
    pkgs,
    lib,
    ...
  }: {
    key = "mynix#nixosModules.wslConfiguration";

    imports = [
      inputs.nixos-wsl.nixosModules.default

      self.nixosModules.globalDefaults
      self.nixosModules.userAdamr
    ];

    wsl = {
      enable = true;
      defaultUser = "adamr";
      interop.includePath = false;
      # binfmt registrations (aarch64/i686 below) unregister WSL's own .exe
      # handler unless it is explicitly re-registered.
      interop.register = true;
    };

    # No secrets file for this host.
    disable-user-sops = true;

    networking.hostName = "wsl";

    # android-tools replaces main's programs.adb, removed from nixpkgs
    # (systemd handles the uaccess rules now).
    environment.systemPackages = [pkgs.hostctl pkgs.android-tools];
    environment.etc.hosts.mode = "0644";

    boot = {
      kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_latest;
      binfmt.emulatedSystems = [
        "aarch64-linux"
        "i686-linux"
      ];
    };

    programs.dconf.enable = true;

    # The tailnet binary cache is usually unreachable from this box; don't
    # stall builds trying (main cleared these in the home profile instead,
    # which never reached the daemon).
    nix.settings = {
      extra-substituters = lib.mkForce [];
      extra-trusted-public-keys = lib.mkForce [];
    };

    nixpkgs.hostPlatform.system = "x86_64-linux";
    system.stateVersion = "25.05";
  };
}
