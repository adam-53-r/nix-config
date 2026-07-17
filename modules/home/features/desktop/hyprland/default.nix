# Hyprland session config (HM side). The compositor + uwsm live in the
# system desktopHyprland module; this renders hyprland.conf, the binds and the
# session helpers, and pulls in the shared desktop app/wayland tooling.
{self, ...}: {
  flake.homeModules.homeHyprland = {
    lib,
    config,
    pkgs,
    ...
  }: let
    rgb = color: "rgb(${lib.removePrefix "#" color})";
    rgba = color: alpha: "rgba(${lib.removePrefix "#" color}${alpha})";
    swayosd = {
      brightness = "swayosd-client --brightness +0";
      output-volume = "swayosd-client --output-volume +0";
      input-volume = "swayosd-client --input-volume +0";
      caps-lock = "sleep 0.2 && swayosd-client --caps-lock";
    };
    grimblast = lib.getExe pkgs.grimblast;
    pactl = lib.getExe' pkgs.pulseaudio "pactl";
    defaultApp = type: "${lib.getExe pkgs.handlr-regex} launch ${type}";
    remote = lib.getExe (pkgs.writeShellScriptBin "remote" ''
      socket="$(basename "$(find ~/.ssh -name 'master-adamr@*' | head -1 | cut -d ':' -f1)")"
      host="''${socket#master-}"
      ssh "$host" "$@"
    '');
  in {
    imports = [
      self.homeModules.homeDesktopCommon
      self.homeModules.homeWaylandWm

      self.homeModules.homeHyprlandBinds
      self.homeModules.homeHypridle
      self.homeModules.homeHyprpaper
    ];

    home.pointerCursor.hyprcursor.enable = true;

    xdg.portal = {
      extraPortals = [pkgs.xdg-desktop-portal-wlr];
      config.hyprland = {
        default = ["wlr" "gtk"];
      };
    };

    home.packages = [
      pkgs.grimblast
      pkgs.hyprpicker
      pkgs.nemo
    ];

    xdg.mimeApps.associations.added = {
      "inode/directory" = "nemo.desktop";
    };

    wayland.windowManager.hyprland = {
      enable = true;
      # The compositor itself comes from the system (programs.hyprland +
      # uwsm); HM only renders the config. main wrapped its own package in
      # nixGL (a no-op on NixOS) which risked a hyprctl/compositor mismatch.
      package = null;
      # UWSM owns the session units; the disabled integration made the
      # extraCommands/variables on main dead config, so they were dropped.
      systemd.enable = false;
      # Since stateVersion 26.05 HM defaults to Hyprland's new Lua config
      # (hyprland.lua) — but it pastes extraConfig (conf syntax) into the Lua
      # file verbatim, breaking the submap block below. Stay on the classic
      # hyprlang renderer; moving to lua + the `submaps` option is a future
      # cleanup.
      configType = "hyprlang";
      importantPrefixes = [
        "$"
        "bezier"
        "name"
        "source"
        "exec-once"
      ];
      settings = {
        ecosystem = {
          no_update_news = true;
        };
        general = {
          gaps_in = 15;
          gaps_out = 20;
          border_size = 2;
          "col.active_border" = rgba config.colorscheme.colors.primary "ee";
          "col.inactive_border" = rgba config.colorscheme.colors.surface "aa";
          # allow_tearing = true;
        };
        cursor.inactive_timeout = 4;
        group = {
          "col.border_active" = rgba config.colorscheme.colors.primary "ee";
          "col.border_inactive" = rgba config.colorscheme.colors.surface "aa";
          groupbar.font_size = 11;
        };
        binds = {
          movefocus_cycles_fullscreen = false;
        };
        input = {
          accel_profile = "flat";
          sensitivity = 0.3;
          kb_layout = "us,es";
          kb_options = "grp:win_space_toggle";
          touchpad = {
            disable_while_typing = true;
            natural_scroll = true;
          };
        };
        device = [
          # {
          #   name = "keychron-keychron-v3";
          #   kb_layout = "us_intl";
          # }
          # {
          #   name = "keychron-keychron-v3-keyboard";
          #   kb_layout = "us_intl";
          # }
        ];
        # dwindle:pseudotile was removed with the 0.55 layout refactor (the
        # pseudo dispatcher still works without it).
        dwindle = {
          split_width_multiplier = 1.35;
        };
        # gestures = {
        #   workspace_swipe = true;
        #   workspace_swipe_min_speed_to_force = 10;
        #   workspace_swipe_forever = true;
        # };
        # vfr = true not carried over: it moved to debug:vfr in 0.55 and is
        # already the default.
        misc = {
          close_special_on_empty = true;
          focus_on_activate = true;
          # Unfullscreen when opening something
          on_focus_under_fullscreen = 2;
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          enable_swallow = true;
          swallow_regex = "(?i)(${lib.concatMapStringsSep "|" (lib.removeSuffix ".desktop") config.xdg.mimeApps.defaultApplications."x-scheme-handler/terminal"})";
        };
        windowrule = let
          steamGame = "match:class steam_app_[0-9]*";
          kdeconnect-pointer = "match:class org.kdeconnect.daemon";
          wineTray = "match:class explorer.exe";
          steamBigPicture = "match:title Steam Big Picture Mode";
          calculator = "match:class org.gnome.Calculator";
          nemo = "match:class nemo";
        in [
          "immediate on, ${steamGame}"
          "size 100% 100%, ${kdeconnect-pointer}"
          "float on, ${kdeconnect-pointer}"
          "no_focus on, ${kdeconnect-pointer}"
          "no_blur on, ${kdeconnect-pointer}"
          "no_anim on, ${kdeconnect-pointer}"
          "no_shadow on, ${kdeconnect-pointer}"
          "border_size 0, ${kdeconnect-pointer}"
          # "plugin:hyprbars:nobar, ${kdeconnect-pointer}"
          "suppress_event fullscreen, ${kdeconnect-pointer}"
          "workspace special silent, ${wineTray}"
          "fullscreen on, ${steamBigPicture}"
          "float on, ${calculator}"
          "move (monitor_w-window_w-10) (monitor_h-window_h-10), ${calculator}"
          "float on, ${nemo}"
          "size (monitor_w*0.5) (monitor_h*0.5), ${nemo}"
        ];

        layerrule = [
          "animation fade, match:namespace hyprpicker"
          "animation fade, match:namespace selection"
          "animation slide, match:namespace waybar"
          "blur on, match:namespace waybar"
          "ignore_alpha 0, match:namespace waybar"
          "blur on, match:namespace notifications"
          "ignore_alpha 0, match:namespace notifications"
          "blur on, match:namespace wofi"
          "ignore_alpha 0, match:namespace wofi"
          "no_anim on, match:namespace wallpaper"
          "above_lock 2, match:namespace swayosd"
        ];

        decoration = {
          active_opacity = 1.0;
          inactive_opacity = 0.95;
          fullscreen_opacity = 1.0;
          rounding = 7;
          blur = {
            enabled = false;
            size = 4;
            passes = 3;
            new_optimizations = true;
            ignore_opacity = true;
            popups = true;
          };
          shadow = {
            enabled = false;
            offset = "3 3";
            range = 12;
            color = "0x44000000";
            color_inactive = "0x66000000";
          };
        };
        animations = {
          enabled = true;
          bezier = [
            # "easein,0.1, 0, 0.5, 0"
            # "easeinback,0.35, 0, 0.95, -0.3"

            "easeout,0.5, 1, 0.9, 1"
            "easeoutback,0.34, 1.22, 0.65, 1"

            # "easeinout,0.45, 0, 0.55, 1"
          ];

          animation = [
            "fadeIn,1,3,easeout"
            "fadeLayersIn,1,3,easeout"
            "fadeLayersIn,1,3,easeout"
            "fadeOut,1,3,easeout"
            "fadeLayersOut,1,3,easeout"
            "fadeSwitch,1,2,easeout"
            "fadeDim,1,3,easeout"
            "fadeShadow,1,2,easeout"
            "border,1,2,easeout"
            "layersIn,1,3,easeoutback,slide"
            "layersOut,1,3,easeoutback,slide"

            "windowsOut,1,3,easeout,slide"
            "windowsMove,1,3,easeoutback"
            "windowsIn,1,3,easeoutback,slide"

            "workspaces,1,2.5,easeoutback,slidefade"
          ];
        };

        exec = [
          "hyprctl setcursor ${config.home.pointerCursor.name} ${toString config.home.pointerCursor.size}"
        ];

        # Will repeat when h[e]ld, also works when [l]ocked
        bindel = [
          # Brightness control
          ",XF86MonBrightnessUp,exec,${lib.getExe pkgs.brightnessctl} s +5%; ${swayosd.brightness}"
          ",XF86MonBrightnessDown,exec,${lib.getExe pkgs.brightnessctl} s 5%-; ${swayosd.brightness}"
          # Volume
          ",XF86AudioRaiseVolume,exec,${pactl} set-sink-volume @DEFAULT_SINK@ +5%; ${swayosd.output-volume}"
          ",XF86AudioLowerVolume,exec,${pactl} set-sink-volume @DEFAULT_SINK@ -5%; ${swayosd.output-volume}"
          "SHIFT,XF86AudioRaiseVolume,exec,${pactl} set-source-volume @DEFAULT_SOURCE@ +5%; ${swayosd.input-volume}"
          "SHIFT,XF86AudioLowerVolume,exec,${pactl} set-source-volume @DEFAULT_SOURCE@ -5%; ${swayosd.input-volume}"
        ];
        # Also works when [l]ocked
        bindl =
          [
            # Mute volume
            ",XF86AudioMute,exec,${pactl} set-sink-mute @DEFAULT_SINK@ toggle; ${swayosd.output-volume}"
            "SHIFT,XF86AudioMute,exec,${pactl} set-source-mute @DEFAULT_SOURCE@ toggle; ${swayosd.input-volume}"
            ",XF86AudioMicMute,exec,${pactl} set-source-mute @DEFAULT_SOURCE@ toggle; ${swayosd.input-volume}"
            # Show caps lock
            ",Caps_Lock,exec,${swayosd.caps-lock}"
          ]
          ++ (
            let
              playerctl = lib.getExe' config.services.playerctld.package "playerctl";
              playerctld = lib.getExe' config.services.playerctld.package "playerctld";
            in
              lib.optionals config.services.playerctld.enable [
                # Media control
                ",XF86AudioNext,exec,${playerctl} next"
                ",XF86AudioPrev,exec,${playerctl} previous"
                ",XF86AudioPlay,exec,${playerctl} play-pause"
                ",XF86AudioStop,exec,${playerctl} stop"
                "SHIFT,XF86AudioNext,exec,${playerctld} shift"
                "SHIFT,XF86AudioPrev,exec,${playerctld} unshift"
                "SHIFT,XF86AudioPlay,exec,systemctl --user restart playerctld"
              ]
            # )
          );
        # Normal bindings
        bind =
          [
            # Rename workspace
            "SUPER,r,exec,${pkgs.writeShellScript "rename" ''
              workspace="$(hyprctl activeworkspace -j)"
              id="$(jq -r .id <<< "$workspace")"
              prefix="$id - "
              name="$(jq -r .name <<< "$workspace")"
              name="''${name#"$prefix"}" # Remove prefix
              entry="$(GSK_RENDERER=cairo ${lib.getExe pkgs.zenity} --entry --title "Rename Workspace" --entry-text="$name")"
              if [ -z "$entry" ] || [ "$entry" == "$id" ]; then
                new_name="$id"
              else
                new_name="$prefix$entry"
              fi
              hyprctl dispatch renameworkspace "$id" "$new_name"
            ''}"
            # Program bindings
            "SUPER,Return,exec,${defaultApp "x-scheme-handler/terminal"}"
            "SUPER,e,exec,${defaultApp "text/plain"}"
            "SUPER,b,exec,${defaultApp "x-scheme-handler/https"}"
            "SUPERALT,Return,exec,${remote} ${defaultApp "x-scheme-handler/terminal"}"
            "SUPERALT,e,exec,${remote} ${defaultApp "text/plain"}"
            "SUPERALT,b,exec,${remote} ${defaultApp "x-scheme-handler/https"}"
            # Screenshotting
            ",Print,exec,${grimblast} --notify --freeze copy area"
            "SHIFT,Print,exec,${grimblast} --notify --freeze copy output"
          ]
          ++
          # Notification manager
          (
            let
              makoctl = lib.getExe' config.services.mako.package "makoctl";
            in
              lib.optionals config.services.mako.enable [
                "SUPER,w,exec,${makoctl} dismiss"
                "SUPERSHIFT,w,exec,${makoctl} restore"
              ]
          )
          ++
          # Launcher
          (
            let
              wofi = lib.getExe config.programs.wofi.package;
            in
              lib.optionals config.programs.wofi.enable [
                "SUPER,x,exec,${wofi} -S drun -x 10 -y 10 -W 25% -H 60%"
                "SUPER,s,exec,specialisation $(specialisation | ${wofi} -S dmenu)"
                "SUPER,d,exec,${wofi} -S run"

                "SUPERALT,x,exec,${remote} ${wofi} -S drun -x 10 -y 10 -W 25% -H 60%"
                "SUPERALT,d,exec,${remote} ${wofi} -S run"
              ]
              ++ (
                let
                  pass-wofi = lib.getExe (pkgs.pass-wofi.override {pass = config.programs.password-store.package;});
                in
                  lib.optionals config.programs.password-store.enable [
                    ",XF86Calculator,exec,${pass-wofi}"
                    "SHIFT,XF86Calculator,exec,${pass-wofi} fill"

                    "SUPER,semicolon,exec,${pass-wofi}"
                    "SHIFTSUPER,semicolon,exec,${pass-wofi} fill"
                  ]
              )
              ++ (
                let
                  cliphist = lib.getExe config.services.cliphist.package;
                in
                  lib.optionals config.services.cliphist.enable [
                    ''SUPER,c,exec,selected=$(${cliphist} list | ${wofi} -S dmenu) && echo "$selected" | ${cliphist} decode | wl-copy''
                  ]
              )
              ++ (
                let
                  # Save to image and share it to device, if png; else share as text to clipboard.
                  share-kdeconnect = lib.getExe (pkgs.writeShellScriptBin "kdeconnect-share" ''
                    type="$(wl-paste -l | head -1)"
                    device="$(kdeconnect-cli -a --id-only | head -1)"
                    if [ "$type" == "image/png" ]; then
                      path="$(mktemp XXXXXXX.png)"
                      wl-paste > "$path"
                      output="$(kdeconnect-cli --share "$path" -d "$device")"
                    else
                      output="$(kdeconnect-cli --share-text "$(wl-paste)" -d "$device")"
                    fi
                    notify-send -i kdeconnect "$output"
                  '');
                in
                  lib.optionals config.services.kdeconnect.enable [
                    "SUPER,v,exec,${share-kdeconnect}"
                  ]
              )
          )
          ++
          # Screen lock
          (
            let
              swaylock = lib.getExe config.programs.swaylock.package;
            in
              lib.optionals config.programs.swaylock.enable [
                "SUPER,backspace,exec,${swaylock} -S --grace 2 --grace-no-mouse"
                "SUPER,XF86Calculator,exec,${swaylock} -S --grace 2 --grace-no-mouse"
              ]
          );

        monitor = let
          waybarSpace = let
            inherit (config.wayland.windowManager.hyprland.settings.general) gaps_in gaps_out;
            inherit (config.programs.waybar.settings.primary) position height width;
            gap = gaps_out - gaps_in;
          in {
            top =
              if (position == "top")
              then height + gap
              else 0;
            bottom =
              if (position == "bottom")
              then height + gap
              else 0;
            left =
              if (position == "left")
              then width + gap
              else 0;
            right =
              if (position == "right")
              then width + gap
              else 0;
          };
        in
          [
            # ",addreserved,${toString waybarSpace.top},${toString waybarSpace.bottom},${toString waybarSpace.left},${toString waybarSpace.right}"
          ]
          ++ (map (
            m: "${m.name},${
              if m.enabled
              then "${toString m.width}x${toString m.height}@${toString m.refreshRate},${m.position},1"
              else "disable"
            }"
          ) (config.monitors));

        workspace = map (m: "${m.workspace},monitor:${m.name}") (
          lib.filter (m: m.enabled && m.workspace != null) config.monitors
        );
      };
      # This is order sensitive, so it has to come here.
      extraConfig = ''
            # Passthrough mode (e.g. for VNC)
            bind=SUPER,P,submap,passthrough
            submap=passthrough
            bind=SUPER,P,submap,reset
            submap=reset
        # '';
    };
  };
}
