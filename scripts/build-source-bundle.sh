#!/usr/bin/env bash
# Generates the AGPLv3 "complete corresponding source" archive of this
# repository. The same archive is produced automatically inside the API Docker
# image (see api/Dockerfile); this script is for generating it outside Docker,
# e.g. for a local (non-Docker) build or to hand a copy to whoever requests it.
#
# Usage: scripts/build-source-bundle.sh [output-dir]
#   Default output: api/src/main/resources/static/source/atlas-cmms-source.zip
#   (so a subsequent `mvn package` embeds it for /source-code/download)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${1:-$REPO_ROOT/api/src/main/resources/static/source}"
OUT_FILE="$OUT_DIR/atlas-cmms-source.zip"

mkdir -p "$OUT_DIR"
rm -f "$OUT_FILE"

cd "$REPO_ROOT"

if command -v zip >/dev/null 2>&1; then
  # Preferred path (Linux/macOS/Docker, or Windows with Info-ZIP installed).
  #
  # SECURITY: this archive is served publicly at /source-code/download, so it
  # must NOT contain deployment secrets/config. AGPLv3 §13 "complete
  # corresponding source" means code + build scripts, NOT env files or keys.
  # Exclude env files (dev.env holds OAUTH2_CLIENT_SECRET) and key material.
  zip -r -q "$OUT_FILE" . \
    -x '.git/*' \
    -x '*/node_modules/*' \
    -x 'api/target/*' \
    -x '*/build/*' \
    -x 'dist/*' '*/dist/*' \
    -x '*/.gradle/*' \
    -x '*/.idea/*' \
    -x 'api/src/main/resources/static/source/*' \
    -x '.env' '*.env' 'env.*' \
    -x '*.pem' '*.key' '*.p12' '*.jks' '*.keystore' 'id_rsa*'
else
  # Fallback for Windows boxes without `zip`: stage the tree with robocopy
  # (native, robust directory excludes) then compress with PowerShell. We stage
  # to a temp dir OUTSIDE the repo so the growing archive can't recurse into
  # itself, then move the result into place.
  echo "zip not found — using PowerShell Compress-Archive fallback"
  command -v powershell >/dev/null 2>&1 || { echo "Neither zip nor powershell available" >&2; exit 1; }

  STAGING="$(mktemp -d)"
  TMP_ZIP="$(mktemp -u).zip"
  trap 'rm -rf "$STAGING" "$TMP_ZIP"' EXIT

  # robocopy excludes directories by name at any depth (/XD). Exit codes 0-7
  # are success for robocopy; 8+ are failures.
  # /XD excludes directories by name; /XF excludes files by name/pattern.
  # SECURITY: exclude env files (dev.env holds OAUTH2_CLIENT_SECRET) and key
  # material — this archive is served publicly at /source-code/download.
  # MSYS2_ARG_CONV_EXCL/MSYS_NO_PATHCONV stop Git Bash from mangling robocopy's
  # /E /XD /XF switches into Windows paths (which makes robocopy fail with 16).
  MSYS2_ARG_CONV_EXCL='*' MSYS_NO_PATHCONV=1 \
  robocopy "$(cygpath -w "$REPO_ROOT")" "$(cygpath -w "$STAGING")" /E /NFL /NDL /NJH /NJS /NP \
    /XD .git node_modules target build dist .gradle .idea \
    /XF dev.env "*.env" ".env" "*.pem" "*.key" "*.p12" "*.jks" "*.keystore" "id_rsa*" \
    >/dev/null || [ "$?" -lt 8 ]

  WIN_STAGING="$(cygpath -w "$STAGING")"
  WIN_ZIP="$(cygpath -w "$TMP_ZIP")"
  powershell -NoProfile -Command \
    "Compress-Archive -Path '$WIN_STAGING\\*' -DestinationPath '$WIN_ZIP' -Force"

  mv -f "$TMP_ZIP" "$OUT_FILE"
fi

echo "Source bundle written to: $OUT_FILE"
