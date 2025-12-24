#!/bin/bash

# Guard: prevent loading this module multiple times
if [[ -n "${CRONJOB_MENU_MODULE_LOADED:-}" ]]; then
  return
fi

: "${QUICKSTART_ROOT:?QUICKSTART_ROOT is not set}"

# show_main_menu
# Displays the interactive main menu and dispatches to action handlers.
show_main_menu() {
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
    echo "6) Deploy test service (cron demo)"
    echo "7) View logs of test service (cron demo)"
    echo "8) Remove test service (cron demo)"
    echo ""
    echo "9) Exit"
    echo ""
    read -p "Your choice (1-9): " choice

    case "$choice" in
      1) edit_env_manually ;;
      2) guided_setup ;;
      3) deploy_stack ;;
      4) show_status ;;
      5) remove_stack ;;
      6) deploy_test_service ;;
      7) view_test_logs ;;
      8) remove_test_service ;;
      9) echo ""; echo "👋 Goodbye!"; exit 0 ;;
      *) echo "❌ Invalid choice" ;;
    esac
  done
}

CRONJOB_MENU_MODULE_LOADED=1
