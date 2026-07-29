> **Status:** Historical — implemented and merged in commit 70f007e on 2026-07-29. This plan was an active build/fix artifact; treat as historical reference only.

# Fix Plan: #87 — known-pitfalls.md navigability reorg + line-cite hardening (Option A)

Plan-format-version: 1

## Root Cause

Two `.roughly/known-pitfalls.md` entries drifted into the wrong section (`## Review-Plan Fixture Design`) and belong in topical homes; separately, several docs cite entries in that file by absolute line number, which rots silently as entries shift. #87's substantive drivers already shipped (#74 threshold 80→300, #80 refactors); what remains is cosmetic navigability + citation hardening. Per the Option A scope decision (2026-07-29), this fix also repairs two **already-broken** live line-cites (`CONTRIBUTING.md`, `skills/review-plan/SKILL.md`, both stale `L86`) that are the same failure mode in normative/enforced files. Pure docs bookkeeping — no code, no CONTRIBUTING convention, no review-plan check.

## Scope (4 tasks — all pure relocation / citation-form edits; NO new convention, NO enforcement hook)
- **T1:** `.roughly/known-pitfalls.md` — relocate 2 misfiled `###` entries out of `## Review-Plan Fixture Design`, verbatim (MOVE, do not edit content): (a) `### CHANGELOG entries with intra-file line references must be re-computed post-insertion` → `## Documentation Hygiene`; (b) `### Gates presented via a UI tool let the model re-author them and launder unauthorized actions` → `## Skill & Agent Authoring`. Net-zero lines (stays 208). One subagent (single file, coordinated edits).
- **T2:** `docs/adrs/ADR-009-plan-mode-detection.md` — convert its **2** `.roughly/known-pitfalls.md` line-14 cites (lines 13 + 69) to topic-form (`§ "Domain-Specific"`, the plan-mode-hijack entry). (The 3rd occurrence the investigation first counted is in the frozen spike doc `plan-mode-detection-findings.md` — out of scope.)
- **T3:** `CONTRIBUTING.md` — convert the stale `L86` cite (line 81) to topic-form (`§ "Skill & Agent Authoring"`, the "LLM self-check anchor pattern" entry). Already wrong (target is at L110, not L86).
- **T4:** `skills/review-plan/SKILL.md` — convert the stale `L86` cite (line 47) to the same topic-form. Already wrong.
- All destinations verified: the "LLM self-check anchor pattern" entry lives in `## Skill & Agent Authoring`; line-14 target lives in `## Domain-Specific`. Both are unaffected by T1's moves (both moves are after line 14 and the L110 entry stays in its section), so topic-form refs are correct regardless of T1.

## File Table
| File | Action | Task |
|------|--------|------|
| .roughly/known-pitfalls.md | Modify (relocate 2 entries) | T1 |
| docs/adrs/ADR-009-plan-mode-detection.md | Modify (2 cites → topic-form) | T2 |
| CONTRIBUTING.md | Modify (1 cite → topic-form) | T3 |
| skills/review-plan/SKILL.md | Modify (1 cite → topic-form) | T4 |

## Baseline facts (captured 2026-07-29, branch `fix/81-86-contributing-convention-bundle`, 12 commits ahead of main)
- known-pitfalls sections: `## Domain-Specific` (10), `## Data & State` (16), `## Build & Deploy` (20), `## Skill & Agent Authoring` (84), `## Documentation Hygiene` (122), `## Planning & Scoping` (140), `## Review-Plan Fixture Design` (172). File = 208 lines. verify-all only checks the 300-line threshold on this file (no byte-identity/order/section check) — a net-zero move will not trip it.
- Entry (a) currently sits between `### Cross-AC cross-read…` and `### A story that installs a new disposition/gate…`. Entry (b) is the LAST entry in the file (EOF, single trailing newline).
- Dest (a): insert between the `- **Doc claims that cite specific line numbers in cross-referenced files rot silently.**` bullet and the `- **A "verified" tag on an inferred mechanism…**` bullet in `## Documentation Hygiene` (entry (a) is the same-file special case of that general rot pattern — coherent grouping).
- Dest (b): insert at the END of `## Skill & Agent Authoring`, immediately before the `## Documentation Hygiene` heading (after the `- **Before treating silent-failure-hunter findings against shared-reference files…**` entry).
- The `L86` cite target = `- **LLM self-check anchor pattern: prefer "begins with" over "is" + ellipsis.**` entry, in `## Skill & Agent Authoring`.
- Session shims `grep` — use `command grep`.

## Tasks

### T1: Relocate the 2 misfiled entries in known-pitfalls.md (~6 min)
**Files:** .roughly/known-pitfalls.md
**Action:** MOVE two `###` entries verbatim out of `## Review-Plan Fixture Design` — do NOT alter their text, do NOT merge. Read the file first; do the moves as exact-string edits (removal + insertion per entry). After the moves, `## Review-Plan Fixture Design` retains only: PASS fixtures, BORDERLINE-PASS, Cross-AC cross-read, and `### A story that installs a new disposition/gate dogfoods itself at Stage 6` (which becomes the file's last entry, with a single trailing newline).

**Move (a) → `## Documentation Hygiene`:** Remove the entry `### CHANGELOG entries with intra-file line references must be re-computed post-insertion` (heading + its `**Symptom:**`/`**Cause:**`/`**Fix:**` body) together with one adjacent blank line, so exactly one blank line separates `### Cross-AC cross-read…` from `### A story that installs…`. Re-insert it verbatim in `## Documentation Hygiene`, immediately BEFORE the bullet that begins `- **A "verified" tag on an inferred mechanism` (i.e. right after the `- **Doc claims that cite specific line numbers…**` bullet), with one blank line on each side.

**Move (b) → `## Skill & Agent Authoring`:** Remove the entry `### Gates presented via a UI tool let the model re-author them and launder unauthorized actions` (heading + `**Symptom:**`/`**Cause:**`/`**Fix:**` body) and the blank line preceding it (it is currently the file's last entry). Re-insert it verbatim at the END of `## Skill & Agent Authoring`, immediately BEFORE the `## Documentation Hygiene` heading, with one blank line separating it from the preceding entry and one blank line before `## Documentation Hygiene`.

**Details:** Both entries are large; move their bodies byte-for-byte (the `**Symptom:**`/`**Cause:**`/`**Fix:**` lines exactly as written, including all backticks and the trailing `Reference:` sentence). Do not touch the `### A story that installs…` entry that stays in Review-Plan Fixture Design between them. Net line delta = 0.
**Verify:**
```
cd "$(git rev-parse --show-toplevel)"
# each moved heading appears exactly once (no duplication/drop)
[ "$(command grep -cF -e '### CHANGELOG entries with intra-file line references must be re-computed post-insertion' .roughly/known-pitfalls.md)" -eq 1 ] || { echo FAIL-a-count; exit 1; }
[ "$(command grep -cF -e '### Gates presented via a UI tool let the model re-author them and launder unauthorized actions' .roughly/known-pitfalls.md)" -eq 1 ] || { echo FAIL-b-count; exit 1; }
# (a) now in Documentation Hygiene
awk '/^## Documentation Hygiene$/{a=1} /^## Planning & Scoping$/{a=0} a && /CHANGELOG entries with intra-file line references/{f=1} END{exit !f}' .roughly/known-pitfalls.md || { echo FAIL-a-dest; exit 1; }
# (b) now in Skill & Agent Authoring
awk '/^## Skill & Agent Authoring$/{a=1} /^## Documentation Hygiene$/{a=0} a && /Gates presented via a UI tool/{f=1} END{exit !f}' .roughly/known-pitfalls.md || { echo FAIL-b-dest; exit 1; }
# neither remains in Review-Plan Fixture Design
awk '/^## Review-Plan Fixture Design$/{a=1} a && (/CHANGELOG entries with intra-file line references/ || /Gates presented via a UI tool/){f=1} END{exit f}' .roughly/known-pitfalls.md || { echo FAIL-still-in-RPFD; exit 1; }
# net-zero move: line count unchanged
n=$(wc -l < .roughly/known-pitfalls.md); [ "$n" -eq 208 ] || { echo "FAIL-linecount ($n, expected 208)"; exit 1; }
# bodies preserved (spot-check a unique phrase from each)
command grep -qF -e 'silently inaccurate the moment the entry is written' .roughly/known-pitfalls.md || { echo FAIL-a-body; exit 1; }
command grep -qF -e 'laundered an unauthorized `git push` attempt at Stage 8' .roughly/known-pitfalls.md || { echo FAIL-b-body; exit 1; }
out=$(bash .claude/hooks/verify-all.sh 2>&1); [ -z "$out" ] || { echo "FAIL-verify: $out"; exit 1; }
echo "T1 PASS ($n lines)"
```
**UI:** no

### T2: Harden ADR-009's 2 line-14 cites → topic-form (~3 min)
**Files:** docs/adrs/ADR-009-plan-mode-detection.md
**Action:** Convert both `.roughly/known-pitfalls.md` line-14 references to a drift-proof topic-form naming the section + entry. Two exact-string Edits:
1. Replace `This structural bypass is documented in \`.roughly/known-pitfalls.md\` line 14.` with `This structural bypass is documented in the plan-mode-hijack entry in \`.roughly/known-pitfalls.md\` § "Domain-Specific".`
2. Replace `the pitfall entry at \`.roughly/known-pitfalls.md:14\` documents the same bypass mode from prior observation.` with `the plan-mode-hijack entry in \`.roughly/known-pitfalls.md\` § "Domain-Specific" documents the same bypass mode from prior observation.`

Do not alter surrounding prose. Do NOT touch the frozen spike doc `docs/planning/spikes/plan-mode-detection-findings.md` (out of scope).
**Verify:**
```
cd "$(git rev-parse --show-toplevel)"
[ "$(command grep -cE 'known-pitfalls\.md`?(:14|#L14| line 14)' docs/adrs/ADR-009-plan-mode-detection.md)" -eq 0 ] || { echo FAIL-line14-remains; exit 1; }
[ "$(command grep -cF -e '`.roughly/known-pitfalls.md` § "Domain-Specific"' docs/adrs/ADR-009-plan-mode-detection.md)" -eq 2 ] || { echo FAIL-topicform-count; exit 1; }
echo "T2 PASS"
```
**UI:** no

### T3: Harden CONTRIBUTING.md's stale L86 cite → topic-form (~2 min)
**Files:** CONTRIBUTING.md
**Action:** In the `## AC authoring conventions` paragraph (line ~81), replace the stale line-number cite with topic-form. Single exact-string Edit: replace
`See [.roughly/known-pitfalls.md](.roughly/known-pitfalls.md) L86 (LLM self-check anchor pattern: prefer "begins with" over "is" + ellipsis) for the underlying spec-time anti-pattern`
with
`See [.roughly/known-pitfalls.md](.roughly/known-pitfalls.md) § "Skill & Agent Authoring" (the "LLM self-check anchor pattern" entry: prefer "begins with" over "is" + ellipsis) for the underlying spec-time anti-pattern`
Do not alter the rest of the sentence (the `Enforcement is at plan-review time…` closer stays).
**Verify:**
```
cd "$(git rev-parse --show-toplevel)"
command grep -qF -e '§ "Skill & Agent Authoring" (the "LLM self-check anchor pattern" entry' CONTRIBUTING.md || { echo FAIL-not-converted; exit 1; }
[ "$(command grep -cF -e '](.roughly/known-pitfalls.md) L86' CONTRIBUTING.md)" -eq 0 ] || { echo FAIL-L86-remains; exit 1; }
echo "T3 PASS"
```
**UI:** no

### T4: Harden review-plan/SKILL.md's stale L86 cite → topic-form (~2 min)
**Files:** skills/review-plan/SKILL.md
**Action:** In the `**Completeness:**` `AC quoted-wording marker` carve-out (line ~47), replace the stale cite. Single exact-string Edit: replace
`the trailing \`…\` is metasyntactic per \`.roughly/known-pitfalls.md\` L86 LLM self-check anchor pattern)`
with
`the trailing \`…\` is metasyntactic per the \`.roughly/known-pitfalls.md\` § "Skill & Agent Authoring" "LLM self-check anchor pattern" entry)`
Do not alter the rest of the carve-out. File must stay ≤300 lines (currently 124).
**Verify:**
```
cd "$(git rev-parse --show-toplevel)"
command grep -qF -e '§ "Skill & Agent Authoring" "LLM self-check anchor pattern" entry)' skills/review-plan/SKILL.md || { echo FAIL-not-converted; exit 1; }
[ "$(command grep -cF -e 'known-pitfalls.md` L86' skills/review-plan/SKILL.md)" -eq 0 ] || { echo FAIL-L86-remains; exit 1; }
n=$(wc -l < skills/review-plan/SKILL.md); [ "$n" -le 300 ] || { echo "FAIL-cap $n"; exit 1; }
out=$(bash .claude/hooks/verify-all.sh 2>&1); [ -z "$out" ] || { echo "FAIL-verify: $out"; exit 1; }
echo "T4 PASS ($n/300)"
```
**UI:** no

## Blast Radius
- **Do NOT modify:** the moved entries' text (verbatim relocation only); the `### A story that installs a new disposition/gate…` entry (stays in Review-Plan Fixture Design); the frozen `docs/planning/spikes/plan-mode-detection-findings.md` and any `docs/planning/epics/complete/**` / CHANGELOG.md / ROADMAP.md stale cites (append-only/frozen, out of scope — noted for a possible future pass); any code/agent/other file.
- **Watch for:** (a) T1 is a pure MOVE — net line delta 0 (verify asserts 208); each moved heading must appear exactly once; do not merge entry (a) into the general "Doc claims…" bullet — it stays a distinct `###` entry; (b) topic-form cites use `§ "<section>"` section names, never line numbers; (c) T2/T3/T4 are decoupled from T1 (topic-form, no line dependency) → all 4 tasks parallelizable across 4 distinct files; (d) preserve the file's single trailing newline after moving entry (b) off EOF; (e) shimmed grep — use `command grep`; (f) verify greps are positive-presence + count/absence guards — none self-defeating.

## Conventions
- No build/test harness — inline `command grep`/`awk`/verify-all-clean Verify blocks are the validation.
- 4 distinct files → parallelizable.
