#!/bin/bash

# ==================== Utility Functions ====================

print_message() {
  local color=$1
  shift
  echo -e "${color}$@${NC}"
}

print_separator() {
  echo "============================================================"
}

# Get cpuset from running container using docker inspect
get_runtime_cpuset() {
  docker inspect --format='{{.HostConfig.CpusetCpus}}' "$1" 2>/dev/null || echo ""
}
