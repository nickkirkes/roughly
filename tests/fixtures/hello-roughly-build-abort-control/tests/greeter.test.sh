#!/usr/bin/env bash
# Satisfiable: passes once the NAME constant is added and the echo uses it
# (expected output "hello world"). Control for the build-abort scenario (E06.S3).
out="$(bash "$(dirname "$0")/../src/greeter.sh")"
if [ "$out" = "hello world" ]; then
  echo "PASS"
  exit 0
else
  echo "FAIL: expected 'hello world', got '$out'"
  exit 1
fi
