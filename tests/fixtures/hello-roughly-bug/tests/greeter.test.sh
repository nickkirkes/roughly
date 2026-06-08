#!/usr/bin/env bash
set -euo pipefail
OUT="$(bash "$(dirname "$0")/../src/greeter.sh")"
EXPECTED="hello world"
if [ "$OUT" != "$EXPECTED" ]; then
  echo "FAIL: expected '$EXPECTED', got '$OUT'" >&2
  exit 1
fi
echo "PASS: greeter output matches expected"
