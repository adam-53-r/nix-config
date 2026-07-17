# Reusable, identity-free CLI home-manager profile.
#
# This is the "tools + shell" layer: prompt, shell config, file/dir tooling and
# a curated package set. It intentionally contains NO personal identity (git
# user/email/signing key) and NO host-specific assumptions, so it is safe to
# assign to ANY user — including root, which on this box is handy because admin
# work often lands in a root shell.
#
# Optional shared features (gpg, ssh, gh) and personal identity layer on top of
# this in modules/home/adamr/. It pulls in the impermanence feature so the shell
# state below can colocate its persisted dirs; whether they actually persist is
# governed by myPersistence.enable (off by default — per-host profiles flip it).
{self, ...}: {
  flake.homeModules.cliBase = {
    pkgs,
    lib,
    config,
    ...
  }: let
    # Feature-detect optional tools so their shell abbreviations only appear
    # when something else in the profile actually installs them.
    packageNames = map (p: p.pname or p.name or null) config.home.packages;
    hasPackage = name: lib.any (x: x == name) packageNames;
    hasSpecialisationCli = hasPackage "specialisation";
    hasAwsCli = hasPackage "awscli2";
    hasNeomutt = config.programs.neomutt.enable;
  in {
    imports = [self.homeModules.homeImpermanence];

    # Let home-manager manage itself so `home-manager` is on PATH.
    programs.home-manager.enable = true;

    home.stateVersion = lib.mkDefault "26.05";

    home.sessionVariables = {
      EDITOR = "hx";
      VISUAL = "hx";
      PAGER = "less -FRX";
      COLORTERM = "truecolor";
      # Point the nh/nix flake helpers at the live config checkout.
      FLAKE = "$HOME/mynix";
      NH_FLAKE = "$HOME/mynix";
    };
    home.sessionPath = ["$HOME/.local/bin"];

    # Shell state worth keeping across reboots (history, dir-jump db, direnv
    # allowlist). Only persisted when myPersistence.enable is set.
    home.persistence."/persist".directories = [
      ".local/share/atuin"
      ".local/share/zoxide"
      ".local/share/direnv"
      ".local/share/fish"
    ];

    ###########################################################################
    # Shell + prompt
    ###########################################################################
    programs.starship = {
      enable = true;
      enableFishIntegration = true;
      enableTransience = true;
    };

    programs.bash.enable = true; # fallback / non-interactive scripts

    programs.fish = {
      enable = true;
      plugins = [
        {
          name = "grc";
          src = pkgs.fishPlugins.grc.src;
        }
        {
          name = "done"; # desktop/terminal notification when long commands finish
          src = pkgs.fishPlugins.done.src;
        }
      ];
      shellAbbrs = rec {
        # nix
        n = "nix";
        nd = "nix develop -c $SHELL";
        ns = "nix shell";
        nsn = "nix shell nixpkgs#";
        nf = "nix flake";
        nr = "nixos-rebuild --flake .";
        nrs = "nixos-rebuild --flake . switch";
        snr = "sudo nixos-rebuild --flake .";
        snrs = "sudo nixos-rebuild --flake . switch";
        hm = "home-manager --flake .";
        hms = "home-manager --flake . switch";
        # misc
        jqless = "jq -C | less -r";
        gits = "git status";
        # only where the corresponding tool is present
        s = lib.mkIf hasSpecialisationCli "specialisation";
        mutt = lib.mkIf hasNeomutt "neomutt";
        m = mutt;
        aws-switch = lib.mkIf hasAwsCli "export AWS_PROFILE=(aws configure list-profiles | fzf)";
        awssw = aws-switch;
      };
      shellAliases = {
        ls = "eza -alg --color=always --group-directories-first --icons";
        # Clear screen and scrollback buffer.
        clear = "printf '\\033[2J\\033[3J\\033[1;1H'";
        # Route deletions through trash-cli instead of unrecoverable rm.
        rm = "trash ";
        mtr = "mtr ";
        cc = "fish_clipboard_copy ";
      };
      functions = {
        fish_greeting = "";
        gitignore = "curl -sL https://www.gitignore.io/api/$argv";
        # Merge history when pressing up
        up-or-search = lib.readFile ./up-or-search.fish;
        # Check stuff in PATH
        nix-inspect =
          /*
          fish
          */
          ''
            set -s PATH | grep "PATH\[.*/nix/store" | cut -d '|' -f2 |  grep -v -e "-man" -e "-terminfo" | perl -pe 's:^/nix/store/\w{32}-([^/]*)/bin$:\1:' | sort | uniq
          '';
        # Fall back to bash completions for commands fish has none for
        __fish_complete_bash =
          /*
          fish
          */
          ''
            set cmd (commandline -cp)
            bash -ic "source ${./get-bash-completions.sh}; get_completions '$cmd'"
          '';
        __fish_command_not_found_handler = {
          body = "__fish_default_command_not_found_handler $argv[1]";
          onEvent = "fish_command_not_found";
        };
      };
      interactiveShellInit = ''
        # vi mode with cursor shapes per mode
        fish_vi_key_bindings
        set fish_cursor_default     block      blink
        set fish_cursor_insert      line       blink
        set fish_cursor_replace_one underscore blink
        set fish_cursor_visual      block

        # Open command buffer in editor when alt+e is pressed
        bind \ee edit_command_buffer

        # Delete key fix
        bind -M insert delete delete-char

        # Use terminal colours for fish syntax highlighting.
        set -x fish_color_autosuggestion      brblack
        set -x fish_color_cancel              -r
        set -x fish_color_command             brgreen
        set -x fish_color_comment             brmagenta
        set -x fish_color_cwd                 green
        set -x fish_color_cwd_root            red
        set -x fish_color_end                 brmagenta
        set -x fish_color_error               brred
        set -x fish_color_escape              brcyan
        set -x fish_color_history_current     --bold
        set -x fish_color_host                normal
        set -x fish_color_host_remote         yellow
        set -x fish_color_match               --background=brblue
        set -x fish_color_normal              normal
        set -x fish_color_operator            cyan
        set -x fish_color_param               brblue
        set -x fish_color_quote               yellow
        set -x fish_color_redirection         bryellow
        set -x fish_color_search_match        'bryellow' '--background=brblack'
        set -x fish_color_selection           'white' '--bold' '--background=brblack'
        set -x fish_color_status              red
        set -x fish_color_user                brgreen
        set -x fish_color_valid_path          --underline
        set -x fish_pager_color_completion    normal
        set -x fish_pager_color_description   yellow
        set -x fish_pager_color_prefix        'white' '--bold' '--underline'
        set -x fish_pager_color_progress      'brwhite' '--background=cyan'
      '';
    };

    # Better, syncable shell history with fuzzy search (fish-integrated).
    programs.atuin = {
      enable = true;
      enableFishIntegration = true;
      flags = ["--disable-up-arrow"]; # keep fish's native up-arrow behaviour
      settings = {
        style = "compact";
        inline_height = 15;
      };
    };

    # Disable fzf Ctrl+R keybind (atuin uses it)
    programs.fzf.historyWidget.command = "";

    ###########################################################################
    # File / dir tooling
    ###########################################################################
    programs.bat = {
      enable = true;
      config.theme = "base16";
    };
    programs.fzf = {
      enable = true;
      enableFishIntegration = true;
      defaultOptions = ["--color 16"];
    };
    programs.zoxide = {
      enable = true;
      enableFishIntegration = true;
    };
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    programs.yazi = {
      enable = true;
      enableFishIntegration = true;
      extraPackages = with pkgs; [glow ouch];
      plugins = {
        inherit (pkgs.yaziPlugins) git ouch lsar glow diff piper mount;
      };
      flavors = {
        inherit (pkgs.yaziPlugins) nord;
      };
      theme.flavor.dark = "nord";
    };
    programs.zellij.enable = true;

    programs.nix-index.enable = true;
    # Keep the nix-index database fresh from mic92/nix-index-database instead
    # of building it locally (which takes ages).
    systemd.user.services.nix-index-database-sync = {
      Unit.Description = "fetch mic92/nix-index-database";
      Service = {
        Type = "oneshot";
        ExecStart = lib.getExe (
          pkgs.writeShellApplication {
            name = "fetch-nix-index-database";
            runtimeInputs = with pkgs; [
              wget
              coreutils
            ];
            text = ''
              mkdir -p ~/.cache/nix-index
              cd ~/.cache/nix-index
              name="index-${pkgs.stdenv.hostPlatform.system}"
              wget -N "https://github.com/Mic92/nix-index-database/releases/latest/download/$name"
              ln -sf "$name" "files"
            '';
          }
        );
        Restart = "on-failure";
        RestartSec = "5m";
      };
    };
    systemd.user.timers.nix-index-database-sync = {
      Unit.Description = "Automatic github:mic92/nix-index-database fetching";
      Timer = {
        OnBootSec = "10m";
        OnUnitActiveSec = "24h";
      };
      Install.WantedBy = ["timers.target"];
    };

    ###########################################################################
    # Git / version control (generic — NO identity, no signing)
    ###########################################################################
    programs.git = {
      enable = true;
      lfs.enable = true;
      ignores = [".direnv" "result" ".jj"];
      settings = {
        init.defaultBranch = "main";
        merge.conflictStyle = "zdiff3";
        commit.verbose = true;
        diff.algorithm = "histogram";
        log.date = "iso";
        column.ui = "auto";
        branch.sort = "committerdate";
        push.autoSetupRemote = true;
        rerere.enabled = true;
        alias = {
          p = "pull --ff-only";
          ff = "merge --ff-only";
          graph = "log --decorate --oneline --graph";
          pushall = "!git remote | xargs -L1 git push --all";
          add-nowhitespace = "!git diff -U0 -w --no-color | git apply --cached --ignore-whitespace --unidiff-zero -";
        };
      };
    };
    programs.delta = {
      enable = true;
      enableGitIntegration = true;
    };
    programs.lazygit = {
      enable = true;
      enableFishIntegration = true;
      settings.git.autoFetch = false;
    };
    programs.jujutsu = {
      enable = true;
      settings = {
        ui = {
          pager = "less -FRX";
          show-cryptographic-signatures = true;
        };
        revset-aliases = {
          "closest_bookmark(to)" = "heads(::to & bookmarks())";
        };
        aliases = {
          # Advances closest bookmark to parent commit
          tug = ["bookmark" "move" "--from" "closest_bookmark(@-)" "--to" "@-"];
        };
        template-aliases = {
          "gerrit_change_id(change_id)" = ''
            "Id0000000" ++ change_id.normal_hex()
          '';
        };
        templates = {
          draft_commit_description = ''
            concat(
              description,
              indent("JJ: ", concat(
                if(
                  !description.contains("Change-Id: "),
                  "Change-Id: " ++ gerrit_change_id(change_id) ++ "\n",
                  "",
                ),
                "Change summary:\n",
                indent("     ", diff.summary()),
                "Full change:\n",
                "ignore-rest\n",
              )),
              diff.git(),
            )
          '';
        };
      };
    };

    ###########################################################################
    # Curated CLI package set (headless server / dev focus)
    ###########################################################################
    home.packages = with pkgs; [
      # coreutils-style replacements & file tooling
      eza
      ripgrep
      fd
      sd
      choose
      jq
      yq-go
      tree
      file
      ncdu
      gdu
      dust
      duf
      dua
      broot
      lsd
      trash-cli
      ouch # universal (un)archiver
      zip
      unzip
      xz
      p7zip

      # system / process / disk inspection
      btop
      bottom
      glances
      procs
      lsof
      sysstat
      lm_sensors
      smartmontools
      pciutils
      usbutils
      parted
      gptfdisk
      dysk # modern df

      # log / observability
      lnav # log file navigator — great for server triage

      # network tooling
      dnsutils
      doggo
      nmap
      tcpdump
      iperf3
      socat
      rsync
      sshfs
      aria2
      wget
      xh # friendly HTTP client (httpie-like)
      httpie
      curlie
      gping
      bandwhich # per-process network usage

      # containers (podman host)
      lazydocker
      dive # inspect OCI image layers

      # dev / git extras
      gh
      git-absorb # auto-fixup staged changes into the right commit
      difftastic # structural diff
      glow # render markdown in the terminal
      hyperfine # command benchmarking
      # git commit --amend, but for older commits
      (writeShellScriptBin "git-fixup" ''
        rev="$(git rev-parse "$1")"
        git commit --fixup "$@"
        GIT_SEQUENCE_EDITOR=true git rebase -i --autostash --autosquash $rev^
      '')

      # colouriser the fish grc plugin wraps common commands with
      grc

      # nix tooling
      nixd
      alejandra
      nh
      nvd
      nix-diff
      nix-tree
      nix-output-monitor
      comma # run a program without installing: , cowsay

      # secrets
      sops
      age
      ssh-to-age
      gnupg

      # misc quality-of-life
      tldr
      timer
      bc
      fastfetch
      helix
    ];
  };
}
