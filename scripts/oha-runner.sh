#!/bin/bash

# ==================== Oha Test Functions ====================

run_oha_attack() {
  local concurrency=$1
  local output_file=$2

  docker compose run --rm oha \
    -z "$DURATION" \
    -c "$concurrency" \
    --no-tui \
    --output-format=json \
    --output "/results/$(basename "$output_file")" \
    "$TARGET_URL"
}

generate_text_report() {
  local json_file=$1

  print_message "$YELLOW" "Summary from JSON report:"
  if command -v jq &>/dev/null; then
    cat "$json_file" | jq -r '
      "
  Success rate:    \(.summary.successRate * 100)%
  Total requests:  \(.summary.total)
  Slowest:         \(.summary.slowest)s
  Fastest:         \(.summary.fastest)s
  Average:         \(.summary.average)s
  Requests/sec:    \(.summary.requestsPerSec)
      "
    '
  else
    print_message "$YELLOW" "  (Install jq for formatted summary)"
    head -20 "$json_file"
  fi
}

# Run complete test for a single concurrency level with CPU monitoring
run_test_for_concurrency() {
  local concurrency=$1
  local test_num=$2
  local total_tests=$3

  local json_file="${RESULTS_DIR}/${concurrency}c.json"
  local cpu_csv_file="${RESULTS_DIR}/${concurrency}c-cpu.csv"

  print_separator
  print_message "$GREEN" "Test $test_num/$total_tests: Load test with ${concurrency} concurrent connections"
  print_separator

  echo "Attack parameters:"
  echo "  - Duration: $DURATION"
  echo "  - Concurrency: $concurrency connections"
  echo "  - Target: $TARGET_URL"
  echo "  - Output: $json_file"
  if [ -n "$CPUSET" ]; then
    echo "  - CPU Monitor: $cpu_csv_file (cpuset: $CPUSET)"
  fi
  echo ""

  local cpumon_pid=""
  if [ -n "$CPUSET" ]; then
    print_message "$YELLOW" "Starting CPU monitor..."
    cpumon -f csv $CPUSET >"$cpu_csv_file" &
    cpumon_pid=$!
    sleep 1
  fi

  print_message "$YELLOW" "Running Oha attack..."
  run_oha_attack "$concurrency" "$json_file"

  if [ -n "$cpumon_pid" ]; then
    print_message "$YELLOW" "Stopping CPU monitor..."
    kill $cpumon_pid 2>/dev/null || true
    wait $cpumon_pid 2>/dev/null || true
  fi

  print_message "$YELLOW" "Generating text summary..."
  generate_text_report "$json_file"

  print_message "$GREEN" "✓ Test with ${concurrency} connections completed"
  print_message "$GREEN" "  Results: $json_file"
  if [ -n "$CPUSET" ]; then
    print_message "$GREEN" "  CPU data: $cpu_csv_file"
  fi
  echo ""
}
