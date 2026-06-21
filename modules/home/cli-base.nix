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
  }: {
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
      shellAbbrs = {
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
      };
      shellAliases = {
        ls = "eza -alg --color=always --group-directories-first --icons";
        # Clear screen and scrollback buffer.
        clear = "printf '\\033[2J\\033[3J\\033[1;1H'";
        # Route deletions through trash-cli instead of unrecoverable rm.
        rm = "trash ";
      };
      functions = {
        fish_greeting = "";
        gitignore = "curl -sL https://www.gitignore.io/api/$argv";
      };
      interactiveShellInit = ''
        # Use terminal colours for fish syntax highlighting.
        set -x fish_color_autosuggestion      brblack
        set -x fish_color_command             brgreen
        set -x fish_color_comment             brmagenta
        set -x fish_color_cwd                 green
        set -x fish_color_cwd_root            red
        set -x fish_color_error               brred
        set -x fish_color_param               brblue
        set -x fish_color_quote               yellow
        set -x fish_color_redirection         bryellow
        set -x fish_color_host_remote         yellow
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
    };
    programs.zellij.enable = true;
    programs.nix-index.enable = true;

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
        };
      };
    };
    programs.delta = {
      enable = true;
      enableGitIntegration = true;
    };
    programs.lazygit = {
      enable = true;
      settings.git.autoFetch = false;
    };
    programs.jujutsu = {
      enable = true;
      settings.ui = {
        pager = "less -FRX";
        show-cryptographic-signatures = true;
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
      dust
      duf
      dua
      broot
      trash-cli
      ouch # universal (un)archiver
      zip
      unzip
      xz
      p7zip

      # system / process / disk inspection
      btop
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
