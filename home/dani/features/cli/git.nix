{
  pkgs,
  config,
  lib,
  ...
}: let
  ssh = "${pkgs.openssh}/bin/ssh";

  git-fixup = pkgs.writeShellScriptBin "git-fixup" ''
    rev="$(git rev-parse "$1")"
    git commit --fixup "$@"
    GIT_SEQUENCE_EDITOR=true git rebase -i --autostash --autosquash $rev^
  '';
in {
  home.packages = with pkgs; [
    git-fixup
    lazygit
  ];
  programs.git = {
    enable = true;
    package = pkgs.gitAndTools.gitFull;
    aliases = {
      p = "pull --ff-only";
      ff = "merge --ff-only";
      graph = "log --decorate --oneline --graph";
      pushall = "!git remote | xargs -L1 git push --all";
      add-nowhitespace = "!git diff -U0 -w --no-color | git apply --cached --ignore-whitespace --unidiff-zero -";
    };
    userName = "Daniel Floria Lopez";
    userEmail = lib.mkDefault "dani-f53@protonmail.com";
    extraConfig = {
      init.defaultBranch = "main";
      user.signing = {
        signByDefault = true;
        key = "197E0A55F7BF748AE35B69804FD8819DFE1EF761";
      };
      commit.gpgSign = lib.mkDefault true;
      gpg.program = "${config.programs.gpg.package}/bin/gpg2";

      merge.conflictStyle = "zdiff3";
      commit.verbose = true;
      diff.algorithm = "histogram";
      log.date = "iso";
      column.ui = "auto";
      branch.sort = "committerdate";
      # Automatically track remote branch
      push.autoSetupRemote = true;
      # Reuse merge conflict fixes when rebasing
      rerere.enabled = true;
    };
    lfs.enable = true;
    ignores = [
      ".direnv"
      "result"
      ".jj"
    ];
  };
}