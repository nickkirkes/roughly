> **Status:** Historical — implemented and merged in commit 432b778f6b88f2793f245abd1597334f7ada3e37 on 2026-05-26. This plan was an active build/fix artifact; treat as historical reference only.

# Implementation Plan: E05.S1 — project-wide agent word cap revision 500 → 650

Plan-format-version: 1

## Source

Story spec: `docs/planning/epics/E05-doc-writer-hardening-and-spec-quality-gates.md` §E05.S1 (lines 55–85).

## Scope expansion from discovery (user-approved 2026-05-26)

The original story spec named **3 files**: `.claude/hooks/verify-all.sh`, `CONTRIBUTING.md`, `CHANGELOG.md`. Discovery surfaced two additional concrete `500` references in normative documentation that would create internal inconsistency if left at 500 after the cap revision lands:

1. **CONTRIBUTING.md** contains the literal `500` in **three** locations, not just the `## Stop hook drift checks` section the spec names:
   - Line 39 — `## PR Process` item 5: "agents under 500 words"
   - Line 121 — `## Testing` item 5: "agents < 500 words"
   - Line 166 — `## Stop hook drift checks` Check 3: "≤ 500 words"
2. **CLAUDE.md** line 39 — `Agent prompts must stay under 500 words`. Live, normative; read by agents at runtime per ADR-006.

User-approved scope decisions:
- **Q1 → all 3 CONTRIBUTING.md occurrences updated** (39, 121, 166).
- **Q2 → CLAUDE.md added as a 4th touched file** (line 39 only).
- **Q3 → rationale line appended at end of `## Stop hook drift checks` section** (before `## License`), as a trailing explanatory note rather than interrupting the numbered check list.

Net effect on AC5: `git diff --stat` now expects **4 files** (`.claude/hooks/verify-all.sh`, `CONTRIBUTING.md`, `CLAUDE.md`, `CHANGELOG.md`), not 3. This is a documented amendment to the spec's AC5 enumeration; the spirit of AC5 ("no agent file edits") is preserved — none of the four files are under `agents/`.

## File Table

| File | Action | Task(s) |
|------|--------|---------|
| `.claude/hooks/verify-all.sh` | Modify (2 occurrences, same line 30 + comment line 27) | T1 |
| `CONTRIBUTING.md` | Modify (3 occurrences + append rationale line) | T2 |
| `CLAUDE.md` | Modify (1 occurrence) | T3 |
| `CHANGELOG.md` | Modify (insert new `## [Unreleased]` + `### Changed` section at line 3) | T4 |
| (no file edit — runtime verification) | Runtime test | T5 |

## Tasks

### T1: Update agent word cap constant in verify-all.sh (~2 min)

**Files:** `.claude/hooks/verify-all.sh`

**Depends on:** none

**Action:** Change the agent word cap from 500 to 650 in the script's agent-word-cap check block (currently lines 27–31).

**Details:**
- Line 27 contains the comment `# Agent word cap (500)`. Change to `# Agent word cap (650)`.
- Line 30 contains the conditional and drift message: `[ "$n" -gt 500 ] && issues="${issues}- $f: $n words exceeds 500 cap\n"`. Change BOTH literal `500` occurrences on this line to `650`. The final line must read: `  [ "$n" -gt 650 ] && issues="${issues}- $f: $n words exceeds 650 cap\n"` (preserving the leading 2-space indent and trailing semantics byte-identically).
- Use `Edit` tool with `replace_all: false` for each `old_string` → `new_string` substitution. Do not edit any other line in the file. Specifically: the `PITFALLS_ORGANIZE_THRESHOLD=80` constant on line 90 is out of scope and must not be touched.
- The drift message format string `- $f: $n words exceeds <N> cap` is preserved (AC2 requirement) — only the numeric value swaps.

**Verify:**
- `grep -Fn "650" .claude/hooks/verify-all.sh` returns matches on lines 27 and 30 (the comment and the conditional/message line).
- `grep -Fcn "500" .claude/hooks/verify-all.sh` returns 0 matches in the agent-word-cap block (lines 27–31). (The string `500` may legitimately appear elsewhere in the file in unrelated contexts — restrict the check visually to lines 27–31.)
- `bash -n .claude/hooks/verify-all.sh` exits 0 (syntax check; no execution).

**UI:** no

---

### T2: Update CONTRIBUTING.md (3 occurrences + append rationale) (~4 min)

**Files:** `CONTRIBUTING.md`

**Depends on:** none

**Action:** Update all three live normative references to the 500-word agent cap to 650, then append the AC3-mandated rationale line at the end of the `## Stop hook drift checks` section.

**Details:**
- **Edit 1 (line 39, `## PR Process` item 5):** locate the substring `agents under 500 words`. Change `500` → `650`. Use `Edit` with `old_string` containing enough surrounding context to be unique (e.g., `agents under 500 words`).
- **Edit 2 (line 121, `## Testing` item 5):** locate `agents < 500 words`. Change `500` → `650`. Use unique context to disambiguate from edit 1.
- **Edit 3 (line 166, `## Stop hook drift checks` Check 3):** locate `every \`agents/*.md\` stays ≤ 500 words`. Change `500` → `650`.
- **Edit 4 (append rationale):** insert a new paragraph at the end of the `## Stop hook drift checks` section, immediately before the `## License` heading. The new content must be a single line containing the AC3-mandated exact prose, byte-for-byte:

  > agent word cap raised 500 → 650 in E05.S1 to accommodate failure-handling clauses with verbatim summary templates and to provide real headroom (≥50 words at projected post-E05.S2 state) rather than landing at the edge of a tighter cap.

  Format as a standalone paragraph (no list marker, no blockquote, no heading). Separate from the preceding content with a blank line; separate from `## License` with a blank line.
- **The rationale line embeds the literal string `500 → 650`**, so the post-edit `grep -Fcn "500" CONTRIBUTING.md` will legitimately return **1** match within the rationale text — this is the only acceptable surviving `500`. T2's verify steps account for this.
- Use `Edit` with `replace_all: false` for each substitution. Do not modify any other content. Do not change `≤` to `<=` or otherwise reformat the existing lines beyond the numeric value.

**Verify:**
- `grep -Fcn "650" CONTRIBUTING.md` returns **4** matches (lines 39, 121, 166, plus one occurrence of `500 → 650` in the rationale line).
- `grep -Fcn "500" CONTRIBUTING.md` returns exactly **1** match (the `500 → 650` literal in the rationale line). The number `500` must NOT appear in any of lines 39, 121, or 166 post-edit.
- `grep -Fn "agent word cap raised 500 → 650 in E05.S1" CONTRIBUTING.md` returns exactly 1 match.
- Section ordering preserved: `grep -nE "^## " CONTRIBUTING.md` shows the same section order as pre-edit (no headings added or moved).

**UI:** no

---

### T3: Update CLAUDE.md line 39 (~1 min)

**Files:** `CLAUDE.md`

**Depends on:** none

**Action:** Change the normative agent prompt cap line from 500 to 650.

**Details:**
- Locate the line `Agent prompts must stay under 500 words` (line 39 in current revision; matched by exact string).
- Change `500` → `650`. The rest of the line is byte-identical post-edit.
- Use `Edit` with `replace_all: false`. Do not modify any other line. Do not touch the project-name, structure table, or any other section.
- This edit lands the project's own convention statement in sync with the new enforcement value, eliminating the documented contradiction that would otherwise persist.

**Verify:**
- `grep -Fn "Agent prompts must stay under 650 words" CLAUDE.md` returns exactly 1 match.
- `grep -Fcn "500 words" CLAUDE.md` returns 0 matches (the file should have no remaining literal "500 words" string anywhere).
- `grep -nE "^## " CLAUDE.md` shows section structure unchanged.

**UI:** no

---

### T4: Add `## [Unreleased]` + `### Changed` to CHANGELOG.md (~3 min)

**Files:** `CHANGELOG.md`

**Depends on:** none (content references the cap change but doesn't strictly require T1–T3 to be done first)

**Action:** Introduce a new `## [Unreleased]` section at the top of the file (after the `# Changelog` heading) with a `### Changed` subsection documenting the cap revision.

**Details:**
- The file currently goes from `# Changelog` directly to `## [0.1.6] — 2026-05-24`. Insert the new section between them.
- Use `Edit` with `replace_all: false`; `old_string` = the existing `## [0.1.6] — 2026-05-24` line; `new_string` = the full new section (Unreleased + Changed entry) followed by a blank line and then the original `## [0.1.6]` line. This preserves the order without disturbing the [0.1.6] entry.
- The new section MUST begin with `## [Unreleased]` (no date, no blockquote summary — match the project's pre-release convention).
- Under it, add `### Changed` followed by a single bullet entry matching the dense paragraph style of [0.1.6]'s `### Changed` entries (bold-prefixed, inline detail, markdown links to touched files).
- Required content of the entry:
  - Bold prefix naming the change (e.g., `**Agent word cap raised 500 → 650.**`)
  - State the constant moved in `.claude/hooks/verify-all.sh` (with relative-path markdown link).
  - State that [CONTRIBUTING.md](CONTRIBUTING.md) and [CLAUDE.md](CLAUDE.md) were updated to match.
  - Document the E04.S8 post-revision compliance status: `agents/doc-writer.md` is now compliant at 557/650 pre-E05.S2; projected 595–625 post-E05.S2 (comfortable headroom). This is mandated by AC4.
  - Reference the rationale: accommodate E05.S2 failure-handling clauses with verbatim summary templates and provide ≥50-word headroom.
- One paragraph, no sub-bullets. Match the prose density of the existing [0.1.6] entries.

**Verify:**
- `grep -Fn "## [Unreleased]" CHANGELOG.md` returns exactly 1 match, on a line before `## [0.1.6]`.
- `grep -Fn "557/650" CHANGELOG.md` returns ≥1 match (AC4 compliance number cited).
- `grep -Fn "500 → 650" CHANGELOG.md` returns ≥1 match.
- The `## [0.1.6]` section content is byte-identical to its pre-edit state (no accidental modification): `git diff CHANGELOG.md` shows only additions above the `## [0.1.6]` line, no deletions or modifications in [0.1.6] or below.

**UI:** no

---

### T5: AC2 drift-entry runtime verification (~3 min)

**Files:** none (temporary edit + revert)

**Depends on:** T1 (verify-all.sh must already reflect the new cap)

**Action:** Exercise the agent-word-cap drift check at the new 650 threshold to confirm AC2 — the drift entry fires with the new threshold value substituted while preserving format.

**Details:**
- Pick a low-risk agent file (recommend `agents/doc-writer.md` since it is the largest at 557 words; padding it to >650 needs only a small temporary additive comment block).
- Strategy: append a temporary HTML comment block of dummy filler words to the end of `agents/doc-writer.md` sufficient to push word count above 650 (target ~660 — comfortable margin). HTML comments do not affect the agent's runtime behavior if accidentally not reverted (defense in depth), but the revert IS mandatory.
- After padding, run `bash .claude/hooks/verify-all.sh 2>&1` (the hook script directly — does not require triggering a Stop hook). Capture output.
- Confirm the output contains the literal substring `agents/doc-writer.md: <N> words exceeds 650 cap` where `<N>` is the padded word count and `650` is the new threshold value. The format string `- $f: $n words exceeds <N> cap` must be preserved byte-identically (only the numeric value differs).
- Confirm no other agent file fires the drift entry at the new threshold (all other agents should be ≤650 words — sanity check that the new cap isn't accidentally too low).
- **Revert immediately:** undo the temporary edit. Verify `wc -w agents/doc-writer.md` returns 557 (pre-padding value) and `git status agents/doc-writer.md` shows no modification.

**Verify:**
- Drift output during the test contained `exceeds 650 cap` (NOT `exceeds 500 cap` and NOT `exceeds 0 cap` or other corruption).
- Post-revert: `git status agents/doc-writer.md` reports the file as unmodified.
- Post-revert: `wc -w agents/doc-writer.md` returns 557.
- Post-revert: `bash .claude/hooks/verify-all.sh 2>&1` produces NO agent-word-cap drift entries (since 557 ≤ 650).

**UI:** no

---

## Blast Radius

**Do NOT modify:**
- Any file under `agents/` — including `agents/doc-writer.md` content (E05.S2 territory). T5's temporary padding is restored within the same task; no committed change to any agent file.
- Any file under `skills/`.
- Any file under `docs/planning/archive/` or `docs/planning/epics/complete/` — historical record, do not retroactively change `500` references.
- `CHANGELOG.md` entries below the new `## [Unreleased]` section — historical record, including the existing `500`-related text in prior release entries.
- The `PITFALLS_ORGANIZE_THRESHOLD=80` constant in `.claude/hooks/verify-all.sh` (line 90) — out of scope per epic.
- Any ADR — the epic explicitly states the cap is a maintenance parameter, not an ADR-level decision (per OQ3).

**Watch for:**
- Any other surviving `500` literal in CONTRIBUTING.md or CLAUDE.md that we did not enumerate above. If `grep -Fcn "500" CONTRIBUTING.md` returns more than the expected 1 match after T2 completes, investigate — it may be a legitimate non-agent-cap reference (e.g., port number, byte size), but flag for review.
- The PM agent prompt file `docs/planning/prompts/roughly-pm-agent-v0.1.7.md` mentions 500 — this is historical PM artifact, do not modify.

## Conventions

- Use `Edit` tool with `replace_all: false` for every text substitution. Surround `old_string` with enough context to be unique in the file (relevant especially for T2 where `500` appears in multiple sections — disambiguate by neighboring words, not just the digit).
- Match existing CHANGELOG style ([0.1.6] as reference): bold-prefixed dense paragraph bullets, markdown links via `[filename](relative-path)`, no sub-bullets.
- Do not introduce trailing whitespace. Do not change line endings.
- Per CLAUDE.md, no emojis in any of the touched files unless already present.
- Per the build SKILL Stage 8: Stage 5b/5c subagents must NOT commit. The orchestrator handles the commit in Stage 8.

## Out of scope (explicit per epic §E05.S1)

- Any edits to `agents/doc-writer.md` content (E05.S2 territory).
- Per-agent caps (E04.S8 v0.1.7 candidate option c — deferred without forcing function).
- ADR amendment.
- Adjusting `PITFALLS_ORGANIZE_THRESHOLD=80` or any other Stop hook threshold.
