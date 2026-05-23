> **Status:** Historical — implemented and merged in commit 5bf8f3623e70ff2e29ae09104fc5598e3f60618d on 2026-05-11. This plan was an active build/fix artifact; treat as historical reference only.

# Implementation Plan: E03.S10 — Retry-loop tuning

**Story:** E03.S10 (docs/planning/epics/E03-trust-and-ergonomics.md#L581-L641)
**OQ3 status:** Ratified 2026-05-10 — five per-cap dispositions locked.
**Implementation path:** **Path C** (single auto-fix cap raised to 4; test-fix conditional escalates after attempt 2). Selected by user pre-implementation.

## Path C reframe (resolved at plan-write)

The epic frames the test-fix conditional as "if Stage 5c was hit by changes to test files," which is file-path-based and brittle (no test-file detection mechanism exists; conventions vary across user projects). Per discovery, the corrected framing is **command-output-based**: classify by which command failed (type-check / lint / format vs the test command). The orchestrator already runs configured commands from CLAUDE.md and observes their outputs — the failing command is immediately knowable.

**Conditional wording (canonical for both files):** parenthetical inline addition ending with `— if the failing check was the test command, escalate after attempt 2 instead of 4 (OQ3 #4: open-ended; runaway test-rewriting is a known failure mode)`.

This eliminates Path C's ambiguity. No fallback to Path B required.

## Line-budget plan (mandatory constraint)

Build SKILL.md is at 298/300; fix SKILL.md is at 299/300. Net delta budget: build +2, fix +1.

**All three OQ3 rationale annotations are appended as inline parenthetical clauses on existing cap lines — never new lines.** This is non-negotiable for fix's 1-line headroom. The only new line in each file is the test-fix conditional inserted as a continuation of the auto-fix bullet.

Per-file expected delta: **+0 lines** (the test-fix conditional is appended as a parenthetical to the existing auto-fix bullet, NOT as a new line).

Verification: `wc -l` after each file edit must show 298 (build) and 299 (fix) unchanged.

## File Table

| File | Action | Task(s) |
|------|--------|---------|
| skills/build/SKILL.md | Modify (3 surgical edits) | T1 |
| skills/fix/SKILL.md | Modify (3 surgical edits, parity-synced with T1) | T2 |
| CHANGELOG.md | Append entry under `[Unreleased] v0.1.5 — Changed` | T3 |
| docs/plans/E03-S10-retry-loop-tuning-plan.md | (this plan; created at Stage 3) | — |

## Tasks

### T1: Update Stage 5c and Stage 6 caps in build/SKILL.md (~5 min)

**Files:** skills/build/SKILL.md

**Action:** Apply three surgical edits per OQ3 dispositions, keeping line count at 298.

**Details:**

Use `Edit` (not `replace_all`) — `max 2` appears in multiple semantic roles and must not be globally substituted.

Before editing, run `grep -n 'max 2\|max 4' skills/build/SKILL.md` to confirm current line numbers. As of 2026-05-10 7:44am these are L176, L180, L185, L203 — but verify, do not trust the plan.

**Edit 1 — Stage 5c questions cap (OQ3 #1, keep at 2):**
- Locate: `- If the subagent returned questions: answer them, re-dispatch (max 2; then escalate to human).`
- Replace with: `- If the subagent returned questions: answer them, re-dispatch (max 2; then escalate to human — OQ3 #1: questions interrupt fresh subagents, raising risks runaway clarification loops).`

**Edit 2 — Stage 5c auto-fix cap (OQ3 #2/#3/#4, raise to 4 with test-fix conditional):**
- Locate: `- If it fails on files this task owns: attempt auto-fix (max 2 attempts); if still failing, escalate to human.`
- Replace with: `- If it fails on files this task owns: attempt auto-fix (max 4 attempts; if the failing check was the test command, escalate after attempt 2 instead — OQ3 #2/#3/#4, Path C); if still failing, escalate to human. If unclear which command failed, default to cap 2 (conservative).`
- Then locate: `**If quality check auto-fix fails after 2 attempts:** escalate to human.`
- Replace with: `**If quality check auto-fix fails after the applicable cap (4 for type-check/lint, 2 for test):** escalate to human.`

**Edit 3 — Stage 6 review-fix cycles cap (OQ3 #5, keep at 2):**
- Locate: `Fix critical findings and re-run review (max 2 review-fix cycles; if still failing, present findings to human).`
- Replace with: `Fix critical findings and re-run review (max 2 review-fix cycles; if still failing, present findings to human — OQ3 #5: most expensive loop in the pipeline, conversion-to-prompt deferred pending v0.1.5 dogfood evidence).`

**Verify:**
- `wc -l skills/build/SKILL.md` returns `298` (no new lines added)
- `grep -n 'OQ3 #1\|OQ3 #2/#3/#4\|OQ3 #5' skills/build/SKILL.md` returns 3 matches
- `grep -n 'max 4\|max 2' skills/build/SKILL.md` returns 4+ matches consistent with the changes (questions L176, auto-fix L180, summary L185, Stage 6 L203)

**UI:** no

---

### T2: Update Stage 5c and Stage 6 caps in fix/SKILL.md (~5 min)

**Files:** skills/fix/SKILL.md

**Depends on:** T1 (text reused for parity)

**Action:** Apply the three same surgical edits to fix/SKILL.md — text byte-identical to T1's three replacements where possible.

**Details:**

Pre-existing intentional divergence between build and fix Stage 5c: build line `**If both stages pass:** mark task complete in TodoWrite, proceed to next task.` versus fix line `**If both stages pass:** mark task complete, proceed to next task.` — preserve this divergence; do not normalize. S10 is out of scope for that.

Use the same three Edit operations as T1, targeting the analogous lines in fix/SKILL.md.

Before editing, grep for current line numbers — as of 2026-05-10 7:44am they are L183, L187, L192, L206.

**Edits 1 and 2:** Same `Edit` payloads as T1's Edits 1 and 2 — verbatim text (the questions cap and auto-fix cap lines are byte-identical between build and fix).

**Edit 3 differs from T1.** The Stage 6 sentence in fix/SKILL.md is prefixed with `Invoke /roughly:review with a description of the fix.` — apply the parenthetical extension to the full sentence:
- Locate: `Invoke /roughly:review with a description of the fix. Fix critical findings and re-run (max 2 review-fix cycles; if still failing, present findings to human).`
- Replace with: `Invoke /roughly:review with a description of the fix. Fix critical findings and re-run (max 2 review-fix cycles; if still failing, present findings to human — OQ3 #5: most expensive loop in the pipeline, conversion-to-prompt deferred pending v0.1.5 dogfood evidence).`

**Verify:**
- `wc -l skills/fix/SKILL.md` returns `299` (no new lines added)
- `grep -n 'OQ3 #1\|OQ3 #2/#3/#4\|OQ3 #5' skills/fix/SKILL.md` returns 3 matches
- `grep -n 'max 4\|max 2' skills/fix/SKILL.md` returns 4+ matches consistent with changes
- **Parity check:** `diff <(sed -n '/^### 5c/,/^### 5d/p' skills/build/SKILL.md) <(sed -n '/^### 5c/,/^### 5d/p' skills/fix/SKILL.md)` — only the pre-existing "in TodoWrite" divergence on the `**If both stages pass:**` line should appear

**UI:** no

---

### T3: CHANGELOG entry under Unreleased v0.1.5 Changed (~2 min)

**Files:** CHANGELOG.md

**Depends on:** T1, T2 (entry summarizes their changes)

**Action:** Append a new bullet under `### Changed` (currently L47) listing all five caps and their dispositions, with Path C noted.

**Details:**

Insert after the existing `Plan-mode hijack pitfall recategorized` bullet (L49) — append, do not modify the existing entry. New bullet text:

```
- **Retry-loop caps tuned (OQ3 ratified 2026-05-10).** [skills/build/SKILL.md](skills/build/SKILL.md) and [skills/fix/SKILL.md](skills/fix/SKILL.md) Stage 5c/Stage 6 cap dispositions: questions cap **kept at 2** (OQ3 #1), auto-fix cap **raised from 2 to 4** for type-check and lint/format with **kept at 2** for test-command failures (OQ3 #2/#3/#4 via Path C — single unified cap with command-output-based test conditional), Stage 6 review-fix cycles **kept at 2** (OQ3 #5). Build/fix parity preserved. Inline OQ3 rationale annotations added per cap; no new ADR (rationale lives in the epic story body).
```

**Verify:**
- `grep -n "Retry-loop caps tuned" CHANGELOG.md` returns 1 match in the `[Unreleased] — v0.1.5` section
- `wc -l CHANGELOG.md` is 1 greater than the pre-edit count (single-line bullet)

**UI:** no

---

## Synthetic before/after dogfood cases (AC: each adjusted cap has before/after)

No real cap-hit incidents exist in git history — all five caps were pre-emptive, added in v0.1.2 (commit `fd22bfb`). Before/after cases are therefore synthetic replay scenarios.

| Cap | Before (current behavior) | After (post-S10 behavior) |
|---|---|---|
| **#1 Stage 5c questions (kept at 2)** | Subagent returns 2 questions → orchestrator answers and re-dispatches twice → if 3rd question, escalate to human | No behavior change — annotation only |
| **#2 Stage 5c auto-fix type-check (raised to 4)** | TypeScript error on owned files → 2 fix attempts → escalate to human | TypeScript error → up to 4 fix attempts → escalate only if 4 fail |
| **#3 Stage 5c auto-fix lint/format (raised to 4)** | Lint/format error → 2 fix attempts → escalate | Lint/format error → up to 4 fix attempts → escalate only if 4 fail |
| **#4 Stage 5c auto-fix test (kept at 2)** | Test failure on owned files → 2 fix attempts → escalate | No behavior change for test-command failure path (test-fix conditional preserves cap 2) |
| **#5 Stage 6 review-fix cycles (kept at 2)** | Critical findings after review → 2 fix-and-re-review cycles → escalate | No behavior change — annotation only |

Caps that are kept at 2 (#1, #4, #5) have trivially-satisfied before/after — same behavior, annotation only. Caps that are raised to 4 (#2, #3) have synthetic-replay before/after as documented above.

CI fixture from S11b-2 (`tests/fixtures/hello-roughly/`) is happy-path only and does not exercise any cap. Path C's changes should be invisible to the CI run unless something regresses into a loop — this is the implicit dogfood validation.

## Blast Radius

**Do NOT modify:**
- `skills/build/implementer-prompt.md` — confirmed no cap logic per discovery; ADR-003 reference-copy pattern does not apply to S10 changes
- `skills/build/spec-reviewer-prompt.md` — same as above
- `.roughly/known-pitfalls.md` — no existing retry-cap pitfall to update; new pitfall (if warranted) added at wrap-up via doc-writer dispatch
- `docs/adrs/` — no new ADR required per AC #7
- Pre-existing build/fix divergence (`mark task complete in TodoWrite` vs `mark task complete`) — preserve as-is
- The `If it fails on files outside this task's scope` bullet — out of scope for S10
- All other skills, agents, and stories — none reference these caps

**Watch for:**
- `Edit replace_all: true` is forbidden on `max 2` strings — surgical edits only with unique surrounding context (see known-pitfalls.md)
- Line count regression: any net-positive line change to fix/SKILL.md > 1 invokes the prose-extraction off-ramp (not expected with the inline-parenthetical strategy, but verify with `wc -l` after each Edit)
- Markdown link integrity in CHANGELOG bullet (relative paths to skills/build/SKILL.md and skills/fix/SKILL.md)

## Conventions

- ADR-003 reference-copy pattern: not applicable to Stage 5c body; applies only to `*-prompt.md` reference files
- Build/fix Stage 5c parity per known-pitfalls — manual sync, verified with `diff` post-edit
- Inline parenthetical comment style for OQ3 rationale (line-budget-driven; mandatory for fix)
- CHANGELOG bullet style follows v0.1.5 `### Changed` precedent (one paragraph, markdown links to relevant files, inline rationale)

## Final verification (post-T3, before Stage 6)

```sh
wc -l skills/build/SKILL.md skills/fix/SKILL.md   # 298, 299
rg -n '\bmax 2\b|\bmax 4\b' skills/build/SKILL.md skills/fix/SKILL.md   # AC verification
diff <(sed -n '/^### 5c/,/^### 5d/p' skills/build/SKILL.md) <(sed -n '/^### 5c/,/^### 5d/p' skills/fix/SKILL.md)   # parity (one expected divergence)
grep -c 'OQ3 #' skills/build/SKILL.md skills/fix/SKILL.md   # ≥3 each
grep -n 'Retry-loop caps tuned' CHANGELOG.md   # 1 match
```
