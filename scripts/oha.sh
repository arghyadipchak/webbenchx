#!/bin/bash

set -e

# ==================== Setup ====================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Export host user ID for docker-compose
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)

# Source component scripts
source "${SCRIPT_DIR}/config.sh"
source "${SCRIPT_DIR}/utils.sh"
source "${SCRIPT_DIR}/server.sh"
source "${SCRIPT_DIR}/oha-runner.sh"

# Oha-specific configuration
CONCURRENCY_LEVELS=("${CONCURRENCY_LEVELS[@]}")

# Override results directory for Oha
RESULTS_DIR="${RESULTS_DIR:-$RESULTS_DIR_OHA}"

# ==================== Cleanup ====================

cleanup() {
  print_message "$YELLOW" "\n[Cleanup] Stopping any running cpumon processes..."
  pkill -f "cpumon -f csv" 2>/dev/null || true
  print_message "$YELLOW" "[Cleanup] Stopping ${SERVER} server..."
  stop_server
  print_message "$GREEN" "Cleanup completed."
}

trap cleanup EXIT INT TERM

# ==================== Main Execution ====================

main() {
  print_separator
  print_message "$GREEN" "Starting ${SERVER} Load Test with Oha"
  print_separator

  mkdir -p "$RESULTS_DIR"

  # Start server and verify
  print_message "$YELLOW" "\n[Setup] Starting ${SERVER} server..."
  start_server
  verify_server

  # Auto-detect cpuset from running container
  print_message "$YELLOW" "Detecting ${SERVER} container cpuset..."
  CPUSET=$(get_runtime_cpuset "$SERVER")
  if [ -n "$CPUSET" ]; then
    print_message "$GREEN" "✓ Detected runtime cpuset: $CPUSET"
  else
    print_message "$RED" "✗ Could not detect cpuset from container"
    print_message "$RED" "  CPU monitoring will be skipped"
  fi
  echo ""

  # Run tests at each concurrency level
  local total_tests=${#CONCURRENCY_LEVELS[@]}
  local current_test=0

  for concurrency in "${CONCURRENCY_LEVELS[@]}"; do
    current_test=$((current_test + 1))

    # Restart server between tests to ensure clean state
    if [ $current_test -gt 1 ]; then
      print_message "$YELLOW" "\n[Between Tests] Restarting ${SERVER}..."
      restart_server
      verify_server
    fi

    run_test_for_concurrency "$concurrency" "$current_test" "$total_tests"
  done

  # Print summary
  print_separator
  print_message "$GREEN" "All load tests completed successfully!"
  print_message "$GREEN" "Results saved to $RESULTS_DIR/ directory:"
  for concurrency in "${CONCURRENCY_LEVELS[@]}"; do
    print_message "$GREEN" "  - $RESULTS_DIR/${concurrency}c.json"
    if [ -n "$CPUSET" ]; then
      print_message "$GREEN" "  - $RESULTS_DIR/${concurrency}c-cpu.csv"
    fi
  done
  print_separator
}

main
