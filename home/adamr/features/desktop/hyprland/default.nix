{
  lib,
  config,
  pkgs,
  outputs,
  ...
}: let
  getHostname = x: lib.last (lib.splitString "@" x);
  # remoteColorschemes =
  #   lib.mapAttrs' (n: v: {
  #     name = getHostname n;
  #     value = v.config.colorscheme.rawColorscheme.colors.${config.colorscheme.mode};
  #   })
  #   outputs.homeConfigurations;
  # rgb = color: "rgb(${lib.removePrefix "#" color})";
  # rgba = color: alpha: "rgba(${lib.removePrefix "#" color}${alpha})";
  mainMod = "SUPER";
  terminal = "alacritty";
  menu = "wofi --show drun";
in {
  imports = [
    ../common
    ../common/wayland-wm
    # ./basic-binds.nix
    # ./hyprbars.nix
  ];

  xdg.portal = {
    extraPortals = [pkgs.xdg-desktop-portal-wlr];
    config.hyprland = {
      default = ["wlr" "gtk"];
    };
  };

  home.packages = with pkgs; [
    grimblast
    hyprpicker
  ];

  services.hyprpolkitagent.enable = true;
  
  wayland.windowManager.hyprland = {
    enable = true;
    # package = pkgs.hyprland.override {wrapRuntimeDeps = false;};
    package = pkgs.hyprland;
    systemd = {
      enable = false;
      # Same as default, but stop graphical-session too
      extraCommands = lib.mkBefore [
        "systemctl --user stop graphical-session.target"
        "systemctl --user start hyprland-session.target"
      ];
    };

    settings = {
      # "debug:disable_logs" = false;

      monitor = [
        "eDP-1,1920x1080@144,0x0,1"
        "DP-2,1920x1080@144,1920x0,1"
      ];

      env = [
        "AQ_DRM_DEVICES,/dev/dri/card0:/dev/dri/card1"
        "LIBVA_DRIVER_NAME,nvidia"
        "__GLX_VENDOR_LIBRARY_NAME,nvidia"
        "NVD_BACKEND,direct"
        "XCURSOR_SIZE,14"
        "HYPRCURSOR_SIZE,14"
      ];

      
      bind = [
        "${mainMod}, Q, exec, ${terminal}"
        "${mainMod}, R, exec, ${menu}"
        "${mainMod}, T, togglegroup,"
        "${mainMod}, C, killactive,"
        "${mainMod}, M, exit,"
        "${mainMod}, V, togglefloating,"
        "${mainMod}, P, pseudo, # dwindle"
        "${mainMod}, f, fullscreen, 0"
        "${mainMod} SHIFT, F, fullscreen, 1"
        # "${mainMod}, J, togglesplit, # dwindle"
        "SUPER+ALT, k, changegroupactive, f"
        "SUPER+ALT, j, changegroupactive, b"

        # Move window with {mainMod} + motion keys
        "${mainMod}, h, movefocus, l"
        "${mainMod}, l, movefocus, r"
        "${mainMod}, k, movefocus, u"
        "${mainMod}, j, movefocus, d"

        # Move window with {mainMod} + motion keys
        "${mainMod} SHIFT, h, movewindoworgroup, l"
        "${mainMod} SHIFT, l, movewindoworgroup, r"
        "${mainMod} SHIFT, k, movewindoworgroup, u"
        "${mainMod} SHIFT, j, movewindoworgroup, d"

        # Move focus with {mainMod} + arrow keys
        # "${mainMod}, left, movefocus, l"
        # "${mainMod}, right, movefocus, r"
        # "${mainMod}, up, movefocus, u"
        # "${mainMod}, down, movefocus, d"

        # Switch workspaces with {mainMod} + [0-9]
        "${mainMod}, 1, workspace, 1"
        "${mainMod}, 2, workspace, 2"
        "${mainMod}, 3, workspace, 3"
        "${mainMod}, 4, workspace, 4"
        "${mainMod}, 5, workspace, 5"
        "${mainMod}, 6, workspace, 6"
        "${mainMod}, 7, workspace, 7"
        "${mainMod}, 8, workspace, 8"
        "${mainMod}, 9, workspace, 9"
        "${mainMod}, 0, workspace, 10"

        # Move active window to a workspace with {mainMod} + SHIFT + [0-9]
        "${mainMod} SHIFT, 1, movetoworkspace, 1"
        "${mainMod} SHIFT, 2, movetoworkspace, 2"
        "${mainMod} SHIFT, 3, movetoworkspace, 3"
        "${mainMod} SHIFT, 4, movetoworkspace, 4"
        "${mainMod} SHIFT, 5, movetoworkspace, 5"
        "${mainMod} SHIFT, 6, movetoworkspace, 6"
        "${mainMod} SHIFT, 7, movetoworkspace, 7"
        "${mainMod} SHIFT, 8, movetoworkspace, 8"
        "${mainMod} SHIFT, 9, movetoworkspace, 9"
        "${mainMod} SHIFT, 0, movetoworkspace, 10"

        # Example special workspace (scratchpad)
        "${mainMod}, S, togglespecialworkspace, magic"
        "${mainMod} SHIFT, S, movetoworkspace, special:magic"

        # Scroll through existing workspaces with {mainMod} + scroll
        # "${mainMod}, mouse_down, workspace, e+1"
        # "${mainMod}, mouse_up, workspace, e-1"
      ];

        # Move/resize windows with mainMod + LMB/RMB and dragging
        bindm = [
          "${mainMod}, mouse:272, movewindow"
          "${mainMod}, mouse:273, resizewindow"
        ];

        # Laptop multimedia keys for volume and LCD brightness
        bindel = [
          ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
          ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
          ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
          ",XF86MonBrightnessUp, exec, ${pkgs.brightnessctl}/bin/brightnessctl s 10%+"
          ",XF86MonBrightnessDown, exec, ${pkgs.brightnessctl}/bin/brightnessctl s 10%-"
        ];

        # Requires playerctl
        bindl = [
          ", XF86AudioNext, exec, playerctl next"
          ", XF86AudioPause, exec, playerctl play-pause"
          ", XF86AudioPlay, exec, playerctl play-pause"
          ", XF86AudioPrev, exec, playerctl previous"
        ];
      
        windowrule = [
          # Ignore maximize requests from apps. You'll probably like this.
          "suppressevent maximize, class:.*"
          # Fix some dragging issues with XWayland
          "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
        ];

        
        general = {
            gaps_in = 5;
            gaps_out = 20;
            border_size = 2;
            # https://wiki.hyprland.org/Configuring/Variables/#variable-types for info about colors
            "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
            "col.inactive_border" = "rgba(595959aa)";
            # Set to true enable resizing windows by clicking and dragging on borders and gaps
            resize_on_border = false;
            # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
            allow_tearing = false;
            layout = "dwindle";
        };

        # https://wiki.hyprland.org/Configuring/Variables/#decoration
        decoration = {
            rounding = 10;
            rounding_power = 2;

            # Change transparency of focused and unfocused windows
            active_opacity = 1.0;
            inactive_opacity = 1.0;

            shadow = {
              enabled = true;
              range = 4;
              render_power = 3;
              color = "rgba(1a1a1aee)";
            };

            # https://wiki.hyprland.org/Configuring/Variables/#blur
            blur = {
              enabled = true;
              size = 3;
              passes = 1;
              vibrancy = 0.1696;
            };
        };

        # https://wiki.hyprland.org/Configuring/Variables/#animations
        animations = {
            enabled = "yes, please :)";

            # Default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more

            bezier = [
              "easeOutQuint,0.23,1,0.32,1"
              "easeInOutCubic,0.65,0.05,0.36,1"
              "linear,0,0,1,1"
              "almostLinear,0.5,0.5,0.75,1.0"
              "quick,0.15,0,0.1,1"
            ];

            animation = [
            "global, 1, 10, default"
            "border, 1, 5.39, easeOutQuint"
            "windows, 1, 4.79, easeOutQuint"
            "windowsIn, 1, 4.1, easeOutQuint, popin 87%"
            "windowsOut, 1, 1.49, linear, popin 87%"
            "fadeIn, 1, 1.73, almostLinear"
            "fadeOut, 1, 1.46, almostLinear"
            "fade, 1, 3.03, quick"
            "layers, 1, 3.81, easeOutQuint"
            "layersIn, 1, 4, easeOutQuint, fade"
            "layersOut, 1, 1.5, linear, fade"
            "fadeLayersIn, 1, 1.79, almostLinear"
            "fadeLayersOut, 1, 1.39, almostLinear"
            "workspaces, 1, 1.94, almostLinear, fade"
            "workspacesIn, 1, 1.21, almostLinear, fade"
            "workspacesOut, 1, 1.94, almostLinear, fade"
            ];
        };

        # Ref https://wiki.hyprland.org/Configuring/Workspace-Rules/
        # "Smart gaps" / "No gaps when only"
        # uncomment all if you wish to use that.
        # workspace = w[tv1], gapsout:0, gapsin:0
        # workspace = f[1], gapsout:0, gapsin:0
        # windowrule = bordersize 0, floating:0, onworkspace:w[tv1]
        # windowrule = rounding 0, floating:0, onworkspace:w[tv1]
        # windowrule = bordersize 0, floating:0, onworkspace:f[1]
        # windowrule = rounding 0, floating:0, onworkspace:f[1]

        # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
        dwindle = {
            pseudotile = true; # Master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
            preserve_split = true; # You probably want this
        };

        # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
        master = {
            new_status = "master";
        };

        # https://wiki.hyprland.org/Configuring/Variables/#misc
        misc = {
            force_default_wallpaper = -1; # Set to 0 or 1 to disable the anime mascot wallpapers
            disable_hyprland_logo = false; # If true disables the random hyprland logo / anime girl background. :(
        };


        #############
        ### INPUT ###
        #############

        # https://wiki.hyprland.org/Configuring/Variables/#input
        input = {
            kb_layout = "us";
            # kb_variant =
            # kb_model =
            # kb_options =
            # kb_rules =

            follow_mouse = 1;

            sensitivity = 0; # -1.0 - 1.0, 0 means no modification.

            touchpad = {
              natural_scroll = false;
            };
        };

        # https://wiki.hyprland.org/Configuring/Variables/#gestures
        gestures = {
            workspace_swipe = false;
        };

        # Example per-device config
        # See https://wiki.hyprland.org/Configuring/Keywords/#per-device-input-configs for more
        device = {
            name = "epic-mouse-v1";
            sensitivity = -0.5;
        };
        
        #### OLD CONFIG (WIP)
    #   general = {
    #     gaps_in = 15;
    #     gaps_out = 20;
    #     border_size = 2;
    #     "col.active_border" = rgba config.colorscheme.colors.primary "aa";
    #     "col.inactive_border" = rgba config.colorscheme.colors.surface "aa";
    #     # allow_tearing = true;
    #   };
    #   cursor.inactive_timeout = 4;
    #   group = {
    #     "col.border_active" = rgba config.colorscheme.colors.primary "aa";
    #     "col.border_inactive" = rgba config.colorscheme.colors.surface "aa";
    #     groupbar.font_size = 11;
    #   };
    #   binds = {
    #     movefocus_cycles_fullscreen = false;
    #   };
    #   input = {
    #     kb_layout = "br";
    #     touchpad.disable_while_typing = false;
    #   };
    #   device = [
    #     {
    #       name = "keychron-keychron-v3";
    #       kb_layout = "us_intl";
    #     }
    #     {
    #       name = "keychron-keychron-v3-keyboard";
    #       kb_layout = "us_intl";
    #     }
    #   ];
    #   dwindle = {
    #     split_width_multiplier = 1.35;
    #     pseudotile = true;
    #   };
    #   misc = {
    #     vfr = true;
    #     close_special_on_empty = true;
    #     focus_on_activate = true;
    #     # Unfullscreen when opening something
    #     new_window_takes_over_fullscreen = 2;
    #   };
    #   windowrulev2 = let
    #     sweethome3d-tooltips = "title:win[0-9],class:com-eteks-sweethome3d-SweetHome3DBootstrap";
    #     steamGame = "class:steam_app_[0-9]*";
    #     kdeconnect-pointer = "class:org.kdeconnect.daemon";
    #     wineTray ="class:explorer.exe";
    #     rsiLauncher ="class:rsi launcher.exe";
    #     steamBigPicture = "title:Steam Big Picture Mode";
    #   in
    #     [
    #       "nofocus, ${sweethome3d-tooltips}"

    #       "immediate, ${steamGame}"

    #       "size 100% 100%, ${kdeconnect-pointer}"
    #       "float, ${kdeconnect-pointer}"
    #       "nofocus, ${kdeconnect-pointer}"
    #       "noblur, ${kdeconnect-pointer}"
    #       "noanim, ${kdeconnect-pointer}"
    #       "noshadow, ${kdeconnect-pointer}"
    #       "noborder, ${kdeconnect-pointer}"
    #       "plugin:hyprbars:nobar, ${kdeconnect-pointer}"
    #       "suppressevent fullscreen, ${kdeconnect-pointer}"

    #       "workspace special silent, ${wineTray}"

    #       "tile, ${rsiLauncher}"

    #       "fullscreen, ${steamBigPicture}"
    #     ]
    #     ++ (lib.mapAttrsToList (
    #         name: colors: "bordercolor ${rgba colors.primary "aa"} ${rgba colors.primary_container "aa"}, title:\\[${name}\\].*"
    #       )
    #       remoteColorschemes);
    #   layerrule = [
    #     "animation fade,hyprpicker"
    #     "animation fade,selection"

    #     "animation fade,waybar"
    #     "blur,waybar"
    #     "ignorezero,waybar"

    #     "blur,notifications"
    #     "ignorezero,notifications"

    #     "blur,wofi"
    #     "ignorezero,wofi"

    #     "noanim,wallpaper"
    #   ];

    #   decoration = {
    #     active_opacity = 1.0;
    #     inactive_opacity = 0.85;
    #     fullscreen_opacity = 1.0;
    #     rounding = 7;
    #     blur = {
    #       enabled = true;
    #       size = 4;
    #       passes = 3;
    #       new_optimizations = true;
    #       ignore_opacity = true;
    #       popups = true;
    #     };
    #     shadow = {
    #       enabled = true;
    #       offset = "3 3";
    #       range = 12;
    #       color = "0x44000000";
    #       color_inactive = "0x66000000";
    #     };
    #   };
    #   animations = {
    #     enabled = true;
    #     bezier = [
    #       "easein,0.1, 0, 0.5, 0"
    #       "easeinback,0.35, 0, 0.95, -0.3"

    #       "easeout,0.5, 1, 0.9, 1"
    #       "easeoutback,0.35, 1.35, 0.65, 1"

    #       "easeinout,0.45, 0, 0.55, 1"
    #     ];

    #     animation = [
    #       "fadeIn,1,3,easeout"
    #       "fadeLayersIn,1,3,easeoutback"
    #       "layersIn,1,3,easeoutback,slide"
    #       "windowsIn,1,3,easeoutback,slide"

    #       "fadeLayersOut,1,3,easeinback"
    #       "fadeOut,1,3,easein"
    #       "layersOut,1,3,easeinback,slide"
    #       "windowsOut,1,3,easeinback,slide"

    #       "border,1,3,easeout"
    #       "fadeDim,1,3,easeinout"
    #       "fadeShadow,1,3,easeinout"
    #       "fadeSwitch,1,3,easeinout"
    #       "windowsMove,1,3,easeoutback"
    #       "workspaces,1,2.6,easeoutback,slide"
    #     ];
    #   };

    #   exec = [
    #     "${pkgs.swaybg}/bin/swaybg -i ${config.wallpaper} --mode fill"
    #     "hyprctl setcursor ${config.gtk.cursorTheme.name} ${toString config.gtk.cursorTheme.size}"
    #   ];

    #   bind = let
    #     grimblast = lib.getExe pkgs.grimblast;
    #     pactl = lib.getExe' pkgs.pulseaudio "pactl";
    #     defaultApp = type: "${lib.getExe pkgs.handlr-regex} launch ${type}";
    #     remote = lib.getExe (pkgs.writeShellScriptBin "remote" ''
    #       socket="$(basename "$(find ~/.ssh -name 'master-gabriel@*' | head -1 | cut -d ':' -f1)")"
    #       host="''${socket#master-}"
    #       ssh "$host" "$@"
    #     '');
    #   in
    #     [
    #       # Program bindings
    #       "SUPER,Return,exec,${defaultApp "x-scheme-handler/terminal"}"
    #       "SUPER,e,exec,${defaultApp "text/plain"}"
    #       "SUPER,b,exec,${defaultApp "x-scheme-handler/https"}"
    #       "SUPERALT,Return,exec,${remote} ${defaultApp "x-scheme-handler/terminal"}"
    #       "SUPERALT,e,exec,${remote} ${defaultApp "text/plain"}"
    #       "SUPERALT,b,exec,${remote} ${defaultApp "x-scheme-handler/https"}"
    #       # Brightness control (only works if the system has lightd)
    #       ",XF86MonBrightnessUp,exec,light -A 10"
    #       ",XF86MonBrightnessDown,exec,light -U 10"
    #       # Volume
    #       ",XF86AudioRaiseVolume,exec,${pactl} set-sink-volume @DEFAULT_SINK@ +5%"
    #       ",XF86AudioLowerVolume,exec,${pactl} set-sink-volume @DEFAULT_SINK@ -5%"
    #       ",XF86AudioMute,exec,${pactl} set-sink-mute @DEFAULT_SINK@ toggle"
    #       "SHIFT,XF86AudioRaiseVolume,exec,${pactl} set-source-volume @DEFAULT_SOURCE@ +5%"
    #       "SHIFT,XF86AudioLowerVolume,exec,${pactl} set-source-volume @DEFAULT_SOURCE@ -5%"
    #       "SHIFT,XF86AudioMute,exec,${pactl} set-source-mute @DEFAULT_SOURCE@ toggle"
    #       ",XF86AudioMicMute,exec,${pactl} set-source-mute @DEFAULT_SOURCE@ toggle"
    #       # Screenshotting
    #       ",Print,exec,${grimblast} --notify --freeze copy area"
    #       "SHIFT,Print,exec,${grimblast} --notify --freeze copy output"
    #     ]
    #     ++ (
    #       let
    #         playerctl = lib.getExe' config.services.playerctld.package "playerctl";
    #         playerctld = lib.getExe' config.services.playerctld.package "playerctld";
    #       in
    #         lib.optionals config.services.playerctld.enable [
    #           # Media control
    #           ",XF86AudioNext,exec,${playerctl} next"
    #           ",XF86AudioPrev,exec,${playerctl} previous"
    #           ",XF86AudioPlay,exec,${playerctl} play-pause"
    #           ",XF86AudioStop,exec,${playerctl} stop"
    #           "SHIFT,XF86AudioNext,exec,${playerctld} shift"
    #           "SHIFT,XF86AudioPrev,exec,${playerctld} unshift"
    #           "SHIFT,XF86AudioPlay,exec,systemctl --user restart playerctld"
    #         ]
    #     )
    #     ++
    #     # Screen lock
    #     (
    #       let
    #         swaylock = lib.getExe config.programs.swaylock.package;
    #       in
    #         lib.optionals config.programs.swaylock.enable [
    #           "SUPER,backspace,exec,${swaylock} -S --grace 2 --grace-no-mouse"
    #           "SUPER,XF86Calculator,exec,${swaylock} -S --grace 2 --grace-no-mouse"
    #         ]
    #     )
    #     ++
    #     # Notification manager
    #     (
    #       let
    #         makoctl = lib.getExe' config.services.mako.package "makoctl";
    #       in
    #         lib.optionals config.services.mako.enable [
    #           "SUPER,w,exec,${makoctl} dismiss"
    #           "SUPERSHIFT,w,exec,${makoctl} restore"
    #         ]
    #     )
    #     ++
    #     # Launcher
    #     (
    #       let
    #         wofi = lib.getExe config.programs.wofi.package;
    #       in
    #         lib.optionals config.programs.wofi.enable [
    #           "SUPER,x,exec,${wofi} -S drun -x 10 -y 10 -W 25% -H 60%"
    #           "SUPER,s,exec,specialisation $(specialisation | ${wofi} -S dmenu)"
    #           "SUPER,d,exec,${wofi} -S run"

    #           "SUPERALT,x,exec,${remote} ${wofi} -S drun -x 10 -y 10 -W 25% -H 60%"
    #           "SUPERALT,d,exec,${remote} ${wofi} -S run"
    #         ]
    #         ++ (
    #           let
    #             pass-wofi = lib.getExe (pkgs.pass-wofi.override {pass = config.programs.password-store.package;});
    #           in
    #             lib.optionals config.programs.password-store.enable [
    #               ",XF86Calculator,exec,${pass-wofi}"
    #               "SHIFT,XF86Calculator,exec,${pass-wofi} fill"

    #               "SUPER,semicolon,exec,${pass-wofi}"
    #               "SHIFTSUPER,semicolon,exec,${pass-wofi} fill"
    #             ]
    #         )
    #         ++ (
    #           let
    #             cliphist = lib.getExe config.services.cliphist.package;
    #           in
    #             lib.optionals config.services.cliphist.enable [
    #               ''SUPER,c,exec,selected=$(${cliphist} list | ${wofi} -S dmenu) && echo "$selected" | ${cliphist} decode | wl-copy''
    #             ]
    #         )
    #         ++ (
    #           let
    #             # Save to image and share it to device, if png; else share as text to clipboard.
    #             share-kdeconnect = lib.getExe (pkgs.writeShellScriptBin "kdeconnect-share" ''
    #               type="$(wl-paste -l | head -1)"
    #               device="$(kdeconnect-cli -a --id-only | head -1)"
    #               if [ "$type" == "image/png" ]; then
    #                 path="$(mktemp XXXXXXX.png)"
    #                 wl-paste > "$path"
    #                 output="$(kdeconnect-cli --share "$path" -d "$device")"
    #               else
    #                 output="$(kdeconnect-cli --share-text "$(wl-paste)" -d "$device")"
    #               fi
    #               notify-send -i kdeconnect "$output"
    #             '');
    #           in
    #             lib.optionals config.services.kdeconnect.enable [
    #               "SUPER,v,exec,${share-kdeconnect}"
    #             ]
    #         )
    #     );

    #   monitor = let
    #     waybarSpace = let
    #       inherit (config.wayland.windowManager.hyprland.settings.general) gaps_in gaps_out;
    #       inherit (config.programs.waybar.settings.primary) position height width;
    #       gap = gaps_out - gaps_in;
    #     in {
    #       top =
    #         if (position == "top")
    #         then height + gap
    #         else 0;
    #       bottom =
    #         if (position == "bottom")
    #         then height + gap
    #         else 0;
    #       left =
    #         if (position == "left")
    #         then width + gap
    #         else 0;
    #       right =
    #         if (position == "right")
    #         then width + gap
    #         else 0;
    #     };
    #   in
    #     [
    #       ",addreserved,${toString waybarSpace.top},${toString waybarSpace.bottom},${toString waybarSpace.left},${toString waybarSpace.right}"
    #     ]
    #     ++ (map (
    #       m: "${m.name},${
    #         if m.enabled
    #         then "${toString m.width}x${toString m.height}@${toString m.refreshRate},${m.position},1"
    #         else "disable"
    #       }"
    #     ) (config.monitors));

    #   workspace = map (m: "name:${m.workspace},monitor:${m.name}") (
    #     lib.filter (m: m.enabled && m.workspace != null) config.monitors
    #   );
    };

    # This is order sensitive, so it has to come here.
    # extraConfig = ''
    #   # Passthrough mode (e.g. for VNC)
    #   bind=SUPER,P,submap,passthrough
    #   submap=passthrough
    #   bind=SUPER,P,submap,reset
    #   submap=reset
    # '';
  };
}
