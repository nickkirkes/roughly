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
# Runtime: ~2-5 minutes. This runs the REAL scripts/ci-dogfood.sh end-to-end,
# once per row in the CASES table below, in sequence. Each run pays its own
# `git worktree add`/`remove` (ci-dogfood.sh's stale-worktree guard makes
# repeated same-SHA runs safe), which dominates the wall-clock cost since the
# stubbed `claude` itself returns instantly.
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
# ── Case table format ───────────────────────────────────────────────────────
# Each row in CASES (below) is a single `|`-delimited string with fields:
#   target   | smoke | plugin
#   text     | stub `claude` stdout (must not itself contain `|`)
#   exit     | stub `claude` exit code
#   label    | short human label, used verbatim in "=== case N: <label> ==="
#   expected | substring that MUST appear in ci-dogfood.sh's output
#   forbid   | optional substring that must NOT appear (blank = skip this
#            | assertion). This is what makes a row a negative/guard control.
# The case id (N) is always the row's 1-based position in CASES, assigned by
# the loop — it is never hand-written into an assertion call, so inserting,
# removing, or reordering a row cannot desync the id from the assertions.
#
# Bash 3.2 (macOS default) has no associative arrays, hence the flat
# `|`-delimited rows read apart with `IFS='|' read -r` rather than a
# `declare -A` table.
#
# What each case proves (case id = row position in CASES):
#   1  (smoke,  insufficient credit)      -> smoke-step account-state marker fires
#   2  (smoke,  invalid/revoked key)      -> smoke-step account-state marker fires
#   3  (smoke,  rate limited)             -> smoke-step account-state marker fires
#   4  (smoke,  unrelated TypeError)      -> NEGATIVE CONTROL: a non-account
#                                             failure produces the existing
#                                             generic "smoke step claude exited"
#                                             ladder, NOT an account-state marker
#   5  (plugin, insufficient credit)      -> plugin-load-step account-state marker fires
#   6  (plugin, unrelated TypeError)      -> NEGATIVE CONTROL: a non-account
#                                             failure produces the existing
#                                             generic "plugin-load step claude
#                                             exited" ladder, NOT an account-
#                                             state marker
#   7  (plugin, invalid/revoked key)      -> plugin-load-step account-state marker fires
#   8  (plugin, rate limited)             -> plugin-load-step account-state marker fires
#   9  (smoke,  exit 0, output != "ok")   -> GUARD REGRESSION CONTROL: a zero-exit
#                                             wrong response reaches the
#                                             `grep -qx "ok"` assertion rung and
#                                             is NOT diverted into the account-
#                                             state path
#   10 (plugin, exit 0, no /roughly:setup)-> GUARD REGRESSION CONTROL: a zero-exit
#                                             wrong response reaches the
#                                             `/roughly:setup` assertion rung and
#                                             is NOT diverted into the account-
#                                             state path
#
# Cases 4 and 6 are the discriminating negative controls: without them, this
# suite would pass just as well against a classifier that fires on every
# failure (a classify_account_state that always matches). They prove the
# generic non-account-failure ladder still fires unmodified.
#
# Cases 1-8 set exit=1 (non-zero, non-124) so the classification and generic
# rungs fire deterministically. Cases 9 and 10 are the only exit=0 cases and
# exist to pin the `$SMOKE_EXIT != 0` / `$PLUGIN_EXIT != 0` guards on the two
# account-state rungs: every other case forces a non-zero exit, so without
# cases 9/10 nothing here could ever reach — or protect — the assertion rung
# sitting below each account-state rung.
#
# Case 9 pins the guard on the smoke ladder (protects the `grep -qx "ok"`
# rung). Case 10 pins the identical guard on the plugin ladder (protects the
# `/roughly:setup` rung) — the two ladders are structurally identical
# (timeout rung -> account-state rung -> generic non-zero rung -> success-
# shape assertion), so case 10 is the plugin-side twin of case 9, closing a
# gap where the smoke guard was covered but the plugin guard was not.
#
# For both, the stub text deliberately CONTAINS an account-state phrase
# ("rate limit") while exiting 0. That is what makes these cases
# discriminating rather than decorative: a neutral string would match no
# classifier pattern, so dropping the guard would change nothing and the case
# would pass either way. With this text, removing the exit-code guard makes
# classify_account_state match and the assert_not_contains below fails —
# verified by mutation (see the harness's own verification notes/commit).
# Case 10's stub text additionally must NOT contain "/roughly:setup", so that
# — guard intact — control reaches the real `/roughly:setup` assertion rung
# and fails there for the expected reason ("plugin loading not verified"),
# not by accident.
#
# Cases 7 and 8 give the plugin-load ladder the same per-classification
# coverage the smoke ladder has. The rung is byte-identical between ladders and
# classify_account_state is shared, so they are defence-in-depth, not distinct
# code paths.
#
# This harness deliberately does NOT assert against the 124 timeout rung — a
# sleeping stub is out of scope for this AC.

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

# ── case table ───────────────────────────────────────────────────────────────
# Fields: target|text|exit|label|expected|forbid  (forbid may be empty; see
# "Case table format" comment above). Order matches the "What each case
# proves" list above 1:1 by position.
CASES=(
  "smoke|Credit balance is too low|1|smoke / insufficient credit|API account state: insufficient credit|"
  "smoke|Invalid API key · Please run /login|1|smoke / invalid or revoked API key|API account state: invalid or revoked API key|"
  "smoke|rate_limit_error: too many requests|1|smoke / rate limited|API account state: rate limited|"
  "smoke|TypeError: cannot read property of undefined|1|smoke / unrelated failure — NEGATIVE CONTROL|smoke step claude exited|API account state"
  "plugin|Credit balance is too low|1|plugin-load / insufficient credit|API account state: insufficient credit|"
  "plugin|TypeError: cannot read property of undefined|1|plugin-load / unrelated failure — NEGATIVE CONTROL|plugin-load step claude exited|API account state"
  "plugin|Invalid API key · Please run /login|1|plugin-load / invalid or revoked API key|API account state: invalid or revoked API key|"
  "plugin|rate_limit_error: too many requests|1|plugin-load / rate limited|API account state: rate limited|"
  "smoke|I cannot comply; see the rate limit guidance in the docs|0|smoke / exit 0 but wrong output — GUARD REGRESSION CONTROL|smoke step did not produce expected response|API account state"
  "plugin|I cannot comply; see the rate limit guidance in the docs|0|plugin-load / exit 0 but wrong output, no /roughly:setup — GUARD REGRESSION CONTROL|plugin loading not verified|API account state"
)

# ── run all cases ────────────────────────────────────────────────────────────
CASE_ID=0
for row in "${CASES[@]}"; do
  CASE_ID=$((CASE_ID+1))
  IFS='|' read -r target text exit_code label expected forbid <<< "$row"

  echo "=== case $CASE_ID: $label ==="
  run_stub "$target" "$text" "$exit_code"
  assert_contains "$CASE_ID" "$expected"
  if [ -n "$forbid" ]; then
    assert_not_contains "$CASE_ID" "$forbid"
  fi
  assert_exit_nonzero "$CASE_ID"
done

echo "---"
echo "assertions passed: $PASS, failed: $FAILED"
[ "$FAILED" -eq 0 ] || exit 1
