#!/usr/bin/env bash
set -euo pipefail

# Fail fast if readiness marker missing
test -f /tmp/app.ready || exit 1

URL="${HEALTHCHECK_URL:-http://localhost:8000/healthz}"

if command -v curl >/dev/null 2>&1; then
  curl -fsS "$URL" >/dev/null || exit 1
else
  # Fallback TCP check
  nc -z localhost 8000 || exit 1
fi

exit 0

