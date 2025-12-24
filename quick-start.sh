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
source "${QUICKSTART_ROOT}/setup/modules/menu_handlers.sh"

main() {
  show_main_menu
}

main
