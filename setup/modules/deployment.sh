#!/bin/bash

# Guard: prevent loading this module multiple times
if [[ -n "${CRONJOB_DEPLOYMENT_MODULE_LOADED:-}" ]]; then
  return
fi

: "${QUICKSTART_ROOT:?QUICKSTART_ROOT is not set}"

deploy_stack() {
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
  docker stack deploy -c "$COMPOSE_FILE" "$stack_name"
}

remove_stack() {
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
