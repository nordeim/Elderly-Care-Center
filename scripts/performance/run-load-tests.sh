#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: run-load-tests.sh [--scenario booking|payments|cdn|notifications|all] [--vus N] [--duration 5m]

Runs predefined k6 load test scenarios and stores reports under storage/load-tests/.
EOF
}

SCENARIO="all"
VUS="50"
DURATION="15m"
K6_SCRIPT="ops/performance/k6/scenarios.js"
OUTPUT_DIR="storage/load-tests"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scenario)
      SCENARIO="$2"
      shift 2
      ;;
    --vus)
      VUS="$2"
      shift 2
      ;;
    --duration)
      DURATION="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ ! -f "$K6_SCRIPT" ]]; then
  echo "k6 script not found at $K6_SCRIPT" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
RESULT_FILE="$OUTPUT_DIR/${SCENARIO}-${TIMESTAMP}.json"

k6 run "$K6_SCRIPT" \
  --vus "$VUS" \
  --duration "$DURATION" \
  --summary-export "$RESULT_FILE" \
  --tag scenario="$SCENARIO"

echo "Load test results saved to $RESULT_FILE"
