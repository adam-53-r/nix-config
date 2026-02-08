#!/usr/bin/env bash
# hytale-update.sh
#
# Checks latest Hytale server version via downloader.
# If the corresponding zip isn't present in updates/:
#   - downloads it (atomic temp download -> rename)
# Then ensures it is extracted to:
#   updates/hytale-server-<version>/
# Finally cleans older versions (zip + extracted dir), keeping the N newest.
#
# Exit codes:
#   0 = success (including "already latest and extracted")
#   non-zero = error

set -euo pipefail
IFS=$'\n\t'

# ----------------------------
# Configuration (edit as needed)
# ----------------------------
KEEP_NEWEST=2

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

# LOCK_FILE="${SERVER_DIR}/hytale-update.lock"
DOWNLOADER_BIN="${SERVER_DIR}/downloader/hytale-downloader-linux-amd64"
CREDS_FILE="${SERVER_DIR}/downloader/.hytale-downloader-credentials.json"
UPDATES_DIR="${SERVER_DIR}/updates"

# ----------------------------
# Helpers
# ----------------------------
log() { printf '[%s] %s\n' "$(date -Is)" "$*"; }
die() { log "ERROR: $*"; exit 1; }

require_file() { [[ -f "$1" ]] || die "Required file not found: $1"; }
require_executable() { [[ -x "$1" ]] || die "Required executable not found or not executable: $1"; }
have_cmd() { command -v "$1" >/dev/null 2>&1; }

# # ----------------------------
# # Optional locking (prevents overlapping runs)
# # ----------------------------
# run_with_lock() {
#   if [[ -z "${LOCK_FILE}" ]]; then
#     "$@"; return
#   fi

#   if have_cmd flock; then
#     # -n = do not wait if locked (exit cleanly)
#     flock -n "$LOCK_FILE" "$@" || {
#       log "Another update run is already in progress (lock: $LOCK_FILE). Exiting."
#       exit 0
#     }
#   else
#     log "flock not found; proceeding without locking."
#     "$@"
#   fi
# }

# ----------------------------
# Main logic
# ----------------------------
main() {
  require_executable "$DOWNLOADER_BIN"
  require_file "$CREDS_FILE"
  mkdir -p -- "$UPDATES_DIR"

  # Track temp paths for cleanup on error
  tmp_download=""
  tmp_extract=""
  # shellcheck disable=SC2329
  cleanup() {
    # Remove temp download if it still exists
    if [[ -n "${tmp_download}" && -e "${tmp_download}" ]]; then
      rm -f -- "$tmp_download"
    fi
    # Remove temp extraction dir if it still exists
    if [[ -n "${tmp_extract}" && -d "${tmp_extract}" ]]; then
      rm -rf -- "$tmp_extract"
    fi
  }
  trap cleanup EXIT

  log "Checking for update..."

  # Get latest version string from downloader
  LATEST_VERSION="$("$DOWNLOADER_BIN" \
    -credentials-path "$CREDS_FILE" \
    -print-version \
    | tr -d '\r' \
    | sed -e 's/[[:space:]]\+$//')"

  [[ -n "$LATEST_VERSION" ]] || die "Downloader returned an empty version string."

  latest_zip="${UPDATES_DIR}/hytale-server-${LATEST_VERSION}.zip"
  extract_dir="${SERVER_DIR}"

  # ----------------------------
  # Download if zip missing
  # ----------------------------
  if [[ -e "$latest_zip" ]]; then
    log "Latest zip already present: $latest_zip"
  else
    log "Update available! Downloading to: $latest_zip"

    # Download to a temp file first, then rename into place atomically
    tmp_download="$(mktemp --tmpdir="$UPDATES_DIR" "hytale-server-${LATEST_VERSION}.part.XXXXXX")"

    "$DOWNLOADER_BIN" \
      -credentials-path "$CREDS_FILE" \
      -download-path "$tmp_download"

    tmp_download="$tmp_download.zip"

    [[ -s "$tmp_download" ]] || die "Download finished but temp file is missing/empty: $tmp_download"

    mv -f -- "$tmp_download" "$latest_zip"
    tmp_download=""  # renamed into place, no longer a temp path

    log "Update downloaded successfully."
  fi

  # ----------------------------
  # Extract if not already extracted
  # ----------------------------
  log "Extracting zip into: $extract_dir"

  # Need an extractor: prefer unzip; fall back to bsdtar if available
  if ! have_cmd unzip && ! have_cmd bsdtar; then
    die "Neither 'unzip' nor 'bsdtar' found. Install one to extract .zip files."
  fi

  # Extract into a temp dir first, then move into place (prevents partial extracts)
  tmp_extract="$(mktemp -d --tmpdir="$UPDATES_DIR" "hytale-server-${LATEST_VERSION}.extract.XXXXXX")"

  if have_cmd unzip; then
    # -q = quiet (remove if you want file-by-file output)
    unzip -q -- "$latest_zip" -d "$tmp_extract"
  else
    # bsdtar can extract zips too on many distros
    bsdtar -xf "$latest_zip" -C "$tmp_extract"
  fi

  # Basic sanity check: ensure something was extracted
  if [[ -z "$(ls -A -- "$tmp_extract")" ]]; then
    die "Extraction produced no files; zip may be corrupt or empty: $latest_zip"
  fi

  # Move temp extraction directory into final location
  # -f ensures we replace the target path
  mv -f -- "$tmp_extract" "$extract_dir"
  tmp_extract=""  # moved into place

  log "Extraction complete."

  # ----------------------------
  # Cleanup: keep only the newest KEEP_NEWEST zips (and their extracted dirs)
  # ----------------------------
  log "Cleaning old updates (keeping newest ${KEEP_NEWEST})..."

  # Find all update zips; we use zips as the authoritative list of versions to keep/remove.
  mapfile -d '' zips < <(
    find "$UPDATES_DIR" -maxdepth 1 -type f -name 'hytale-server-*.zip' -print0
  )

  if (( ${#zips[@]} <= KEEP_NEWEST )); then
    log "Nothing to clean (found ${#zips[@]} zip(s))."
    trap - EXIT
    return 0
  fi

  # Sort zips newest -> oldest by mtime
  mapfile -d '' sorted_zips < <(
    printf '%s\0' "${zips[@]}" \
      | xargs -0 stat --printf '%Y\t%n\0' \
      | sort -z -nr -t $'\t' -k1,1 \
      | sed -z 's/^[0-9]\+\t//'
  )

  # Delete everything beyond the newest KEEP_NEWEST
  for ((i=KEEP_NEWEST; i<${#sorted_zips[@]}; i++)); do
    old_zip="${sorted_zips[$i]}"
    base="$(basename -- "$old_zip")"                     # e.g. hytale-server-1.2.3.zip
    version="${base#hytale-server-}"                     # e.g. 1.2.3.zip
    version="${version%.zip}"                            # e.g. 1.2.3
    old_dir="${UPDATES_DIR}/hytale-server-${version}"    # extracted directory path

    log "Deleting old zip: $old_zip"
    rm -f -- "$old_zip"

    if [[ -d "$old_dir" ]]; then
      log "Deleting old extracted dir: $old_dir"
      rm -rf -- "$old_dir"
    fi
  done

  log "Cleanup complete."
  log "Ready to apply update (latest extracted at: $extract_dir)"

  # Clear trap (nothing temporary left to clean)
  trap - EXIT
}

# run_with_lock main "$@"
main "$@"
