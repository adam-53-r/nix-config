{
  lib,
  config,
  pkgs,
  outputs,
  ...
}: let
  inherit (lib) mkIf;
  packageNames = map (p: p.pname or p.name or null) config.home.packages;
  hasPackage = name: lib.any (x: x == name) packageNames;
  # hasEza = hasPackage "eza";
  hasGhostty = config.programs.ghostty.enable;
  hasAlacritty = config.programs.alacritty.enable;
in {
  imports = [
    ../common
  ];

  dconf.settings = {
    # "org/gnome/desktop/interface".color-scheme = "prefer-dark";
    "org/cinnamon/desktop/applications/terminal" = {
      exec = "handlr launch x-scheme-handler/terminal";
      exec-arg = "--";
    };
    "org/cinnamon/desktop/interface" = {
      clock-show-seconds = false;
      cursor-blink-time = 1200;
      cursor-size = 19;
      cursor-theme = "Bibata-Modern-Classic";
      gtk-enable-primary-paste = false;
      gtk-theme = "Mint-Y-Dark-Aqua";
      icon-theme = "Mint-Y-Sand";
      text-scaling-factor = 1.0;
    };
    "org/cinnamon/desktop/media-handling" = {
      autorun-never = true;
    };
    "org/cinnamon/desktop/peripherals/mouse" = {
      accel-profile = "flat";
      double-click = 400;
      drag-threshold = 8;
      speed = 0.39;
    };
    "org/cinnamon/desktop/peripherals/touchpad".speed = 0.4159;
    "org/cinnamon/desktop/wm/preferences" = {
      mouse-button-modifier = "<Super>";
    };
    "org/cinnamon/desktop/session".idle-delay = lib.hm.gvariant.mkUint32 0;
    "org/cinnamon/theme".name = "Mint-Y-Dark-Aqua";
    "org/gnome/desktop/a11y/applications" = {
      screen-keyboard-enabled = false;
      screen-reader-enabled = false;
    };
    "org/nemo/preferences".show-hidden-files = true;
    "org/x/apps/portal".color-scheme = "prefer-dark";
    "org/gnome/libgnomekbd/keyboard".layouts = ["us" "es"];
    "org/gnome/libgnomekbd/keyboard".options = ["grp\tgrp:win_space_toggle"];
    "org/cinnamon/settings-daemon/plugins/power" = {
      sleep-display-ac = 0;
      sleep-display-battery = 0;
    };
    "org/cinnamon/desktop/peripherals/touchpad".send-events = "disabled-on-external-mouse";
    "org/cinnamon/muffin".tile-maximize = true;
    "org/cinnamon/desktop/keybindings" = {
      custom-list = ["custom0"];
    };
    "org/cinnamon/desktop/keybindings/custom-keybindings/custom0" = {
      name = "Launch Terminal";
      binding = ["<Primary><Alt>t"];
      command = "handlr launch x-scheme-handler/terminal";
    };
    "org/cinnamon/desktop/keybindings/wm" = {
      move-to-workspace-left = lib.gvariant.mkEmptyArray (lib.gvariant.type.string);
      move-to-workspace-right = lib.gvariant.mkEmptyArray (lib.gvariant.type.string);
      move-to-workspace-up = lib.gvariant.mkEmptyArray (lib.gvariant.type.string);
      move-to-workspace-down = lib.gvariant.mkEmptyArray (lib.gvariant.type.string);
    };
    "org/cinnamon/desktop/media-handling" = {
      automount = false;
      automount-open = false;
    };
    "org/nemo/preferences".detect-content = false;
  };

  xdg.mimeApps.defaultApplications = {
    "application/pdf" = ["xreader.desktop"];
  };
}
