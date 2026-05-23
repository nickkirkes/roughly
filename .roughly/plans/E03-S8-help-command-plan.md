> **Status:** Historical — implemented and merged in commit 740ab5f7dfa0f6f51e696114749bc1654340d5ef on 2026-05-13. This plan was an active build/fix artifact; treat as historical reference only.

# Implementation Plan: E03.S8 — `/roughly:help` command

**Branch:** `feat/E03.S8-help-command`
**Story:** [docs/planning/epics/E03-trust-and-ergonomics.md:507-543](../planning/epics/E03-trust-and-ergonomics.md#L507)
**Type:** New skill (10th) + two table-row edits in existing docs

**Status:** ✅ Implementation complete on 2026-05-12 (commit `d1d257f` shipped all four tasks; commits `21519e8`, `1d6b242`, `d04d453`, `fea12fb`, `92c3cdc`, `9dee87c` refined Step 3 of `skills/help/SKILL.md` based on cubic post-merge feedback). This file is a **historical record** of the planned approach — tasks T1–T4 below are NOT instructions to re-execute. Re-running them against the current repo would either duplicate rows (T3 would add `/roughly:help` rows that already exist in `README.md`) or fail (T4 expects `(9 skills)` in `CLAUDE.md`, but it already shows `(10 skills)`). The descriptions are preserved for traceability of intent.

## File Table

| File | Action | Task(s) |
|------|--------|---------|
| `skills/help/SKILL.md` | Create | T1, T2 |
| `README.md` | Modify | T3 |
| `CLAUDE.md` | Modify | T4 |

## Tasks

### T1: Create `skills/help/SKILL.md` scaffold with pre-flight + Section 1 (~4 min)
**Files:** `skills/help/SKILL.md` (new)
**Action:** Create the new skill file with frontmatter, title, pre-flight migration handling (note-only, NOT abort), and Section 1 (commands grouped by cluster).
**Details:**

Write a NEW file at `skills/help/SKILL.md`. **Do not** look for an existing copy — this file does not exist yet.

**Frontmatter (exact text):**
```yaml
---
name: help
description: "In-CLI overview of Roughly commands, maturity-check state, and any in-progress plan. Read-only and interactive — never aborts, never modifies files."
disable-model-invocation: false
---
```

Note: `disable-model-invocation: false` is **explicit per spec** (E03.S8 AC #1). This diverges from setup/upgrade which omit the field entirely; the divergence is intentional because the spec calls it out.

**Body structure:** Mirror the style of `skills/upgrade/SKILL.md` (numbered `## STEP N:` sections separated by `---`). The skill body instructs the LLM what to emit when the user types `/roughly:help`.

**Open with:**
```markdown
# Roughly Help

In-CLI overview: commands by cluster, current maturity-check state, and any in-progress plan.

**Read-only.** This skill never modifies files, never aborts the session, and never blocks other work. It is itself a recovery path — like `/roughly:upgrade` — so it surfaces legacy state without halting.

---

## STEP 0: PRE-FLIGHT NOTE (NEVER ABORTS)

If `.ruckus/` directory exists at the project root, emit a single note line before Step 1's output:
> "Legacy `.ruckus/` directory detected (v0.1.3 install or incomplete v0.1.4 migration). Run `/roughly:upgrade` when ready to migrate."

Do NOT abort. Continue to Step 1. If no `.ruckus/` directory exists, emit nothing and proceed silently.

---

## STEP 1: COMMANDS BY CLUSTER

Emit three labeled groups. For each command, give one short line of purpose. Use this exact grouping:

**Pipeline** (orchestrators with gated stages):
- `/roughly:build` — feature pipeline with discovery, plan review, subagent-per-task implementation, review, verify, commit
- `/roughly:fix` — bug pipeline with investigation instead of discovery; same gate structure

**Coordinator** (dispatch agents or other skills):
- `/roughly:review` — parallel 3-agent review of recent changes (code-reviewer, static-analysis, silent-failure-hunter)
- `/roughly:review-plan` — verify an implementation plan against the codebase (auto-dispatched by build/fix; also usable standalone)
- `/roughly:review-epic` — pre-implementation epic review (Opus); flags spec issues before any code is written
- `/roughly:audit-epic` — post-implementation epic audit; verifies acceptance criteria across all stories
- `/roughly:verify-all` — type check + test + build verification loop

**Utility** (interactive, non-gate):
- `/roughly:setup` — first-time project bootstrap with maturity detection
- `/roughly:upgrade` — diff installed files against latest plugin templates; apply structural updates
- `/roughly:help` — this command
```

**Verify:** After writing, confirm: (1) file exists at `skills/help/SKILL.md`, (2) frontmatter is exactly as specified, (3) Section 0 (pre-flight) does NOT contain the word "abort" in its action — only in the labeled legacy-state note, (4) all 10 commands are listed in Step 1 across the three clusters, (5) file is under 300 lines.

**UI:** no

---

### T2: Add Section 2 (maturity-check state) and Section 3 (in-progress plans) to `skills/help/SKILL.md` (~5 min)
**Files:** `skills/help/SKILL.md` (modify)
**Depends on:** T1
**Action:** Append two additional STEP sections to the help skill, covering maturity-check state from `.roughly/workflow-upgrades` and in-progress plan detection from `docs/plans/`.
**Details:**

Append the following sections to the file created in T1. Place them after the Section 1 block, separated by `---` dividers consistent with the existing structure.

**Section 2 content:**
```markdown
## STEP 2: MATURITY-CHECK STATE

Read `.roughly/workflow-upgrades`. If the file does not exist, emit:
> "No `.roughly/workflow-upgrades` file found. Run `/roughly:setup` to initialize, or `/roughly:upgrade` if a `.ruckus/` legacy file is present."
Skip the rest of Step 2.

If the file exists, parse it:
- **Line 1** is the version line: `roughly-version X.Y.Z YYYY-MM-DD`. Display as: `Plugin version: X.Y.Z (recorded YYYY-MM-DD)`. If line 1 does not match this format, display: `Plugin version: unrecorded (file may predate v0.1.2)`.
- **Remaining lines** match the pattern `[check-id]-[added|declined] YYYY-MM-DD`. For each, classify by suffix:

Active check IDs (display under their natural label):
- `investigator-v1` — bug-diagnosis subagent for `/roughly:fix`
- `stop-hook-v1` — verify-all enforcement via Claude Code Stop hook

Retired check IDs (display under "Retired — no longer offered"):
- `pitfalls-organized-v1`
- `test-verify-v1`

For each ID found in the file, emit one line:
> "✓ [id] — added YYYY-MM-DD" (for `-added` entries)
> "✗ [id] — declined YYYY-MM-DD" (for `-declined` entries)

If a check ID in the file does not match any known active or retired ID, emit:
> "? [id] — unknown check (YYYY-MM-DD)"
Do not crash or filter; display the unknown entry so the user can investigate.

If no check entries are present beyond the version line, emit:
> "No maturity checks recorded yet. Checks are offered during `/roughly:build` and `/roughly:fix` wrap-up."

---

## STEP 3: IN-PROGRESS PLAN STATE

Use `Glob` for `docs/plans/*-plan.md`. Sort results by modification time descending (most recent first).

**Zero matches:** emit `"No in-progress plans found in docs/plans/."` and skip the rest of Step 3.

**Exactly one match:** emit:
> "One plan found in docs/plans/:
> - `<filename>` (modified YYYY-MM-DD HH:MM)"

**Multiple matches:** emit:
> "Multiple plan files exist in docs/plans/. The presence of a plan file does not necessarily mean a pipeline is mid-flight — old plans may persist after their feature shipped. Which is your current in-progress plan?"

Then list every file with its modification date:
> - `<filename>` (modified YYYY-MM-DD HH:MM)
> - `<filename>` (modified YYYY-MM-DD HH:MM)
> - ...

Then ask: **"Which plan is current? (paste filename, or 'none' if no pipeline is in progress)"**

Do NOT silently pick the most-recent file. Do NOT filter or guess based on filename. Display all matches and wait for the user's answer.

If the user names a plan, emit a follow-up line confirming: `"Current plan: <filename>. Resume with /roughly:build or /roughly:fix as appropriate."` If the user answers "none", emit: `"No active pipeline. Old plans can be deleted manually when no longer useful."`

**Display only.** Do not delete, rename, or modify any plan file.

---

## STEP 4: WRAP-UP

After all three sections render, emit:
> "For per-command details, run the command without arguments or read `skills/<name>/SKILL.md` in the plugin source."

End. The session continues — `/roughly:help` is informational and does not gate further work.
```

**Verify:** After writing, confirm: (1) the file still parses (frontmatter intact at lines 1-5), (2) all four STEP sections are present in order (0, 1, 2, 3, plus the wrap-up), (3) total line count is under 300, (4) Step 3 contains the literal phrase "Do NOT silently pick" (positive AC check for E03.S8 AC #4), (5) Step 2 references both active checks (`investigator-v1`, `stop-hook-v1`) and both retired checks (`pitfalls-organized-v1`, `test-verify-v1`).

**UI:** no

---

### T3: Update `README.md` — add `/roughly:help` to both tables (~2 min)
**Files:** `README.md`
**Action:** Add one row to the "Choose Your Workflow" table and one row to the "Skills Reference" table.
**Details:**

Edit `README.md`. Two table edits, both append-to-table-end (after the existing `/roughly:upgrade` and `upgrade` rows).

**Edit 1 — "Choose Your Workflow" table** at [README.md:108-117](../../README.md#L108-L117). After the `/roughly:upgrade` row (currently the last), insert:
```
| Getting an overview of commands and pipeline state | `/roughly:help` | Lists commands by cluster, maturity-check state, and any in-progress plan |
```

**Edit 2 — "Skills Reference" table** at [README.md:121-131](../../README.md#L121-L131). After the `upgrade` row (currently the last), insert:
```
| `help` | In-CLI command and pipeline overview | Any time — lists commands by cluster, maturity-check status, and current plan state |
```

Preserve all existing rows verbatim. Do not modify column headers, alignment dashes, or other table content.

**Verify:** After editing, grep `README.md` for `/roughly:help` and confirm it appears at least twice (once per table). Confirm no existing row was modified by spot-checking the `/roughly:upgrade` row text. File line count should increase by exactly 2.

**UI:** no

---

### T4: Update `CLAUDE.md` structure table — bump skill count 9 → 10 (~1 min)
**Files:** `CLAUDE.md`
**Action:** Change the skill count in the structure table from 9 to 10.
**Details:**

Edit `CLAUDE.md` at [CLAUDE.md:11](../../CLAUDE.md#L11). Current line reads:

```
| `skills/<name>/SKILL.md` | Skill definitions (9 skills) |
```

Replace `(9 skills)` with `(10 skills)`. No other change.

Do NOT add a new row to the table — the table describes the directory pattern, not individual skills. The skill count number is the only edit.

**Verify:** After editing, grep `CLAUDE.md` for `(10 skills)` — should match exactly once. Grep for `(9 skills)` — should match zero times. No other CLAUDE.md lines should change.

**UI:** no

---

## Blast Radius

**Do NOT modify:**
- `.claude-plugin/plugin.json` — no manifest edit needed (skills auto-discovered)
- Any other skill in `skills/` — help is additive, not refactor
- `agents/` — help is a skill, not an agent; no preamble work
- `.roughly/workflow-upgrades` — help only READS this file; the maturity-check additions happen in build/fix wrap-up, not here
- `docs/plans/*-plan.md` — help only READS; never deletes or renames
- CHANGELOG.md — defer to wrap-up (Stage 8 may add an `[Unreleased]` entry; not in scope of T1-T4)

**Watch for:**
- The 300-line cap on `skills/help/SKILL.md`. After T1 the file should be ~50-80 lines. After T2 it should be ~150-200 lines. If T2's output approaches 290 lines, the subagent must compress prose before returning, not return at 295+.
- Spec literal compliance: `disable-model-invocation: false` is explicit in T1 (E03.S8 AC #1). Setup and upgrade analogues OMIT the field entirely; the help spec instructs to include `false`. Follow the spec.
- AC #4 ("if multiple in-progress plan files are detected, list each with modified date and ask the user which is current — do not silently assume the most-recent one"): verified by the literal phrase in T2 ("Do NOT silently pick the most-recent file") and the multi-match emit prose.
- AC #5 ("respects pre-flight migration check; S4 conventions don't apply"): satisfied by Step 0 emitting a NOTE-only and continuing — verified by absence of `abort` in the action verb.
- Pre-existing 25 plan files in `docs/plans/` — dogfooding `/roughly:help` in this repo at wrap-up will surface the full list. This is expected per spec; not a bug.

## Conventions

- **Skill structure:** mirror `skills/upgrade/SKILL.md` — frontmatter, `# Title`, one-sentence description, bold invariant line, `---` divider, numbered `## STEP N:` sections with `---` dividers between.
- **Frontmatter format:** YAML triple-dash delimited. The `description` field must be one line (multi-line YAML quoting can break plugin discovery).
- **Line-cap budget contract** (per [docs/planning/epics/E03-trust-and-ergonomics.md:64-76](../planning/epics/E03-trust-and-ergonomics.md#L64-L76)): help has the full 300-line budget; target ~150-200 lines. Do not pad prose.
- **No agent-preamble inclusion:** `agents/agent-preamble.md` is for AGENTS (subagents), not for skills. Help dispatches no subagents and needs no project-context preamble.
- **No `$ARGUMENTS`:** help takes no arguments. Pipeline skills use `$ARGUMENTS` for feature input; help does not.
- **ADR-005 (versioned maturity check IDs):** the active vs. retired classification in Step 2 must match the current ADR; if ADR-005 adds a new active check ID after this story ships, that's a future help-skill update, out of scope here.
- **ADR-006 (runtime context, not baked):** help reads `.roughly/workflow-upgrades` and `docs/plans/` at runtime — no values are baked into the skill text. Compliant.

## Verification (post-implementation, prior to Stage 6 review)

Manual sanity (orchestrator-level, optional but recommended before review dispatch):
1. `wc -l skills/help/SKILL.md` — confirm under 300
2. `head -5 skills/help/SKILL.md` — confirm frontmatter intact and contains `disable-model-invocation: false`
3. `grep -c '/roughly:help' README.md` — expect 2 (one per table)
4. `grep -c '(10 skills)' CLAUDE.md` — expect 1
5. `grep -c '(9 skills)' CLAUDE.md` — expect 0

These are sanity checks for the orchestrator, not Stage-6 review substitutes. Full quality and silent-failure review happens in Stage 6.
