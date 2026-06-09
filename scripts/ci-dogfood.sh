#!/usr/bin/env bash
set -euo pipefail

# Guard: must run from inside the roughly plugin repo.
# Run this FIRST (before SHA/ROOT resolution) so a wrong-cwd invocation gets
# a friendly diagnostic instead of a raw `git fatal: not a git repository`.
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$ROOT" ] || [ ! -f "$ROOT/.claude-plugin/plugin.json" ]; then
  echo "ci-dogfood: must run from the roughly plugin repo" >&2
  exit 1
fi

# Portability: select timeout binary (Linux uses 'timeout'; macOS via coreutils uses 'gtimeout').
if command -v timeout >/dev/null 2>&1; then
  TIMEOUT=timeout
elif command -v gtimeout >/dev/null 2>&1; then
  TIMEOUT=gtimeout
else
  echo "ci-dogfood: FAIL — no timeout binary available (install coreutils on macOS via 'brew install coreutils')" >&2
  exit 1
fi

# Guard: ANTHROPIC_API_KEY must be set (the ${VAR:-} form is required because `set -u` is active above).
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  echo "ci-dogfood: FAIL — ANTHROPIC_API_KEY not set or empty (configure in GitHub Settings → Secrets and variables → Actions, or export for local repro)" >&2
  exit 1
fi

# Resolve SHA (CI provides $GITHUB_SHA; locally, derive from HEAD)
SHA="${GITHUB_SHA:-$(git -C "$ROOT" rev-parse HEAD)}"

WORKTREE="/tmp/roughly-dogfood-${SHA}"

# Capture pre-run source-tree state
PRE_STATE="$(git -C "$ROOT" status --porcelain)"

# Cleanup function — registered before worktree creation so partial-failure cleanup still fires.
# Failures are logged to stderr but do not fail the trap (cleanup must complete).
cleanup() {
  git -C "$ROOT" worktree remove --force "$WORKTREE" 2>/dev/null \
    || echo "ci-dogfood: warning — worktree remove failed during cleanup; orphan registration may remain (rerun cleans up via prune)" >&2
  rm -rf "$WORKTREE"
}
trap cleanup EXIT

# Stale-worktree guard: handles same-SHA reruns where a prior run left the path populated.
# `worktree prune` reclaims orphaned registrations; failures here are logged but non-fatal.
git -C "$ROOT" worktree prune 2>/dev/null \
  || echo "ci-dogfood: warning — worktree prune failed; proceeding with stale-path cleanup" >&2
if [ -d "$WORKTREE" ]; then
  git -C "$ROOT" worktree remove --force "$WORKTREE" 2>/dev/null \
    || echo "ci-dogfood: warning — stale worktree remove failed; falling back to rm -rf" >&2
  rm -rf "$WORKTREE"
fi

# Create ephemeral worktree and enter it.
# Use "$SHA" (not HEAD) so the worktree contents match the SHA encoded in the path —
# guards against HEAD moving between SHA resolution and worktree add.
git -C "$ROOT" worktree add "$WORKTREE" "$SHA"
cd "$WORKTREE"

# ──────────────────────────────────────────────────────────────────────
# Smoke test: auth + API exercise, then plugin-load verification
# ──────────────────────────────────────────────────────────────────────

# --bare is mandatory: forces strict ANTHROPIC_API_KEY-only auth with no
# keychain/OAuth fallback. Without it, a missing/invalid secret in CI may
# hang or prompt for OAuth instead of failing cleanly.
#
# The `... && EXIT=0 || EXIT=$?` idiom captures the exit code explicitly.
# Without it, `set -e` would kill the script at the assignment on any
# non-zero exit (timeout 124, auth failure, budget breach), producing a
# bare exit with no diagnostic instead of the FAIL message below.
SMOKE_OUT="$($TIMEOUT 25 claude --bare --plugin-dir "$WORKTREE" \
  --no-session-persistence --max-budget-usd 0.05 \
  -p "respond with the literal string ok" 2>&1)" && SMOKE_EXIT=0 || SMOKE_EXIT=$?
if [ "$SMOKE_EXIT" = 124 ]; then
  echo "ci-dogfood: FAIL — smoke step timed out (claude did not return within 25s)" >&2
  printf '%s\n' "$SMOKE_OUT" | sed 's/^/    /' >&2
  exit 1
fi
if [ "$SMOKE_EXIT" != 0 ]; then
  echo "ci-dogfood: FAIL — smoke step claude exited $SMOKE_EXIT" >&2
  printf '%s\n' "$SMOKE_OUT" | sed 's/^/    /' >&2
  exit 1
fi
# `grep -qx` requires the entire line to be exactly "ok" — guards against
# false-positive matches in incidental prose (e.g., "looks ok to me").
if ! printf '%s\n' "$SMOKE_OUT" | grep -qx "ok"; then
  echo "ci-dogfood: FAIL — smoke step did not produce expected response" >&2
  printf '%s\n' "$SMOKE_OUT" | sed 's/^/    /' >&2
  exit 1
fi

# NOTE: The slash-command listing relies on the model's compliance
# with the prompt format. claude has no deterministic --list-commands
# flag in -p mode, so this is the most reliable approximation. The
# /roughly:setup anchor is the deterministic plugin-load proof:
# if it appears in the response, --plugin-dir was honored.
PLUGIN_OUT="$($TIMEOUT 25 claude --bare --plugin-dir "$WORKTREE" \
  --no-session-persistence --max-budget-usd 0.05 \
  -p "List each of your available slash commands on a separate line with the / prefix. Do not include any other text." 2>&1)" && PLUGIN_EXIT=0 || PLUGIN_EXIT=$?
if [ "$PLUGIN_EXIT" = 124 ]; then
  echo "ci-dogfood: FAIL — plugin-load step timed out (claude did not return within 25s)" >&2
  printf '%s\n' "$PLUGIN_OUT" | sed 's/^/    /' >&2
  exit 1
fi
if [ "$PLUGIN_EXIT" != 0 ]; then
  echo "ci-dogfood: FAIL — plugin-load step claude exited $PLUGIN_EXIT" >&2
  printf '%s\n' "$PLUGIN_OUT" | sed 's/^/    /' >&2
  exit 1
fi
# Anchor: line start, optional non-alphabetic prefix (covers any decoration —
# whitespace, list markers like `- ` `* ` `1. `, markdown formatting like
# backticks/quotes/brackets/angle-brackets/hashes, table pipes, indentation,
# nested combinations like `  - \`/roughly:setup\``), the literal
# `/roughly:setup`, then EOL or a non-identifier character. Rejects prose
# mentions (lines starting with a letter — "I have access to /roughly:setup
# ...") AND rejects substring drift (`/roughly:setupx`, `/roughly:setup-other`,
# `/roughly:setup_x` — char after command must be a non-identifier boundary,
# i.e. not letter/digit/`-`/`_`). Liberal enough to accept any common markdown
# format the model might emit; strict enough to require evidence the model
# treated this as a command listing, not as prose.
if ! printf '%s\n' "$PLUGIN_OUT" | grep -qE "^[^A-Za-z]*/roughly:setup($|[^A-Za-z0-9_-])"; then
  echo "ci-dogfood: FAIL — plugin loading not verified (no /roughly:setup list-item line in output)" >&2
  printf '%s\n' "$PLUGIN_OUT" | sed 's/^/    /' >&2
  exit 1
fi

echo "ci-dogfood: smoke + plugin-load — both assertions passed"

# ──────────────────────────────────────────────────────────────────────
# Full scenario: /roughly:build --ci against fixture
# ──────────────────────────────────────────────────────────────────────

cd "$WORKTREE/tests/fixtures/hello-roughly"

# 1.50 USD ≈ ~150K mixed Sonnet tokens at current pricing (3/M in + 15/M
# out, ~80/20 mix). Recompute if pricing changes.
SCENARIO_OUT="$($TIMEOUT 270 claude --bare --plugin-dir "$WORKTREE" \
  --no-session-persistence --max-budget-usd 1.50 \
  -p "/roughly:build --ci add a NAME constant to src/greeter.sh and update the echo to use it" 2>&1)" \
  && SCENARIO_EXIT=0 || SCENARIO_EXIT=$?
if [ "$SCENARIO_EXIT" = 124 ]; then
  echo "ci-dogfood: FAIL — full-scenario step timed out (claude did not return within 270s)" >&2
  printf '%s\n' "$SCENARIO_OUT" | sed 's/^/    /' >&2
  exit 1
fi
if [ "$SCENARIO_EXIT" != 0 ]; then
  echo "ci-dogfood: FAIL — full-scenario step claude exited $SCENARIO_EXIT" >&2
  printf '%s\n' "$SCENARIO_OUT" | sed 's/^/    /' >&2
  exit 1
fi

# Assertion 1: plan-review PASS marker present (proves Stage 4 dispatched
# review-plan under --ci and it returned PASS — build's --ci now RUNS
# review-plan rather than skipping it; see ADR-013). Full-string match (-F)
# keeps this in lockstep with skills/build/SKILL.md Stage 4's verdict-marker emit.
if ! printf '%s\n' "$SCENARIO_OUT" | grep -qF '[--ci] plan review verdict: PASS'; then
  echo "ci-dogfood: FAIL — plan-review PASS marker missing (Stage 4 may not have dispatched review-plan under --ci; see ADR-013)" >&2
  printf '%s\n' "$SCENARIO_OUT" | sed 's/^/    /' >&2
  exit 1
fi

# Assertion 2: plan file exists (proves Stage 3 ran, plan was written).
# Exit-capture idiom required: under set -euo pipefail with pipefail, a
# failing `ls` (no matches, missing dir) propagates through the pipe and
# would silently kill the script before the [-z "$PLAN_FILE"] guard runs.
PLAN_FILE="$(ls "$WORKTREE/tests/fixtures/hello-roughly/.roughly/plans/"*-plan.md 2>/dev/null | head -1)" \
  && PLAN_FILE_EXIT=0 || PLAN_FILE_EXIT=$?
if [ "$PLAN_FILE_EXIT" != 0 ] || [ -z "$PLAN_FILE" ] || [ ! -f "$PLAN_FILE" ]; then
  echo "ci-dogfood: FAIL — no plan file found in $WORKTREE/tests/fixtures/hello-roughly/.roughly/plans/" >&2
  printf '%s\n' "$SCENARIO_OUT" | sed 's/^/    /' >&2
  exit 1
fi

# Assertion 3: plan has '## Tasks' section (structural; AC4 — survives
# plan-format drift).
if ! grep -q '^## Tasks' "$PLAN_FILE"; then
  echo "ci-dogfood: FAIL — plan file at $PLAN_FILE has no '## Tasks' section" >&2
  sed 's/^/    /' "$PLAN_FILE" >&2
  exit 1
fi

# Assertion 4: plan has at least T1 (per S6 epic note, the ### T1 anchor
# is stable across Plan-format-version evolution). Match `### T1` with no
# required trailing char so minor heading variations (`### T1`, `### T1 -
# title`, `### T1: title`) all pass — the assertion's purpose is to
# confirm T1 exists, not to validate its title format.
if ! grep -qE '^### T1' "$PLAN_FILE"; then
  echo "ci-dogfood: FAIL — plan file at $PLAN_FILE has no T1 task" >&2
  sed 's/^/    /' "$PLAN_FILE" >&2
  exit 1
fi

# Assertion 5: plan file's first line is the Status block marker (proves
# the new Stage 8 plan-historical-marking step ran — E04.S3). The block
# format is fully specified per CONTRIBUTING.md "Plan-file lifecycle";
# this assertion only checks the opening marker pattern, not the SHA or
# date fields (those are runtime-dependent).
if ! head -1 "$PLAN_FILE" | grep -qE '^> \*\*Status:\*\* Historical'; then
  echo "ci-dogfood: FAIL — plan file at $PLAN_FILE missing Status block on first line (expected '> **Status:** Historical — ...'; the build skill's new Stage 8 step 4 may not have run, or the block was inserted elsewhere)" >&2
  sed 's/^/    /' "$PLAN_FILE" >&2
  exit 1
fi

# Assertion 5a: NAME= assignment present at line start (proves the constant
# was added as a real assignment). Line-start anchor with optional indent
# and optional `readonly`/`export` prefix — rejects comment lines like
# `# NAME=foo`, `# Original: NAME=value` (don't match `^[[:space:]]*NAME=`
# because of the leading `#`) and inline-comment lines like
# `foo=bar # NAME=oops` (line starts with `foo=`, not NAME=). The
# requirement is a real shell assignment, not a mention in prose.
if ! grep -qE '^[[:space:]]*(readonly[[:space:]]+|export[[:space:]]+)?NAME=' "$WORKTREE/tests/fixtures/hello-roughly/src/greeter.sh"; then
  echo "ci-dogfood: FAIL — src/greeter.sh in worktree shows no NAME= assignment at line start (implementation may not have run, or wrote only a comment)" >&2
  sed 's/^/    /' "$WORKTREE/tests/fixtures/hello-roughly/src/greeter.sh" >&2
  exit 1
fi

# Assertion 5b: an `echo` statement uses $NAME or ${NAME} (proves the
# echo update happened in the right place — the prompt asked to "update
# the echo to use it"). The line must start with `echo` (with optional
# leading whitespace), then contain a NAME reference somewhere on the
# same line. Without the `echo` anchor, `# Could use $NAME here` (a
# comment) or `OTHER=$NAME` (a different statement) would silently pass
# while the original `echo "hello"` line remained unchanged. Variable-
# name boundary preserved from the prior fix: rejects $NAMESPACE,
# ${NAME_VAR}, etc. Three accepted forms within an echo line:
# (a) `${NAME}` — fully-braced; (b) `$NAME` followed by a non-identifier
# char; (c) `$NAME` at end of line.
if ! grep -qE '^[[:space:]]*echo[[:space:]].*(\$\{NAME\}|\$NAME([^A-Za-z0-9_]|$))' "$WORKTREE/tests/fixtures/hello-roughly/src/greeter.sh"; then
  echo "ci-dogfood: FAIL — src/greeter.sh has NAME= but no echo line references \$NAME or \${NAME} (echo update missing or NAME used elsewhere)" >&2
  sed 's/^/    /' "$WORKTREE/tests/fixtures/hello-roughly/src/greeter.sh" >&2
  exit 1
fi

# Assertion 5c: the original `echo "hello"` statement was not preserved
# (proves the line was actually replaced or extended, not supplemented
# with a parallel statement or redirected). Whitespace between `echo`
# and `"hello"` matches `[[:space:]]+` — covers a single space (the
# fixture's original form), multiple spaces, and tabs (any form an LLM
# might emit while otherwise preserving the line). The character class
# [#;&|<>] covers every shell construct that terminates or redirects
# the original `echo "hello"` while leaving its output behavior intact:
# `;`, `&`, `&&`, `|`, `||`, `>`, `>>`, `<`, `<<`, `#` (trailing
# comment), or end-of-line. Multi-char operators (`&&`, `||`, `>>`,
# `<<`, `<<<`) all start with one of these chars, so single-char match
# captures them. Valid extended echos do NOT match because `"`, `$`, or
# bare-word args after `echo "hello"` are NOT in this class, so the
# regex correctly accepts: `echo "hello" "$NAME"`, `echo "hello $NAME"`,
# `echo "hello, $NAME"`, `echo "hello" $NAME`, `echo "hello" world`.
if grep -qE '^[[:space:]]*echo[[:space:]]+"hello"[[:space:]]*($|[#;&|<>])' "$WORKTREE/tests/fixtures/hello-roughly/src/greeter.sh"; then
  echo "ci-dogfood: FAIL — src/greeter.sh still contains the original \`echo \"hello\"\` statement unchanged (preserved via redirect, pipe, sequence, or as-is); the echo was added to, not updated" >&2
  sed 's/^/    /' "$WORKTREE/tests/fixtures/hello-roughly/src/greeter.sh" >&2
  exit 1
fi

echo "ci-dogfood: full-scenario — all 7 structural assertions passed"

# ──────────────────────────────────────────────────────────────────────
# Fix scenario: /roughly:fix --ci against the hello-roughly-bug fixture
# ──────────────────────────────────────────────────────────────────────

# Fail loudly if the fixture is absent from the worktree (e.g. uncommitted or
# renamed) — a bare `cd` under set -e would otherwise die with no diagnostic.
if [ ! -d "$WORKTREE/tests/fixtures/hello-roughly-bug" ]; then
  echo "ci-dogfood: FAIL — fix fixture directory missing from worktree at $WORKTREE/tests/fixtures/hello-roughly-bug (fixture may be untracked or the path changed)" >&2
  exit 1
fi
cd "$WORKTREE/tests/fixtures/hello-roughly-bug"

# Same budget envelope + exit-capture idiom as the build scenario (never
# `OUT="$(...)"` direct-assign under set -e — distinct failure diagnostics
# required; see known-pitfalls "set -e + command-substitution-in-assignment").
FIX_OUT="$($TIMEOUT 270 claude --bare --plugin-dir "$WORKTREE" \
  --no-session-persistence --max-budget-usd 1.50 \
  -p "/roughly:fix --ci src/greeter.sh prints 'hello ' instead of 'hello world' — variable reference typo in the echo" 2>&1)" \
  && FIX_EXIT=0 || FIX_EXIT=$?
if [ "$FIX_EXIT" = 124 ]; then
  echo "ci-dogfood: FAIL — fix-scenario step timed out (claude did not return within 270s)" >&2
  printf '%s\n' "$FIX_OUT" | sed 's/^/    /' >&2
  exit 1
fi
if [ "$FIX_EXIT" != 0 ]; then
  echo "ci-dogfood: FAIL — fix-scenario step claude exited $FIX_EXIT" >&2
  printf '%s\n' "$FIX_OUT" | sed 's/^/    /' >&2
  exit 1
fi

# Fix asserts on completion artifacts, NOT the build synthetic-PASS marker:
# fix's --ci RUNS review-plan and branches on its verdict (E06.S2 AC1), so no
# `[--ci] plan review skipped` marker is emitted on this path.

# Assertion F1: fix plan file exists (proves Stage 3+ ran). `ls -t` picks the
# newest match so re-runs validate the current plan, not a stale prior one.
# Exit-capture idiom required — a failing `ls` under pipefail would kill the
# script before the guard.
FIX_PLAN="$(ls -t "$WORKTREE/tests/fixtures/hello-roughly-bug/.roughly/plans/"*-plan.md 2>/dev/null | head -1)" \
  && FIX_PLAN_EXIT=0 || FIX_PLAN_EXIT=$?
if [ "$FIX_PLAN_EXIT" != 0 ] || [ -z "$FIX_PLAN" ] || [ ! -f "$FIX_PLAN" ]; then
  echo "ci-dogfood: FAIL — no fix plan file found in $WORKTREE/tests/fixtures/hello-roughly-bug/.roughly/plans/" >&2
  printf '%s\n' "$FIX_OUT" | sed 's/^/    /' >&2
  exit 1
fi

# Assertion F2: plan has '## Tasks' section (structural).
if ! grep -q '^## Tasks' "$FIX_PLAN"; then
  echo "ci-dogfood: FAIL — fix plan file at $FIX_PLAN has no '## Tasks' section" >&2
  sed 's/^/    /' "$FIX_PLAN" >&2
  exit 1
fi

# Assertion F3: plan has at least T1.
if ! grep -qE '^### T1' "$FIX_PLAN"; then
  echo "ci-dogfood: FAIL — fix plan file at $FIX_PLAN has no T1 task" >&2
  sed 's/^/    /' "$FIX_PLAN" >&2
  exit 1
fi

# Assertion F4: plan first line is the Status block marker (proves the Stage 8
# plan-historical-marking step ran — the fix-completion proof through Stage 8).
if ! head -1 "$FIX_PLAN" | grep -qE '^> \*\*Status:\*\* Historical'; then
  echo "ci-dogfood: FAIL — fix plan file at $FIX_PLAN missing Status block on first line (Stage 8 plan-historical step may not have run)" >&2
  sed 's/^/    /' "$FIX_PLAN" >&2
  exit 1
fi

# Assertion F5a: the fix was applied — an echo line now references $NAME/${NAME}
# (variable-name boundary guarded as in the build scenario: rejects $NAMESPACE etc.).
if ! grep -qE '^[[:space:]]*echo[[:space:]].*(\$\{NAME\}|\$NAME([^A-Za-z0-9_]|$))' "$WORKTREE/tests/fixtures/hello-roughly-bug/src/greeter.sh"; then
  echo "ci-dogfood: FAIL — src/greeter.sh has no echo line referencing \$NAME or \${NAME} (fix not applied)" >&2
  sed 's/^/    /' "$WORKTREE/tests/fixtures/hello-roughly-bug/src/greeter.sh" >&2
  exit 1
fi

# Assertion F5b: the original \$NMAE typo is gone (proves the bug was actually
# fixed, not merely supplemented with a parallel correct statement).
if grep -q 'NMAE' "$WORKTREE/tests/fixtures/hello-roughly-bug/src/greeter.sh"; then
  echo "ci-dogfood: FAIL — src/greeter.sh still contains the \$NMAE typo (bug not fixed)" >&2
  sed 's/^/    /' "$WORKTREE/tests/fixtures/hello-roughly-bug/src/greeter.sh" >&2
  exit 1
fi

# Assertion F6: the fixture's own regression test now passes (behavioral proof
# the fix produces the correct output — `hello world` — not merely plausible
# structure). This test FAILS pre-fix and must PASS post-fix; the grep checks
# above are necessary but not sufficient (e.g. `echo "goodbye $NAME"` satisfies
# F5a/F5b but fails this test). Exit-capture idiom: a non-zero test under
# set -e would otherwise kill the script before the diagnostic fires.
FIX_TEST_OUT="$(bash "$WORKTREE/tests/fixtures/hello-roughly-bug/tests/greeter.test.sh" 2>&1)" \
  && FIX_TEST_EXIT=0 || FIX_TEST_EXIT=$?
if [ "$FIX_TEST_EXIT" != 0 ]; then
  echo "ci-dogfood: FAIL — fixture regression test did not pass post-fix (exit $FIX_TEST_EXIT; fix did not produce correct behavior)" >&2
  printf '%s\n' "$FIX_TEST_OUT" | sed 's/^/    /' >&2
  exit 1
fi

echo "ci-dogfood: fix-scenario — all structural + behavioral assertions passed"

# ──────────────────────────────────────────────────────────────────────
# Build-abort scenario: /roughly:build --ci against an unsatisfiable-test fixture
# (E06.S3 AC1 — Stage 5c auto-fix-cap abort; INVERTED-SUCCESS assertion)
# ──────────────────────────────────────────────────────────────────────

# Fail loudly if the fixture is absent from the worktree (e.g. uncommitted or
# renamed) — a bare `cd` under set -e would otherwise die with no diagnostic.
if [ ! -d "$WORKTREE/tests/fixtures/hello-roughly-build-abort" ]; then
  echo "ci-dogfood: FAIL — build-abort fixture directory missing from worktree at $WORKTREE/tests/fixtures/hello-roughly-build-abort (fixture may be untracked or the path changed)" >&2
  exit 1
fi
cd "$WORKTREE/tests/fixtures/hello-roughly-build-abort"

# Same budget envelope + exit-capture idiom as the build scenario (never
# `OUT="$(...)"` direct-assign under set -e — distinct failure diagnostics
# required; see known-pitfalls "set -e + command-substitution-in-assignment").
BUILD_ABORT_OUT="$($TIMEOUT 270 claude --bare --plugin-dir "$WORKTREE" \
  --no-session-persistence --max-budget-usd 1.50 \
  -p "/roughly:build --ci add a NAME constant to src/greeter.sh and update the echo to use it" 2>&1)" \
  && BUILD_ABORT_EXIT=0 || BUILD_ABORT_EXIT=$?
# Per epic AC4, 124 (timeout — process killed) is ALWAYS a hard FAIL: a killed
# process is not the abort path, it is an infra failure masquerading as one.
if [ "$BUILD_ABORT_EXIT" = 124 ]; then
  echo "ci-dogfood: FAIL — build-abort step timed out — process killed, not the abort path (claude did not return within 270s)" >&2
  printf '%s\n' "$BUILD_ABORT_OUT" | sed 's/^/    /' >&2
  exit 1
fi

# Marker-primary: the Stage 5c auto-fix-cap escalation marker is the proof the
# abort fired. NOTE: claude -p may exit 0 even on a model-level abort (the model
# cannot set a process exit code on normal turn completion), so we key on the
# marker, not the exit code. The exit-code rung below is left permissive pending
# empirical calibration (E06.S3 T11) — only 124 (timeout) is a hard FAIL.
if ! printf '%s\n' "$BUILD_ABORT_OUT" | grep -qF 'cannot proceed: auto-fix cap reached on'; then
  echo "ci-dogfood: FAIL — Stage 5c auto-fix-cap abort marker missing (the unsatisfiable-test fixture did not drive the build to the Stage 5c abort)" >&2
  printf '%s\n' "$BUILD_ABORT_OUT" | sed 's/^/    /' >&2
  exit 1
fi
# T11-CALIBRATE: confirm during per-fixture validation whether this abort yields
# process exit 0 (model emitted marker, CLI completed) or non-zero. If validation
# shows a deterministic non-zero abort code, add a rung asserting it here. Until
# then, marker-present is the PASS condition and only 124 is a hard FAIL.

# Negative backstop: the abort fires at Stage 5c, so the build MUST NOT reach
# Stage 8 (no plan-historical marking). If a plan file exists with the Stage 8
# Status block on its first line, the build completed the full pipeline — the
# abort was bypassed despite the marker appearing. Closes the one-directional
# false-PASS gap (marker-present alone could otherwise co-occur with completion).
ABORT_PLAN="$(ls -t "$WORKTREE/tests/fixtures/hello-roughly-build-abort/.roughly/plans/"*-plan.md 2>/dev/null | head -1)" \
  && ABORT_PLAN_EXIT=0 || ABORT_PLAN_EXIT=$?
if [ "$ABORT_PLAN_EXIT" = 0 ] && [ -n "$ABORT_PLAN" ] && [ -f "$ABORT_PLAN" ] \
  && head -1 "$ABORT_PLAN" | grep -qE '^> \*\*Status:\*\* Historical'; then
  echo "ci-dogfood: FAIL — build-abort fixture reached Stage 8 (plan carries a Historical Status block; the abort was bypassed despite the marker)" >&2
  printf '%s\n' "$BUILD_ABORT_OUT" | sed 's/^/    /' >&2
  exit 1
fi

echo "ci-dogfood: build-abort scenario — Stage 5c auto-fix-cap abort marker present, no Stage 8 completion (exit ${BUILD_ABORT_EXIT})"

# ──────────────────────────────────────────────────────────────────────
# Build-abort CONTROL: satisfiable test — same task completes the full pipeline (E06.S3 AC1/AC3)
# ──────────────────────────────────────────────────────────────────────

# Fail loudly if the control fixture is absent from the worktree.
if [ ! -d "$WORKTREE/tests/fixtures/hello-roughly-build-abort-control" ]; then
  echo "ci-dogfood: FAIL — build-abort control fixture directory missing from worktree at $WORKTREE/tests/fixtures/hello-roughly-build-abort-control (fixture may be untracked or the path changed)" >&2
  exit 1
fi
cd "$WORKTREE/tests/fixtures/hello-roughly-build-abort-control"

# Same task string + budget envelope as the abort scenario — the ONLY difference
# is the fixture's test satisfiability, isolating the abort trigger to the rig.
BUILD_ABORT_CTRL_OUT="$($TIMEOUT 270 claude --bare --plugin-dir "$WORKTREE" \
  --no-session-persistence --max-budget-usd 1.50 \
  -p "/roughly:build --ci add a NAME constant to src/greeter.sh and update the echo to use it" 2>&1)" \
  && BUILD_ABORT_CTRL_EXIT=0 || BUILD_ABORT_CTRL_EXIT=$?
if [ "$BUILD_ABORT_CTRL_EXIT" = 124 ]; then
  echo "ci-dogfood: FAIL — build-abort control step timed out (claude did not return within 270s)" >&2
  printf '%s\n' "$BUILD_ABORT_CTRL_OUT" | sed 's/^/    /' >&2
  exit 1
fi
# The control's satisfiable test means the build completes the full pipeline:
# a non-zero exit here is a real failure, not the abort path.
if [ "$BUILD_ABORT_CTRL_EXIT" != 0 ]; then
  echo "ci-dogfood: FAIL — control build exited non-zero — expected full completion (exit $BUILD_ABORT_CTRL_EXIT)" >&2
  printf '%s\n' "$BUILD_ABORT_CTRL_OUT" | sed 's/^/    /' >&2
  exit 1
fi

# Control assertion (a): the Stage 5c abort marker must be ABSENT (positive-guard
# form — `if grep` matches → FAIL — proves the abort trigger is isolated to the
# rigged fixture and does not fire on a satisfiable test).
if printf '%s\n' "$BUILD_ABORT_CTRL_OUT" | grep -qF 'cannot proceed: auto-fix cap reached on'; then
  echo "ci-dogfood: FAIL — build-abort control unexpectedly hit the Stage 5c abort (the abort trigger is not isolated to the rigged test)" >&2
  printf '%s\n' "$BUILD_ABORT_CTRL_OUT" | sed 's/^/    /' >&2
  exit 1
fi

# Control assertion (b): plan file written with Status block on its first line
# (proves the control completed the full pipeline through Stage 8's plan-
# historical-marking step). Distinct CTRL_PLAN var avoids clobbering PLAN_FILE/
# FIX_PLAN. Exit-capture idiom required — a failing `ls` under pipefail would
# kill the script before the guard.
CTRL_PLAN="$(ls -t "$WORKTREE/tests/fixtures/hello-roughly-build-abort-control/.roughly/plans/"*-plan.md 2>/dev/null | head -1)" \
  && CTRL_PLAN_EXIT=0 || CTRL_PLAN_EXIT=$?
if [ "$CTRL_PLAN_EXIT" != 0 ] || [ -z "$CTRL_PLAN" ] || [ ! -f "$CTRL_PLAN" ]; then
  echo "ci-dogfood: FAIL — no control plan file found in $WORKTREE/tests/fixtures/hello-roughly-build-abort-control/.roughly/plans/" >&2
  printf '%s\n' "$BUILD_ABORT_CTRL_OUT" | sed 's/^/    /' >&2
  exit 1
fi
if ! head -1 "$CTRL_PLAN" | grep -qE '^> \*\*Status:\*\* Historical'; then
  echo "ci-dogfood: FAIL — control plan file at $CTRL_PLAN missing Status block on first line (the full pipeline may not have reached Stage 8)" >&2
  sed 's/^/    /' "$CTRL_PLAN" >&2
  exit 1
fi

echo "ci-dogfood: build-abort control — completed full pipeline, no abort (exit 0)"

# ──────────────────────────────────────────────────────────────────────
# Plan-revision scenario: /roughly:build --ci against a fixture whose task steers a
# flaggable verify, driving review-plan NEEDS REVISION → revise → PASS (E06.S3 AC2)
# ──────────────────────────────────────────────────────────────────────

# Fail loudly if the fixture is absent from the worktree (e.g. uncommitted or
# renamed) — a bare `cd` under set -e would otherwise die with no diagnostic.
if [ ! -d "$WORKTREE/tests/fixtures/hello-roughly-plan-revision" ]; then
  echo "ci-dogfood: FAIL — plan-revision fixture directory missing from worktree at $WORKTREE/tests/fixtures/hello-roughly-plan-revision (fixture may be untracked or the path changed)" >&2
  exit 1
fi
cd "$WORKTREE/tests/fixtures/hello-roughly-plan-revision"

# Task string copied verbatim from the fixture README's "Expected Input". The
# steered task puts TWO occurrences of the word `world` on a SINGLE echo line and
# asks the Verify to count them with `grep -Fc world …` asserting `= 2`. Because
# `grep -Fc` counts matching LINES (not occurrences), the two co-located matches
# return 1, not 2 — the genuine same-line co-location hazard review-plan's E05.S3
# AC2 check flags as NEEDS REVISION (a single match on its own line would fall
# under the carve-out and PASS first-pass, never exercising recovery). The fix is
# `grep -Fo world … | wc -l`, which review-plan then PASSes.
# Budget note: AC2 recovery may need 2.00 if T11 validation shows breach — left
# at 1.50 for now, documented. Same exit-capture idiom as the build scenario.
PLAN_REV_OUT="$($TIMEOUT 270 claude --bare --plugin-dir "$WORKTREE" \
  --no-session-persistence --max-budget-usd 1.50 \
  -p "/roughly:build --ci update src/greeter.sh so its single echo statement prints the greeting word \"world\" twice on the same line (for example: echo \"hello world, goodbye world\"); in the plan, the task's Verify command MUST use grep -Fc world src/greeter.sh to assert the number of \"world\" occurrences equals 2" 2>&1)" \
  && PLAN_REV_EXIT=0 || PLAN_REV_EXIT=$?
if [ "$PLAN_REV_EXIT" = 124 ]; then
  echo "ci-dogfood: FAIL — plan-revision step timed out (claude did not return within 270s)" >&2
  printf '%s\n' "$PLAN_REV_OUT" | sed 's/^/    /' >&2
  exit 1
fi
# The recovery completes the full pipeline: a non-zero exit here is a real
# failure, not the abort path.
if [ "$PLAN_REV_EXIT" != 0 ]; then
  echo "ci-dogfood: FAIL — plan-revision build exited non-zero — expected exit 0 after recovery (exit $PLAN_REV_EXIT)" >&2
  printf '%s\n' "$PLAN_REV_OUT" | sed 's/^/    /' >&2
  exit 1
fi

# Assertion (a): ≥2 plan-review verdict markers (NEEDS REVISION then PASS).
# Count via `grep -Fo … | wc -l` against the marker PREFIX — `grep -Fc` counts
# matching lines, not occurrences, and would miscount if two markers co-locate
# on one line (the very anti-pattern this fixture exercises; see known-pitfalls).
PLAN_REV_VERDICTS="$(printf '%s\n' "$PLAN_REV_OUT" | grep -Fo '[--ci] plan review verdict:' | wc -l | tr -d '[:space:]')"
if [ "$PLAN_REV_VERDICTS" -lt 2 ]; then
  echo "ci-dogfood: FAIL — expected >=2 plan-review verdict markers (NEEDS REVISION then PASS), saw $PLAN_REV_VERDICTS" >&2
  printf '%s\n' "$PLAN_REV_OUT" | sed 's/^/    /' >&2
  exit 1
fi

# Assertion (b): a NEEDS REVISION verdict marker is present (the first-pass
# flag). Prefix match — the runtime marker is `… NEEDS REVISION (attempt <n>)`.
if ! printf '%s\n' "$PLAN_REV_OUT" | grep -qF '[--ci] plan review verdict: NEEDS REVISION'; then
  echo "ci-dogfood: FAIL — plan-revision scenario produced no NEEDS REVISION verdict marker (the flaggable verify did not drive review-plan to NEEDS REVISION)" >&2
  printf '%s\n' "$PLAN_REV_OUT" | sed 's/^/    /' >&2
  exit 1
fi

# Assertion (c): a PASS verdict marker is present (recovery reached PASS after
# the revise).
if ! printf '%s\n' "$PLAN_REV_OUT" | grep -qF '[--ci] plan review verdict: PASS'; then
  echo "ci-dogfood: FAIL — plan-revision recovery did not reach PASS (no PASS verdict marker after the revise)" >&2
  printf '%s\n' "$PLAN_REV_OUT" | sed 's/^/    /' >&2
  exit 1
fi

# Assertion (d): plan file written with Status block on its first line (proves
# the recovery completed the full pipeline through Stage 8). Distinct REV_PLAN
# var avoids clobbering PLAN_FILE/FIX_PLAN/CTRL_PLAN. Exit-capture idiom required
# — a failing `ls` under pipefail would kill the script before the guard.
REV_PLAN="$(ls -t "$WORKTREE/tests/fixtures/hello-roughly-plan-revision/.roughly/plans/"*-plan.md 2>/dev/null | head -1)" \
  && REV_PLAN_EXIT=0 || REV_PLAN_EXIT=$?
if [ "$REV_PLAN_EXIT" != 0 ] || [ -z "$REV_PLAN" ] || [ ! -f "$REV_PLAN" ]; then
  echo "ci-dogfood: FAIL — no plan-revision plan file found in $WORKTREE/tests/fixtures/hello-roughly-plan-revision/.roughly/plans/" >&2
  printf '%s\n' "$PLAN_REV_OUT" | sed 's/^/    /' >&2
  exit 1
fi
if ! head -1 "$REV_PLAN" | grep -qE '^> \*\*Status:\*\* Historical'; then
  echo "ci-dogfood: FAIL — plan-revision plan file at $REV_PLAN missing Status block on first line (the full pipeline may not have reached Stage 8)" >&2
  sed 's/^/    /' "$REV_PLAN" >&2
  exit 1
fi

echo "ci-dogfood: plan-revision scenario — NEEDS REVISION→PASS recovery confirmed ($PLAN_REV_VERDICTS verdict markers)"

# ──────────────────────────────────────────────────────────────────────
# Plan-clean CONTROL: clean task → review-plan PASSes first pass (E06.S3 AC2/AC3)
# ──────────────────────────────────────────────────────────────────────

# Fail loudly if the control fixture is absent from the worktree.
if [ ! -d "$WORKTREE/tests/fixtures/hello-roughly-plan-clean" ]; then
  echo "ci-dogfood: FAIL — plan-clean control fixture directory missing from worktree at $WORKTREE/tests/fixtures/hello-roughly-plan-clean (fixture may be untracked or the path changed)" >&2
  exit 1
fi
cd "$WORKTREE/tests/fixtures/hello-roughly-plan-clean"

# Same budget envelope as the recovery scenario — the ONLY difference is the
# task string (no anti-pattern instruction), isolating the NEEDS REVISION
# trigger to the rigged verify. Task string verbatim from the fixture README.
PLAN_CLEAN_OUT="$($TIMEOUT 270 claude --bare --plugin-dir "$WORKTREE" \
  --no-session-persistence --max-budget-usd 1.50 \
  -p "/roughly:build --ci add a NAME constant to src/greeter.sh and update the echo to use it" 2>&1)" \
  && PLAN_CLEAN_EXIT=0 || PLAN_CLEAN_EXIT=$?
if [ "$PLAN_CLEAN_EXIT" = 124 ]; then
  echo "ci-dogfood: FAIL — plan-clean control step timed out (claude did not return within 270s)" >&2
  printf '%s\n' "$PLAN_CLEAN_OUT" | sed 's/^/    /' >&2
  exit 1
fi
# The clean control completes the full pipeline: a non-zero exit here is a real
# failure.
if [ "$PLAN_CLEAN_EXIT" != 0 ]; then
  echo "ci-dogfood: FAIL — plan-clean control build exited non-zero — expected full completion (exit $PLAN_CLEAN_EXIT)" >&2
  printf '%s\n' "$PLAN_CLEAN_OUT" | sed 's/^/    /' >&2
  exit 1
fi

# Control assertion (a): exactly 1 plan-review verdict marker (clean first-pass
# PASS — no revision round). Count via `grep -Fo … | wc -l` for the same
# co-location-safety reason as the recovery block.
PLAN_CLEAN_VERDICTS="$(printf '%s\n' "$PLAN_CLEAN_OUT" | grep -Fo '[--ci] plan review verdict:' | wc -l | tr -d '[:space:]')"
if [ "$PLAN_CLEAN_VERDICTS" -ne 1 ]; then
  echo "ci-dogfood: FAIL — expected exactly 1 plan-review verdict marker (clean first-pass PASS), saw $PLAN_CLEAN_VERDICTS" >&2
  printf '%s\n' "$PLAN_CLEAN_OUT" | sed 's/^/    /' >&2
  exit 1
fi

# Control assertion (b): NO NEEDS REVISION marker (positive-guard form —
# `if grep` matches → FAIL — proves the NEEDS REVISION trigger is isolated to
# the rigged verify and does not fire on a clean task).
if printf '%s\n' "$PLAN_CLEAN_OUT" | grep -qF '[--ci] plan review verdict: NEEDS REVISION'; then
  echo "ci-dogfood: FAIL — plan-clean control unexpectedly triggered NEEDS REVISION" >&2
  printf '%s\n' "$PLAN_CLEAN_OUT" | sed 's/^/    /' >&2
  exit 1
fi

# Control assertion (c): a PASS verdict marker is present (sanity — the single
# verdict was a PASS, not some other verdict string).
if ! printf '%s\n' "$PLAN_CLEAN_OUT" | grep -qF '[--ci] plan review verdict: PASS'; then
  echo "ci-dogfood: FAIL — plan-clean control single verdict was not PASS (no PASS verdict marker)" >&2
  printf '%s\n' "$PLAN_CLEAN_OUT" | sed 's/^/    /' >&2
  exit 1
fi

# Control assertion (d): plan file written with Status block on its first line
# (proves the control completed the full pipeline through Stage 8). Distinct
# CLEAN_PLAN var avoids clobbering the other plan vars. Exit-capture idiom
# required — a failing `ls` under pipefail would kill the script before the guard.
CLEAN_PLAN="$(ls -t "$WORKTREE/tests/fixtures/hello-roughly-plan-clean/.roughly/plans/"*-plan.md 2>/dev/null | head -1)" \
  && CLEAN_PLAN_EXIT=0 || CLEAN_PLAN_EXIT=$?
if [ "$CLEAN_PLAN_EXIT" != 0 ] || [ -z "$CLEAN_PLAN" ] || [ ! -f "$CLEAN_PLAN" ]; then
  echo "ci-dogfood: FAIL — no plan-clean control plan file found in $WORKTREE/tests/fixtures/hello-roughly-plan-clean/.roughly/plans/" >&2
  printf '%s\n' "$PLAN_CLEAN_OUT" | sed 's/^/    /' >&2
  exit 1
fi
if ! head -1 "$CLEAN_PLAN" | grep -qE '^> \*\*Status:\*\* Historical'; then
  echo "ci-dogfood: FAIL — plan-clean control plan file at $CLEAN_PLAN missing Status block on first line (the full pipeline may not have reached Stage 8)" >&2
  sed 's/^/    /' "$CLEAN_PLAN" >&2
  exit 1
fi

echo "ci-dogfood: plan-clean control — clean first-pass PASS confirmed (1 verdict marker)"

# Post-state check: confirm no source-tree pollution
POST_STATE="$(git -C "$ROOT" status --porcelain)"
if [ "$PRE_STATE" != "$POST_STATE" ]; then
  echo "ci-dogfood: FAIL — source-tree pollution detected" >&2
  echo "  Pre-state:" >&2
  printf '%s\n' "$PRE_STATE" | sed 's/^/    /' >&2
  echo "  Post-state:" >&2
  printf '%s\n' "$POST_STATE" | sed 's/^/    /' >&2
  exit 1
fi

echo "ci-dogfood: SUCCESS — no source-tree pollution"
