#!/bin/bash
#
# quick-start.sh
#
# Simple helper to configure and deploy the swarm-cronjob controller stack.
# Supports two modes:
#   1) Edit .env manually
#   2) Guided prompts to update key values
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

ENV_FILE=".env"
COMPOSE_FILE="swarm-compose.yml"

# --- Helpers ---------------------------------------------------------------

ensure_docker() {
  echo "🔍 Checking Docker installation..."
  if ! command -v docker >/dev/null 2>&1; then
    echo "❌ Docker is not installed. Please install Docker first." >&2
    exit 1
  fi
  if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker daemon is not running. Please start Docker." >&2
    exit 1
  fi
}

ensure_env_file() {
  if [ -f "$ENV_FILE" ]; then
    return
  fi

  if [ -f ".env.template" ]; then
    cp .env.template "$ENV_FILE"
    echo "📄 Created $ENV_FILE from .env.template"
  else
    cat >"$ENV_FILE" <<'EOF'
STACK_NAME=swarm_cronjob
IMAGE_NAME=crazymax/swarm-cronjob
IMAGE_VERSION=latest
TZ=Europe/Berlin
LOG_LEVEL=info
LOG_JSON=false
EOF
    echo "📄 Created $ENV_FILE with default values"
  fi
}

get_env_value() {
  local key="$1"
  local default="$2"
  local value
  value=$(grep -E "^${key}=" "$ENV_FILE" 2>/dev/null | head -n1 | cut -d'=' -f2-)
  value="${value:-$default}"
  echo "$value" | tr -d '"'
}

update_env_value() {
  local key="$1"
  local value="$2"

  if grep -qE "^${key}=" "$ENV_FILE" 2>/dev/null; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
    else
      sed -i "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
    fi
  else
    echo "${key}=${value}" >>"$ENV_FILE"
  fi
}

choose_editor() {
  if [ -n "$EDITOR" ]; then
    echo "$EDITOR"
    return
  fi
  if command -v nano >/dev/null 2>&1; then
    echo "nano"
  else
    echo "vi"
  fi
}

edit_env_manually() {
  echo ""
  echo "📝 Opening $ENV_FILE for manual editing"
  local editor
  editor=$(choose_editor)
  echo "Using editor: $editor"
  "$editor" "$ENV_FILE"
}

guided_setup() {
  echo ""
  echo "🧩 Guided configuration for swarm-cronjob"
  echo "-----------------------------------------"

  local cur_stack cur_image_name cur_image_version cur_tz cur_log_level cur_log_json
  cur_stack=$(get_env_value STACK_NAME "swarm_cronjob")
  cur_image_name=$(get_env_value IMAGE_NAME "crazymax/swarm-cronjob")
  cur_image_version=$(get_env_value IMAGE_VERSION "latest")
  cur_tz=$(get_env_value TZ "Europe/Berlin")
  cur_log_level=$(get_env_value LOG_LEVEL "info")
  cur_log_json=$(get_env_value LOG_JSON "false")

  read -p "Stack name [$cur_stack]: " val
  update_env_value STACK_NAME "${val:-$cur_stack}"

  read -p "Image name [$cur_image_name]: " val
  update_env_value IMAGE_NAME "${val:-$cur_image_name}"

  read -p "Image version [$cur_image_version]: " val
  update_env_value IMAGE_VERSION "${val:-$cur_image_version}"

  read -p "Timezone TZ [$cur_tz]: " val
  update_env_value TZ "${val:-$cur_tz}"

  read -p "Log level [$cur_log_level]: " val
  update_env_value LOG_LEVEL "${val:-$cur_log_level}"

  read -p "Log JSON (true/false) [$cur_log_json]: " val
  update_env_value LOG_JSON "${val:-$cur_log_json}"

  echo ""
  echo "✅ Updated $ENV_FILE"
}

show_current_config() {
  local stack image_name image_version tz log_level log_json
  stack=$(get_env_value STACK_NAME "swarm_cronjob")
  image_name=$(get_env_value IMAGE_NAME "crazymax/swarm-cronjob")
  image_version=$(get_env_value IMAGE_VERSION "latest")
  tz=$(get_env_value TZ "Europe/Berlin")
  log_level=$(get_env_value LOG_LEVEL "info")
  log_json=$(get_env_value LOG_JSON "false")

  echo "📋 Current configuration"
  echo "========================"
  echo "Stack name:   $stack"
  echo "Image:        $image_name:$image_version"
  echo "TZ:           $tz"
  echo "LOG_LEVEL:    $log_level"
  echo "LOG_JSON:     $log_json"
  echo ""
}

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

# --- Main ------------------------------------------------------------------

ensure_env_file

while true; do
  echo ""
  show_current_config
  echo "Choose an option:"
  echo "1) Edit .env manually"
  echo "2) Guided configuration"
  echo "3) Deploy / update swarm-cronjob stack"
  echo "4) Show stack status"
  echo "5) Remove stack"
  echo "6) Exit"
  echo ""
  read -p "Your choice (1-6): " choice

  case "$choice" in
    1) edit_env_manually ;;
    2) guided_setup ;;
    3) deploy_stack ;;
    4) show_status ;;
    5) remove_stack ;;
    6) echo ""; echo "👋 Goodbye!"; exit 0 ;;
    *) echo "❌ Invalid choice" ;;
  esac
done
