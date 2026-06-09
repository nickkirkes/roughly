#!/usr/bin/env bash
# Satisfiable test — passes once the task is applied: a SINGLE echo line prints
# the greeting word "world" twice (e.g. "hello world, goodbye world"). Asserts the
# two occurrences land on the SAME line (grep for world…world within one line) —
# that co-located shape is what the plan-revision recovery is built around; two
# "world"s on separate lines would satisfy a naive count but NOT exercise the
# same-line co-location hazard, so this test rejects it.
out="$(bash "$(dirname "$0")/../src/greeter.sh")"
if printf '%s\n' "$out" | grep -q 'world.*world'; then
  echo "PASS"; exit 0
else
  echo "FAIL: expected a single line printing 'world' twice, got: '$out'"; exit 1
fi
