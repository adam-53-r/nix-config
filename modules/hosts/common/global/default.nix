# Aggregate of the global baseline applied to every host.
# Ported from msi-server `common/global/default.nix`: it pulls together all the
# individual global aspect modules and adds a few small cross-cutting settings.
#
# Desktop/laptop-only modules from the original (kdeconnect, upower,
# steam-hardware, gamemode, tpm, pass, keymap/xserver, networkmanager) are
# intentionally not ported here since this baseline targets a headless cloud VM.
{self, ...}: {
  flake.nixosModules.globalDefaults = {lib, ...}: {
    imports = [
      self.nixosModules.globalNix
      self.nixosModules.globalOpenssh
      self.nixosModules.globalFish
      self.nixosModules.globalNvim
      self.nixosModules.globalLocale
      self.nixosModules.globalTailscale
      self.nixosModules.globalAutoUpgrade
      self.nixosModules.globalPodman
      self.nixosModules.globalSops
      self.nixosModules.globalPersistence
      self.nixosModules.globalNodeExporter
      self.nixosModules.globalSwappiness
      self.nixosModules.globalSystemdInitrd
      self.nixosModules.globalNixLd
      self.nixosModules.globalMtr
      self.nixosModules.globalAcme
      self.nixosModules.globalHomeManager
    ];

    nixpkgs.config.allowUnfree = true;

    hardware.enableRedistributableFirmware = lib.mkDefault true;

    # Use the modern nftables firewall backend.
    networking.nftables.enable = true;

    # The tailnet domain, used for host name resolution.
    networking.domain = "tail6743b5.ts.net";

    # Increase the open file limit for members of the wheel group.
    security.pam.loginLimits = [
      {
        domain = "@wheel";
        item = "nofile";
        type = "soft";
        value = "524288";
      }
      {
        domain = "@wheel";
        item = "nofile";
        type = "hard";
        value = "1048576";
      }
    ];

    # Cleanup stuff pulled in by default that a server does not need.
    services.speechd.enable = lib.mkForce false;
  };
}
