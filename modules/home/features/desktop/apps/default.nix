# Aggregate of the graphical app set shared by every desktop session, plus the
# xdg plumbing (portals, mime handling via handlr) they rely on. Apps that are
# a bare package with no config live in the package list here; anything with
# settings or persistence gets its own module file.
{self, ...}: {
  flake.homeModules.homeDesktopCommon = {
    config,
    pkgs,
    ...
  }: {
    imports = [
      self.homeModules.homeGhostty
      self.homeModules.homeDiscord
      self.homeModules.homeFirefox
      self.homeModules.homeFont
      self.homeModules.homeGtk
      self.homeModules.homeQt
      self.homeModules.homeKdeconnect
      self.homeModules.homePlayerctl
      self.homeModules.homeBitwarden
      self.homeModules.homeDrawio
      self.homeModules.homeGns3
      self.homeModules.homeJetbrains
      self.homeModules.homeObsidian
      self.homeModules.homeRemmina
      self.homeModules.homeVmware
      self.homeModules.homeVscodium
      self.homeModules.homeWinbox
      self.homeModules.homeVirtualbox
      self.homeModules.homeSpotify
      self.homeModules.homeTelegram
      self.homeModules.homeThunderbird
    ];

    home.packages = with pkgs; [
      # xdg helpers
      libnotify
      handlr-regex
      (writeShellScriptBin "xterm" ''
        handlr launch x-scheme-handler/terminal -- "$@"
      '')
      (writeShellScriptBin "xdg-open" ''
        handlr open "$@"
      '')
      yubioath-flutter

      # Plain packages without config/persistence
      anydesk
      audacity
      blender
      burpsuite
      chromium
      deluge
      dragon-drop
      emote
      ghidra
      gimp
      godot_4
      gparted
      libreoffice
      pavucontrol
      pokemmo-installer
      postman
      qbittorrent
      restic
      restic-browser
      teamviewer
      vlc
    ];

    # Also sets org.freedesktop.appearance color-scheme
    dconf.settings."org/gnome/desktop/interface".color-scheme =
      if config.colorscheme.mode == "dark"
      then "prefer-dark"
      else if config.colorscheme.mode == "light"
      then "prefer-light"
      else "default";

    xdg.portal.enable = true;
    xdg.portal.config.common.default = "*";
    xdg.mimeApps.enable = true;

    # Persisting wireplumber state so I dont have to change the default audio
    # devices on each boot.
    home.persistence."/persist".directories = [
      ".local/state/wireplumber"
    ];
  };
}
