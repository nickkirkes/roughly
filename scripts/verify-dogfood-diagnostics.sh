#!/usr/bin/env bash
# E07.S1 AC1 (issue #94) — stub-injection verification harness for the account-state
# diagnostic ladder in scripts/ci-dogfood.sh (classify_account_state + the
# account-state rung in both the smoke and plugin-load failure ladders).
#
# Cost: ZERO. A fake `claude` binary is put on PATH ahead of the real one, so
# no request ever reaches the Anthropic API — safe to run anytime, as often
# as you like, with no ANTHROPIC_API_KEY billing implications (the key value
# used below is a placeholder string, never a real credential).
#
# Runtime: ~1-3 minutes. This runs the REAL scripts/ci-dogfood.sh end-to-end,
# six times in sequence, one per case below. Each run pays its own `git
# worktree add`/`remove` (ci-dogfood.sh's stale-worktree guard makes repeated
# same-SHA runs safe), which dominates the wall-clock cost since the stubbed
# `claude` itself returns instantly.
#
# IMPORTANT — this harness tests UNCOMMITTED changes to ci-dogfood.sh. We
# invoke it as `bash "$ROOT/scripts/ci-dogfood.sh"` (by path, not by SHA/
# worktree contents). Bash opens that file descriptor at invocation and keeps
# reading from it even after the script internally `cd`s into its own ephemeral
# worktree — so this harness exercises the working-tree copy of ci-dogfood.sh,
# not the committed-at-HEAD copy. That is exactly what makes it useful during
# development: edit ci-dogfood.sh, rerun this harness, see the effect
# immediately, with no commit required.
#
# What each case proves:
#   1 (smoke,  insufficient credit)      -> smoke-step account-state marker fires
#   2 (smoke,  invalid/revoked key)      -> smoke-step account-state marker fires
#   3 (smoke,  rate limited)             -> smoke-step account-state marker fires
#   4 (smoke,  unrelated TypeError)      -> NEGATIVE CONTROL: a non-account
#                                            failure produces the existing
#                                            generic "smoke step claude exited"
#                                            ladder, NOT an account-state marker
#   5 (plugin, insufficient credit)      -> plugin-load-step account-state marker fires
#   6 (plugin, unrelated TypeError)      -> NEGATIVE CONTROL: a non-account
#                                            failure produces the existing
#                                            generic "plugin-load step claude
#                                            exited" ladder, NOT an account-
#                                            state marker
#
# Cases 4 and 6 are the discriminating negative controls: without them, this
# suite would pass just as well against a classifier that fires on every
# failure (a classify_account_state that always matches). They prove the
# generic non-account-failure ladder still fires unmodified.
#
# All six cases set STUB_EXIT=1 (non-zero, non-124) so the classification and
# generic rungs fire deterministically. This harness deliberately does NOT
# assert against the 124 timeout rung — a sleeping stub is out of scope for
# this AC.

set -uo pipefail

ROOT="$(git rev-parse --show-toplevel)" || { echo "FAIL: not in a git repo"; exit 1; }

# ── scratch dir + stub `claude` ─────────────────────────────────────────────
SCRATCH="$(mktemp -d)" || { echo "FAIL: mktemp -d"; exit 1; }
trap 'rm -rf "$SCRATCH"' EXIT

cat > "$SCRATCH/claude" <<'STUBEOF'
#!/usr/bin/env bash
# Stub `claude` for verify-dogfood-diagnostics.sh — never contacts the API.
# Parses -p <prompt> from argv (all other flags/values are skipped verbatim);
# reads STUB_TARGET / STUB_TEXT / STUB_EXIT from the environment.
prompt=""
while [ $# -gt 0 ]; do
  case "$1" in
    -p)
      prompt="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

# Lets the smoke step pass (so a "plugin" case's run reaches the plugin-load
# step) while still letting the plugin-load step itself fail per STUB_TEXT/
# STUB_EXIT below.
if [ "${STUB_TARGET:-}" = "plugin" ] && [ "$prompt" != "/roughly:help" ]; then
  echo "ok"
  exit 0
fi

echo "${STUB_TEXT:-}"
exit "${STUB_EXIT:-1}"
STUBEOF
chmod +x "$SCRATCH/claude"

# ── run + assert helpers ────────────────────────────────────────────────────
PASS=0
FAILED=0

# run_stub <target> <text> <exit> — runs the real ci-dogfood.sh with the stub
# claude on PATH, capturing combined output and exit code. Uses the
# `&& X=0 || X=$?` idiom (not a direct assignment) so a non-zero exit from
# ci-dogfood.sh cannot kill THIS script under set -e-style death — it can't
# here since we deliberately did not set -e, but the idiom is kept for
# parity with ci-dogfood.sh's own documented convention and to guarantee the
# real exit code is captured rather than lost to a pipeline/subshell quirk.
run_stub() {
  local target=$1 text=$2 exit_code=$3
  OUT="$(PATH="$SCRATCH:$PATH" ANTHROPIC_API_KEY=stub-key-not-real \
      STUB_TARGET="$target" STUB_TEXT="$text" STUB_EXIT="$exit_code" \
      bash "$ROOT/scripts/ci-dogfood.sh" 2>&1)" && RUN_EXIT=0 || RUN_EXIT=$?
}

assert_contains() {
  local case_id=$1 needle=$2
  if printf '%s\n' "$OUT" | grep -qF -- "$needle"; then
    echo "PASS case $case_id: output contains \"$needle\""
    PASS=$((PASS+1))
  else
    echo "FAIL case $case_id: output missing \"$needle\""
    FAILED=$((FAILED+1))
  fi
}

assert_not_contains() {
  local case_id=$1 needle=$2
  if printf '%s\n' "$OUT" | grep -qF -- "$needle"; then
    echo "FAIL case $case_id: output unexpectedly contains \"$needle\""
    FAILED=$((FAILED+1))
  else
    echo "PASS case $case_id: output does not contain \"$needle\""
    PASS=$((PASS+1))
  fi
}

assert_exit_nonzero() {
  local case_id=$1
  if [ "$RUN_EXIT" -ne 0 ]; then
    echo "PASS case $case_id: run exited non-zero ($RUN_EXIT)"
    PASS=$((PASS+1))
  else
    echo "FAIL case $case_id: run exited zero, expected non-zero"
    FAILED=$((FAILED+1))
  fi
}

# ── cases ────────────────────────────────────────────────────────────────────

echo "=== case 1: smoke / insufficient credit ==="
run_stub smoke "Credit balance is too low" 1
assert_contains 1 "API account state: insufficient credit"
assert_exit_nonzero 1

echo "=== case 2: smoke / invalid or revoked API key ==="
run_stub smoke "Invalid API key · Please run /login" 1
assert_contains 2 "API account state: invalid or revoked API key"
assert_exit_nonzero 2

echo "=== case 3: smoke / rate limited ==="
run_stub smoke "rate_limit_error: too many requests" 1
assert_contains 3 "API account state: rate limited"
assert_exit_nonzero 3

echo "=== case 4: smoke / unrelated failure — NEGATIVE CONTROL ==="
# Discriminating negative control: a non-account-state failure must fall
# through to the pre-existing generic ladder, not be misclassified as an
# account-state issue. Without this case (and case 6), a classifier that
# fires on every failure would pass this suite just as well as a correct one.
run_stub smoke "TypeError: cannot read property of undefined" 1
assert_contains 4 "smoke step claude exited"
assert_not_contains 4 "API account state"
assert_exit_nonzero 4

echo "=== case 5: plugin-load / insufficient credit ==="
run_stub plugin "Credit balance is too low" 1
assert_contains 5 "API account state: insufficient credit"
assert_exit_nonzero 5

echo "=== case 6: plugin-load / unrelated failure — NEGATIVE CONTROL ==="
# Discriminating negative control (plugin-load side): same rationale as case
# 4 — proves the generic "plugin-load step claude exited" ladder still fires
# unmodified for a non-account failure, and no account-state marker leaks in.
run_stub plugin "TypeError: cannot read property of undefined" 1
assert_contains 6 "plugin-load step claude exited"
assert_not_contains 6 "API account state"
assert_exit_nonzero 6

echo "---"
echo "assertions passed: $PASS, failed: $FAILED"
[ "$FAILED" -eq 0 ] || exit 1
