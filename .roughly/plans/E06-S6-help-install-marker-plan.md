> **Status:** Historical — implemented and merged in commit 091e53bb3cefcbe1e87459e1cc81d02e01ed28a9 on 2026-06-08. This plan was an active build/fix artifact; treat as historical reference only.

# Implementation Plan: E06.S6 — `/roughly:help` install-marker schema fix

Plan-format-version: 1

## Context / discovery findings

`/roughly:help` STEP 2 reads `.roughly/workflow-upgrades` and categorizes each `[base-id]-[added|declined] YYYY-MM-DD` entry by matching the **base ID** (suffix stripped) against two hardcoded lists: Active (`investigator-v1`, `stop-hook-v1`) and Retired (`pitfalls-organized-v1`, `test-verify-v1`). Anything else → `"? [id] — unknown check"`. So a legitimate install marker like `plan-mode-gate-v1-added` falls through to Unknown.

**Audit result (AC1 "any others surfaced during plan-write"):** No skill writes a `plan-mode-gate-v1` marker today — `setup` installs `.claude/hooks/plan-mode-gate.sh` (Step 5b) but records no marker. The only marker-write strings anywhere in `skills/` are `investigator-v1-added`, `stop-hook-v1-added`, `stop-hook-v1-declined` (all maturity checks). Therefore the install-marker recognition list contains exactly one base ID: **`plan-mode-gate-v1`** (from E03.S1, ADR-009). Wiring `setup` to *write* that marker is explicitly out-of-scope for S6 (this story is categorization plumbing only) — noted as a follow-up gap.

**This repo's `.roughly/workflow-upgrades`** (git-tracked) currently lacks `plan-mode-gate-v1-added`, yet `.claude/hooks/plan-mode-gate.sh` *is* installed here. AC1/AC2's manual-dispatch verification requires the marker present. T2 corrects this repo's own install record (not a new setup write-site) so the verification can run honestly.

CHANGELOG version block is `## [0.1.8] — 2026-06-03` with an existing `### Changed` section at L30 (prior E06 stories landed there). AC5's `## [Unreleased] — v0.1.8` phrasing maps to this block.

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| skills/help/SKILL.md | Modify | T1 |
| .roughly/workflow-upgrades | Modify | T2 |
| CHANGELOG.md | Modify | T3 |

## Tasks

### T1: Add install-marker recognition + three-section output to help STEP 2 (~5 min)
**Files:** skills/help/SKILL.md
**Action:** Add a base-ID install-marker recognition list, restructure STEP 2's emit into three labeled sections (Maturity-check state — unchanged glyphs; Installed components — new; Unknown markers — narrowed), and rename the STEP 2 heading.
**Details:**
1. Rename the heading on line 46 from `## STEP 2: MATURITY-CHECK STATE` to `## STEP 2: MARKER STATE`. (Verified: only this skill and a historical plan file reference the old name; no runtime cross-reference breaks.)
1b. In the frontmatter `description` (line 3), change `maturity-check state` to `marker state` so the description stays accurate after STEP 2 now surfaces install markers too. Change only that phrase; leave the rest of the description byte-identical.
2. Replace the block from `- **Remaining lines** match the pattern` (line 54) through the `No maturity checks recorded yet. Checks are offered during ...` block (line 79) with the following. Preserve the maturity ✓/✗ emit lines **byte-identical** to satisfy AC2(i)'s "unchanged behavior":

```
- **Remaining lines** match the pattern `[check-id]-[added|declined] YYYY-MM-DD`.

Active check IDs:
- `investigator-v1` — bug-diagnosis subagent for `/roughly:fix`
- `stop-hook-v1` — verify-all enforcement via Claude Code Stop hook

Retired check IDs (display under "Retired — no longer offered"):
- `pitfalls-organized-v1`
- `test-verify-v1`

Install-marker base IDs (record components installed into the project, not maturity checks):
- `plan-mode-gate-v1` — UserPromptSubmit hook blocking `/roughly:build` and `/roughly:fix` in plan mode (ADR-009)

**Parse rules.** Skip blank lines silently (trailing newlines and visual spacing are benign and present in normal installs). If a non-blank line does not match the `[check-id]-[added|declined] YYYY-MM-DD` shape (broken suffix, missing date, `#`-prefixed comment, stray text), emit `"! [raw line] — unparseable entry"` — do not silently skip non-blank malformed lines; surface them so the user can repair the file.

**Match by base ID.** Strip the `-added`/`-declined` suffix from each parsed entry, then look the base ID up in the three lists above and partition into one of three buckets: maturity-check (active or retired list), installed-component (install-marker list), or unknown (in no list). Emit the buckets as three labeled sections, in this order:

**Maturity-check state** — for each maturity-check entry, emit one line (behavior unchanged):
> "✓ [id] — added YYYY-MM-DD" (for `-added` entries)
> "✗ [id] — declined YYYY-MM-DD" (for `-declined` entries)
If no maturity-check entries are present, emit:
> "No maturity checks recorded yet. Checks are offered during `/roughly:build` and `/roughly:fix` wrap-up."

**Installed components** — for each installed-component entry, emit one line:
> "✓ [id] — installed YYYY-MM-DD" (for `-added` entries)
> "✗ [id] — removed YYYY-MM-DD" (for `-declined` entries)
If no installed-component entries are present, emit:
> "No install markers recorded."

**Unknown markers** — for each unknown entry, emit:
> "? [id] — unknown marker (YYYY-MM-DD)"
Do not crash or filter; surface unknown entries so the user can investigate. If none are present, emit nothing.
```

Note: the original lines 72 (blank-line skip) and 74–76 (unparseable-entry) handling are folded into the `**Parse rules.**` paragraph above; the original lines 78–79 "No maturity checks recorded yet" message is folded into the Maturity-check-state empty branch. Do NOT leave duplicate copies of those instructions below the replaced block — verify lines 72–79 of the old file are fully superseded.
**Verify:** `wc -l skills/help/SKILL.md` returns ≤173; `grep -Fn "plan-mode-gate-v1" skills/help/SKILL.md` returns ≥1 match in the install-marker list; `grep -Fn "Installed components" skills/help/SKILL.md` returns ≥1 match; `grep -Fc "✓ [id] — added YYYY-MM-DD" skills/help/SKILL.md` returns 1 (maturity glyph line preserved byte-identical).
**UI:** no

### T2: Record the plan-mode-gate-v1 install marker in this repo's workflow-upgrades (~2 min)
**Files:** .roughly/workflow-upgrades
**Action:** Append `plan-mode-gate-v1-added 2026-06-08` after the existing marker lines so this repo's install record reflects the plan-mode-gate hook that is genuinely installed (`.claude/hooks/plan-mode-gate.sh` exists). This makes AC1/AC2's manual-dispatch verification real. This is NOT a new setup write-site (out of scope) — it is a one-line correction to the dogfood repo's own tracked install record.
**Details:** The file currently reads:
```
roughly-version 0.1.7 2026-06-01
investigator-v1-added 2026-04-25
stop-hook-v1-added 2026-04-30
```
Add a new final line `plan-mode-gate-v1-added 2026-06-08` (today's date = the date the marker is being recorded). Do not alter the version line or the two existing marker lines.
**Verify:** `grep -Fc "plan-mode-gate-v1-added 2026-06-08" .roughly/workflow-upgrades` returns 1; the three pre-existing lines are unchanged.
**UI:** no

### T3: CHANGELOG `### Changed` entry (~4 min)
**Files:** CHANGELOG.md
**Action:** Add a new bullet to the existing `### Changed` block under `## [0.1.8] — 2026-06-03` (the block starting at line 30, immediately after the existing E06.S1 entries — append as a new top-level bullet in that `### Changed` list).
**Details:** The bullet must document, per AC3 + AC5:
- The schema fix and named files (`skills/help/SKILL.md`, `.roughly/workflow-upgrades`).
- That **option (a)** (help categorizes install markers separately) was chosen over **(b)** a `-installed` suffix migration and **(c)** a per-entry `kind` field in the `.roughly/workflow-upgrades` schema — per the E04 v0.1.7 candidate framing at the E04 epic.
- The install-marker list as it stands at ship: a single base ID `plan-mode-gate-v1` (ADR-009). Note the list is **contributor-maintained** — future install markers must be added to help's install-marker list when shipped; no convention codification beyond this entry. Defer to v0.1.9 if the list grows beyond ~3–5 entries.
- The list-maintenance burden acknowledged as the explicit tradeoff of option (a).
- A note that `setup` does not yet write the `plan-mode-gate-v1` marker automatically (T2 recorded it manually in this repo); auto-writing it from `setup` is a deferred follow-up.
- Cross-reference: E04 v0.1.7 candidates "`/roughly:help` 'Unknown' categorization for non-maturity-check install markers" (E04 epic L583).

Use markdown link syntax for file references consistent with the surrounding CHANGELOG entries (e.g., `[skills/help/SKILL.md](skills/help/SKILL.md)`).
**Verify:** `grep -Fn "E06.S6" CHANGELOG.md` returns ≥1 match under the `## [0.1.8]` `### Changed` block; the entry names both files, the option-(a)-over-(b)/(c) decision, and the cross-reference.
**UI:** no

## Blast Radius
- Do NOT modify: `skills/setup/SKILL.md` (adding a marker write-site is out of scope), the maturity-check ✓/✗ emit glyphs (AC2(i) "unchanged"), STEP 0/1/3/4 of help, the version line or existing marker lines in `.roughly/workflow-upgrades`, any other skill.
- Watch for: STEP 2 line-cap (≤173); leaving duplicated parse-rule / "no maturity checks" prose after the T1 replacement (the old lines 72–79 must be fully superseded, not duplicated); accidentally changing the maturity-check glyph lines (must stay byte-identical).

## Conventions
- ADR-009 (plan-mode-gate hook). E04 L583 candidate framing (option a/b/c).
- Strictly additive to help's categorization logic — do not refactor existing maturity-check logic (S6 out-of-scope).
- Skill body line cap 300; help projected ≤173 post-edit.
- Base-ID match (suffix-strip) is the existing convention; reuse it for install markers symmetrically (resolves cubic P1 from the spec: recognition list is base-ID form, not literal-marker-entry form).
