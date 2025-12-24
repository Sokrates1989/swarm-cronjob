#!/bin/bash

# Guard: prevent loading this module multiple times
if [[ -n "${CRONJOB_DEPLOYMENT_MODULE_LOADED:-}" ]]; then
  return
fi

: "${QUICKSTART_ROOT:?QUICKSTART_ROOT is not set}"

deploy_stack() {
  # deploy_stack
  # Deploys the configured swarm-cronjob stack.
  # Notes:
  # - Renders the compose file through docker-compose/docker compose to resolve ${VAR} substitutions.
  ensure_docker
  ensure_env_file

  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a

  local stack_name
  stack_name="${STACK_NAME:-swarm_cronjob}"

  echo ""
  echo "🚀 Deploying stack '$stack_name' using $COMPOSE_FILE"
  echo ""

  local compose_cmd
  if command -v docker-compose >/dev/null 2>&1; then
    compose_cmd=(docker-compose)
  elif docker compose version >/dev/null 2>&1; then
    compose_cmd=(docker compose)
  else
    echo "[WARN] Neither docker-compose nor 'docker compose' is available. Deploying raw compose file (env substitution may be incomplete)." >&2
    docker stack deploy -c "$COMPOSE_FILE" "$stack_name"
    return
  fi

  local compose_env_opt=()
  if [ -f "$ENV_FILE" ]; then
    compose_env_opt=(--env-file "$ENV_FILE")
  fi

  docker stack deploy -c <("${compose_cmd[@]}" -f "$COMPOSE_FILE" "${compose_env_opt[@]}" config) "$stack_name"
}

remove_stack() {
  # remove_stack
  # Removes the configured stack after confirmation.
  ensure_docker
  ensure_env_file

  local stack
  stack=$(get_env_value STACK_NAME "swarm_cronjob")

  echo ""
  read -p "Remove stack '$stack'? (y/N): " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    return
  fi

  docker stack rm "$stack" || true
  echo "✅ Removal requested. Wait for services to stop."
}

show_status() {
  # show_status
  # Displays the current stack status (docker stack services).
  ensure_docker
  ensure_env_file
  local stack
  stack=$(get_env_value STACK_NAME "swarm_cronjob")

  echo ""
  echo "📊 Stack status for '$stack'"
  echo "----------------------------"
  docker stack services "$stack" 2>/dev/null || echo "(no services or stack not found)"
}

CRONJOB_DEPLOYMENT_MODULE_LOADED=1
