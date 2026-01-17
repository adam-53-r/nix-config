{
  pkgs,
  config,
  ...
}: {
  imports = [
    # ./alacritty.nix
    ./ghostty.nix
    ./deluge.nix
    ./discord.nix
    ./dragon.nix
    ./firefox.nix
    ./font.nix
    ./gtk.nix
    ./kdeconnect.nix
    ./pavucontrol.nix
    ./playerctl.nix
    ./qt.nix
    ./sublime-music.nix
    ./anydesk.nix
    ./audacity.nix
    ./bitwarden.nix
    ./blender.nix
    # ./brave.nix
    ./burpsuite.nix
    ./chromium.nix
    ./drawio.nix
    ./emote.nix
    # ./firefox-devedition.nix
    ./ghidra.nix
    ./gimp.nix
    ./gns3.nix
    ./vmware.nix
    ./godot.nix
    ./gparted.nix
    ./jetbrains.nix
    ./libreoffice.nix
    ./obsidian.nix
    ./pokemmo-installer.nix
    ./postman.nix
    ./qbittorrent.nix
    ./remmina.nix
    # ./rustdesk.nix
    ./teamviewer.nix
    ./vlc.nix
    ./vscodium.nix
    ./winbox.nix
    ./virtualbox.nix
    ./spotify.nix
    ./telegram.nix
    ./thunderbird.nix
    ./restic-browser.nix
  ];

  home.packages = [
    pkgs.libnotify
    pkgs.handlr-regex
    (pkgs.writeShellScriptBin "xterm" ''
      handlr launch x-scheme-handler/terminal -- "$@"
    '')
    (pkgs.writeShellScriptBin "xdg-open" ''
      handlr open "$@"
    '')
    pkgs.yubioath-flutter
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

  # Persisting wirepluber state so I dont have to change the default audio devices
  # on each boot.
  home.persistence."/persist".directories = [
    ".local/state/wireplumber"
  ];
}
