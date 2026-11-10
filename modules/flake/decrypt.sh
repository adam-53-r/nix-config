#!/usr/bin/env bash
set -euo pipefail
# create a temporary file
# TMP=$(mktemp --suff .nix) || { echo "Failed to create a temporary file to decrypt '$1'!" >&2; exit 1; }
# decrypt input (if this fails, the script exits with an unsuccessful code causing an evaluation error)
# umask 077
# gpg --batch --yes --output "$TMP" --decrypt "$1"
# sops decrypt "$1" --output "$TMP"
# print the filename of the result
# echo "$TMP"
sops decrypt "$1"
