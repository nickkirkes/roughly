#!/usr/bin/env bash
set -euo pipefail
OUT="$(bash "$(dirname "$0")/../src/greeter.sh")"
if [ -z "$OUT" ]; then
  echo "FAIL: greeter produced empty output" >&2
  exit 1
fi
echo "PASS: greeter produced non-empty output"
