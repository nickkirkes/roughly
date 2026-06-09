#!/usr/bin/env bash
# Satisfiable test — passes once the task (add NAME constant, echo uses it) is applied.
out="$(bash "$(dirname "$0")/../src/greeter.sh")"
if [ "$out" = "hello world" ]; then
  echo "PASS"; exit 0
else
  echo "FAIL: expected 'hello world', got '$out'"; exit 1
fi
