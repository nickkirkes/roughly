**Fixture purpose:** AC5 BORDERLINE-PASS — verify uses grep -v exclusion to filter documented self-reference sites; exhaustiveness debatable (exercises carve-out boundary).

# Implementation Plan: Add retro-mark sweep detection to audit-epic pipeline

Plan-format-version: 1

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| `skills/audit-epic/SKILL.md` | edit | T1 |
| `agents/audit-agent.md` | edit | T2 |

## Notes

**Self-reference sites for the literal `retro-sweep-needed`:**

The literal `retro-sweep-needed` is introduced as an error-signal label in the new detection prose added by T1. It appears at two specific locations within `skills/audit-epic/SKILL.md`:

- Line 42: inside the Stage 3 detection block header (`**retro-sweep-needed**: output this label when...`)
- Line 78: inside the Stage 3 example output snippet (`Example: "retro-sweep-needed: 4 tasks lack retro marks"`)

Both are documented self-reference sites — instructional/explanatory text, not active runtime trigger points. The verify command below uses `grep -v` exclusions keyed to these two line-anchored sites. Any reviewer should note that the exclusions are line-number-keyed, which is fragile: if lines shift due to future edits above line 42 or 78, the exclusions will stop matching and the verify will silently regress to a self-defeating state.

## Tasks

### T1: Add retro-sweep-needed detection block to audit-epic SKILL.md (~7 min)
**Files:** `skills/audit-epic/SKILL.md`
**Action:** Insert a Stage 3 detection step that labels tasks missing retrospective marks as `retro-sweep-needed` and outputs a summary count.
**Details:**
Edit site 1: `skills/audit-epic/SKILL.md` Stage 3, after the existing "Count completed tasks" step — insert:

```
**Stage 3b — Retro-mark sweep**
For each task in the epic that is marked `done` or `shipped` but lacks a `## Retro` section:
  Emit label: retro-sweep-needed
If any tasks are labeled, output:
  "retro-sweep-needed: <N> tasks lack retro marks — add ## Retro sections before closing the epic"
If no tasks are labeled, continue to Stage 4.
```

Note: "retro-sweep-needed" appears at line 42 (block header) and line 78 (example output) within `skills/audit-epic/SKILL.md` after this edit. See Notes section above.
**Verify:** `rg -Fn "retro-sweep-needed" skills/ agents/ | grep -v "skills/audit-epic/SKILL.md:42" | grep -v "skills/audit-epic/SKILL.md:78"`

This verify searches all `skills/` and `agents/` files for the literal, then filters out the two documented self-reference lines. Any remaining hits would indicate the label was copied into a file other than the documented self-reference sites — a signal that the wiring may be incomplete or that the label has leaked into an unexpected location.

The `grep -v` exclusion satisfies the AC5 carve-out: the documented self-reference sites are named and excluded. However, the exclusions are keyed to specific line numbers, which means they are fragile — an edit that inserts lines above line 42 in `skills/audit-epic/SKILL.md` would cause the exclusion to miss the self-reference site, reverting the verify to a self-defeating state without any visible error.
**UI:** no

### T2: Reference retro-sweep-needed label in audit-agent prompt (~4 min)
**Files:** `agents/audit-agent.md`
**Action:** Add a bullet to the audit-agent's output format section documenting that the agent should emit `retro-sweep-needed` labels per the SKILL.md Stage 3b instructions.
**Details:**
Edit site 1: `agents/audit-agent.md` Output Format section — append:

```
- If Stage 3b fires, include a `retro-sweep-needed` summary line at the top of the report with the count.
```

Note: this creates a third occurrence of the literal in `agents/audit-agent.md`. The verify in T1 would catch this occurrence if it were not expected — but it IS expected (it is runtime wiring, not a self-reference site). The `grep -v` exclusions only filter the two sites in `skills/audit-epic/SKILL.md`, so a hit in `agents/audit-agent.md` would correctly appear in verify output as a non-excluded match.
**UI:** no
