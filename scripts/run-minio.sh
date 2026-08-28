#!/usr/bin/env bash
# Runs a local MinIO container for testing, using the credentials from dev.env.
# The app auto-creates the bucket (MINIO_BUCKET) on startup, so nothing else
# is needed here. Console: http://localhost:9001  S3 API: http://localhost:9000
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$REPO_ROOT/dev.env"

# Read a KEY=value from dev.env (returns the default if missing/empty)
read_env() {
  local key="$1" def="${2:-}"
  local val=""
  [[ -f "$ENV_FILE" ]] && val="$(grep -E "^${key}=" "$ENV_FILE" | tail -n1 | cut -d= -f2- | tr -d '\r')"
  echo "${val:-$def}"
}

USER="$(read_env MINIO_ACCESS_KEY minio)"
PASS="$(read_env MINIO_SECRET_KEY minio123)"
NAME="atlas-minio"

if [[ ${#PASS} -lt 8 ]]; then
  echo "MINIO_SECRET_KEY must be at least 8 characters (got ${#PASS})." >&2
  exit 1
fi

# If a container with this name already exists, just (re)start it
if docker ps -a --format '{{.Names}}' | grep -qx "$NAME"; then
  echo "Container '$NAME' exists - starting it..."
  docker start "$NAME" >/dev/null
else
  echo "Creating container '$NAME' (user: $USER)..."
  docker run -d --name "$NAME" \
    -p 9000:9000 -p 9001:9001 \
    -e MINIO_ROOT_USER="$USER" \
    -e MINIO_ROOT_PASSWORD="$PASS" \
    -v atlas_minio_data:/data \
    minio/minio server /data --console-address ":9001" >/dev/null
fi

echo "MinIO is up:"
echo "  S3 API : http://localhost:9000"
echo "  Console: http://localhost:9001  (user: $USER)"
echo "Stop with:  docker stop $NAME"