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
SMOKE_OUT="$(timeout 25 claude --bare --plugin-dir "$WORKTREE" \
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
PLUGIN_OUT="$(timeout 25 claude --bare --plugin-dir "$WORKTREE" \
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
SCENARIO_OUT="$(timeout 270 claude --bare --plugin-dir "$WORKTREE" \
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

# Assertion 1: synthetic-PASS marker present (proves Stage 4 took the
# --ci branch instead of attempting real review-plan dispatch; AC5).
# Full-string match (-F) keeps this in lockstep with skills/build/SKILL.md
# Stage 4's emit instruction — drift in either side fails CI loudly.
if ! printf '%s\n' "$SCENARIO_OUT" | grep -qF '[--ci] plan review skipped — synthetic PASS'; then
  echo "ci-dogfood: FAIL — synthetic-PASS marker missing (Stage 4 may have attempted real review-plan dispatch despite --ci)" >&2
  printf '%s\n' "$SCENARIO_OUT" | sed 's/^/    /' >&2
  exit 1
fi

# Assertion 2: plan file exists (proves Stage 3 ran, plan was written).
# Exit-capture idiom required: under set -euo pipefail with pipefail, a
# failing `ls` (no matches, missing dir) propagates through the pipe and
# would silently kill the script before the [-z "$PLAN_FILE"] guard runs.
PLAN_FILE="$(ls "$WORKTREE/tests/fixtures/hello-roughly/docs/plans/"*-plan.md 2>/dev/null | head -1)" \
  && PLAN_FILE_EXIT=0 || PLAN_FILE_EXIT=$?
if [ "$PLAN_FILE_EXIT" != 0 ] || [ -z "$PLAN_FILE" ] || [ ! -f "$PLAN_FILE" ]; then
  echo "ci-dogfood: FAIL — no plan file found in $WORKTREE/tests/fixtures/hello-roughly/docs/plans/" >&2
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
# with a parallel statement or redirected). The character class
# [#;&|<>] covers every shell construct that terminates or redirects
# the original `echo "hello"` while leaving its output behavior intact:
# `;`, `&`, `&&`, `|`, `||`, `>`, `>>`, `<`, `<<`, `#` (trailing
# comment), or end-of-line. Multi-char operators (`&&`, `||`, `>>`,
# `<<`, `<<<`) all start with one of these chars, so single-char match
# captures them. Valid extended echos do NOT match because `"`, `$`, or
# bare-word args after `echo "hello"` are NOT in this class, so the
# regex correctly accepts: `echo "hello" "$NAME"`, `echo "hello $NAME"`,
# `echo "hello, $NAME"`, `echo "hello" $NAME`, `echo "hello" world`.
if grep -qE '^[[:space:]]*echo "hello"[[:space:]]*($|[#;&|<>])' "$WORKTREE/tests/fixtures/hello-roughly/src/greeter.sh"; then
  echo "ci-dogfood: FAIL — src/greeter.sh still contains the original \`echo \"hello\"\` statement unchanged (preserved via redirect, pipe, sequence, or as-is); the echo was added to, not updated" >&2
  sed 's/^/    /' "$WORKTREE/tests/fixtures/hello-roughly/src/greeter.sh" >&2
  exit 1
fi

echo "ci-dogfood: full-scenario — all 6 structural assertions passed"

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
