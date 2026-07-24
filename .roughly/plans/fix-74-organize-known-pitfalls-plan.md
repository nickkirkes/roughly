# Fix Plan: #74 — silence the known-pitfalls "consider organizing" advisory (threshold recalibration)

Plan-format-version: 1

## Root Cause

The Stop hook check at `.claude/hooks/verify-all.sh:90-96` is a **whole-file `wc -l`** count against `PITFALLS_ORGANIZE_THRESHOLD=80`. `.roughly/known-pitfalls.md` is 192 lines and grows monotonically (~15 lines/week; it is an append-only knowledge base populated by `doc-writer` at every build/fix wrap-up). Because the check counts physical lines of one file, the issue's proposed "group into domain sections" cannot reduce the count — the file is **already** organized into 7 `##` domain sections, and there are **no true duplicate entries** to dedup away. The advisory therefore fires on every run purely because the corpus is genuinely large, and the only change that clears it (without deleting real content) is recalibrating the threshold. The original 80 was set when the file was ~36 lines and was crossed within ~3 weeks; it has been permanent noise ever since — training contributors to ignore verify-all output, the opposite of a drift signal's purpose.

## Decision: raise `PITFALLS_ORGANIZE_THRESHOLD` 80 → 300

**Why 300:** reuses the project's existing "genuinely large file" number (the `skills/*/SKILL.md` line cap is 300, per `verify-all.sh` and `CONTRIBUTING.md:206`) rather than inventing a new arbitrary value; gives real headroom over the current 192 (avoiding the original 80's mistake of sitting at the edge); and is growth-justified — it buys ~7-10 more weeks before the advisory legitimately re-fires on a corpus that has genuinely grown unwieldy again. No fixed threshold is permanently correct for an append-only file; 300 is a defensible "not immediately, not forever."

The threshold is **bidirectionally synced** (per the hook's own comment): `verify-all.sh:90` and `agents/doc-writer.md:33` must change together (AC2). Several docs also cite the literal `80` and go stale if not updated — swept for consistency.

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| .claude/hooks/verify-all.sh | Modify | T1 |
| agents/doc-writer.md | Modify | T2 |
| CONTRIBUTING.md | Modify | T3 |
| README.md | Modify | T3 |
| skills/review-plan/SKILL.md | Modify | T3 |
| docs/ROADMAP.md | Modify | T3 |

## Baseline facts (captured 2026-07-24, branch `fix/74-organize-known-pitfalls`, at parity with `main`)
- Check mechanism: `.claude/hooks/verify-all.sh:90` `PITFALLS_ORGANIZE_THRESHOLD=80`; `n=$(wc -l < .roughly/known-pitfalls.md)`; fires `- .roughly/known-pitfalls.md is $n lines (>${THRESHOLD} threshold) — consider organizing` when `n > threshold`. Current n = 192.
- Synced pair (AC2): `verify-all.sh:90` and `agents/doc-writer.md:33` (the `If line count > 80` clause, guarded by an inline `<!-- Bidirectional sync ... -->` comment).
- `agents/doc-writer.md` is 647/650 words. Changing the numeral `80`→`300` is **word-count-neutral** (one word either way) — safe. Do NOT add prose there.
- No consumer-facing template change: `skills/setup/templates/verify-all-stop-hook.sh.template` has NO known-pitfalls check (verified) — the dogfood hook and the template are an intentionally-unsynced pair (`CONTRIBUTING.md:208`, E03.S2). Out of scope.
- Session `grep`/`diff` are shimmed — use `command grep` / `command diff` in verification.

## Tasks

### T1: Raise the threshold in the hook (~2 min)
**Files:** .claude/hooks/verify-all.sh
**Action:** Change `PITFALLS_ORGANIZE_THRESHOLD=80` to `300`, and update the adjacent sync comment to record the rationale + the new synced value.
**Details:**
1. Replace the line `PITFALLS_ORGANIZE_THRESHOLD=80` with `PITFALLS_ORGANIZE_THRESHOLD=300`.
2. There is a 3-line comment block immediately above the assignment; line 87 (`# .roughly/known-pitfalls.md organize-suggestion threshold (closes E03.S3 manual-edit coverage gap).`) is unrelated and stays untouched. The last two lines of that block currently read:
   `# Bidirectional sync: matching policy parameter in agents/doc-writer.md Process step 5`
   `# ("Organize suggestion"). Update both if the threshold changes.`
   Append one comment line after them (before the `PITFALLS_ORGANIZE_THRESHOLD=` line): `# Value 300 mirrors the SKILL.md line cap: known-pitfalls is an append-only corpus, so this flags "genuinely large" (was 80, permanent noise from ~36 lines up).`
Do not change the `if`/`wc -l` logic or the emitted message string.
**Verify:**
```
command grep -qF 'PITFALLS_ORGANIZE_THRESHOLD=300' .claude/hooks/verify-all.sh || { echo FAIL-not-300; exit 1; }
command grep -qF 'PITFALLS_ORGANIZE_THRESHOLD=80' .claude/hooks/verify-all.sh && { echo FAIL-old-80-remains; exit 1; }
command grep -qF 'Value 300 mirrors the SKILL.md line cap' .claude/hooks/verify-all.sh || { echo FAIL-comment-missing; exit 1; }
bash -n .claude/hooks/verify-all.sh || { echo FAIL-syntax; exit 1; }
# advisory must no longer fire (file is 192 < 300):
bash .claude/hooks/verify-all.sh 2>&1 | command grep -qF 'consider organizing' && { echo FAIL-advisory-still-fires; exit 1; }
echo "T1 PASS"
```
**UI:** no

### T2: Update the synced parameter in doc-writer (~2 min)
**Files:** agents/doc-writer.md
**Depends on:** T1
**Action:** Change the `If line count > 80` threshold on line 33 to `> 300`, keeping the bidirectional-sync comment intact. Word-count-neutral — add NO other prose.
**Details:** On `agents/doc-writer.md:33`, in the `**Organize suggestion:**` bullet, replace the substring `If line count > 80, append` with `If line count > 300, append`. Leave the `<!-- Bidirectional sync: ... -->` comment and everything else on the line unchanged.
**Verify:**
```
command grep -qF 'If line count > 300, append' agents/doc-writer.md || { echo FAIL-not-300; exit 1; }
command grep -qF 'If line count > 80, append' agents/doc-writer.md && { echo FAIL-old-80-remains; exit 1; }
w=$(wc -w < agents/doc-writer.md); [ "$w" -le 650 ] || { echo "FAIL-word-cap $w"; exit 1; }
command grep -qF 'Bidirectional sync' agents/doc-writer.md || { echo FAIL-sync-comment-lost; exit 1; }
echo "T2 PASS ($w/650 words)"
```
**UI:** no

### T3: Consistency sweep — de-stale the literal "80" references + mark ROADMAP item resolved (~4 min)
**Files:** CONTRIBUTING.md, README.md, skills/review-plan/SKILL.md, docs/ROADMAP.md
**Depends on:** T1, T2
**Action:** Update the four docs that name the old literal `80` so they don't contradict the new value; mark the ROADMAP backlog item resolved.
**Details:**
1. `CONTRIBUTING.md:209` — replace `wc -l > PITFALLS_ORGANIZE_THRESHOLD` (currently 80)` with `wc -l > PITFALLS_ORGANIZE_THRESHOLD` (currently 300)`.
2. `README.md:223` — replace `the file exceeds 80 lines, it suggests reorganization` with `the file exceeds 300 lines, it suggests reorganization`.
3. `skills/review-plan/SKILL.md:57` — replace `A duplicated \`80\` threshold is not a violation of this check.` with `A duplicated \`300\` threshold is not a violation of this check.` (illustrative example — keep it aligned with the real synced value).
4. `docs/ROADMAP.md:133` — the backlog item currently reads `- **\`.roughly/known-pitfalls.md\` organization sweep** — 174 lines vs 80 threshold; recurring advisory across all v0.1.8 stories.` Replace it with: `- ~~**\`.roughly/known-pitfalls.md\` organization sweep**~~ **RESOLVED (#74):** the advisory is a whole-file \`wc -l\` count (domain-grouping can't reduce it) on an append-only corpus; threshold recalibrated 80→300 rather than deleting real content.`
Do not otherwise edit these files.
**Verify:**
```
command grep -qF '(currently 300)' CONTRIBUTING.md || { echo FAIL-contributing; exit 1; }
command grep -qF 'exceeds 300 lines' README.md || { echo FAIL-readme; exit 1; }
command grep -qF 'A duplicated `300` threshold' skills/review-plan/SKILL.md || { echo FAIL-reviewplan; exit 1; }
command grep -qF 'RESOLVED (#74)' docs/ROADMAP.md || { echo FAIL-roadmap; exit 1; }
# no stray old-80 threshold refs remain in the swept docs:
for f in CONTRIBUTING.md README.md skills/review-plan/SKILL.md; do
  command grep -qF '80' "$f" && echo "NOTE: check $f still contains '80' (may be unrelated — reviewer to confirm)"
done
echo "T3 PASS"
```
**UI:** no

## Blast Radius
- **Do NOT modify:** `.roughly/known-pitfalls.md` content (no reorg/dedup this pass — see below), `skills/setup/templates/verify-all-stop-hook.sh.template` (intentionally has no such check), the `wc -l`/`if` logic or the emitted message string in verify-all.sh, CHANGELOG's already-stale line citations (append-only historical record). Also intentionally NOT swept: `docs/planning/prompts/*.md` (e.g. `roughly-pm-agent-v0.1.{6,7,8}.md`, which state the old "80" threshold) and `docs/planning/archive/*.md` — versioned point-in-time PM-engagement snapshots, same append-only-historical-record rationale as CHANGELOG; their "80" is correct for the moment they captured.
- **Watch for:** (a) the T3 `grep '80'` note is advisory — some files may contain an unrelated `80` (e.g. a different context); the reviewer confirms no *threshold* reference is left stale, not that the digits `80` never appear. (b) doc-writer word cap — add no prose. (c) shimmed grep/diff — use `command grep`.

## Out of scope — investigator-surfaced, deliberately deferred (not bundled)
These do not advance any #74 AC and carry churn/judgment risk; recorded here so they aren't lost, to be picked up only if the human opts in at the plan gate or in a follow-up:
- **Move 2 misfiled entries** in `.roughly/known-pitfalls.md` out of `## Review-Plan Fixture Design` (a CHANGELOG same-file line-cite-rot entry → `## Documentation Hygiene`; a gate-UI-laundering/ADR-015 entry → a gate/pipeline home). Cosmetic; the ADR-015 entry has no clean existing target section.
- **Convert `docs/adrs/ADR-009-plan-mode-detection.md:13`'s "line 14" citation to topic-form** (per E06.S2 precedent). Currently *accurate*, so this is protective hardening against a future reorg, not a live break — nothing in #74 disturbs line 14.

## Conventions
- No build step / test harness — the inline `bash -n` + grep + live-hook-run Verify blocks are the validation (consistent with how verify-all.sh changes are checked in this repo).
- AC3 ("no pitfall content lost") is satisfied trivially: this plan does not touch `.roughly/known-pitfalls.md` content at all.
