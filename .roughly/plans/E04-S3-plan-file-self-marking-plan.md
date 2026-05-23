# Implementation Plan: E04.S3 — Plan-file self-marking historical at completion

Plan-format-version: 1

## Scope summary

Generalize the S8 one-off Status-block mitigation into Stage 8 of build/fix and retro-mark all existing historical plans. After this story merges, every plan file in `.roughly/plans/` carries a `> **Status:** Historical — ...` blockquote so external review tools (cubic) treat them as historical reference, not actionable instructions. Stage 8 in both build and fix becomes a **2-commit pattern**: the existing implementation commit, then a second wrap-up commit that prepends the Status block to the plan file (SHA = the just-made implementation commit). This makes the SHA in the block semantically meaningful (per AC1: "wrap-up commit's parent = the implementation feat commit").

## File Table

| File | Action | Task(s) |
|------|--------|---------|
| `skills/build/SKILL.md` | Modify (Stage 8: insert new step 4, renumber 4→5, 5→6) | T1 |
| `skills/fix/SKILL.md` | Modify (Stage 8: insert new step 4, renumber 4→5, 5→6) | T2 |
| `CONTRIBUTING.md` | Modify (insert new `## Plan-file lifecycle` section after L88) | T3 |
| `.roughly/plans/*.md` (33 files) | Modify (Status block prepend via per-file Edit) | T4 |
| `scripts/ci-dogfood.sh` | Modify (insert new Status assertion after T1 assertion at L194) | T5 |

## Pre-implementation invariants

- `wc -l skills/build/SKILL.md` = **298** (2 lines headroom to 300 cap)
- `wc -l skills/fix/SKILL.md` = **299** (1 line headroom to 300 cap)
- T1 and T2 each add exactly **1 net line** per file (3 lines → 4 lines in a 3-line Edit window). Post-merge: build = 299, fix = 300. Both within the AC3 ≤300 cap. The line-cap budget contract's off-ramp is NOT invoked — this is a substitution-margin fit.
- `.roughly/plans/` currently contains 33 historical plan files (discovery report enumerates each). The E04.S3 plan file at `.roughly/plans/E04-S3-plan-file-self-marking-plan.md` is the 34th file but is **in-flight**, not historical — it is NOT in T4's sweep. It receives its Status block at Stage 8 of THIS build run via the new 2-commit pattern (with the meaningful implementation-commit SHA).

## Tasks

### T1: Add Stage 8 plan-historical-marking step to build/SKILL.md (~3 min)

**Files:** `skills/build/SKILL.md`
**Action:** Insert a new numbered step 4 into `## STAGE 8: WRAP-UP` (current lines 223–237) between the existing step 3 (commit) and step 4 (maturity checks). Renumber existing steps 4 and 5 to 5 and 6.

**Details:**

Single `Edit` call covering lines 235–237 (current step 3, 4, 5):

`old_string`:
```
3. Show commit for approval. Commit but do NOT push.
4. Run maturity checks (see below).
5. Ask: "Did this work reveal any new pitfalls or conventions for `.roughly/known-pitfalls.md`?" If yes, dispatch `doc-writer` agent.
```

`new_string`:
```
3. Show commit for approval. Commit but do NOT push.
4. **Plan historical marking (2nd commit, post-implementation):** Run `IMPL_SHA=$(git rev-parse HEAD)`. Prepend Status block to the plan file via `Edit` (not `Write` — append-only pitfall): `old_string` = the plan file's current first line; `new_string` = literal text `> **Status:** Historical — implemented and merged in commit <SHA> on <YYYY-MM-DD>. This plan was an active build/fix artifact; treat as historical reference only.` (substituting `$IMPL_SHA` for `<SHA>` and today's date for `<YYYY-MM-DD>`), then a blank line, then the original first line. Then `git add <plan-file>` and `git commit -m "docs: mark <feature> plan historical"` (do NOT push).
5. Run maturity checks (see below).
6. Ask: "Did this work reveal any new pitfalls or conventions for `.roughly/known-pitfalls.md`?" If yes, dispatch `doc-writer` agent.
```

Net delta: +1 line (3-line window → 4-line window).

**Verify:**
- `wc -l skills/build/SKILL.md` returns `299 skills/build/SKILL.md` (or smaller — must be ≤300).
- `grep -nE '^4\. \*\*Plan historical marking' skills/build/SKILL.md` returns exactly one match in the Stage 8 region (line ~236).
- `grep -c '^[0-9]\. ' skills/build/SKILL.md` for the Stage 8 region shows 6 numbered steps (was 5).

**UI:** no

---

### T2: Add Stage 8 plan-historical-marking step to fix/SKILL.md (~3 min)

**Files:** `skills/fix/SKILL.md`
**Action:** Same insertion as T1, applied to fix's Stage 8 (current lines 226–240). The only fix-specific divergence is the wording in step 6 (`"Did this fix reveal..."` vs `"Did this work reveal..."`); the new step 4 text is identical to T1.

**Details:**

Single `Edit` call covering lines 238–240 (current step 3, 4, 5):

`old_string`:
```
3. Show commit for approval. Commit but do NOT push.
4. Run maturity checks (see below).
5. Ask: "Did this fix reveal any new pitfalls or conventions for `.roughly/known-pitfalls.md`?" If yes, dispatch `doc-writer` agent.
```

`new_string`:
```
3. Show commit for approval. Commit but do NOT push.
4. **Plan historical marking (2nd commit, post-implementation):** Run `IMPL_SHA=$(git rev-parse HEAD)`. Prepend Status block to the plan file via `Edit` (not `Write` — append-only pitfall): `old_string` = the plan file's current first line; `new_string` = literal text `> **Status:** Historical — implemented and merged in commit <SHA> on <YYYY-MM-DD>. This plan was an active build/fix artifact; treat as historical reference only.` (substituting `$IMPL_SHA` for `<SHA>` and today's date for `<YYYY-MM-DD>`), then a blank line, then the original first line. Then `git add <plan-file>` and `git commit -m "docs: mark <feature> plan historical"` (do NOT push).
5. Run maturity checks (see below).
6. Ask: "Did this fix reveal any new pitfalls or conventions for `.roughly/known-pitfalls.md`?" If yes, dispatch `doc-writer` agent.
```

Net delta: +1 line (3-line window → 4-line window).

**Verify:**
- `wc -l skills/fix/SKILL.md` returns `300 skills/fix/SKILL.md` (must be ≤300 — at cap).
- `grep -nE '^4\. \*\*Plan historical marking' skills/fix/SKILL.md` returns exactly one match.

**UI:** no

---

### T3: Add `## Plan-file lifecycle` section to CONTRIBUTING.md (~4 min)

**Files:** `CONTRIBUTING.md`
**Action:** Insert a new top-level section between `## Migration` (body ends at L87) and `## Testing` (starts at L89).

**Details:**

Use a single `Edit`. The Migration body is one expanded paragraph (from E04.S1); use its tail + the `## Testing` heading as a minimal unique anchor:

`old_string`:
```
redirects to `/roughly:upgrade`.

## Testing
```

`new_string`:
```
redirects to `/roughly:upgrade`.

## Plan-file lifecycle

Plan files in `.roughly/plans/` are build/fix pipeline artifacts. Once the pipeline's wrap-up stage completes, the plan is historical reference — not actionable instructions.

At Stage 8 of every successful build/fix run, the orchestrator prepends a Status block to the plan file in a second wrap-up commit:

```
> **Status:** Historical — implemented and merged in commit <SHA> on <YYYY-MM-DD>. This plan was an active build/fix artifact; treat as historical reference only.
```

The SHA is the implementation feat commit (parent of the wrap-up commit). The date is the wrap-up date. Format is fully specified — no LLM creative writing.

This signals to external review tools (cubic and similar) that the plan content is historical reference, not actionable instructions. Without it, plan files accumulate as stale prose that cubic reads as live findings during later reviews (the S8 retrospective surfaced this; root cause for two late P2 findings during the S8 review pass).

Existing plans were retro-marked in E04.S3 via a one-shot `Edit` sweep. Each plan's SHA + date came from its first-add commit: `git log --diff-filter=A --follow --format='%H %ad' --date=short -- <plan-file> | tail -1`. The `--follow` flag is required to trace through the E04.S1 rename (`docs/plans/` → `.roughly/plans/`); without it, pre-E04.S1 plans return the rename commit, not the original add.

## Testing
```

⚠ The subagent should Read CONTRIBUTING.md L83–89 before the Edit to confirm the anchor matches verbatim. The `old_string` above uses the minimal unique tail; if it fails to match (e.g., the Migration body has been further expanded since plan-write), Read first and use the file's actual content.

**Verify:**
- `grep -c '^## Plan-file lifecycle$' CONTRIBUTING.md` returns 1.
- `grep -n '^## ' CONTRIBUTING.md` shows `Plan-file lifecycle` between `Migration` and `Testing`.
- Section body is roughly 10–15 content lines (AC4).

**UI:** no

---

### T4: Retro-mark sweep — prepend Status block to 33 historical plans in `.roughly/plans/` (~12 min)

**Files:** all 33 files listed below in `.roughly/plans/`. The E04.S3 plan file (`E04-S3-plan-file-self-marking-plan.md`) is **NOT** in this sweep — it gets its Status block at Stage 8 of this build run.

**Action:** For each file, prepend a Status block using the file's first-add commit SHA + date. Each prepend is a per-file `Edit` (one call per file, `replace_all: false`).

**Details:**

For each file in the list:

1. Compute SHA + date:
   ```bash
   git log --diff-filter=A --follow --format='%H %ad' --date=short -- .roughly/plans/<filename> | tail -1
   ```
   Returns `<SHA> <YYYY-MM-DD>` on one line. Capture both fields.

2. Read the file's current first line (use the table below as expected `old_string`; verify by Reading the file's first line before `Edit` since whitespace/exact-match matters).

3. Issue an `Edit` call:
   - `old_string` = the file's first line, verbatim (from the table below)
   - `new_string` = `> **Status:** Historical — implemented and merged in commit <SHA> on <YYYY-MM-DD>. This plan was an active build/fix artifact; treat as historical reference only.` + newline + blank line + original first line
   - `replace_all: false`

**Full file list with expected `old_string` first lines** (from discovery — re-verify per file before Edit):

| # | File | First line (expected `old_string`) |
|---|------|-----------------------------------|
| 1 | `E01-S4-error-handling-disambiguation-plan.md` | `# Implementation Plan: E01.S4 — Error handling disambiguation` |
| 2 | `E03-S0-plan-mode-detection-spike-plan.md` | `# Implementation Plan: E03.S0 — Plan-mode detection spike` |
| 3 | `E03-S1-plan-mode-auto-detect-plan.md` | `# Implementation Plan: E03.S1 — Plan-mode auto-detect/exit at Stage 1 of build/fix` |
| 4 | `E03-S10-retry-loop-tuning-plan.md` | `# Implementation Plan: E03.S10 — Retry-loop tuning` |
| 5 | `E03-S11a-plugin-self-test-ci-scaffolding-plan.md` | `# Implementation Plan: E03.S11a Plugin self-test CI scaffolding` |
| 6 | `E03-S11b-1-plan.md` | `Plan-format-version: 1` ⚠ (non-title first line — see note below) |
| 7 | `E03-S11b-2-scripted-dogfood-happy-path-build-cycle-plan.md` | `# Implementation Plan: E03.S11b-2 Scripted dogfood happy-path build cycle` |
| 8 | `E03-S2-stop-hook-v1-plan.md` | `# Implementation Plan: E03.S2 — Stop-hook-v1 maturity check completion` |
| 9 | `E03-S3-retire-maturity-checks-plan.md` | `# Implementation Plan: E03.S3 — Retire test-verify-v1 and pitfalls-organized-v1` |
| 10 | `E03-S4-pre-flight-migration-check-plan.md` | `# Implementation Plan: E03.S4 — Pre-flight migration check in remaining 2 skills` |
| 11 | `E03-S5-tooling-pitfalls-plan.md` | `# Implementation Plan: E03.S5 — Tooling Pitfalls section in CONTRIBUTING.md` |
| 12 | `E03-S6-plan-format-version-field-plan.md` | `# Implementation Plan: E03.S6 — Plan-format version field` |
| 13 | `E03-S8-help-command-plan.md` | `# Implementation Plan: E03.S8 — \`/roughly:help\` command` |
| 14 | `E03-S9-abort-prose-plan.md` | `# Implementation Plan: E03.S9 — Situation-specific abort prose at every pipeline failure point` |
| 15 | `E04-S1-plan-path-consolidation-plan.md` | `# Implementation Plan: E04.S1 — Plan-path consolidation \`docs/plans/\` → \`.roughly/plans/\`` |
| 16 | `E04-S2-marker-aware-resume-reporting-plan.md` | `# Implementation Plan: E04.S2 — Marker-aware resume reporting in \`/roughly:upgrade\`` |
| 17 | `E04-S4-dogfood-verify-all-cleanup-plan.md` | `# Implementation Plan: E04.S4 — Dogfood \`.claude/hooks/verify-all.sh\` cleanup` |
| 18 | `E04-S5-stop-hook-drift-coverage-expansion-plan.md` | `# Implementation Plan: E04.S5 Stop Hook Drift Coverage Expansion` |
| 19 | `E04-S6-plan-discipline-codification-plan.md` | `# Implementation Plan: E04.S6 — Plan-discipline codification` |
| 20 | `E04-S7-adr-011-skill-flags-plan.md` | `# Implementation Plan: E04.S7 — ADR-011 Skill Flags as Public API` |
| 21 | `E04-S8-doc-writer-multi-file-guard-plan.md` | `# Implementation Plan: E04.S8 — doc-writer multi-file-invocation guard` |
| 22 | `E04-S9-ci-dogfood-polish-plan.md` | `# Implementation Plan: E04.S9 — CI dogfood polish (macOS \`gtimeout\` + \`ANTHROPIC_API_KEY\` empty-guard)` |
| 23 | `S02.5-documentation-plan.md` | `# Implementation Plan: S02.5 Documentation prose + ADR footnotes` |
| 24 | `S02.7-final-verification-plan.md` | `# Implementation Plan: S2.7 — Final Verification, Version Bump, CHANGELOG, Tag` |
| 25 | `S2.3-agent-preamble-sync-plan.md` | `# Implementation Plan: S2.3 — Agent preamble sync (\`.ruckus/\` → \`.roughly/\`)` |
| 26 | `audit-epic-batching-plan.md` | `# Implementation Plan: E01.S6 — Audit-epic Token Budget Batching` |
| 27 | `e01-s1-directory-rename-plan.md` | `# Implementation Plan: E01.S1 — Rename \`docs/claude/\` to \`.ruckus/\`` |
| 28 | `e01-s2-pipeline-loop-caps-plan.md` | `# Implementation Plan: S2 — Pipeline Loop Caps` |
| 29 | `fix-E01-S7-setup-upgrade-hardening-plan.md` | `# Fix Plan: E01.S7 — Setup and Upgrade Hardening` |
| 30 | `fix-E01-S8-documentation-accuracy-plan.md` | `# Fix Plan: E01.S8 — Documentation Accuracy` |
| 31 | `fix-E01-audit-findings-plan.md` | `# Fix Plan: E01 Audit Findings + Upgrade Agent Installation Bug` |
| 32 | `fix-E03-audit-doc-hygiene-plan.md` | `# Fix Plan: E03 audit doc-hygiene findings` |
| 33 | `s5-agent-preamble-drift-plan.md` | `# Implementation Plan: E01.S5 Agent Preamble Drift Documentation and Detection` |

⚠ **Special case — file #6 (`E03-S11b-1-plan.md`):** The first line is `Plan-format-version: 1`, not a title. The `Edit` still works (prepend before line 1 regardless of content); the resulting file will have the Status block at line 1, the `Plan-format-version: 1` field at line 3 (with blank line 2 between). This is a minor formatting oddity but functionally correct — Status block is at line 1 for all 33 files post-sweep, which is what the AC5 verify command checks.

⚠ **Pitfall: `--follow` is required** (per discovery). Without `--follow`, pre-E04.S1 plans return the rename commit `4939875` as the "first add," which is semantically wrong. Use `--follow` for ALL files in this list. (Post-S1 plans like `E04-S9` don't need `--follow` but it's harmless to apply uniformly.)

⚠ **Pitfall: each `old_string` must be unique** (no `replace_all: true`). Spot-check: all 33 first lines are distinct (verified at discovery). If any two collided, Edit would refuse the call.

**Verify:**
- `grep -L "^> \*\*Status:\*\* Historical" .roughly/plans/*.md` returns exactly one line: the E04.S3 plan file path. (`wc -l` of that grep returns 1 — the S3 plan, which is in-flight and gets marked at Stage 8.)
- `grep -c "^> \*\*Status:\*\* Historical" .roughly/plans/*.md | grep -vc ':0$'` returns 33 (33 files have a Status block; only the S3 plan returns `:0`).
- For 3 spot-check files (one pre-S1, one post-S1, one fix-): confirm the SHA and date in the prepended block matches `git log --diff-filter=A --follow --format='%H %ad' --date=short -- <file> | tail -1` output. Spot checks: `E01-S4-error-handling-disambiguation-plan.md` (pre-S1, expected ~`17cf10a 2026-04-25`), `E04-S9-ci-dogfood-polish-plan.md` (post-S1, expected ~`f3ff1ed 2026-05-22`), `fix-E01-audit-findings-plan.md` (a fix plan).
- `git diff --stat .roughly/plans/` shows 33 files changed; each insertion is exactly 2 lines added (Status block + blank line), zero lines removed.

**UI:** no

---

### T5: Add Status block assertion to CI dogfood script (~3 min)

**Files:** `scripts/ci-dogfood.sh`
**Action:** Two edits in this task:
1. Insert a new "Assertion 5: Status block" between Assertion 4 (ends L194) and Assertion 5a (starts L196).
2. Update the summary echo at L247 from `all 6 structural assertions passed` to `all 7 structural assertions passed` (preserve the existing off-by-one convention — do NOT try to reconcile pre-existing count drift in this story).

**Details:**

The script uses no `pass`/`fail` helper functions. The real pattern is: silent on individual pass, `echo "ci-dogfood: FAIL — ..." >&2` + diagnostic dump + `exit 1` on individual fail, single summary `echo` at the end of all assertions. Match this convention exactly.

**Edit 1 — insert new assertion block (between L194 `fi` and L196 `# Assertion 5a:`):**

`old_string`:
```
fi

# Assertion 5a: NAME= assignment present at line start (proves the constant
```

`new_string`:
```
fi

# Assertion 5: plan file's first line is the Status block marker (proves
# the new Stage 8 plan-historical-marking step ran — E04.S3). The block
# format is fully specified per CONTRIBUTING.md "Plan-file lifecycle";
# this assertion only checks the opening marker pattern, not the SHA or
# date fields (those are runtime-dependent).
if ! grep -qE '^> \*\*Status:\*\* Historical' "$PLAN_FILE"; then
  echo "ci-dogfood: FAIL — plan file at $PLAN_FILE missing Status block (expected '> **Status:** Historical — ...' on first line; the build skill's new Stage 8 step 4 may not have run)" >&2
  sed 's/^/    /' "$PLAN_FILE" >&2
  exit 1
fi

# Assertion 5a: NAME= assignment present at line start (proves the constant
```

**Edit 2 — update the summary echo at L247:**

`old_string`:
```
echo "ci-dogfood: full-scenario — all 6 structural assertions passed"
```

`new_string`:
```
echo "ci-dogfood: full-scenario — all 7 structural assertions passed"
```

(Note: the pre-existing count of 6 is itself off-by-one against actual if-block count — Assertions 1, 2, 3, 4, 5a, 5b, 5c = 7 blocks vs. echo's "6". The plan deliberately preserves the existing convention by incrementing by 1; reconciling the prior drift is out of scope for E04.S3.)

**Verify:**
- `bash -n scripts/ci-dogfood.sh` exits 0 (syntax valid).
- `grep -nE '^# Assertion 5:' scripts/ci-dogfood.sh` returns exactly one match (around L196).
- `grep -c 'all 7 structural assertions passed' scripts/ci-dogfood.sh` returns 1; `grep -c 'all 6 structural assertions passed' scripts/ci-dogfood.sh` returns 0.
- `shellcheck scripts/ci-dogfood.sh` returns no new findings beyond the 2 pre-existing info-level warnings (per memory observation 1842).

**UI:** no

---

## Blast Radius

- **Do NOT modify** outside the file table above. In particular:
  - Do not modify any file under `.roughly/plans/` beyond the Status-block prepend (T4).
  - Do not modify `skills/build/SKILL.md` or `skills/fix/SKILL.md` beyond the single Stage 8 step insertion (T1/T2). No other stage prose changes; no preamble edits; no MATURITY CHECKS / ABORT HANDLING extraction (off-ramp not required).
  - Do not modify `agents/*` — there is no agent change in this story.
  - Do not modify `verify-all.sh` — the cubic gate is a human-run check, not a hook addition.
- **Watch for line-cap regressions** on build (≤299 post-T1) and fix (≤300 post-T2). The fix file is at the absolute cap; any unrelated edit that adds even 1 line would breach.
- **Watch for Edit collisions** on T4 — each of the 33 plans has a unique first line; `replace_all: false` is mandatory.
- **Watch for the S3 plan being swept by T4 mistakenly.** T4's file list is explicit (33 named files); `.roughly/plans/E04-S3-plan-file-self-marking-plan.md` is NOT in the list and must not be marked until Stage 8 of THIS build run.

## Conventions

- **AC1 — Status block format is fully specified.** No LLM creative writing. Template (with literal `<SHA>` and `<YYYY-MM-DD>` placeholders to be substituted at use site):
  ```
  > **Status:** Historical — implemented and merged in commit <SHA> on <YYYY-MM-DD>. This plan was an active build/fix artifact; treat as historical reference only.
  ```
- **AC2 — `Edit` not `Write`** for all prepend operations (T1, T2, T3, T4). Pure prepend: `old_string` = first line(s), `new_string` = new content + original first line(s). See `.roughly/known-pitfalls.md` L84 (append-only pitfall) and L86 (`replace_all: true` caution).
- **AC3 — Line cap ≤300** for build/SKILL.md and fix/SKILL.md post-merge.
- **AC4 — `## Plan-file lifecycle` section in CONTRIBUTING.md** documents the format, when it's added (Stage 8), what it signals to external review tools. 10–15 content lines.
- **AC5 — Sweep covers all historical plans** in `.roughly/plans/`. Verify command: `grep -L "^> \*\*Status:\*\* Historical" .roughly/plans/*.md | wc -l` returns 1 during this build run (only the S3 plan unmarked; S3 plan marked at Stage 8 → 0 post-Stage-8).
- **Stage 8 is a 2-commit pattern** in the new flow. First commit: `feat: ...` containing all implementation work (T1–T5). Second commit: `docs: mark E04.S3 plan historical` containing only the Status-block prepend to the S3 plan file. The Status block's SHA references the first commit (= `git rev-parse HEAD` after first commit, before second commit).
- **Cubic gate is a manual pre-merge step** (per discovery — no hook automation). After the wrap-up commit on this branch, the human runs `cubic review --json` against 2–3 retro-marked plans + the S3 plan itself. Required: cubic does not flag the Status block content as actionable. If it does, the story does not ship — format must be adjusted (candidates: `<!-- CUBIC-IGNORE: historical -->` markers, different blockquote shape, relocation). This is in scope of THIS build run's Stage 6/7 verification — it cannot be deferred.

## Dependencies and ordering

- E04.S1 (already merged) — provides `.roughly/plans/` location for T4 sweep.
- Task order: T1 → T2 → T3 → T4 → T5. T1 and T2 are near-identical; T3 is standalone; T4 is the large sweep; T5 is the smallest. No hard dependencies between tasks at the file level (no two tasks touch the same file), so tasks can be parallelized in principle. Recommend sequential execution per the build skill's "for each task in order" convention.

## Out of scope (per epic L185–189)

- Changing plan-file content beyond the prepended Status block (plan-format-v2 is v0.2.0).
- Marking review-plan findings, spike docs, or audit reports as historical.
- Automated re-marking on plan-file mutation post-completion (one-shot at Stage 8 only).
- Delegating the Stage 8 marking step to `doc-writer` (decided against at PM time — different trigger surface).
- Invoking the line-cap budget off-ramp (not needed; substitution-margin fits within cap).
