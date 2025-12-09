#!/bin/bash

# Guard: prevent loading this module multiple times
if [[ -n "${CRONJOB_TEST_MODULE_LOADED:-}" ]]; then
  return
fi

: "${QUICKSTART_ROOT:?QUICKSTART_ROOT is not set}"

deploy_test_service() {
  ensure_docker
  ensure_env_file

  if [ ! -f "$TEST_COMPOSE_FILE" ]; then
    echo "❌ Test compose file '$TEST_COMPOSE_FILE' not found."
    echo "   Make sure the repository is intact."
    return 1
  fi

  local base_stack test_stack
  base_stack=$(get_env_value STACK_NAME "swarm_cronjob")
  test_stack="${base_stack}_test"

  echo ""
  echo "🚀 Deploying test stack '$test_stack' using $TEST_COMPOSE_FILE"
  echo "   This defines a simple busybox service that logs once per minute via swarm-cronjob."
  echo ""
  docker stack deploy -c "$TEST_COMPOSE_FILE" "$test_stack"
}

view_test_logs() {
  ensure_docker
  ensure_env_file

  local base_stack test_stack service_name
  base_stack=$(get_env_value STACK_NAME "swarm_cronjob")
  test_stack="${base_stack}_test"
  service_name="${test_stack}_swarm-cronjob-test"

  if ! docker service ps "$service_name" >/dev/null 2>&1; then
    echo ""
    echo "❌ Test service '$service_name' not found."
    echo "   Deploy the test stack first from the test menu (option 1)."
    return 1
  fi

  echo ""
  echo "⏱  The test job is scheduled to run once per minute."
  echo "   Please wait at least 2 minutes before expecting multiple log entries."
  echo ""
  echo "👀 Now streaming logs for service '$service_name'."
  echo "   Press Ctrl+C at any time to stop watching the logs."
  echo ""

  docker service logs -f "$service_name"
}

remove_test_service() {
  ensure_docker
  ensure_env_file

  local base_stack test_stack
  base_stack=$(get_env_value STACK_NAME "swarm_cronjob")
  test_stack="${base_stack}_test"

  echo ""
  read -p "Remove test stack '$test_stack'? (y/N): " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    return
  fi

  docker stack rm "$test_stack" || true
  echo "✅ Removal of test stack requested. Wait for services to stop."
}

test_menu() {
  while true; do
    echo ""
    echo "🧪 Test service menu (cron demo)"
    echo "------------------------------"
    echo "1) Deploy test service"
    echo "2) View logs of test service"
    echo "3) Remove test service"
    echo "4) Back to main menu"
    echo ""
    read -p "Your choice (1-4): " tchoice

    case "$tchoice" in
      1) deploy_test_service ;;
      2) view_test_logs ;;
      3) remove_test_service ;;
      4) break ;;
      *) echo "❌ Invalid choice" ;;
    esac
  done
}

CRONJOB_TEST_MODULE_LOADED=1
