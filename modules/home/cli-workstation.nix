# Dev-workstation CLI layer on top of cliBase: everything main's
# home/adamr/features/cli/ carried that a headless server (oci, and root on
# any host) has no use for — embedded/infra tooling, profilers, a few extra
# shells/program configs, and xpo. Imported by adamr@pc only.
#
# The only package from main not carried over is the bare fzf package
# (programs.fzf in cliBase already installs it).
{self, ...}: {
  flake.homeModules.cliWorkstation = {
    pkgs,
    lib,
    config,
    ...
  }: {
    imports = [self.homeModules.homeXpo];

    # wsl runs Windows programs natively; main disabled its wine feature there.
    options.myWine.enable =
      lib.mkEnableOption "wine (32+64-bit WoW64) and winetricks" // {default = true;};

    config = {
      programs.xpo = {
        enable = true;
        defaultServer = "arm53.xyz";
      };

      programs.tmux.enable = true;

      # cliBase enables starship for fish; also hook it into nushell here.
      programs.starship.enableNushellIntegration = true;

      programs.nushell = {
        enable = true;
        extraConfig =
          /*
          nu
          */
          ''
            def create_left_prompt [] {
                let dir = match (do -i { $env.PWD | path relative-to $nu.home-path }) {
                    null => $env.PWD
                    ''' => '~'
                    $relative_pwd => ([~ $relative_pwd] | path join)
                }

                let path_color = (if (is-admin) { ansi red_bold } else { ansi green_bold })
                let separator_color = (if (is-admin) { ansi light_red_bold } else { ansi light_green_bold })
                let path_segment = $"($path_color)($dir)"

                $path_segment | str replace --all (char path_sep) $"($separator_color)(char path_sep)($path_color)"
            }

            def create_right_prompt [] {
                # create a right prompt in magenta with green separators and am/pm underlined
                let time_segment = ([
                    (ansi reset)
                    (ansi magenta)
                    (date now | format date '%x %X') # try to respect user's locale
                ] | str join | str replace --regex --all "([/:])" $"(ansi green)''${1}(ansi magenta)" |
                    str replace --regex --all "([AP]M)" $"(ansi magenta_underline)''${1}")

                let last_exit_code = if ($env.LAST_EXIT_CODE != 0) {([
                    (ansi rb)
                    ($env.LAST_EXIT_CODE)
                ] | str join)
                } else { "" }

                ([$last_exit_code, (char space), $time_segment] | str join)
            }

            def create_title [] {
              let prefix = if SSH_TTY in $env {$"[(hostname | str replace -r "\\..*" "")] "}
              let path = pwd | str replace $env.HOME "~"
              ([$prefix, $path] | str join)
            }

            $env.PROMPT_COMMAND = { || create_left_prompt }
            $env.PROMPT_COMMAND_RIGHT = { || create_right_prompt }
            $env.PROMPT_INDICATOR = {|| "> " }
            $env.PROMPT_INDICATOR_VI_INSERT = {|| "> " }
            $env.PROMPT_INDICATOR_VI_NORMAL = {|| "| " }
            $env.PROMPT_MULTILINE_INDICATOR = {|| "::: " }

            $env.config = {
              edit_mode: vi,
              show_banner: false,
              use_kitty_protocol: true,
              shell_integration: {
                osc2: false,
                osc7: true,
                osc8: true,
                osc133: true,
                osc633: true,
                reset_application_mode: true,
              },
              completions: {
                algorithm: "fuzzy",
              },
              history: {
                sync_on_enter: true,
              },
              hooks: {
                pre_prompt: [{
                  print -n $"(ansi title)(create_title)(ansi st)"
                }]
              }
            }
            $env.KITTY_SHELL_INTEGRATION = "enabled"
          '';
      };

      home.file = {
        ".config/byobu/backend".text = "BYOBU_BACKEND=tmux";
        ".config/byobu/keybindings.tmux".text = ''
          unbind-key -n C-a
          set -g prefix ^A
          set -g prefix2 F12
          bind a send-prefix
        '';
      };

      home.sessionVariables.PF_INFO = "ascii title os kernel uptime shell de palette";

      home.persistence."/persist".directories =
        [
          ".aws"
          ".config/.jira"
          ".nb"
          ".local/share/flatpak"
        ]
        ++ lib.optionals config.myWine.enable [".wine"];

      home.packages = with pkgs;
        [
          # shells / prompts
          byobu
          pfetch-rs

          # cloud / infra
          awscli2
          jira-cli-go
          nb
          ansible
          yaml-language-server
          devenv
          deploy-rs
          nixos-anywhere
          stable.localstack

          # embedded
          esptool
          esphome
          platformio

          # profiling
          perf-tools
          flamegraph
          cargo-flamegraph
          stable.ltrace

          # web / lang runtime
          python3
          hugo
          apacheHttpd

          # misc extras main carried that cliBase doesn't cover
          cheat
          fx
          distrobox
          uutils-coreutils-noprefix
          iputils
          inetutils
          iotop
          iftop
          ipcalc
          ldns
          ethtool
          efibootmgr
          keyutils
          hashid
          tparted
          nixfmt
          vim
        ]
        ++ lib.optionals (config.myWine.enable && pkgs.stdenv.hostPlatform.system != "aarch64-linux") [
          wineWow64Packages.stable
          winetricks
        ];
    };
  };
}
