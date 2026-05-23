> **Status:** Historical — implemented and merged in commit b22144f969f36b9ae5ac510fca7c3bbf682a67a0 on 2026-05-08. This plan was an active build/fix artifact; treat as historical reference only.

# Implementation Plan: E03.S6 — Plan-format version field

Plan-format-version: 1

## Feature summary

Add a forward-compat marker line `Plan-format-version: 1` to the plan template in two skills (`skills/build/SKILL.md` Stage 3 and `skills/fix/SKILL.md` Stage 3) so v0.2.0's migration step can detect existing v1-format plans by greppable header. **Nothing in v0.1.5 reads the field** — it's a marker only. Per epic E03.S6 (`docs/planning/epics/E03-trust-and-ergonomics.md` lines 432–464). Single CHANGELOG entry under "Added" notes the field is forward-compat only. No new ADR (the plan-format-v2 ADR lands in v0.2.0 and folds in this rationale).

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| skills/build/SKILL.md | Modify | T1 |
| skills/fix/SKILL.md | Modify | T2 |
| CHANGELOG.md | Modify | T3 |

## Tasks

### T1: Add `Plan-format-version: 1` to build Stage 3 plan template (~2 min)
**Files:** skills/build/SKILL.md
**Action:** Insert `Plan-format-version: 1` between the `# Implementation Plan: [feature name]` title and the `## File Table` section in the Stage 3 plan format markdown code block.
**Details:**
Use Edit tool on `skills/build/SKILL.md`. Current Stage 3 plan-format block (lines 47–52):

```
```markdown
# Implementation Plan: [feature name]

## File Table
| File | Action | Task(s) |
|------|--------|---------|
```

Replace the `# Implementation Plan: [feature name]\n\n## File Table` segment with `# Implementation Plan: [feature name]\n\nPlan-format-version: 1\n\n## File Table`.

Concretely, the `old_string` for the Edit tool should be:

```
# Implementation Plan: [feature name]

## File Table
```

And the `new_string` should be:

```
# Implementation Plan: [feature name]

Plan-format-version: 1

## File Table
```

This adds 2 lines (the version-marker line and a separating blank line) to follow the existing real-world precedent in `docs/plans/E03-S0-plan-mode-detection-spike-plan.md` (lines 1–5: title, blank, version, blank, next heading) and standard markdown style requiring a blank line before a heading. Format mirrors `.roughly/workflow-upgrades` style: single-line key-value, no frontmatter delimiters, no HTML comment. Greppable post-implementation with `rg '^Plan-format-version:' skills/build/SKILL.md`.

**Verify:**
1. `wc -l skills/build/SKILL.md` returns 296 (was 294, +2).
2. `rg -n '^Plan-format-version:' skills/build/SKILL.md` returns exactly one match showing `Plan-format-version: 1` inside the plan-format markdown code block.
3. The line preceding the version line (within the code block) is blank, and the line following is also blank, matching the spike-plan precedent.

**UI:** no

---

### T2: Add `Plan-format-version: 1` to fix Stage 3 plan template (~2 min)
**Files:** skills/fix/SKILL.md
**Action:** Insert `Plan-format-version: 1` between the `# Fix Plan: [issue ID or short description]` title and the `## Root Cause` section in the Stage 3 plan format markdown code block.
**Details:**
Use Edit tool on `skills/fix/SKILL.md`. Current Stage 3 plan-format block (lines 60–66):

```
```markdown
# Fix Plan: [issue ID or short description]

## Root Cause
[One paragraph explaining why the bug exists]

## File Table
```

Replace the `# Fix Plan: [issue ID or short description]\n\n## Root Cause` segment with `# Fix Plan: [issue ID or short description]\n\nPlan-format-version: 1\n\n## Root Cause`.

Concretely, the `old_string` for the Edit tool should be:

```
# Fix Plan: [issue ID or short description]

## Root Cause
```

And the `new_string` should be:

```
# Fix Plan: [issue ID or short description]

Plan-format-version: 1

## Root Cause
```

The fix template differs from build by having `## Root Cause` between the title and `## File Table`. Per discovery, the most natural reading of "between title and `## File Table`" in the fix context is "immediately after the title" (i.e., before `## Root Cause`), keeping the version line near the top of any generated plan file regardless of template variant. This is also the position v0.2.0's migration `rg '^Plan-format-version:'` will find — placement consistency between build and fix matters for the future migration step.

**Verify:**
1. `wc -l skills/fix/SKILL.md` returns 299 (was 297, +2). **This is at 299/300 — within 1 line of the cap. Verify the cap hook still passes.**
2. `rg -n '^Plan-format-version:' skills/fix/SKILL.md` returns exactly one match showing `Plan-format-version: 1` inside the plan-format markdown code block, positioned BEFORE `## Root Cause`.
3. `rg -n 'Plan-format-version' skills/review-plan/SKILL.md` returns zero matches (AC3 sanity check — confirms we did not accidentally edit review-plan).

**UI:** no

---

### T3: Add CHANGELOG entry under v0.1.5 "Added" (~2 min)
**Files:** CHANGELOG.md
**Action:** Prepend a new bullet for E03.S6 at the top of the v0.1.5 "Added" list (currently the E03.S4 bullet at line 9). Note that the field is forward-compat only — nothing reads it in v0.1.5.
**Details:**
Use Edit tool on `CHANGELOG.md`. Insert the new bullet immediately after `### Added\n\n` and before the existing E03.S4 bullet at line 9.

Concretely, the `old_string` should be (the unique boundary between `### Added` blank line and the first bullet):

```
### Added

- **E03.S4 — Pre-flight migration check
```

And the `new_string` should be:

```
### Added

- **E03.S6 — Plan-format version field.** Forward-compat marker line `Plan-format-version: 1` added to the Stage 3 plan template in [skills/build/SKILL.md](skills/build/SKILL.md) and [skills/fix/SKILL.md](skills/fix/SKILL.md), placed between the plan title and the next section (`## File Table` in build; `## Root Cause` in fix). Format mirrors `.roughly/workflow-upgrades` style: single-line key-value, no frontmatter delimiters, no HTML comment — greppable with `rg '^Plan-format-version:'`. **Nothing reads the field in v0.1.5.** It exists so v0.2.0's plan-format-v2 migration step (per ADR-010, formerly ADR-009 before S1's plan-mode-detection ADR took that slot) can detect existing v1-format plans. [skills/review-plan/SKILL.md](skills/review-plan/SKILL.md) is unchanged — it does not validate, parse, or branch on the version field. No new ADR (rationale folds into v0.2.0's plan-format-v2 ADR). Trust-hardening cluster now 7/7 complete.

- **E03.S4 — Pre-flight migration check
```

This is the only edit to CHANGELOG.md; no entry under "Changed" is needed since this is an additive change with no behavioral impact.

**Verify:**
1. `rg -n '^- \*\*E03\.S6' CHANGELOG.md` returns exactly one match in the v0.1.5 Unreleased "Added" section.
2. The bullet appears BEFORE the E03.S4 bullet (newest-first ordering matches existing convention).
3. `wc -l CHANGELOG.md` returns 234 (was 232, +2 — one new bullet line plus one blank line).

**UI:** no

---

## Blast Radius

**Do NOT modify:**
- `skills/review-plan/SKILL.md` — AC3 explicitly requires this file remain unchanged (review-plan must not validate/parse/branch on the version field in v0.1.5).
- `skills/build/spec-reviewer-prompt.md`, `skills/build/implementer-prompt.md` — discovery confirmed these contain only task-variable placeholders, not plan-template reproductions. AC4's "spec-reviewer prompt reference copies" sync requirement is vacuously satisfied (nothing to sync).
- `docs/planning/archive/ruckus-build-skill.md` — historical archive of an older build-skill copy. Do not back-fill.
- All 14 historical plan files in `docs/plans/` — completed-work artifacts. v0.2.0 migration handles their absence of the field; do not retroactively add it.
- No ADR file should be created (AC6).

**Watch for:**
- **Line-cap pressure on fix/SKILL.md.** After T2, fix is at 299/300 — only 1 line of headroom remains. The `.claude/hooks/verify-all.sh` line-cap hook enforces ≤300. T2's verify step explicitly checks this. If a future story adds even 2 lines to fix/SKILL.md, it will breach the cap and require prose extraction per the epic's line-cap budget contract (epic lines 48–58).
- **The line we add must be inside the markdown code block** in both SKILL files, not as actual SKILL.md prose. The block boundaries are the `\`\`\`markdown` opener and the closing `\`\`\``. Inserting outside the code block would change the rendered SKILL semantics rather than the displayed plan template.
- **Greppability.** AC and v0.2.0 migration depend on `rg '^Plan-format-version:'` matching. Use the exact string `Plan-format-version: 1` with no leading whitespace, single space after the colon, and no trailing whitespace on the line.

## Conventions

- **No frontmatter delimiters / no HTML comment.** Per AC1, the line is a markdown body line, not YAML frontmatter or an HTML comment. Mirrors `.roughly/workflow-upgrades` single-line key-value style.
- **Markdown blank-line style.** Headings should be preceded by a blank line; the spike plan precedent (`docs/plans/E03-S0-plan-mode-detection-spike-plan.md`) uses blank-before-and-after for the version line. Both T1 and T2 follow this exactly.
- **CHANGELOG newest-first ordering.** The existing v0.1.5 "Added" list is ordered by recency — E03.S4 (most recent) at the top, then E03.S5, S2, S3, S1, S0. T3 prepends E03.S6 at the very top.
- **No code-comment inflation.** Per CLAUDE.md, default to no comments unless WHY is non-obvious. The marker line itself is the artifact; do not add HTML comments or `<!-- forward-compat -->` annotations explaining it.
- **Per ADR-003 reference-copy pattern,** if `skills/build/spec-reviewer-prompt.md` *did* reproduce the plan template, we would manually sync it. It does not, so this convention does not apply for S6.
