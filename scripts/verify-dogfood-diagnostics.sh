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
# stubbed `claude` itself returns instantly. The classify_account_state alias
# block below is separate and effectively free (no worktree, no subprocess
# per case — just direct function calls).
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
# ── Legend (non-obvious reasoning only — each row's `label` field states what
#    it proves; this covers what the table can't) ──────────────────────────
# Negative controls (a non-account failure, e.g. an unrelated TypeError)
# exist because without them this suite would pass just as well against a
# classifier that fires on every failure — they prove the generic ladder
# still fires unmodified when the failure is NOT an account-state one.
#
# Guard-regression controls (exit 0, stub text containing an account-state
# phrase) pin the `$EXIT != 0` guard on each account-state rung. The stub
# text must CONTAIN a matching phrase (e.g. "rate limit") while exiting 0:
# a neutral string would match no classifier pattern, so dropping the guard
# would change nothing and the case would pass either way — only text that
# actually matches makes the control discriminating. This is mutation-
# verified: temporarily removing the exit-code guard makes
# classify_account_state match and the row's `forbid` assertion fails.
#
# The exit-124 rows are guard-regression controls for the OTHER guard
# (`!= 124`) on the same rung, using the same discriminating-text trick —
# stub text containing an account-state phrase, this time with exit 124. A
# stub can `exit 124` directly with no sleep: that is exactly the code
# `timeout`/`gtimeout` propagates when it kills a child, so no real timeout
# needs to elapse. Caveat, stated honestly: in ci-dogfood.sh the `= 124`
# timeout rung runs and `exit 1`s BEFORE the account-state rung is ever
# reached, so these rows are defence-in-depth confirming that ordering holds
# — not independent proof the account-state guard alone would catch a 124,
# since given the current code it never gets the chance to run.

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

# ── classify_account_state alias coverage ───────────────────────────────────
# Fast, side-effect-free: extracts the function's source out of ci-dogfood.sh
# and evals it into this shell, then calls it directly — no worktree, no
# stub subprocess, no `git` at all. This is what lets every alias get its own
# assertion cheaply; doing the same via end-to-end CASES rows would cost a
# worktree add/remove per alias.
FN_SRC="$(awk '/^classify_account_state\(\) \{/,/^\}/' "$ROOT/scripts/ci-dogfood.sh")"
eval "$FN_SRC"

# Guard the extraction: if the awk range never matched (e.g. the function was
# renamed or reformatted upstream), FN_SRC is empty, eval is a silent no-op,
# and classify_account_state is simply undefined — every alias assertion
# below would then evaluate `classify_account_state: command not found`,
# fail loudly one-by-one... UNLESS something upstream changes to make that
# failure quiet. Don't rely on downstream noise: check explicitly, right
# here, so an empty extraction is caught as its own named failure rather than
# discovered indirectly.
if ! declare -f classify_account_state >/dev/null 2>&1; then
  echo "FAIL: classify_account_state extraction failed — awk found no match in $ROOT/scripts/ci-dogfood.sh; function not defined after eval"
  FAILED=$((FAILED+1))
  echo "---"
  echo "assertions passed: $PASS, failed: $FAILED"
  exit 1
fi

assert_alias() {
  local desc=$1 input=$2 expected=$3
  local actual rc
  actual="$(classify_account_state "$input")"
  rc=$?
  if [ "$rc" -eq 0 ] && [ "$actual" = "$expected" ]; then
    echo "PASS alias: $desc -> \"$expected\""
    PASS=$((PASS+1))
  else
    echo "FAIL alias: $desc -> expected \"$expected\" (rc 0), got \"$actual\" (rc $rc)"
    FAILED=$((FAILED+1))
  fi
}

assert_alias_no_match() {
  local desc=$1 input=$2
  local actual rc
  actual="$(classify_account_state "$input")"
  rc=$?
  if [ "$rc" -ne 0 ] && [ -z "$actual" ]; then
    echo "PASS alias: $desc -> no match (rc $rc, no output), as expected"
    PASS=$((PASS+1))
  else
    echo "FAIL alias: $desc -> expected no match (non-zero rc, no output), got rc $rc output \"$actual\""
    FAILED=$((FAILED+1))
  fi
}

# insufficient credit
assert_alias "credit balance is too low"  "Credit balance is too low"          "insufficient credit"
assert_alias "insufficient credit"        "insufficient credit on this account" "insufficient credit"
# invalid or revoked API key
assert_alias "invalid api key"      "Invalid API key · Please run /login" "invalid or revoked API key"
assert_alias "not logged in"        "Error: not logged in"                "invalid or revoked API key"
assert_alias "authentication_error" "authentication_error: bad token"     "invalid or revoked API key"
# rate limited
assert_alias "rate limit"          "please slow down — rate limit in effect" "rate limited"
assert_alias "rate_limit_error"    "rate_limit_error: too many requests"     "rate limited"
assert_alias "too many requests"   "429 too many requests"                   "rate limited"

# case-insensitivity — the function uses grep -qiE
assert_alias "case-insensitive INVALID API KEY" "INVALID API KEY, please re-auth" "invalid or revoked API key"

# fall-through contract: non-matching input returns non-zero and no output
assert_alias_no_match "unrelated TypeError" "TypeError: cannot read property of undefined"

# deliberately-excluded broad tokens — too broad on their own, must NOT match
assert_alias_no_match "bare 401"    "HTTP 401"
assert_alias_no_match "bare 429"    "HTTP 429"
assert_alias_no_match "bare billing" "billing page: https://console.anthropic.com"

# ── case table ───────────────────────────────────────────────────────────────
# Fields: target|text|exit|label|expected|forbid  (forbid may be empty; see
# "Case table format" comment above).
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
  "smoke|rate limit exceeded, please retry|124|smoke / exit 124 — GUARD REGRESSION CONTROL (!=124 blind spot)|smoke step timed out|API account state"
  "plugin|rate limit exceeded, please retry|124|plugin-load / exit 124 — GUARD REGRESSION CONTROL (!=124 blind spot)|plugin-load step timed out|API account state"
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
