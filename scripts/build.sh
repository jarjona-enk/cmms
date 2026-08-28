#!/usr/bin/env bash
# Produces the single self-contained Atlas CMMS fat jar (API + web UI) ready to
# run on a server, plus deployment helpers.
#
# Pipeline:
#   1. generate the AGPLv3 source bundle  -> api/src/main/resources/static/source/
#   2. `mvn package` at the repo root     -> builds the frontend, deploys it into
#                                            the api module's static resources, and
#                                            builds the fat jar (api/target/app.jar)
#   3. collect artifacts into ./dist
#
# Output:  dist/atlas-cmms.jar   (run with: java -jar atlas-cmms.jar)
#          dist/.env             (copy of dev.env to fill in on the server)
#          dist/cmms.service     (systemd unit for Linux deployment)
#
# Usage:   scripts/build.sh
# Env:     SKIP_FRONTEND=1 SKIP_SOURCE_BUNDLE=1 to skip stages.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
API_DIR="$REPO_ROOT/api"
DIST="$REPO_ROOT/dist"
ENV_FILE="$REPO_ROOT/dev.env"

read_env() {
  local key="$1" def="${2:-}" val=""
  [[ -f "$ENV_FILE" ]] && val="$(grep -E "^${key}=" "$ENV_FILE" | tail -n1 | cut -d= -f2- | tr -d '\r')"
  echo "${val:-$def}"
}

mkdir -p "$DIST"

# ── 1) AGPLv3 complete-corresponding-source bundle ──
if [[ "${SKIP_SOURCE_BUNDLE:-0}" != "1" ]]; then
  echo "==> Generating source bundle"
  bash "$SCRIPT_DIR/build-source-bundle.sh"
fi

# ── 2) Root maven build: frontend -> api static -> fat jar ──
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
cp -f "$REPO_ROOT/cmms.service" "$DIST/cmms.service"

echo ""
echo "Build complete -> $DIST"
echo "  dist/atlas-cmms.jar   single jar (API + web UI)"
echo "  dist/.env             fill in real values before running"
echo "  dist/cmms.service     systemd unit (Linux)"
echo ""
echo "Run locally:  set -a; source dist/.env; set +a; java -jar dist/atlas-cmms.jar"
echo "Then open:    http://localhost:8080"
