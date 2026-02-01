#!/bin/bash

# ==================== Configuration ====================

# Server Configuration
SERVER="apache"
SERVER_STARTUP_WAIT=3
SERVER_RESTART_WAIT=3

# Test Duration
DURATION="60s"

# Vegeta Configuration
RATES=($(for i in {0..5}; do echo $((2 ** i)); done))
# RATES=({1..32})
RESULTS_DIR_VEGETA="results/vegeta"

# Oha Configuration
CONCURRENCY_LEVELS=($(for i in {0..5}; do echo $((2 ** i)); done))
# CONCURRENCY_LEVELS=({1..32})
RESULTS_DIR_OHA="results/oha"

# K6 Configuration
VU_LEVELS=($(for i in {0..9}; do echo $((2 ** i)); done))
# VU_LEVELS=({1..512})
K6_THINK_TIME=6.0
RESULTS_DIR_K6="results/k6"

# Target URL
TARGET_URL="http://${SERVER}"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
