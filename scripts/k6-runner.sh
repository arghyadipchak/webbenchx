#!/bin/bash

# ==================== K6 Test Functions ====================

run_k6_attack() {
  local vus=$1
  local output_file=$2
  local think_time=$3

  docker compose run --rm \
    -e K6_DURATION="$DURATION" \
    -e K6_VUS="$vus" \
    -e TARGET_URL="$TARGET_URL" \
    -e K6_THINK_TIME="$think_time" \
    k6 run \
    --out json="/results/$(basename "$output_file")" \
    --summary-export="/results/$(basename "${output_file%.json}-summary.json")" \
    /scripts/k6-test.js
}

generate_text_report() {
  local json_file=$1
  local summary_file="${json_file%.json}-summary.json"

  print_message "$YELLOW" "Summary from K6 report:"
  if command -v jq &>/dev/null && [ -f "$summary_file" ]; then
    cat "$summary_file" | jq -r '
      "
  HTTP Request Duration:
    min:     \(.metrics.http_req_duration.values.min)ms
    avg:     \(.metrics.http_req_duration.values.avg)ms
    med:     \(.metrics.http_req_duration.values.med)ms
    max:     \(.metrics.http_req_duration.values.max)ms
    p(90):   \(.metrics.http_req_duration.values["p(90)"])ms
    p(95):   \(.metrics.http_req_duration.values["p(95)"])ms
    p(99):   \(.metrics.http_req_duration.values["p(99)"])ms

  Requests:
    total:   \(.metrics.http_reqs.values.count)
    rate:    \(.metrics.http_reqs.values.rate)/s
    failed:  \(.metrics.http_req_failed.values.rate * 100)%

  VUs:
    min:     \(.metrics.vus.values.min)
    max:     \(.metrics.vus.values.max)
      "
    '
  else
    if [ ! -f "$summary_file" ]; then
      print_message "$YELLOW" "  (Summary file not found)"
    else
      print_message "$YELLOW" "  (Install jq for formatted summary)"
      head -20 "$summary_file"
    fi
  fi
}

# Run complete test for a single VU level with CPU monitoring
run_test_for_vus() {
  local vus=$1
  local test_num=$2
  local total_tests=$3

  local json_file="${RESULTS_DIR}/${vus}vu.json"
  local summary_file="${RESULTS_DIR}/${vus}vu-summary.json"
  local cpu_csv_file="${RESULTS_DIR}/${vus}vu-cpu.csv"

  print_separator
  print_message "$GREEN" "Test $test_num/$total_tests: Load test with ${vus} virtual users"
  print_separator

  echo "Attack parameters:"
  echo "  - Duration: $DURATION"
  echo "  - Virtual Users: $vus"
  echo "  - Think time: ${K6_THINK_TIME}s"
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

  print_message "$YELLOW" "Running K6 attack..."
  run_k6_attack "$vus" "$json_file" "$K6_THINK_TIME"

  if [ -n "$cpumon_pid" ]; then
    print_message "$YELLOW" "Stopping CPU monitor..."
    kill $cpumon_pid 2>/dev/null || true
    wait $cpumon_pid 2>/dev/null || true
  fi

  print_message "$YELLOW" "Generating text summary..."
  generate_text_report "$json_file"

  print_message "$GREEN" "✓ Test with ${vus} VUs completed"
  print_message "$GREEN" "  Results: $json_file, $summary_file"
  if [ -n "$CPUSET" ]; then
    print_message "$GREEN" "  CPU data: $cpu_csv_file"
  fi
  echo ""
}
