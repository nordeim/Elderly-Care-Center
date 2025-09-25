#!/usr/bin/env bash
set -euo pipefail

FILE_PATH="$1"

if [[ -z "${FILE_PATH}" ]]; then
  echo "Usage: $0 <file-path>" >&2
  exit 64
fi

if ! command -v clamscan >/dev/null 2>&1; then
  echo "clamscan not installed; skipping scan" >&2
  exit 0
fi

clamscan --stdout --no-summary "${FILE_PATH}"
