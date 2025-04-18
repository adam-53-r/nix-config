{
  config,
  lib,
  ...
}: {
  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = config.programs.git.userName;
        email = config.programs.git.userEmail;
      };
      ui = {
        pager = "less -FRX";
      };
      signing = let
        gitCfg = config.programs.git.extraConfig;
      in {
        backend = "gpg";
        key = gitCfg.user.signing.key;
        behavior = lib.mkIf gitCfg.commit.gpgSign "own";
      };
      templates = {
        draft_commit_description = ''
          concat(
            description,
            indent("JJ: ", concat(
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
}