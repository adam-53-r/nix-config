#!/usr/bin/env bash
# hytale-update.sh
#
# Checks the latest Hytale server version via the downloader CLI's
# -print-version. If it differs from the last-installed version recorded in
# downloader/.installed-version, downloads the build and extracts it
# (Server/ + Assets.zip) directly over the server directory, overwriting
# in place - this matches the current official update flow (there is no
# longer a need to track/retain multiple past versions).
#
# Exit codes:
#   0 = success (including "already up to date")
#   non-zero = error

set -euo pipefail
IFS=$'\n\t'

# Default (can be overridden by --server-dir)
SERVER_DIR=""

usage() {
  cat <<'EOF'
Usage: hytale-update [--server-dir DIR]

Options:
  -d, --server-dir DIR   Path to the Hytale server directory (required)
  -h, --help             Show this help
EOF
}

# Parse args (supports --server-dir=/path too)
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--server-dir)
      [[ $# -ge 2 ]] || { echo "Missing value for $1" >&2; usage; exit 2; }
      SERVER_DIR="$2"
      shift 2
      ;;
    --server-dir=*)
      SERVER_DIR="${1#*=}"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --) # end of options
      shift
      break
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage
      exit 2
      ;;
    *)
      # positional args (if you later add any)
      break
      ;;
  esac
done

# Enforce required flag
[[ -n "$SERVER_DIR" ]] || { echo "Error: --server-dir is required" >&2; usage; exit 2; }
[[ -d "$SERVER_DIR" ]] || { echo "Error: server dir does not exist: $SERVER_DIR" >&2; exit 2; }

DOWNLOADER_BIN="${SERVER_DIR}/downloader/hytale-downloader-linux-amd64"
CREDS_FILE="${SERVER_DIR}/downloader/.hytale-downloader-credentials.json"
VERSION_FILE="${SERVER_DIR}/downloader/.installed-version"

# ----------------------------
# Helpers
# ----------------------------
log() { printf '[%s] %s\n' "$(date -Is)" "$*"; }
die() { log "ERROR: $*"; exit 1; }

require_file() { [[ -f "$1" ]] || die "Required file not found: $1"; }
require_executable() { [[ -x "$1" ]] || die "Required executable not found or not executable: $1"; }

# ----------------------------
# Main logic
# ----------------------------
main() {
  require_executable "$DOWNLOADER_BIN"
  require_file "$CREDS_FILE"

  log "Checking for update..."

  LATEST_VERSION="$("$DOWNLOADER_BIN" \
    -credentials-path "$CREDS_FILE" \
    -print-version \
    | tr -d '\r' \
    | sed -e 's/[[:space:]]\+$//')"

  [[ -n "$LATEST_VERSION" ]] || die "Downloader returned an empty version string."

  INSTALLED_VERSION=""
  if [[ -f "$VERSION_FILE" ]]; then
    INSTALLED_VERSION="$(<"$VERSION_FILE")"
  fi

  if [[ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]]; then
    log "Already up to date (version ${LATEST_VERSION})."
    return 0
  fi

  log "Update available: ${INSTALLED_VERSION:-<none>} -> ${LATEST_VERSION}"

  # The downloader appends ".zip" to whatever -download-path it's given, so
  # mktemp a unique base name (without the extension) and track the real
  # (suffixed) path for cleanup/extraction.
  tmp_base="$(mktemp --tmpdir="$SERVER_DIR" "hytale-update.XXXXXX")"
  tmp_zip="${tmp_base}.zip"
  trap 'rm -f -- "$tmp_base" "$tmp_zip"' EXIT

  "$DOWNLOADER_BIN" \
    -credentials-path "$CREDS_FILE" \
    -download-path "$tmp_base"

  [[ -s "$tmp_zip" ]] || die "Download finished but file is missing/empty: $tmp_zip"

  log "Extracting into: $SERVER_DIR"
  unzip -oq -- "$tmp_zip" -d "$SERVER_DIR"

  printf '%s' "$LATEST_VERSION" >"$VERSION_FILE"

  log "Update complete (now on version ${LATEST_VERSION})."
}

main "$@"
