> **Status:** Historical — implemented and merged in commit aea184c2347e70199d4363b204baeda59ab28f80 on 2026-07-28. This plan was an active build/fix artifact; treat as historical reference only.

# Fix Plan: #84 — codify mirror-verbatim + negative-grep self-test convention

Plan-format-version: 1

## Root Cause

No plan-write discipline exists for cross-testing an AC that pairs a "verbatim copy from X" requirement with a negative-grep verify clause. When source X already contains the byte sequence the negative grep forbids, the two clauses contradict: satisfying the verbatim-mirror requirement fails the grep, and satisfying the grep breaks the mirror. Each clause reads fine in isolation, so plan-review + Stage 6 can miss it. E06.S2.AC1 shipped exactly this contradiction (its "verbatim from build-side reference" requirement vs. a negative grep against a substring the reference contained); it was resolved post-merge by scoping "verbatim" to the load-bearing standalone-token detection clause and rewording the lead-in verb (E06.S2 deviation note, 2026-06-08). Docs-convention codification, not a code bug. This is a distinct E06 incident from the E06.S7 pair that #81 (provenance) and #83 (execution) mined — a different failure facet (AC-internal contradiction).

## Scope (same 3-task shape as #83; enforcement verdict = NEW peer check)
- **T1:** `CONTRIBUTING.md` `## AC authoring conventions` — the mirror-verbatim vs negative-grep cross-test convention (peer paragraph after #83's `**Executable example content.**`). Canonical text pre-drafted at `docs/planning/epics/complete/E06-anchoring-closure-and-ci-coverage.md:561-563`; promote it. Cite the real incident at `E06-…md:195` (2026-06-08).
- **T2:** `skills/review-plan/SKILL.md` `**Completeness:**` — a **NEW peer** enforcement bullet (investigation verdict: NOT an extension of the `AC quoted-wording marker` check — that fires on notation ambiguity; NOT a duplicate of the `Self-defeating verify pattern` check — that is single-clause self-search-literal collision with NEW prose, whereas #84 is cross-clause verbatim-vs-negative-grep against EXISTING reference text). Same family, distinct trigger/remedy → new peer bullet.
- **T3:** `.roughly/known-pitfalls.md` — an entry documenting this exact pitfall **already exists** at `## Planning & Scoping` ("An AC that pairs a 'mirror the reference verbatim' requirement with a negative-presence grep can be internally self-contradictory," E06.S2.AC1 origin + resolution + Pattern). Do **NOT** add a duplicate under Documentation Hygiene. Instead, extend the existing entry with the codified/enforced cross-reference line it currently lacks (matching how #81's and #83's entries close), wiring it to T1's convention and T2's enforcement.
- Cross-reference all additions by **section name, not line number** (honor the "line-number citations rot" pitfall in the same known-pitfalls section).

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| CONTRIBUTING.md | Modify (append 1 paragraph to `## AC authoring conventions`) | T1 |
| skills/review-plan/SKILL.md | Modify (append 1 `**Completeness:**` peer bullet + carve-out) | T2 |
| .roughly/known-pitfalls.md | Modify (extend the EXISTING mirror-verbatim entry under `## Planning & Scoping` with a codified/enforced cross-ref — NOT a new entry) | T3 |

## Baseline facts (captured 2026-07-28, branch `fix/81-86-contributing-convention-bundle`, 4 commits ahead of main = #81 + #83)
- `CONTRIBUTING.md` `## AC authoring conventions` (L68) now ends with the `**Executable example content.**` paragraph (L83, from #83), blank L84, `## Cross-epic AC amendments` at L85. Append the new peer paragraph after L83, before the blank/heading. No line cap.
- `skills/review-plan/SKILL.md` (121/300) `**Completeness:**` block now ends with the `- **AC executable-example verify command.**` bullet + its `- **Carve-out:**` sub-bullet (ends L50, from #83), blank L51, `**Assumptions:**` at L52. Append the new bullet + carve-out after L50, before `**Assumptions:**`.
- `.roughly/known-pitfalls.md` (197/300) `## Documentation Hygiene` now ends with #83's "Normative docs and ACs can ship example commands…" entry (L126), blank L127, `## Planning & Scoping` at L128. Append after L126, before the blank.
- Canonical pre-drafted convention text (`E06-…md:563`): "…When an AC pairs a 'verbatim copy from X' requirement with a negative grep against a specific byte sequence, the verbatim form must be cross-tested against the negative grep at plan-write time. … either show the verbatim form satisfies the negative grep, or scope 'verbatim' to a load-bearing sub-clause that is grep-safe. Ties to E06.S4's quoted-wording marker work."
- Real incident (`E06-…md:195`, 2026-06-08): "verbatim from build-side reference" mirror requirement paired with the negative-grep clause; the build-side sentence contained the byte sequence the negative grep detects; resolved by scoping "verbatim" to the load-bearing parenthetical (standalone-token detection clause) + rewording the lead-in verb.
- Session may shim grep — use `command grep`.

## Tasks

### T1: Add the mirror-verbatim cross-test convention to CONTRIBUTING.md (~4 min)
**Files:** CONTRIBUTING.md
**Action:** Append one bold-lead-in paragraph to the END of `## AC authoring conventions` (after the `**Executable example content.**` paragraph ending "…there is no runtime check.", before the blank preceding `## Cross-epic AC amendments`). Match the section's house style (bold lead-in + rule + `Precipitating evidence:` + enforcement pointer).
**Details:** Insert this EXACT paragraph, keeping one blank line before and after (before `## Cross-epic AC amendments`):

`**Mirror-verbatim vs negative-grep cross-test.** When an AC combines a "verbatim copy from X" requirement (a clause that must mirror source X byte-for-byte) with a negative-grep verify clause (asserting a byte sequence must NOT appear), cross-test the two at plan-write: confirm the verbatim form of X actually satisfies the negative grep. If X already contains the forbidden byte sequence, a true verbatim copy fails the AC's own verify. Resolve by either (a) showing the verbatim form passes the negative grep, or (b) scoping "verbatim" to a load-bearing sub-clause of X that is grep-safe (the \`verbatim:\` marker from the quoted-wording convention above makes the cross-test surface obvious). Precipitating evidence: E06.S2.AC1 was internally contradictory — its "verbatim from build-side reference" mirror requirement was paired with a negative grep against the very substring-trap-precluding sentence pattern the build-side reference contained, so a true verbatim copy failed the AC's own negative grep (E06.S2 post-merge deviation note, 2026-06-08); resolved by scoping "verbatim" to the load-bearing standalone-token detection clause and rewording the lead-in verb. Enforcement is at plan-review time via the corresponding check in [skills/review-plan/SKILL.md](skills/review-plan/SKILL.md); there is no runtime check.`

Do not modify the existing quoted-wording / executable-example conventions or `## Cross-epic AC amendments`.
**Verify:**
```
cd "$(git rev-parse --show-toplevel)"
command grep -qF '**Mirror-verbatim vs negative-grep cross-test.**' CONTRIBUTING.md || { echo FAIL-not-added; exit 1; }
command grep -qF 'a true verbatim copy fails the AC' CONTRIBUTING.md || { echo FAIL-no-rule; exit 1; }
awk '/^## AC authoring conventions/{a=1} /^## Cross-epic AC amendments/{a=0} a && /Mirror-verbatim vs negative-grep cross-test/{f=1} END{exit !f}' CONTRIBUTING.md || { echo FAIL-wrong-section; exit 1; }
command grep -qF 'Executable example content' CONTRIBUTING.md || { echo FAIL-83-content-lost; exit 1; }
echo "T1 PASS"
```
**UI:** no

### T2: Add the paired enforcement check to review-plan (~4 min)
**Files:** skills/review-plan/SKILL.md
**Action:** Append one `- ` bullet + a 2-space-indented `- **Carve-out:**` sub-bullet to the END of the `**Completeness:**` block (after the `- **AC executable-example verify command.**` bullet + its carve-out, before `**Assumptions:**`). Match the checklist style (bold lead-in + rule + "flag… before approving the plan" + `Carve-out:` with a `Canonical positive:`).
**Details:** Insert these EXACT two lines (top-level bullet, then 2-space-indented carve-out), keeping one blank line before and one after (before `**Assumptions:**`):

`- **Mirror-verbatim vs negative-grep cross-test.** When an AC combines a "verbatim copy from X" requirement (its clause must mirror source X byte-for-byte) with a negative-grep verify clause (a byte sequence must NOT appear), cross-test the two before approving the plan: confirm the verbatim form of X satisfies the negative grep. If X itself contains the byte sequence the negative grep prohibits, a true verbatim copy fails the AC's own verify — flag for clarification. Resolution is either (a) show the verbatim form passes the negative grep, or (b) scope "verbatim" to a load-bearing grep-safe sub-clause of X.`
`  - **Carve-out:** ACs carrying only one of the two clauses (a verbatim-copy requirement alone, or a negative grep alone, with no shared source text between them) are out of scope — the check fires only when both clauses reference overlapping source text. Canonical positive: E06.S2.AC1 — a "verbatim from build-side reference" mirror requirement paired with a negative grep against the substring pattern the build-side reference itself contained; a true verbatim copy failed the AC's own negative grep (resolved by scoping "verbatim" to the load-bearing parenthetical clause rather than the full sentence).`

Do not modify the existing checks or the `**Assumptions:**`/`**Overengineering:**` blocks. File must stay ≤300 lines (currently 121).
**Verify:**
```
cd "$(git rev-parse --show-toplevel)"
command grep -qF -e '- **Mirror-verbatim vs negative-grep cross-test.**' skills/review-plan/SKILL.md || { echo FAIL-not-added; exit 1; }
command grep -qF 'Canonical positive: E06.S2.AC1' skills/review-plan/SKILL.md || { echo FAIL-no-canonical-pos; exit 1; }
awk '/\*\*Completeness:\*\*/{a=1} /\*\*Assumptions:\*\*/{a=0} a && /Mirror-verbatim vs negative-grep cross-test/{f=1} END{exit !f}' skills/review-plan/SKILL.md || { echo FAIL-wrong-block; exit 1; }
command grep -qF '**AC executable-example verify command.**' skills/review-plan/SKILL.md || { echo FAIL-83-check-lost; exit 1; }
n=$(wc -l < skills/review-plan/SKILL.md); [ "$n" -le 300 ] || { echo "FAIL-cap $n"; exit 1; }
out=$(bash .claude/hooks/verify-all.sh 2>&1); [ -z "$out" ] || { echo "FAIL-verify-not-clean: $out"; exit 1; }
echo "T2 PASS ($n/300)"
```
**UI:** no

### T3: Extend the EXISTING known-pitfalls mirror-verbatim entry with the codified/enforced cross-ref (~2 min)
**Files:** .roughly/known-pitfalls.md
**Context:** A pitfall entry for this exact hazard **already exists** under `## Planning & Scoping` — the bullet beginning "**An AC that pairs a 'mirror the reference verbatim' requirement with a negative-presence grep can be internally self-contradictory.**" It fully documents the E06.S2.AC1 origin, resolution, and Pattern, but it does NOT point at any codified convention or enforcement (because none existed before T1/T2). Do **NOT** add a new/duplicate entry (anywhere, including `## Documentation Hygiene`).
**Action:** Append ONE sentence to the END of that existing bullet, wiring it to T1's convention and T2's enforcement (matching how #81's and #83's entries close). Do a single-line Edit: extend the bullet's final sentence.
**Details:** The existing bullet currently ends: `…The fix is to scope "verbatim" to the load-bearing substring, not the whole sentence, and reword the surrounding prose to clear the negative check.` Change ONLY that trailing period to append this sentence (one space after the period), producing:

`…and reword the surrounding prose to clear the negative check. Codified in \`CONTRIBUTING.md\` § "AC authoring conventions"; enforced at \`skills/review-plan/SKILL.md\` § "Completeness".`

Do not alter any other text in that bullet or any other entry. No new lines are added (the bullet is one physical line).
**Verify:**
```
cd "$(git rev-parse --show-toplevel)"
# exactly ONE mirror-verbatim self-contradiction bullet — no duplicate was introduced
c=$(command grep -cF 'can be internally self-contradictory' .roughly/known-pitfalls.md); [ "$c" -eq 1 ] || { echo "FAIL-not-single ($c)"; exit 1; }
# the cross-ref sentence was appended
command grep -qF 'enforced at `skills/review-plan/SKILL.md` § "Completeness"' .roughly/known-pitfalls.md || { echo FAIL-no-crossref; exit 1; }
# the cross-ref lives inside the existing Planning & Scoping bullet (same section as the self-contradiction text)
awk '/^## Planning & Scoping/{a=1} /^## Review-Plan Fixture Design/{a=0} a && /internally self-contradictory/ && /enforced at `skills\/review-plan\/SKILL.md`/{f=1} END{exit !f}' .roughly/known-pitfalls.md || { echo FAIL-wrong-section-or-not-same-bullet; exit 1; }
# the original origin story is intact
command grep -qF 'E06.S2 AC1 required the fix-side' .roughly/known-pitfalls.md || { echo FAIL-origin-lost; exit 1; }
n=$(wc -l < .roughly/known-pitfalls.md); [ "$n" -le 300 ] || { echo "FAIL-over-threshold $n"; exit 1; }
out=$(bash .claude/hooks/verify-all.sh 2>&1); [ -z "$out" ] || { echo "FAIL-verify-not-clean: $out"; exit 1; }
echo "T3 PASS ($n lines)"
```
**UI:** no

## Blast Radius
- **Do NOT modify:** the existing quoted-wording / executable-example conventions in `## AC authoring conventions`; the existing review-plan checks (esp. `Self-defeating verify pattern` — #84 is adjacent-but-distinct, do NOT merge into it); any known-pitfalls entry OTHER than the single trailing-sentence extension in T3 (in particular do NOT add a second mirror-verbatim entry — one already exists under `## Planning & Scoping`); any code/agent/other file; the E06 epic (historical source).
- **Watch for:** (a) cross-refs cite `§ "section name"` / markdown link, never line numbers; (b) T1/T2 insert at each section END (before the next heading/`**Assumptions:**`); T3 extends the last sentence of an existing bullet in place (adds no new line); (c) review-plan ≤300 (121→~123); known-pitfalls unchanged line count (196, T3 grows one existing line); (d) the new prose describes "verbatim" + "negative grep" — do NOT let the plan's own Verify greps become self-defeating (all Verify greps here are POSITIVE-presence checks for stable literals being added, no negative grep against the new text); (e) shimmed grep — use `command grep`.

## Conventions
- No build/test harness — inline `command grep`/`awk`/verify-all-clean Verify blocks are the validation.
- T1/T2/T3 touch 3 distinct files → parallelizable; T1/T2 append to a section end, T3 extends one existing sentence in place.
