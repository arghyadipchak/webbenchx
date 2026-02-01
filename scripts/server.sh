#!/bin/bash

# ==================== Server Management ====================

start_server() {
  print_message "$YELLOW" "Starting ${SERVER} server..."
  docker compose up -d $SERVER
  sleep $SERVER_STARTUP_WAIT
}

stop_server() {
  print_message "$YELLOW" "Stopping ${SERVER} server..."
  docker compose down $SERVER 2>/dev/null || true
}

restart_server() {
  print_message "$YELLOW" "Restarting ${SERVER} server..."
  docker compose restart $SERVER
  sleep $SERVER_RESTART_WAIT
}

verify_server() {
  print_message "$YELLOW" "Verifying ${SERVER} status..."
  if docker compose ps $SERVER | grep -q "Up"; then
    print_message "$GREEN" "✓ ${SERVER} is running"
    return 0
  else
    print_message "$RED" "✗ Warning: Could not verify ${SERVER} status"
    return 1
  fi
}
