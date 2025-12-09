#!/bin/bash
#
# quick-start.sh
#
# Simple helper to configure and deploy the swarm-cronjob controller stack.
# Uses small modules under setup/modules for maintainability.

set -e

export QUICKSTART_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$QUICKSTART_ROOT"

ENV_FILE=".env"
COMPOSE_FILE="swarm-compose.yml"
TEST_COMPOSE_FILE="test/test-stack.yml"

# Load modules
source "${QUICKSTART_ROOT}/setup/modules/docker.sh"
source "${QUICKSTART_ROOT}/setup/modules/config.sh"
source "${QUICKSTART_ROOT}/setup/modules/deployment.sh"
source "${QUICKSTART_ROOT}/setup/modules/test.sh"

main() {
  ensure_env_file

  while true; do
    echo ""
    show_current_config
    echo "Choose an option:"
    echo "1) Edit .env manually"
    echo "2) Guided configuration"
    echo ""
    echo "3) Deploy / update swarm-cronjob stack"
    echo "4) Show stack status"
    echo "5) Remove stack"
    echo ""
    echo "6) Test service menu (cron demo)"
    echo ""
    echo "7) Exit"
    echo ""
    read -p "Your choice (1-7): " choice

    case "$choice" in
      1) edit_env_manually ;;
      2) guided_setup ;;
      3) deploy_stack ;;
      4) show_status ;;
      5) remove_stack ;;
      6) test_menu ;;
      7) echo ""; echo "👋 Goodbye!"; exit 0 ;;
      *) echo "❌ Invalid choice" ;;
    esac
  done
}

main
