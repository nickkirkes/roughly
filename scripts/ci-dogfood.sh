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
# Anchor: line start, optional list-decoration prefix (whitespace, dashes,
# asterisks, digits, dots, pipes — covers `- `, `* `, `1. `, `| `, indentation),
# the literal `/roughly:setup`, then EOL or whitespace. Rejects prose mentions
# (lines starting with a letter — "I have access to /roughly:setup ...") AND
# rejects substring drift (`/roughly:setupx`, `/roughly:setup-other` — char
# after command must be EOL or whitespace). Liberal enough to accept common
# list formats; strict enough to require evidence the model treated this as
# a command-list item, not prose.
if ! printf '%s\n' "$PLUGIN_OUT" | grep -qE "^[[:space:]0-9.*|-]*/roughly:setup($|[[:space:]])"; then
  echo "ci-dogfood: FAIL — plugin loading not verified (no /roughly:setup list-item line in output)" >&2
  printf '%s\n' "$PLUGIN_OUT" | sed 's/^/    /' >&2
  exit 1
fi

echo "ci-dogfood: smoke + plugin-load — both assertions passed"

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
