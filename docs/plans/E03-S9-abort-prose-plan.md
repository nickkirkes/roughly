# Implementation Plan: E03.S9 — Situation-specific abort prose at every pipeline failure point

Plan-format-version: 1

## Overview

Sweep every abort branch in 5 pipeline skills so each emits a message including (a) `Stage [N or name]` paired with `aborted|stopped|cannot proceed`, (b) one-line reason, (c) file state, (d) `recovery` action. Greppable markers required: `Stage .* (aborted|stopped|cannot proceed)` AND one of `recovery|next step|re-run|escalate` per branch.

## Binding constraint: line-cap budget

- skills/build/SKILL.md: 298/300 — **2 lines headroom**
- skills/fix/SKILL.md: 299/300 — **1 line headroom (binding)**
- ABORT HANDLING block in both files (build L276–298, fix L277–299) must remain **byte-verbatim** per AC #4. No edits allowed inside that block.

**Strategy:** All edits are **single-line in-place substitutions** at existing gate-prompt and implicit-escalation sites. Each rewritten line absorbs the 4-field emit instructions inline (orchestrator reads the line, identifies the user-facing prompt, identifies the abort/escalate emit string). No new template block is added — per-site inlining is permitted by AC #5 ("MAY" not "MUST"), and net-zero substitution sidesteps the line cap entirely.

**Why no template block:** A template block above ABORT HANDLING would cost +1 to +3 lines per file (markdown blank-line conventions around an ATX heading). Fix has 1 line of headroom; +1 puts fix at exactly 300. Adding a per-gate pointer line additionally would push fix over. Per-site inline emit instructions cost zero net lines and satisfy AC #2's regex requirement directly at each branch.

## File Table

| File | Action | Task(s) |
|------|--------|---------|
| skills/build/SKILL.md | Edit (substitution-only at 12 sites) | T1, T2 |
| skills/fix/SKILL.md | Edit (substitution-only at 12 sites) | T3, T4 |
| skills/review-plan/SKILL.md | Edit (1 substitution at L21) | T5 |
| skills/review-epic/SKILL.md | Verify-only, no edits | T6 |
| skills/audit-epic/SKILL.md | Verify-only, no edits | T6 |

## Emit-format reference (canonical for all per-site rewrites)

Every per-site edit appends inline to the existing line a clause of the form:

```
On [abort|escalate]: emit `Stage [N or name] [aborted|stopped|cannot proceed]: [reason]. [File state]. Recovery: [next step].`
```

- `Stage [N]` uses numeric stage (Stage 1, Stage 5c, Stage 6, etc.) for build/fix orchestrator gates
- `Stage [name]` uses a name (e.g., `Stage review-plan`) when there is no numeric stage in context
- `[reason]` is one short clause specific to the gate/escalation
- `[File state]` is "No files written" / "Plan at \[path\]" / "Implementation in progress (see ABORT HANDLING)" — referencing the canonical block for stages 5–7 to avoid duplication
- `Recovery` is literal, followed by the recovery action (re-run, revise plan, escalate to human, override, etc.)

Greppability:
- `Stage .* (aborted|stopped|cannot proceed)` matches by construction
- `recovery|next step|re-run|escalate` matches via the explicit `Recovery:` prefix and/or the action verb

## Tasks

### T1: build/SKILL.md — gate-prompt abort-emit instructions (6 sites, ~5 min)

**Files:** skills/build/SKILL.md
**Action:** At each gate prompt, append a single-line `On abort: emit ...` clause to the existing `Ask:` / `**Gate:**` line. No new lines added; the user-facing prompt text is unchanged.

**Sites (verify line numbers at edit time — they may shift +1 if other tasks ran first; in this plan they run isolated):**

1. **L27 (Stage 1 — Intake gate).** Current: `Ask: **"Is this the correct scope? (yes / adjust / abort)"**`. Append: ` On abort: emit \`Stage 1 intake aborted: [reason]. No files written. Recovery: re-run /roughly:build with adjusted scope.\``.
2. **L37 (Stage 2 — Discovery gate).** Current: `**Gate:** "Discovery complete. Proceed to planning? (yes / investigate further / abort)"`. Append: ` On abort: emit \`Stage 2 discovery aborted: [reason]. No files written. Recovery: re-run /roughly:build.\``.
3. **L110 (Stage 4 — Review Plan gate).** Current: `**Gate (only after PASS or explicit override):** "Plan drafted with [N] tasks and verified against the codebase. [Review summary]. Ready to implement? (yes / revise plan / abort)"`. Append: ` On abort: emit \`Stage 4 plan-review aborted: [reason]. Plan written at [path], not consumed. Recovery: revise plan and re-run /roughly:build, or delete plan per ABORT HANDLING.\``.
4. **L191 (Stage 5d — Implementation complete gate).** Current: `**Gate:** "Implementation complete. [N] tasks executed, all passing. Summary: [task list with status]. Proceed to review? (yes / adjust / abort)"`. Append: ` On abort: emit \`Stage 5 implementation aborted: [reason]. Files staged/unstaged per ABORT HANDLING. Recovery: choose rollback option per ABORT HANDLING.\``.
5. **L205 (Stage 6 — Review complete gate).** Current: `**Gate:** "Review complete. Proceed to verification? (yes / list warnings to address [then re-review once] / abort)"`. Append: ` On abort: emit \`Stage 6 review aborted: [reason]. Files modified, not committed. Recovery: choose rollback option per ABORT HANDLING.\``.
6. **L217 (Stage 7 — Verification gate).** Current: `**Gate:** "Verification passed. Ready to commit? (yes / additional checks / abort)"`. Append: ` On abort: emit \`Stage 7 verify aborted: [reason]. Files modified, not committed. Recovery: choose rollback option per ABORT HANDLING.\``.

**Details:**
- Each substitution is a single-line append; the existing line stays one source line longer but no newline is added.
- Use the Edit tool with the full original line as `old_string` and the appended version as `new_string` to ensure uniqueness.
- The `[reason]` placeholder is filled in by the orchestrator at emit time (parallel to existing placeholders like `[N]` in "Stage [N]").

**Verify:** `wc -l skills/build/SKILL.md` returns 298 (unchanged). `rg -n 'On abort: emit' skills/build/SKILL.md` returns 6 matches. `rg -n 'Stage .* (aborted|stopped|cannot proceed)' skills/build/SKILL.md` returns at least 6 matches (the 6 new emit clauses).

**UI:** no

---

### T2: build/SKILL.md — implicit-escalation site rewrites (6 sites, ~5 min)

**Files:** skills/build/SKILL.md
**Depends on:** T1
**Action:** At each escalation site, replace the bare "escalate to human" / "present findings to the human" wording with a dense single-line message that names stage, reason, file state, and recovery. Substitution-only.

**Sites:**

1. **L106 (Stage 4 — NEEDS REVISION ×2 cap).** Replace ` — at that point, present findings to the human and let them decide.` with ` — then escalate: emit \`Stage 4 plan-review cannot proceed: 2 NEEDS REVISION verdicts. Plan at [path] needs human revision. Recovery: revise plan or override.\` and present findings to the human.`
2. **L176 (Stage 5c — question loop max).** Replace `then escalate to human — OQ3 #1: questions interrupt fresh subagents, raising the risk of runaway clarification loops` with `then escalate: emit \`Stage 5c [task ID] cannot proceed: 2 question loops exhausted. Recovery: revise task instructions or hand off to human.\` (OQ3 #1: questions interrupt fresh subagents, raising the risk of runaway clarification loops)`. Net wording shorter; same line count.
3. **L180 (Stage 5c — quality-check auto-fix cap).** Replace `if still failing, escalate to human` with `if still failing, escalate: emit \`Stage 5c [task ID] cannot proceed: auto-fix cap reached on [check]. Files: [task file list]. Recovery: human inspect and fix.\``. Surrounding OQ3 annotation prose preserved; only the escalation phrase is rewritten.
4. **L181 (Stage 5c — out-of-scope failure escalation).** Replace `escalate to human immediately` with `escalate immediately: emit \`Stage 5c [task ID] cannot proceed: failure outside task scope or environmental issue ([detail]). Recovery: human triage.\``.
5. **L184 (Stage 5c — spec compliance failure escalation branch).** Replace `**If spec compliance fails:** re-dispatch with clarified instructions OR escalate to human.` with `**If spec compliance fails:** re-dispatch with clarified instructions OR escalate: emit \`Stage 5c [task ID] cannot proceed: spec compliance failure. Recovery: revise instructions or hand off to human.\``.
6. **L203 (Stage 6 — review-fix max-cycles).** Replace `if still failing, present findings to human — OQ3 #5: most expensive loop in the pipeline, conversion-to-prompt deferred pending v0.1.5 dogfood evidence` with `if still failing, escalate: emit \`Stage 6 review cannot proceed: 2 review-fix cycles exhausted. Findings: [list]. Files: [dirty list]. Recovery: human inspect and fix.\` (OQ3 #5: most expensive loop in the pipeline, conversion-to-prompt deferred pending v0.1.5 dogfood evidence)`.

**Details:**
- All edits are substitution-only — each original line stays one source line.
- OQ3 inline annotations (#1, #2/#3/#4, #5) are preserved verbatim per the established S10 pattern.
- The catch-all auto-fix line (build L185 `**If quality check auto-fix fails after the applicable cap...** escalate to human.`) is **not** rewritten because L180 already prescribes the escalation message and L185 is a duplicate decision flag, not a new emit site. Confirm during edit; if L185 also reads as a discrete emit site, apply the same substitution there.

**Verify:** `wc -l skills/build/SKILL.md` returns 298 (unchanged). `rg -n 'cannot proceed' skills/build/SKILL.md` returns 6 matches at T2 completion (T2 only — T1 emits use `aborted` phrasing, not `cannot proceed`); the count rises to 7 after Stage 6 cycle-2 review-fix aligns L185's catch-all summary with the bullets above. The unified AC#2 regex `rg -n 'Stage .* (aborted|stopped|cannot proceed)' skills/build/SKILL.md` returns 12 matches at T2 completion (6 from T1 + 6 from T2), 13 after cycle-2. `rg -n 'aborted\b' skills/build/SKILL.md | rg -v 'Stage'` returns zero matches.

**UI:** no

---

### T3: fix/SKILL.md — gate-prompt abort-emit instructions (6 sites, ~5 min)

**Files:** skills/fix/SKILL.md
**Action:** Mirror of T1 against fix's gate prompts. Single-line append at each site.

**Sites:**

1. **L34 (Stage 1 — Intake gate).** Current: `Ask: **"Is this the correct issue? (yes / adjust / abort)"**`. Append: ` On abort: emit \`Stage 1 intake aborted: [reason]. No files written. Recovery: re-run /roughly:fix with adjusted issue.\``.
2. **L52 (Stage 2 — Investigation gate).** Current: `**Gate:** "Investigation complete. Root cause: [summary]. Proceed to planning? (yes / investigate further / abort)"`. Append: ` On abort: emit \`Stage 2 investigation aborted: [reason]. Root cause: [summary]. No files written. Recovery: re-run /roughly:fix.\``.
3. **L117 (Stage 4 — Review Plan gate).** Current: `**Gate (only after PASS or explicit override):** "Fix plan drafted with [N] tasks and verified against the codebase. [Review summary]. Ready to implement? (yes / revise plan / abort)"`. Append: ` On abort: emit \`Stage 4 plan-review aborted: [reason]. Plan written at [path], not consumed. Recovery: revise plan and re-run /roughly:fix, or delete plan per ABORT HANDLING.\``.
4. **L196 (Stage 5d — Implementation complete gate).** Current: `**Gate:** "Fix implemented. [N] tasks executed, all passing. Summary: [task list with status]. Proceed to review? (yes / adjust / abort)"`. Append: ` On abort: emit \`Stage 5 implementation aborted: [reason]. Files staged/unstaged per ABORT HANDLING. Recovery: choose rollback option per ABORT HANDLING.\``.
5. **L208 (Stage 6 — Review gate).** Current: `**Gate:** "Review complete. Proceed to verification? (yes / list warnings to address [then re-review once] / abort)"`. Append: ` On abort: emit \`Stage 6 review aborted: [reason]. Files modified, not committed. Recovery: choose rollback option per ABORT HANDLING.\``.
6. **L220 (Stage 7 — Verification gate).** Current: `**Gate:** "Verification passed. Ready to commit? (yes / additional checks / abort)"`. Append: ` On abort: emit \`Stage 7 verify aborted: [reason]. Files modified, not committed. Recovery: choose rollback option per ABORT HANDLING.\``.

**Verify:** `wc -l skills/fix/SKILL.md` returns 299 (unchanged). `rg -n 'On abort: emit' skills/fix/SKILL.md` returns 6 matches. `rg -n 'Stage .* (aborted|stopped|cannot proceed)' skills/fix/SKILL.md` returns at least 6 matches.

**UI:** no

---

### T4: fix/SKILL.md — implicit-escalation site rewrites (6 sites, ~5 min)

**Files:** skills/fix/SKILL.md
**Depends on:** T3
**Action:** Mirror of T2 against fix's escalation sites. Substitution-only.

**Sites:** L113 (Stage 4 NEEDS REVISION ×2 cap), L183 (Stage 5c question loop), L187 (Stage 5c quality-check auto-fix), L188 (Stage 5c out-of-scope), L191 (Stage 5c spec compliance), L206 (Stage 6 review-fix cap). Apply the same substitutions as the build counterparts in T2, adjusting wording only where fix's surrounding prose differs (e.g., "Fix implemented" vs "Implementation complete" — none of these affect the escalation lines).

**Details:**
- Confirm during edit that lines L183, L187, L188, L191 all have their build-equivalent wording — discovery confirmed identical phrasing for the escalation phrase itself.
- Preserve OQ3 inline annotations.

**Verify:** `wc -l skills/fix/SKILL.md` returns 299 (unchanged). `rg -n 'cannot proceed' skills/fix/SKILL.md` returns 6 matches at T4 completion (T4 only — T3 emits use `aborted` phrasing, not `cannot proceed`); the count rises to 7 after Stage 6 cycle-2 review-fix aligns L192's catch-all summary with the bullets above. The unified AC#2 regex `rg -n 'Stage .* (aborted|stopped|cannot proceed)' skills/fix/SKILL.md` returns 12 matches at T4 completion (6 from T3 + 6 from T4), 13 after cycle-2. `rg -n 'aborted\b' skills/fix/SKILL.md | rg -v 'Stage'` returns zero matches.

**UI:** no

---

### T5: review-plan/SKILL.md — add Stage marker to NEEDS REVISION return (~2 min)

**Files:** skills/review-plan/SKILL.md
**Action:** Single substitution at L21. Replace the NEEDS REVISION return string from `"CLAUDE.md not found — run /roughly:setup first."` to `"Stage 4 review-plan cannot proceed: CLAUDE.md not found. Recovery: run /roughly:setup first."`. Substitution-only; line count unchanged.

**Details:**
- review-plan runs as a subagent dispatched from build/fix Stage 4 — the `Stage 4` marker is correct context.
- The existing prose around L21 also notes that .roughly/known-pitfalls.md being missing is informational, not blocking — leave that clause unchanged.

**Verify:** `wc -l skills/review-plan/SKILL.md` returns 92 (unchanged). `rg -n 'Stage 4 review-plan cannot proceed' skills/review-plan/SKILL.md` returns 1 match at L21. `rg -n 'aborted\b' skills/review-plan/SKILL.md | rg -v 'Stage'` returns zero matches.

**UI:** no

---

### T6: Verify review-epic/audit-epic + run all positive/negative regex checks (~5 min)

**Files:** None modified — verification-only task.

**Action:**

1. **Confirm review-epic and audit-epic require no edits.** Run `rg -n 'abort' skills/review-epic/SKILL.md skills/audit-epic/SKILL.md`. Confirm the only `abort` mentions are pre-flight migration aborts (out of scope per spec). Document this in the task return so Stage 6 reviewers can verify.

2. **Negative verification (AC #3).** Run `rg -n 'aborted\b' skills/ | rg -v 'Stage'` from repo root. Must return zero matches.

3. **Positive verification (AC #2).** For each rewritten branch in build / fix / review-plan, confirm the emit string matches the regex `Stage .* (aborted|stopped|cannot proceed)` AND contains one of `recovery|next step|re-run|escalate`. Manual walk:
   - Build: 6 gate-prompt sites (T1) + 6 escalation sites (T2) = 12 branches
   - Fix: 6 + 6 = 12 branches
   - review-plan: 1 branch (T5)
   - **Total: 25 branches verified**

4. **ABORT HANDLING block diff verification (AC #4).** Run `git diff skills/build/SKILL.md skills/fix/SKILL.md` and confirm the diff hunks for L276–298 (build) / L277–299 (fix) show **zero** added/modified/deleted lines. Edits only show outside that range.

5. **Line-cap verification (AC #6).** Run `wc -l skills/build/SKILL.md skills/fix/SKILL.md`. Build must be ≤300, fix must be ≤300. Plan target: build = 298, fix = 299 (both unchanged).

**Verify:** All 5 sub-checks pass. Return a summary table with each check's result.

**UI:** no

---

## Blast Radius

**Modify:**
- skills/build/SKILL.md (12 single-line substitutions)
- skills/fix/SKILL.md (12 single-line substitutions)
- skills/review-plan/SKILL.md (1 single-line substitution at L21)

**Verify-only, no modification:**
- skills/review-epic/SKILL.md (discovery confirmed no in-scope abort branches)
- skills/audit-epic/SKILL.md (discovery confirmed no in-scope abort branches)

**Do NOT modify:**
- ABORT HANDLING block in build (L276–298) and fix (L277–299) — must remain byte-verbatim per AC #4
- Pre-flight migration abort text in any skill — out of feature scope
- Stop-hook Stage 8 prose in build (L268+) / fix (L269+) — internal orchestrator logic, not user-facing gate prose
- Any file outside skills/ — including docs/ and CHANGELOG.md (the spec does not require changelog entry; the maturity check at Stage 8 will decide)

**Watch for:**
- Line count creep — every edit must be a single-line substitution. If the Edit tool adds even 1 line to fix/SKILL.md, the build's verify-all stop hook will fail (>300 lines).
- Edit-tool uniqueness — gate prompts and escalation prose may have similar surrounding context. Use the full original line as `old_string` to guarantee unique match.
- OQ3 annotation preservation — the inline parenthetical `(OQ3 #N: ...)` annotations from S10 must survive the rewrites at L176 build / L183 fix and at L203 build / L206 fix.
- Stage-name divergence between build (DISCOVER) and fix (INVESTIGATE) — only affects Stage 2; emit strings differ accordingly.

## Conventions

- ADR-003 shared-reference pattern was considered (per discovery) and judged a poor fit: the abort prose is per-site and situation-specific, not a copy-pasteable block. Per-site inline edits applied.
- The existing canonical ABORT HANDLING block remains the single source of truth for human-initiated abort recovery actions (rollback options for stages 5–7). Per-gate emit strings reference it ("per ABORT HANDLING") rather than duplicate its contents — keeps fix's binding line cap intact.
- OQ3 inline-parenthetical annotation pattern (established by S10) is preserved at every site where it currently appears.
- Greppable markers are placed at the start (`Stage [N]`) and end (`Recovery:`) of each emit string for predictable rg-based verification.

## Out of Scope

- Pre-flight migration abort text (already specific and out of feature scope per spec)
- Localization
- Abort handling in /roughly:setup, /roughly:upgrade, /roughly:help
- Any changes to the canonical ABORT HANDLING block (locked verbatim per AC #4)
- Dogfood end-to-end abort scenarios (S11b CI is happy-path-only; AC's "dogfood" verification is recommended but not blocking — manual review per AC #2)

## Verification Checklist (mapped to acceptance criteria)

| AC | Verification | Task |
|----|--------------|------|
| #1 (4-field message at every branch) | Manual walk of 25 branches | T6.3 |
| #2 (positive regex + greppable markers) | rg + manual walk | T6.3 |
| #3 (negative regex `aborted` paired with Stage) | `rg -n 'aborted\b' skills/ \| rg -v 'Stage'` returns zero | T6.2 |
| #4 (ABORT HANDLING block verbatim) | `git diff` of block range shows zero changes | T6.4 |
| #5 (template block MAY be used) | N/A — chose per-site inline; satisfies spirit | — |
| #6 (line cap ≤300) | `wc -l` on build and fix | T6.5 |
