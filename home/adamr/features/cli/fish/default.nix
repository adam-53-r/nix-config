{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  packageNames = map (p: p.pname or p.name or null) config.home.packages;
  hasPackage = name: lib.any (x: x == name) packageNames;
  hasEza = hasPackage "eza";
  hasSpecialisationCli = hasPackage "specialisation";
  hasAwsCli = hasPackage "awscli2";
  hasNeomutt = config.programs.neomutt.enable;
in {
  imports = [
    # ./tide.nix
    ./starship.nix
    ./bindings.nix
  ];

  home.packages = with pkgs; [
    grc
    fishPlugins.grc
  ];

  home.persistence = {
    "/persist/${config.home.homeDirectory}".files = [
      ".local/share/fish/fish_history"
    ];
  };

  programs.fish = {
    enable = true;
    plugins = [
      {
        name = "grc";
        src = pkgs.fishPlugins.grc.src;
      }
      {
        name = "done";
        src = pkgs.fishPlugins.done.src;
      }
    ];
    shellAbbrs = rec {
      jqless = "jq -C | less -r";

      n = "nix";
      nd = "nix develop -c $SHELL";
      ns = "nix shell";
      nsn = "nix shell nixpkgs#";
      nb = "nix build";
      nbn = "nix build nixpkgs#";
      nf = "nix flake";

      nr = "nixos-rebuild --flake .";
      nrs = "nixos-rebuild --flake . switch";
      snr = "sudo nixos-rebuild --flake .";
      snrs = "sudo nixos-rebuild --flake . switch";
      hm = "home-manager --flake .";
      hms = "home-manager --flake . switch";

      s = mkIf hasSpecialisationCli "specialisation";

      mutt = mkIf hasNeomutt "neomutt";
      m = mutt;

      aws-switch = mkIf hasAwsCli "export AWS_PROFILE=(aws configure list-profiles | fzf)";
      awssw = aws-switch;

      gits = "git status";
    };
    shellAliases = {
      ls = "eza -alg --color=always --group-directories-first --icons";
      # Clear screen and scrollback
      clear = "printf '\\033[2J\\033[3J\\033[1;1H'";
      rm = "trash ";
      mtr = "mtr ";
    };
    functions = {
      # Disable greeting
      fish_greeting = "";
      # Merge history when pressing up
      up-or-search = lib.readFile ./up-or-search.fish;
      # Check stuff in PATH
      nix-inspect = /* fish */ ''
        set -s PATH | grep "PATH\[.*/nix/store" | cut -d '|' -f2 |  grep -v -e "-man" -e "-terminfo" | perl -pe 's:^/nix/store/\w{32}-([^/]*)/bin$:\1:' | sort | uniq
      '';
      __fish_command_not_found_handler = {
        body = "__fish_default_command_not_found_handler $argv[1]";
        onEvent = "fish_command_not_found";
      };
      gitignore = "curl -sL https://www.gitignore.io/api/$argv";
    };
    interactiveShellInit = /* fish */ ''
      # Open command buffer in editor when alt+e is pressed
      bind \ee edit_command_buffer

      # Use terminal colors
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
}