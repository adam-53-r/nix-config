# Shell snippets for querying/toggling the gpg-agent lock state (used by the
# waybar gpg indicator). Underscore file: skipped by import-tree, imported via
# relative path.
{
  pkgs,
  config,
  lib,
  ...
}: let
  pgrep = lib.getExe' pkgs.procps "pgrep";
  grep = lib.getExe pkgs.gnugrep;
  gpg-connect-agent = lib.getExe' config.programs.gpg.package "gpg-connect-agent";
  gpgconf = lib.getExe' config.programs.gpg.package "gpgconf";
in {
  # TODO: this does not REALLY query whether the PIN is cached, only whether
  # the card has been used by the agent — the user might still be prompted.
  isUnlocked = "${pgrep} 'gpg-agent' &> /dev/null && ${gpg-connect-agent} 'scd getinfo card_list' /bye | ${grep} SERIALNO -q";
  lock = "${gpg-connect-agent} reloadagent /bye";
  unlock = "SSH_AUTH_SOCK=$(${gpgconf} --list-dirs agent-ssh-socket) ssh localhost exit";
}
