# Implementation Plan: E04.S4 — Dogfood `.claude/hooks/verify-all.sh` cleanup

## Summary

Backport the E03.S2 user-facing-template fix to this repo's own dogfood Stop hook. Two surgical edits to `.claude/hooks/verify-all.sh`:
1. Delete `set -e` on line 6 (preserve `shopt -s nullglob` on line 7 verbatim)
2. Add `|| true` inside the `git rev-parse` command substitution on line 9

Net diff: 1 line removed, 1 line modified. No other body changes.

## File Table

| File | Action | Task(s) |
|------|--------|---------|
| `.claude/hooks/verify-all.sh` | Modify | T1, T2 |

## Tasks

### T1: Remove `set -e` from line 6 (~1 min)

**Files:** `.claude/hooks/verify-all.sh`

**Action:** Delete the entire line 6 (`set -e`). Do not replace it with anything. Do not insert a comment. The blank line between line 4's comment block and line 7's `shopt -s nullglob` should NOT be preserved — line 7 should move up to where line 6 was.

**Details:**
- Current line 6 reads exactly: `set -e`
- Current line 7 reads exactly: `shopt -s nullglob  # globs that match nothing expand to empty, not literal pattern`
- After this task, what was line 7 becomes the new line 6 (the `shopt -s nullglob` line), and what was line 8 (blank) becomes the new line 7.
- Use the Edit tool with the trailing comment on the `shopt` line included on BOTH sides (Edit requires exact byte-sequence matching — without the trailing comment, the match would fail).
- `old_string` (two lines, exact): `set -e` then newline then `shopt -s nullglob  # globs that match nothing expand to empty, not literal pattern`
- `new_string` (one line, exact): `shopt -s nullglob  # globs that match nothing expand to empty, not literal pattern`
- The trailing comment text `# globs that match nothing expand to empty, not literal pattern` MUST be preserved verbatim on the `shopt` line in the result.

**Verify:** `grep -n '^set -e' .claude/hooks/verify-all.sh` returns no output (exit 1). `grep -n 'shopt -s nullglob' .claude/hooks/verify-all.sh` returns the line with its exact original suffix `# globs that match nothing expand to empty, not literal pattern`.

**UI:** no

---

### T2: Add `|| true` to `git rev-parse` on line 9 (~1 min)

**Files:** `.claude/hooks/verify-all.sh`

**Depends on:** None — Edit matches by content not line number, so T1 and T2 are ordering-independent. Line-number references in this doc assume T1 applied first, but the Edit calls themselves don't require that order.

**Action:** Modify the `git rev-parse` command substitution to append `|| true` inside the `$(...)` — making the fail-soft explicit and behaviorally independent of `set -e`.

**Details:**
- Pre-T1 line 9 / post-T1 line 8 reads exactly: `ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"`
- Target shape (mirrors `skills/setup/templates/verify-all-stop-hook.sh.template` line 30): `ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"`
- Use the Edit tool with old_string `ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"` and new_string `ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"`.
- The `|| true` MUST be inside the `$(...)`, not outside. Outside would be wrong syntax (assignment can't fail-soft to a literal). The verification step will catch this.

**Verify:** `grep -Fn 'ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"' .claude/hooks/verify-all.sh` returns exactly one match.

**UI:** no

---

## Blast Radius

**Do NOT modify (preserve byte-for-byte):**
- Line 7's `shopt -s nullglob` directive and its trailing comment `# globs that match nothing expand to empty, not literal pattern`
- Lines 10–12: the `if [ -z "$ROOT" ] || [ ! -f "$ROOT/.claude-plugin/plugin.json" ]; then exit 0; fi` no-op guard
- Line 13's `cd "$ROOT"`
- The four existing check blocks (path drift, skill line cap, agent word cap, HTML comment integrity) — lines 15-onward up to `emit_drift_json`
- The `emit_drift_json` function and its `jq → python3 → no-emit` fallback chain
- `.claude/settings.json` — the Stop hook entry there already has its own `git rev-parse 2>/dev/null` guard on the outer wrapper, out of scope

**Do NOT add:**
- `set -uo pipefail`, `set -u`, or any other `set -X` flag — explicitly forbidden by AC5
- Any new comment explaining the removal (per discovery: "do not replace it, do not add a comment in its place")
- Any refactor or improvement to the existing four checks
- Backports of any other non-S2-template changes

**Watch for:**
- The `|| true` belongs INSIDE the `$(...)`, not after the closing quote on the assignment.
- Some shells/editors strip trailing whitespace on save — verify line 7's trailing comment is preserved exactly.

## Conventions

- This mirrors the existing fix already shipped in `skills/setup/templates/verify-all-stop-hook.sh.template` (E03.S2). The dogfood hook is intentionally project-specific (per CONTRIBUTING.md and E03.S2's documented divergence), but the `set -e` + `git rev-parse` latent bug is universal — backporting it does not collapse the intentional divergence.
- ADR-N/A — no architectural decision; this is a single-file latent-bug backport.
- Edits should be done via the Edit tool with exact string matching to guarantee no accidental whitespace damage.

## Acceptance Criteria Mapping

| AC | Task | Verification |
|----|------|--------------|
| AC1 (no `set -e` on line 6, line 7 preserved) | T1 | `grep -n '^set -e'` returns nothing; `shopt` line intact |
| AC2 (line 9 has `\|\| true` suffix) | T2 | `grep -Fn 'ROOT="$(git rev-parse --show-toplevel 2>/dev/null \|\| true)"'` returns 1 match |
| AC3 (no other body changes) | T1+T2 | `git diff --stat` shows 1 file, 2 deletions and 1 insertion (the modify counts as -1/+1, the `set -e` removal counts as -1/+0) |
| AC4 (still emits JSON, still exits 0, still silent no-op outside repo) | T1+T2 | Stage 7 verify-all + manual outside-repo invocation |
| AC5 (no `set -uo pipefail` added) | T1 | `grep -n 'set -uo pipefail\|set -u\|pipefail' .claude/hooks/verify-all.sh` returns nothing |

## Story-Level Verification (Stage 7)

1. **Inside-repo invocation:** Triggered automatically by Stop hook at end of build. Hook should silently no-op on a clean tree (no drift output).
2. **Outside-repo invocation:** `cp .claude/hooks/verify-all.sh /tmp/verify-all-test.sh && bash /tmp/verify-all-test.sh < /dev/null; echo "exit=$?"` → must print only `exit=0`. Pre-fix: script dies on the `git rev-parse` line under `set -e` (silent non-zero). Post-fix: hits the `if [ -z "$ROOT" ]` guard and exits 0 cleanly.
3. **`bash -n` syntax check:** `bash -n .claude/hooks/verify-all.sh` returns no errors.
