#!/usr/bin/env bash
# deploy.sh — build a deployable Atlas CMMS that embeds its own source code.
#
# This is the AGPLv3-compliant deploy build. It guarantees the running app can
# hand every user the *complete corresponding source* of the exact version
# deployed, by embedding a source archive inside the jar:
#
#   1. Bundle the complete corresponding source into the API static resources:
#        api/src/main/resources/static/source/atlas-cmms-source.zip
#      Because Maven copies src/main/resources -> target/classes, this archive
#      ends up on the classpath at /static/source/... and is served by
#      SourceCodeController at GET /source-code/download. It is offered to
#      logged-in users on the in-app About page (/app/about) and on the public
#      /source-code page (AGPLv3 §13 network-use source availability).
#   2. Build the single self-contained fat jar (React UI + REST API) with the
#      source archive embedded.
#   3. Stage the runnable artifacts into ./dist.
#
# Usage:
#   scripts/deploy.sh              build dist/ (jar + .env + systemd unit)
#   scripts/deploy.sh --run        build, then run the jar locally with dev.env
#
# Env toggles:
#   SKIP_FRONTEND=1                reuse the already-built SPA (fast Java-only)
#   SKIP_SOURCE_BUNDLE=1           do NOT regenerate the source archive
#                                  (NOT recommended for a real deploy — the
#                                   embedded source must match what you ship)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
API_DIR="$REPO_ROOT/api"
DIST="$REPO_ROOT/dist"
ENV_FILE="$REPO_ROOT/dev.env"
SOURCE_STATIC_DIR="$API_DIR/src/main/resources/static/source"

RUN=0
[[ "${1:-}" == "--run" ]] && RUN=1

read_env() {
  local key="$1" def="${2:-}" val=""
  [[ -f "$ENV_FILE" ]] && val="$(grep -E "^${key}=" "$ENV_FILE" | tail -n1 | cut -d= -f2- | tr -d '\r')"
  echo "${val:-$def}"
}

mkdir -p "$DIST"

# ── 1) Embed the AGPLv3 complete-corresponding-source archive into static/ ──
if [[ "${SKIP_SOURCE_BUNDLE:-0}" != "1" ]]; then
  echo "==> Bundling source code into $SOURCE_STATIC_DIR"
  bash "$SCRIPT_DIR/build-source-bundle.sh" "$SOURCE_STATIC_DIR"
else
  echo "==> SKIP_SOURCE_BUNDLE=1 — keeping existing source archive (must match deployed code)"
fi

if [[ ! -f "$SOURCE_STATIC_DIR/atlas-cmms-source.zip" ]]; then
  echo "ERROR: source archive missing at $SOURCE_STATIC_DIR/atlas-cmms-source.zip" >&2
  echo "       The deploy must embed the corresponding source (AGPLv3 §13)." >&2
  exit 1
fi

# ── 2) Build the single fat jar (frontend baked in, source embedded) ──
API_URL="$(read_env API_URL "$(read_env PUBLIC_API_URL http://localhost:8080)")"
PROVIDER="$(read_env OAUTH2_PROVIDER microsoft)"
SSO="$(read_env ENABLE_SSO true)"
SKIP_FE="$([[ "${SKIP_FRONTEND:-0}" == "1" ]] && echo true || echo false)"

MVN_ARGS=(-DskipTests "-DskipFrontend=$SKIP_FE"
          "-Dfrontend.api.url=$API_URL"
          "-Dfrontend.oauth2.provider=$PROVIDER"
          "-Dfrontend.enable.sso=$SSO"
          clean package)

echo "==> (in api) mvn ${MVN_ARGS[*]}"
pushd "$API_DIR" >/dev/null
if [[ -x ./mvnw ]]; then
  ./mvnw "${MVN_ARGS[@]}"
else
  mvn "${MVN_ARGS[@]}"
fi
popd >/dev/null

# ── 3) Collect artifacts ──
JAR="$(find "$API_DIR/target" -maxdepth 1 -name '*.jar' ! -name '*.original' | head -n1)"
[[ -n "$JAR" ]] || { echo "No jar produced in api/target" >&2; exit 1; }
cp -f "$JAR" "$DIST/atlas-cmms.jar"

[[ -f "$ENV_FILE" ]] && cp -f "$ENV_FILE" "$DIST/.env"
[[ -f "$REPO_ROOT/cmms.service" ]] && cp -f "$REPO_ROOT/cmms.service" "$DIST/cmms.service"

# Sanity check: confirm the source archive actually made it into the jar.
# Use `grep -c` (consumes all input) rather than `grep -q` (closes the pipe
# early) so `set -o pipefail` doesn't trip on a harmless SIGPIPE to unzip.
if command -v unzip >/dev/null 2>&1; then
  if unzip -l "$DIST/atlas-cmms.jar" | grep -c 'static/source/atlas-cmms-source.zip' >/dev/null; then
    echo "==> Verified: source archive is embedded in the jar"
  else
    echo "WARNING: source archive not found inside the jar — /source-code/download will 404" >&2
  fi
fi

echo ""
echo "Deploy build complete -> $DIST"
echo "  dist/atlas-cmms.jar   single jar (API + web UI + embedded source)"
echo "  dist/.env             fill in real values before running"
echo "  dist/cmms.service     systemd unit (Linux)"
echo ""
echo "Logged-in users get the source on the About page:  /app/about"
echo "Public source offer (AGPLv3 §13):                   /source-code"
echo ""

if [[ "$RUN" == "1" ]]; then
  echo "==> Running locally (java -jar) with $ENV_FILE"
  set -a; [[ -f "$ENV_FILE" ]] && source "$ENV_FILE"; set +a
  exec java -jar "$DIST/atlas-cmms.jar"
else
  echo "Run locally:  set -a; source dist/.env; set +a; java -jar dist/atlas-cmms.jar"
  echo "Then open:    http://localhost:8080"
fi
