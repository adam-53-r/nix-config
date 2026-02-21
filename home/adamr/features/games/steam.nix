{
  pkgs,
  lib,
  config,
  ...
}: let
  # Fixing steam desktop entry to work with AMD GPU
  steam-unwrapped-without-DRI = pkgs.steam-unwrapped.overrideAttrs (old: {
    postInstall =
      ''
        substituteInPlace steam.desktop --replace-fail "steam %U" "env -u DRI_PRIME steam %U"
      ''
      + old.postInstall;
  });
  steam-with-pkgs = pkgs.steam.override {
    steam-unwrapped = steam-unwrapped-without-DRI;
    extraPkgs = pkgs:
      with pkgs; [
        xorg.libXcursor
        xorg.libXi
        xorg.libXinerama
        xorg.libXScrnSaver
        libpng
        libpulseaudio
        libvorbis
        stdenv.cc.cc.lib
        libkrb5
        keyutils
        gamescope
      ];
  };

  monitor = lib.head (lib.filter (m: m.primary) config.monitors);
  steam-session = let
    gamescope = lib.concatStringsSep " " [
      (lib.getExe pkgs.gamescope)
      "--output-width ${toString monitor.width}"
      "--output-height ${toString monitor.height}"
      "--framerate-limit ${toString monitor.refreshRate}"
      "--prefer-output ${monitor.name}"
      "--adaptive-sync"
      "--expose-wayland"
      "--hdr-enabled"
      "--steam"
    ];
    steam = lib.concatStringsSep " " [
      "steam"
      "steam://open/bigpicture"
    ];
  in
    pkgs.writeTextDir "share/wayland-sessions/steam-session.desktop" # ini

    ''
      [Desktop Entry]
      Name=Steam Session
      Exec=${gamescope} -- ${steam}
      Type=Application
    '';
in {
  home.packages = [
    steam-with-pkgs
    steam-session
    pkgs.gamescope
    pkgs.protontricks
  ];

  home.persistence = {
    "/persist" = {
      directories = [
        {
          directory = ".factorio";
        }
        {
          directory = ".steam";
        }
        {
          directory = ".local/share/Steam";
        }
      ];
    };
  };
}
