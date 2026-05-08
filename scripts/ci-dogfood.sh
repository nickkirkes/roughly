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

# Create ephemeral worktree and enter it
git -C "$ROOT" worktree add "$WORKTREE" HEAD
cd "$WORKTREE"

# ──────────────────────────────────────────────────────────────────────
# STUB: real claude invocation lands in S11b-1 (smoke test) and S11b-2
# (full scenario). For now this is a no-op that returns 0.
# ──────────────────────────────────────────────────────────────────────
echo "ci-dogfood: stub claude invocation, returning 0"

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
