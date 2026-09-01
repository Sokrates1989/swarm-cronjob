#!/usr/bin/env bash

# Renders the controller and sample job stacks to reject mutable images.

set -Eeuo pipefail

REPOSITORY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPOSITORY_ROOT
TEMP_DIR="$(mktemp -d)"
readonly TEMP_DIR
readonly ENV_FILE="${TEMP_DIR}/cron.env"

# Removes private temporary render inputs on every exit path.
cleanup() {
  rm -rf -- "$TEMP_DIR"
}
trap cleanup EXIT

command -v docker >/dev/null 2>&1 || {
  echo "Error: docker is required to render the stack files." >&2
  exit 1
}
docker compose version >/dev/null 2>&1 || {
  echo "Error: the Docker Compose plugin is required." >&2
  exit 1
}

cat >"$ENV_FILE" <<'EOF'
STACK_NAME=swarm_cronjob
IMAGE_NAME=crazymax/swarm-cronjob
IMAGE_VERSION=1.16.0
TZ=Europe/Berlin
LOG_LEVEL=info
LOG_JSON=false
EOF

controller_render="${TEMP_DIR}/controller.yml"
sample_render="${TEMP_DIR}/sample.yml"
docker compose --env-file "$ENV_FILE" \
  -f "${REPOSITORY_ROOT}/swarm-compose.yml" config >"$controller_render"
docker compose -f "${REPOSITORY_ROOT}/test/test-stack.yml" \
  config >"$sample_render"

grep -q 'image: crazymax/swarm-cronjob:1.16.0' "$controller_render"
grep -q '/var/run/docker.sock:/var/run/docker.sock:ro' \
  "${REPOSITORY_ROOT}/swarm-compose.yml"
grep -q 'image: busybox:1.37.0' "$sample_render"
if grep -Eq ':latest([[:space:]]|$)' "$controller_render" "$sample_render"; then
  echo "Error: a rendered stack contains a mutable latest image." >&2
  exit 1
fi

echo "PASS: swarm-cronjob stack files use reviewed image versions."
