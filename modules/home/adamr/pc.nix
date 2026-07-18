# Per-host home profile: adamr on the pc desktop (hyprland + cinnamon
# fallback, games, monitor layout, wallpaper).
{self, ...}: {
  flake.homeModules."adamr@pc" = {pkgs, ...}: {
    imports = [
      self.homeModules.adamrHome
      self.homeModules.cliWorkstation

      self.homeModules.homeHyprland
      self.homeModules.homeCinnamon
      self.homeModules.homeWayvnc
      self.homeModules.homeTheming
      self.homeModules.homeGames
      self.homeModules.homeProductivity
      self.homeModules.homePass
      self.homeModules.homeHelix
    ];

    # Ephemeral root → keep the colocated stateful dirs across reboots.
    myPersistence.enable = true;

    # Red
    wallpaper = pkgs.inputs.themes.wallpapers.berserk-blood-moon;

    # Host-local ssh tweaks live outside the store.
    programs.ssh.includes = ["local.conf"];

    monitors = [
      {
        name = "HDMI-A-1";
        width = 1920;
        height = 1080;
        workspace = "1";
        position = "0x0";
        refreshRate = 120;
      }
      {
        name = "DP-3";
        width = 2560;
        height = 1440;
        workspace = "2";
        position = "auto-right";
        primary = true;
        refreshRate = 180;
      }
    ];

    home.persistence."/persist".directories = [
      ".config/Yubico"
      ".var" # flatpak app data
    ];

    dconf.settings = {
      "org/virt-manager/virt-manager/connections" = {
        autoconnect = [
          "qemu:///system"
          "qemu+ssh://adamr@msi-server/system"
        ];
        uris = [
          "qemu:///system"
          "qemu+ssh://adamr@msi-server/system"
        ];
      };
    };
  };
}
