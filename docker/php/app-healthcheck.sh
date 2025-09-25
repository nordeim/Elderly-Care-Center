#!/usr/bin/env bash
set -euo pipefail

# Fail fast if readiness marker missing
test -f /tmp/app.ready || exit 1

# HTTP health endpoint (fast path)
if command -v curl >/dev/null 2>&1; then
  curl -fsS "http://localhost:8000/healthz" >/dev/null || exit 1
else
  # Fallback TCP check
  nc -z localhost 8000 || exit 1
fi

exit 0
