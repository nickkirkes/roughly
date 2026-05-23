> **Status:** Historical — implemented and merged in commit b3a6750fddb3abf13dee12cceb815ad464f89886 on 2026-05-07. This plan was an active build/fix artifact; treat as historical reference only.

# Implementation Plan: E03.S4 — Pre-flight migration check in remaining 2 skills

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| skills/audit-epic/SKILL.md | Modify (insert ~3 lines) | T1 |
| skills/verify-all/SKILL.md | Modify (insert ~3 lines) | T2 |
| docs/ROADMAP.md | Modify (1 line) | T3 |

## Tasks

### T1: Add pre-flight block to skills/audit-epic/SKILL.md (~2 min)
**Files:** skills/audit-epic/SKILL.md
**Action:** Insert the canonical pre-flight migration check block between the existing `## Input` section and the first `---` divider.
**Details:**
- The file currently ends its `## Input` section at L18 with: `If \`$ARGUMENTS\` is empty, ask: **"Which epic file should I audit? (provide path)"**`
- L19 is blank, L20 is the `---` divider.
- Use the Edit tool to insert the canonical block. Anchor on the unique `If \`$ARGUMENTS\` is empty, ask:` line. Replace it with itself + two blank lines + the canonical block + one blank line, so the resulting file has the structure:
  ```
  If `$ARGUMENTS` is empty, ask: **"Which epic file should I audit? (provide path)"**

  **Pre-flight migration check:** If `.ruckus/.migration-in-progress`, `.ruckus/known-pitfalls.md`, or `.ruckus/workflow-upgrades` exists, abort with: "Legacy `.ruckus/` state detected (v0.1.3 install or incomplete v0.1.4 migration). Run `/roughly:upgrade` to migrate or resume, then re-run." A `.ruckus/` directory containing only user-extras (post-`leave` state from a completed upgrade) is fine — proceed.

  ---
  ```
- The pre-flight wording must be byte-identical to the version in `skills/build/SKILL.md` L19. Copy verbatim — do not paraphrase, retype, or "fix" punctuation.
- Do NOT add any new heading. The block is a bare paragraph (matching build/SKILL.md and fix/SKILL.md placement).

**Verify:**
- `rg -c "Legacy \`.ruckus/\` state detected" skills/audit-epic/SKILL.md` → `1`
- `wc -l skills/audit-epic/SKILL.md` → no greater than 145 (currently 139, +2 blank lines + 1 block line)
- `head -22 skills/audit-epic/SKILL.md` shows the block immediately before the `---` divider, with the `## Input` heading still intact above it
**UI:** no

### T2: Add pre-flight block to skills/verify-all/SKILL.md (~2 min)
**Files:** skills/verify-all/SKILL.md
**Action:** Insert the canonical pre-flight migration check block between the existing `## Context` paragraph and the first `---` divider.
**Details:**
- The file's `## Context` section ends at L13 with: `Read CLAUDE.md to resolve verification commands. If commands are missing, warn and ask the human to provide them.`
- L14 is blank, L15 is the `---` divider.
- Use the Edit tool, anchored on the unique `Read CLAUDE.md to resolve verification commands.` line. Replace it with itself + two blank lines + the canonical block + one blank line, so the resulting structure is:
  ```
  Read CLAUDE.md to resolve verification commands. If commands are missing, warn and ask the human to provide them.

  **Pre-flight migration check:** If `.ruckus/.migration-in-progress`, `.ruckus/known-pitfalls.md`, or `.ruckus/workflow-upgrades` exists, abort with: "Legacy `.ruckus/` state detected (v0.1.3 install or incomplete v0.1.4 migration). Run `/roughly:upgrade` to migrate or resume, then re-run." A `.ruckus/` directory containing only user-extras (post-`leave` state from a completed upgrade) is fine — proceed.

  ---
  ```
- Wording must be byte-identical to `skills/build/SKILL.md` L19.

**Verify:**
- `rg -c "Legacy \`.ruckus/\` state detected" skills/verify-all/SKILL.md` → `1`
- `wc -l skills/verify-all/SKILL.md` → no greater than 84 (currently 78, +2 blank + 1 block)
- `head -18 skills/verify-all/SKILL.md` shows the block sitting between the `## Context` paragraph and the `---`
**UI:** no

### T3: Update ROADMAP.md item 4 with Done marker (~1 min)
**Depends on:** T1, T2
**Files:** docs/ROADMAP.md
**Action:** Append a `✅ Done — landed in E03.S4` marker to ROADMAP.md L60, matching the style of item 3 on L59.
**Details:**
- Current L60: `4. **Pre-flight migration check in remaining 2 skills** (currently 6/9, upgrade excluded by design).`
- New L60: `4. **Pre-flight migration check in remaining 2 skills** (currently 6/9, upgrade excluded by design). ✅ Done — landed in E03.S4.`
- The AC text "wording corrected to '...remaining 2 skills (currently 6/9, upgrade excluded by design)'" is already literally satisfied by the existing wording, so the only meaningful completion update is the Done marker. We mirror item 3's pattern (`✅ Done — triggers folded into doc-writer's known-pitfalls write path (E03.S3).`) for consistency.
- Use the Edit tool with the full L60 string as `old_string` so the match is unique.

**Verify:**
- `rg -n "remaining 2 skills" docs/ROADMAP.md` shows the Done marker appended to the line
- The line is still a single bullet — no extra blank lines or wrapping

**UI:** no

### T4: Final cross-skill verification (~1 min)
**Depends on:** T1, T2
**Files:** none (read-only)
**Action:** Confirm AC3 — wording is byte-identical across the **7 hard-abort skills** (with setup excluded as a documented exception).
**Details:**
- Run `rg -c "Legacy \`.ruckus/\` state detected" skills/*/SKILL.md` and confirm output lists 8 files, each with `:1`. (setup matches the rg pattern but uses a different surrounding form — see note below.)
- Run `rg -n "Legacy \`.ruckus/\` state detected" skills/*/SKILL.md` and visually scan the 7 hard-abort skills (audit-epic, build, fix, review, review-plan, review-epic, verify-all) — every match must be on a single line whose full text is byte-identical to the canonical block.
- If any drift is found among those 7, treat as a regression and fix the source.
- **Setup exception:** `skills/setup/SKILL.md` L39-40 uses a two-line prose+blockquote form with a `(proceed anyway / abort)` soft-override option, not the canonical bold-paragraph hard-abort. This is intentional — setup is the install skill and offers a soft option for install-time legacy state. Setup matches the rg keyword pattern (so the count of 8 holds) but its surrounding wording deliberately diverges. **Do not normalize setup to the canonical form** — that would change install behavior and is out of scope for S4. The AC's "identical surrounding context" requirement should be read as applying to the 7 hard-abort skills.

**Verify:**
- 8 lines of output from `rg -c`, each ending in `:1`
- The 7 hard-abort skills (audit-epic, build, fix, review, review-plan, review-epic, verify-all) all show byte-identical canonical block wording
- setup/SKILL.md still shows its existing soft-abort form (two-line prose+blockquote with `(proceed anyway / abort)`)

**UI:** no

## Blast Radius
- Do NOT modify: any other skill, any agent, any ADR, any test, CLAUDE.md, README.md, CHANGELOG.md, the existing 6 skills with the check, or the upgrade skill (deliberately excluded — it IS the migration target).
- Watch for: byte-level drift in the canonical wording between skills (T4 catches this). The block is a free-floating paragraph, not under a heading, in every existing skill — preserve that pattern.
- Out of scope: marker-aware resume in upgrade SKILL, pre-flight in `/roughly:help`, drift-check automation in verify-all.sh — all are deferred to v0.1.6 candidates per the epic.

## Conventions
- Pre-flight block must be byte-identical across all 8 skills — copy verbatim from `skills/build/SKILL.md` L19. ADR-003 establishes a similar shared-reference pattern for spec-reviewer-prompt; this story extends the same "identical text in N files, manually synced" approach to pre-flight checks.
- No new headings — the block is a bare paragraph that follows the last preamble paragraph and precedes the first `---` divider in each skill.
- 300-line skill cap (CLAUDE.md): both target files stay well under (~142 and ~81 lines after the change).
- No emojis except the `✅` glyph in ROADMAP.md item 4, which mirrors item 3's existing usage.

## Risks
- **Wording drift.** Easy mistake: typing the block instead of pasting. T1 and T2 both call out byte-identical copy from build/SKILL.md L19. T4 verifies post-hoc via rg.
- **Wrong insertion point.** audit-epic uses `## Input`, verify-all uses `## Context` — the anchor lines are different. Plan calls out the exact unique anchor string for each.
- **ROADMAP wording confusion.** The literal AC string is already present in L60 (the wording was fixed in a prior edit). T3 reads the AC as completion-marking and adds the Done suffix to mirror item 3's pattern. If the human prefers no Done marker, T3 can be skipped without violating any AC.
- **AC3 ambiguity around setup.** The epic AC reads "Wording is identical across all 8 skills... all with identical surrounding context." Taken literally, this would require normalizing setup/SKILL.md L39-40 to the canonical form. But setup's pre-flight uses a deliberate two-line `(proceed anyway / abort)` soft-abort form because it is the install skill — normalizing would change install behavior. T4 documents setup as a known exception; the AC is read as applying to the 7 hard-abort skills. If the human reads the AC literally, normalizing setup must be added as T5; this should surface at the Stage 4 gate.
