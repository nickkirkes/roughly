#!/usr/bin/env bash
# Intentionally unsatisfiable: asserts the greeter output equals two distinct
# strings at once. No possible src/greeter.sh can satisfy this — every build
# attempt fails Verify, exhausting the Stage 5c auto-fix cap (E06.S3 AC1).
out="$(bash "$(dirname "$0")/../src/greeter.sh")"
if [ "$out" = "hello world" ] && [ "$out" = "goodbye world" ]; then
  echo "PASS"
  exit 0
else
  echo "FAIL: unsatisfiable assertion (output cannot equal two distinct strings)"
  exit 1
fi
