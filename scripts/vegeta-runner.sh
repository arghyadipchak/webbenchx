#!/bin/bash

# ==================== Vegeta Test Functions ====================

run_vegeta_attack() {
  local rate=$1
  local output_file=$2

  echo "GET $TARGET_URL" | docker compose run --rm vegeta attack \
    -duration=$DURATION \
    -rate=$rate \
    >"$output_file"
}

generate_text_report() {
  local input_file=$1

  docker compose run --rm vegeta report \
    -type=text \
    <"$input_file"
}

generate_json_report() {
  local input_file=$1
  local output_file=$2

  docker compose run --rm vegeta report \
    -type=json \
    <"$input_file" \
    >"$output_file"
}

# Run complete test for a single rate with CPU monitoring
run_test_for_rate() {
  local rate=$1
  local test_num=$2
  local total_tests=$3

  local bin_file="${RESULTS_DIR}/${rate}rps.bin"
  local json_file="${RESULTS_DIR}/${rate}rps.json"
  local csv_file="${RESULTS_DIR}/${rate}rps-cpu.csv"

  print_separator
  print_message "$GREEN" "Test $test_num/$total_tests: Load test at ${rate} RPS"
  print_separator

  echo "Attack parameters:"
  echo "  - Duration: $DURATION"
  echo "  - Rate: $rate requests/second"
  echo "  - Target: GET $TARGET_URL"
  echo "  - Output: $bin_file"
  if [ -n "$CPUSET" ]; then
    echo "  - CPU Monitor: $csv_file (cpuset: $CPUSET)"
  fi
  echo ""

  local cpumon_pid=""
  if [ -n "$CPUSET" ]; then
    print_message "$YELLOW" "Starting CPU monitor..."
    cpumon -f csv $CPUSET >"$csv_file" &
    cpumon_pid=$!
    sleep 1
  fi

  print_message "$YELLOW" "Running Vegeta attack..."
  run_vegeta_attack "$rate" "$bin_file"

  if [ -n "$cpumon_pid" ]; then
    print_message "$YELLOW" "Stopping CPU monitor..."
    kill $cpumon_pid 2>/dev/null || true
    wait $cpumon_pid 2>/dev/null || true
  fi

  print_message "$YELLOW" "Generating text report..."
  generate_text_report "$bin_file"

  print_message "$YELLOW" "Generating JSON report..."
  generate_json_report "$bin_file" "$json_file"

  print_message "$GREEN" "✓ Test at ${rate} RPS completed"
  print_message "$GREEN" "  Results: $bin_file, $json_file, $csv_file"
  echo ""
}
