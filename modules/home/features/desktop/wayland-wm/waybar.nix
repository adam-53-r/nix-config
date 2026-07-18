# Status bar. Ported from main minus the sway branches (hyprland only here)
# and the long-commented mail/calendar widgets; the player/minicava widgets
# keep their definitions so they can be toggled back into modules-left.
#
# main pulled hexToRGBString from the nix-colors input just for the bar
# background — inlined below instead of carrying the whole input.
{
  flake.homeModules.homeWaybar = {
    config,
    lib,
    pkgs,
    ...
  }: let
    gpgCmds = import ./_gpg-commands.nix {inherit pkgs config lib;};
    commonDeps = with pkgs; [coreutils gnugrep systemd];
    # Function to simplify making waybar outputs
    mkScript = {
      name ? "script",
      deps ? [],
      script ? "",
    }:
      lib.getExe (pkgs.writeShellApplication {
        inherit name;
        text = script;
        runtimeInputs = commonDeps ++ deps;
      });
    # Specialized for JSON outputs
    mkScriptJson = {
      name ? "script",
      deps ? [],
      script ? "",
      text ? "",
      tooltip ? "",
      alt ? "",
      class ? "",
      percentage ? "",
    }:
      mkScript {
        inherit name;
        deps = [pkgs.jq] ++ deps;
        script = ''
          ${script}
          jq -cn \
            --arg text "${text}" \
            --arg tooltip "${tooltip}" \
            --arg alt "${alt}" \
            --arg class "${class}" \
            --arg percentage "${percentage}" \
            '{text:$text,tooltip:$tooltip,alt:$alt,class:$class,percentage:$percentage}'
        '';
      };

    hyprlandCfg = config.wayland.windowManager.hyprland;
  in {
    systemd.user.services.waybar = {
      Unit = {
        # Let it try to start a few more times
        StartLimitBurst = 30;
        # Reload instead of restarting
        X-Restart-Triggers = lib.mkForce [];
        X-SwitchMethod = "reload";
      };
    };
    programs.waybar = {
      enable = true;
      package = pkgs.waybar;
      systemd.enable = true;
      settings = {
        primary = {
          exclusive = true;
          passthrough = false;
          height = 40;
          margin = "6";
          position = "top";
          modules-left =
            ["custom/menu"]
            ++ (lib.optionals hyprlandCfg.enable [
              "hyprland/workspaces"
              "hyprland/submap"
            ])
            ++ [
              # "custom/currentplayer"
              # "custom/player"
              # "custom/minicava"
            ];

          modules-center = [
            "cpu"
            # "custom/gpu"
            "memory"
            "clock"
          ];

          modules-right = [
            "tray"
            "custom/gpg-status"
            "network"
            "custom/rfkill"
            "pulseaudio"
            "battery"
            "custom/hostname"
          ];

          clock = {
            interval = 1;
            format = "{:%d/%m %H:%M:%S}";
            format-alt = "{:%Y-%m-%d %H:%M:%S %z}";
            on-click-left = "mode";
            tooltip-format = ''
              <big>{:%Y %B}</big>
              <tt><small>{calendar}</small></tt>'';
          };

          cpu = {
            format = "  {usage}%";
          };
          "custom/gpu" = {
            interval = 5;
            exec = mkScript {script = "cat /sys/class/drm/card*/device/gpu_busy_percent | head -1";};
            format = "󰒋  {}%";
          };
          memory = {
            format = "  {}%";
            interval = 5;
          };

          "pulseaudio" = {
            format = "{icon}{format_source}";
            format-bluetooth = "{icon} 󰂯{format_source}";
            format-source = "";
            format-source-muted = " 󰍭";
            format-icons = {
              default-muted = "󰸈";
              default = [
                "󰕿"
                "󰖀"
                "󰖀"
                "󰕾"
              ];
              headphone-muted = "󰟎";
              headphone = "󰋋";
              headset-muted = "󰋐";
              headset = "󰋎";
            };
            on-click = lib.getExe pkgs.pavucontrol;
          };
          idle_inhibitor = {
            format = "{icon}";
            format-icons = {
              activated = "󰒳";
              deactivated = "󰒲";
            };
          };
          battery = {
            bat = "BAT1";
            interval = 10;
            format-icons = [
              "󰁺"
              "󰁻"
              "󰁼"
              "󰁽"
              "󰁾"
              "󰁿"
              "󰂀"
              "󰂁"
              "󰂂"
              "󰁹"
            ];
            format = "{icon} {capacity}%";
            format-charging = "󰂄 {capacity}%";
            onclick = "";
          };
          network = {
            interval = 3;
            format-wifi = "   {essid}";
            format-ethernet = "󰈁 Connected";
            format-disconnected = "";
            tooltip-format = ''
              {ifname}
              {ipaddr}/{cidr}
              Up: {bandwidthUpBits}
              Down: {bandwidthDownBits}'';
          };
          "custom/menu" = {
            interval = 1;
            return-type = "json";
            exec = mkScriptJson {
              # hyprlandCfg.package is null (system owns the compositor), so
              # take hyprctl from nixpkgs — same rev as programs.hyprland.
              deps = lib.optional hyprlandCfg.enable pkgs.hyprland;
              text = "";
              tooltip = ''$(grep PRETTY_NAME /etc/os-release | cut -d '"' -f2)'';
              class = let
                isFullScreen =
                  if hyprlandCfg.enable
                  then "hyprctl activewindow -j | jq -e '.fullscreen' &>/dev/null"
                  else "false";
              in "$(if ${isFullScreen}; then echo fullscreen; fi)";
            };
          };
          "custom/hostname" = {
            exec = mkScript {
              script = ''
                echo "$USER@$HOSTNAME"
              '';
            };
            on-click = mkScript {
              script = ''
                systemctl --user restart waybar
              '';
            };
          };
          "custom/gpg-status" = {
            interval = 3;
            return-type = "json";
            exec = mkScriptJson {
              script = ''
                if ${gpgCmds.isUnlocked}; then
                  status="unlocked"
                  tooltip="GPG is unlocked"
                else
                  status="locked"
                  tooltip="GPG is locked"
                fi
              '';
              alt = "$status";
              tooltip = "$tooltip";
            };
            on-click = mkScript {script = ''if ${gpgCmds.isUnlocked}; then ${gpgCmds.lock}; else ${gpgCmds.unlock}; fi'';};
            format = "{icon}";
            format-icons = {
              locked = "󰌾";
              unlocked = "󰿆";
            };
          };
          "custom/currentplayer" = {
            interval = 2;
            return-type = "json";
            exec = mkScriptJson {
              deps = [pkgs.playerctl];
              script = ''
                all_players=$(playerctl -l 2>/dev/null)
                selected_player="$(playerctl status -f "{{playerName}}" 2>/dev/null || true)"
                clean_player="$(echo "$selected_player" | cut -d '.' -f1)"
              '';
              alt = "$clean_player";
              tooltip = "$all_players";
            };
            format = "{icon}{}";
            format-icons = {
              "" = " ";
              "Celluloid" = "󰎁 ";
              "spotify" = "󰓇 ";
              "ncspot" = "󰓇 ";
              "qutebrowser" = "󰖟 ";
              "firefox" = " ";
              "discord" = " 󰙯 ";
              "sublimemusic" = " ";
              "kdeconnect" = "󰄡 ";
              "chromium" = " ";
            };
          };
          "custom/player" = {
            exec-if = mkScript {
              deps = [pkgs.playerctl];
              script = ''
                selected_player="$(playerctl status -f "{{playerName}}" 2>/dev/null || true)"
                playerctl status -p "$selected_player" 2>/dev/null
              '';
            };
            exec = mkScript {
              deps = [pkgs.playerctl];
              script = ''
                selected_player="$(playerctl status -f "{{playerName}}" 2>/dev/null || true)"
                playerctl metadata -p "$selected_player" \
                  --format '{"text": "{{artist}} - {{title}}", "alt": "{{status}}", "tooltip": "{{artist}} - {{title}} ({{album}})"}' 2>/dev/null
              '';
            };
            return-type = "json";
            interval = 2;
            max-length = 30;
            format = "{icon} {}";
            format-icons = {
              "Playing" = "󰐊";
              "Paused" = "󰏤 ";
              "Stopped" = "󰓛";
            };
            on-click = mkScript {
              deps = [pkgs.playerctl];
              script = "playerctl play-pause";
            };
          };
          "custom/minicava" = {
            exec = mkScript {script = lib.getExe pkgs.minicava;};
            "restart-interval" = 5;
          };
          "custom/rfkill" = {
            interval = 1;
            exec-if = mkScript {
              deps = [pkgs.util-linux];
              script = "rfkill | grep '\<blocked\>'";
            };
          };
        };
      };
      # Cheatsheet:
      # x -> all sides
      # x y -> vertical, horizontal
      # x y z -> top, horizontal, bottom
      # w x y z -> top, right, bottom, left
      style = let
        inherit (config.colorscheme) colors;
        # hex -> decimal, for building CSS rgba() out of #rrggbb colors
        hexDigits = {
          "0" = 0;
          "1" = 1;
          "2" = 2;
          "3" = 3;
          "4" = 4;
          "5" = 5;
          "6" = 6;
          "7" = 7;
          "8" = 8;
          "9" = 9;
          "a" = 10;
          "b" = 11;
          "c" = 12;
          "d" = 13;
          "e" = 14;
          "f" = 15;
        };
        hexToDec = s:
          lib.foldl (acc: c: acc * 16 + hexDigits.${c}) 0
          (lib.stringToCharacters (lib.toLower s));
        toRGBA = color: opacity: let
          c = lib.removePrefix "#" color;
          channel = off: toString (hexToDec (builtins.substring off 2 c));
        in "rgba(${channel 0},${channel 2},${channel 4},${opacity})";
      in
        /*
        css
        */
        ''
          * {
            font-family: ${config.fontProfiles.regular.name}, ${config.fontProfiles.monospace.name};
            font-size: 12pt;
            padding: 0;
            margin: 0 0.4em;
          }

          window#waybar {
            padding: 0;
            border-radius: 0.5em;
            background-color: ${toRGBA colors.surface "0.7"};
            color: ${colors.on_surface};
          }
          .modules-left {
            margin-left: -0.65em;
          }
          .modules-right {
            margin-right: -0.65em;
          }

          #workspaces button {
            background-color: ${colors.surface};
            color: ${colors.on_surface};
            padding-left: 0.4em;
            padding-right: 0.4em;
            margin-top: 0.15em;
            margin-bottom: 0.15em;
          }
          #workspaces button.hidden {
            background-color: ${colors.surface};
            color: ${colors.on_surface_variant};
          }
          #workspaces button.focused,
          #workspaces button.active {
            background-color: ${colors.primary};
            color: ${colors.on_primary};
          }

          #clock {
            padding-right: 1em;
            padding-left: 1em;
            border-radius: 0.5em;
          }

          #custom-menu {
            background-color: ${colors.surface_container};
            color: ${colors.primary};
            padding-right: 1.5em;
            padding-left: 1em;
            margin-right: 0;
            border-radius: 0.5em;
          }
          #custom-menu.fullscreen {
            background-color: ${colors.primary};
            color: ${colors.on_primary};
          }
          #custom-hostname {
            background-color: ${colors.surface_container};
            color: ${colors.primary};
            padding-right: 1em;
            padding-left: 1em;
            margin-left: 0;
            border-radius: 0.5em;
          }
          #custom-currentplayer {
            padding-right: 0;
          }
          #tray {
            color: ${colors.on_surface};
          }
          #custom-gpu, #cpu, #memory {
            margin-left: 0.05em;
            margin-right: 0.55em;
          }
        '';
    };
  };
}
