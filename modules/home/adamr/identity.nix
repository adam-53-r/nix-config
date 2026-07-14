# adamr's personal identity — the only genuinely user-specific bits: git author,
# commit signing key, and the matching jujutsu signing config. Everything else
# (shell, tools, gpg-agent, ssh, gh) is generic and lives in shared features.
{...}: {
  flake.homeModules.adamrIdentity = {
    lib,
    config,
    ...
  }: let
    # OpenPGP key fingerprint backing git commit signing (the secret lives on the
    # hardware token via gpg-agent, configured by the homeGpg feature).
    signingKey = "586D801B64FDF09F4CE596F13068CD4BF2AB1986";
  in {
    programs.git = {
      settings = {
        user.name = "Adam Rkouni";
        user.email = lib.mkDefault "adam-53-r@protonmail.com";
        gpg.program = "${config.programs.gpg.package}/bin/gpg2";
      };
      signing = {
        format = "openpgp";
        key = signingKey;
        signByDefault = true;
      };
    };

    # Mirror git identity + signing into jujutsu.
    programs.jujutsu.settings = {
      user = {
        name = "Adam Rkouni";
        email = "adam-53-r@protonmail.com";
      };
      signing = {
        backend = "gpg";
        behaviour = "own";
        key = signingKey;
      };
    };

    # Own public key, so `git log --show-signature` / `gpg --verify` trust it
    # locally without a keyserver lookup.
    programs.gpg.publicKeys = [
      {
        source = ./pgp.asc;
        trust = 5;
      }
    ];
  };
}
