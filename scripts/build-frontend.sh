#!/usr/bin/env bash
# Builds the React frontend and copies the compiled SPA into the api module's
# static resources (api/src/main/resources/static), so Spring Boot serves it.
#
# Use this for quick local iteration: rebuild the SPA, then run the API with
#   (cd api && ./mvnw spring-boot:run)      (or run the packaged jar)
# and browse http://localhost:8080.
#
# For a full server build (frontend + fat jar in one step) use `mvn package`
# at the repo root instead - see pom.xml.
#
# Reads dev.env (if present) to bake the public values into the bundle.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FRONT_DIR="$REPO_ROOT/frontend"
STATIC_DIR="$REPO_ROOT/api/src/main/resources/static"
ENV_FILE="$REPO_ROOT/dev.env"

read_env() {
  local key="$1" def="${2:-}" val=""
  [[ -f "$ENV_FILE" ]] && val="$(grep -E "^${key}=" "$ENV_FILE" | tail -n1 | cut -d= -f2- | tr -d '\r')"
  echo "${val:-$def}"
}

export REACT_APP_API_URL="$(read_env API_URL "$(read_env PUBLIC_API_URL http://localhost:8080)")"
export REACT_APP_ENABLE_SSO="$(read_env ENABLE_SSO false)"
export REACT_APP_OAUTH2_PROVIDER="$(read_env OAUTH2_PROVIDER '')"
export REACT_APP_GOOGLE_KEY="$(read_env GOOGLE_KEY '')"
export NODE_OPTIONS="--max_old_space_size=4096"

echo "==> Building frontend (API_URL=$REACT_APP_API_URL)"
pushd "$FRONT_DIR" >/dev/null
npm ci    # exact, reproducible install from package-lock.json (.npmrc sets legacy-peer-deps)
npm run build
popd >/dev/null

echo "==> Deploying SPA into $STATIC_DIR"
# Remove only the SPA-owned subtree; keep committed api assets (api-docs.html, css/, images/)
rm -rf "$STATIC_DIR/static"
mkdir -p "$STATIC_DIR"
cp -R "$FRONT_DIR/build/." "$STATIC_DIR/"

echo "Done. The SPA is now served by Spring from /static at http://localhost:8080"
