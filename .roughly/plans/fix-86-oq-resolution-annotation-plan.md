> **Status:** Historical — implemented and merged in commit 9d98d46 on 2026-07-29. This plan was an active build/fix artifact; treat as historical reference only.

# Fix Plan: #86 — codify OQ-resolution-annotation-in-epic convention

Plan-format-version: 1

## Root Cause

When a story build resolves an epic Open Question (OQ), the epic file's OQ section is the canonical record of what was decided and why — but the discipline of annotating that section (strikethrough + bold resolution line) in the same commit that ships the resolution was captured only as a `.roughly/known-pitfalls.md` entry at E06.S7 ship, never written into normative contributor docs (`CONTRIBUTING.md`). E06.S7 itself shipped a CHANGELOG claiming an OQ was resolved while the epic OQ line carried no annotation (Stage 6 flagged it Critical). Without codification, future contributors re-discover the gap. Docs-convention codification, not a code bug.

## Scope (2 tasks — enforcement verdict: CONTRIBUTING-only + extend the EXISTING known-pitfalls entry; NO review-plan check)
- **T1:** `CONTRIBUTING.md` — create a **new top-level `## Epic Open Question resolution` section**, inserted **between `## Cross-epic AC amendments` and `## Audit conventions`**. Investigator verdict: neither `## Skill authoring conventions` nor `## AC authoring conventions` fits (this governs epic-file OQ bookkeeping at ship time, not skill-body or AC-text authoring); the cluster's established growth pattern is a new top-level section in this slot (direct precedent: OQ-S7 added `## Audit conventions` here the same way). House style: descriptive opener + `Canonical first instance:` closer citing E06.S7; **no** "Enforcement is at plan-review time…" closer (there is no automated hook — review-plan runs pre-implementation against plan files and cannot see a ship-time epic edit).
- **T2:** `.roughly/known-pitfalls.md` — the OQ pitfall **already exists** under `## Planning & Scoping` ("Resolving an epic Open Question at ship time requires annotating the OQ in the epic file…"). Do **NOT** duplicate. Extend its final sentence with a `Codified in \`CONTRIBUTING.md\` § "Epic Open Question resolution".` cross-reference (no-enforcement variant, mirroring the #84 extend-pattern and the existing `§ "Audit conventions"` closers in the file).
- Cross-reference by **section name, not line number**. Use the verified house annotation format `~~<original question>~~ **Resolved at <story-id> ship (<YYYY-MM-DD>): <chosen option>** — <rationale>.` (OQ-S4 2026-06-05, OQ-S6 2026-06-08, OQ-S7 2026-06-09).

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| CONTRIBUTING.md | Modify (insert new `## Epic Open Question resolution` section) | T1 |
| .roughly/known-pitfalls.md | Modify (extend the EXISTING OQ entry with a cross-ref — NOT a new entry) | T2 |

## Baseline facts (captured 2026-07-28, branch `fix/81-86-contributing-convention-bundle`, 10 commits ahead of main = #81/#83/#84/#82/#85)
- `CONTRIBUTING.md`: `## Cross-epic AC amendments` section ends with the paragraph beginning "When an already-amended AC is itself re-amended…" whose final sentence is "…First multi-hop instance: E04.S8.AC5 (original) → E05.S2.AC4 (intermediate) → E06.S1 (latest amender)." → blank → `## Audit conventions`. No line cap.
- `.roughly/known-pitfalls.md` `## Planning & Scoping`: the OQ entry ("Resolving an epic Open Question at ship time requires annotating the OQ in the epic file — a CHANGELOG claim alone is not sufficient.") ends with the exact sentence "Precedent: OQ-S4 (resolved at E06.S4 ship) and OQ-S6 (resolved at E06.S6 ship) in the E06 epic." It has NO "Codified in…" cross-ref yet. The file already uses the no-enforcement closer form `Codified in \`CONTRIBUTING.md\` § "Audit conventions".` elsewhere (style reference). File 208 lines, well under the 300 organize-threshold.
- Verified OQ annotation format (E06 epic `## Open questions`): `~~<original question text>~~ **Resolved at <story-id> ship (<YYYY-MM-DD>): <chosen option>** — <one-line rationale>.`
- Origin (triangulated, verified): E06.S7 CHANGELOG claimed it "resolved OQ-S7-section-location toward the new-section option" while the epic OQ line carried no annotation; Stage 6 code-reviewer flagged it Critical; the OQ was then annotated to mirror OQ-S4/OQ-S6.
- No OQ / "Open Question" handling exists in any skill/agent (grepped review-plan, build, review-epic, audit-epic → zero) — confirming no enforcement surface. Session shims `grep` — use `command grep`.

## Tasks

### T1: Add the `## Epic Open Question resolution` section to CONTRIBUTING.md (~4 min)
**Files:** CONTRIBUTING.md
**Action:** Insert a NEW top-level `## Epic Open Question resolution` section (heading + one convention paragraph) between the END of `## Cross-epic AC amendments` and the `## Audit conventions` heading. Keep exactly one blank line before and after the new section.
**Details:** Do a single exact-string Edit anchored on the seam `E06.S1 (latest amender).\n\n## Audit conventions` — insert the new section between the "Recursive application…" paragraph's ending and `## Audit conventions`. The paragraph below is shown between triple-backtick fences for delimiting ONLY; the fences are NOT part of the inserted text. Insert this EXACT section (heading + paragraph):

```
## Epic Open Question resolution

When a story build resolves an epic Open Question (OQ) — one marked "Carried for implementer discretion" or otherwise left open — annotate the epic file's Open Questions entry in the **same commit** that ships the resolution-relevant change. The epic OQ section is the canonical record of what was decided and why; a CHANGELOG note alone is insufficient, and a CHANGELOG that asserts a resolution while the OQ line still shows the original open text creates an inaccurate cross-reference trail. Use the house annotation format — strikethrough the original question text and append a bold resolution line plus a one-line rationale: `~~<original question>~~ **Resolved at <story-id> ship (<YYYY-MM-DD>): <chosen option>** — <rationale>.` The CHANGELOG may then reference the resolution, but only once the epic annotation is in place. Canonical first instance: E06.S7 shipped a CHANGELOG claiming it "resolved OQ-S7-section-location toward the new-section option" while the epic's OQ line carried no annotation; Stage 6 code-reviewer flagged it Critical, and the OQ was annotated to mirror the OQ-S4 (2026-06-05) and OQ-S6 (2026-06-08) precedent. See `.roughly/known-pitfalls.md` § "Planning & Scoping".
```

Do not modify the `## Cross-epic AC amendments` or `## Audit conventions` sections or any other content. Do NOT add an "Enforcement is at plan-review time…" closer.
**Verify:**
```
cd "$(git rev-parse --show-toplevel)"
command grep -qxF '## Epic Open Question resolution' CONTRIBUTING.md || { echo FAIL-no-heading; exit 1; }
command grep -qF -e 'the canonical record of what was decided and why' CONTRIBUTING.md || { echo FAIL-no-rule; exit 1; }
# new section sits between Cross-epic AC amendments and Audit conventions
awk '/^## Cross-epic AC amendments$/{c=NR} /^## Epic Open Question resolution$/{e=NR} /^## Audit conventions$/{a=NR} END{exit !(c>0 && e>c && a>e)}' CONTRIBUTING.md || { echo FAIL-wrong-order; exit 1; }
# no stray leading backtick on the heading
command grep -qF -e '`## Epic Open Question resolution' CONTRIBUTING.md && { echo FAIL-stray-backtick; exit 1; }
# adjacent sections intact
command grep -qF -e '## Cross-epic AC amendments' CONTRIBUTING.md || { echo FAIL-crossepic-lost; exit 1; }
command grep -qF -e '## Audit conventions' CONTRIBUTING.md || { echo FAIL-audit-lost; exit 1; }
echo "T1 PASS"
```
**UI:** no

### T2: Extend the EXISTING known-pitfalls OQ entry with the codified cross-ref (~2 min)
**Files:** .roughly/known-pitfalls.md
**Context:** The OQ pitfall ALREADY EXISTS under `## Planning & Scoping` — the bullet beginning "**Resolving an epic Open Question at ship time requires annotating the OQ in the epic file — a CHANGELOG claim alone is not sufficient.**". It is a single physical line ending with the sentence "Precedent: OQ-S4 (resolved at E06.S4 ship) and OQ-S6 (resolved at E06.S6 ship) in the E06 epic." It has no codified cross-reference. Do NOT add a new/duplicate entry.
**Action:** Append ONE sentence to the END of that existing bullet, wiring it to T1's new section (matching the no-enforcement `Codified in …` form already used elsewhere in the file). Single-line Edit extending the bullet's final sentence.
**Details:** The existing bullet ends: `…Precedent: OQ-S4 (resolved at E06.S4 ship) and OQ-S6 (resolved at E06.S6 ship) in the E06 epic.` Change ONLY that trailing period to append this sentence (one space after the period), producing:

`…in the E06 epic. Codified in \`CONTRIBUTING.md\` § "Epic Open Question resolution".`

Do this as a single exact-string Edit anchored on the existing ending sentence. Because the bullet is one physical line, this adds NO new lines to the file. Do not alter any other text in that bullet or any other entry.
**Verify:**
```
cd "$(git rev-parse --show-toplevel)"
# exactly ONE OQ-resolution pitfall bullet — no duplicate was introduced
c=$(command grep -cF -e 'requires annotating the OQ in the epic file' .roughly/known-pitfalls.md); [ "$c" -eq 1 ] || { echo "FAIL-not-single ($c)"; exit 1; }
# the cross-ref sentence was appended
command grep -qF -e 'Codified in `CONTRIBUTING.md` § "Epic Open Question resolution"' .roughly/known-pitfalls.md || { echo FAIL-no-crossref; exit 1; }
# the cross-ref lives inside the existing Planning & Scoping OQ bullet (same line as the Precedent sentence)
awk '/^## Planning & Scoping/{a=1} /^## Review-Plan Fixture Design/{a=0} a && /requires annotating the OQ in the epic file/ && /Epic Open Question resolution/{f=1} END{exit !f}' .roughly/known-pitfalls.md || { echo FAIL-wrong-bullet; exit 1; }
n=$(wc -l < .roughly/known-pitfalls.md); [ "$n" -le 300 ] || { echo "FAIL-over-threshold $n"; exit 1; }
out=$(bash .claude/hooks/verify-all.sh 2>&1); [ -z "$out" ] || { echo "FAIL-verify-not-clean: $out"; exit 1; }
echo "T2 PASS ($n lines)"
```
**UI:** no

## Blast Radius
- **Do NOT modify:** the `## Cross-epic AC amendments` or `## Audit conventions` sections (T1 inserts between them, touching neither); any known-pitfalls entry OTHER than the single trailing-sentence extension in T2 (do NOT add a second OQ entry — one already exists); the E06 epic (historical source); `CHANGELOG.md` (bundle uses a single consolidated entry at PR time, consistent with #81–#85); any code/agent/other file.
- **Watch for:** (a) create the new `## Epic Open Question resolution` section — do NOT append to `## Skill authoring conventions` / `## AC authoring conventions`; (b) the convention paragraph must NOT carry an "Enforcement is at plan-review time…" closer (no hook exists); (c) T1 inserts the section as plain markdown (no wrapping backtick around the heading/paragraph); (d) cross-refs by section name, never line number; (e) T2 extends the existing bullet in place (adds no new line) — assert single-occurrence to prove no duplicate; (f) known-pitfalls stays under 300; (g) shimmed grep — use `command grep`; (h) all Verify greps here are POSITIVE-presence checks (plus explicit stray-backtick / single-occurrence guards) — none self-defeating.

## Conventions
- No build/test harness — inline `command grep`/`awk`/verify-all-clean Verify blocks are the validation.
- T1/T2 touch 2 distinct files → parallelizable; T1 inserts a section, T2 extends one existing sentence in place.
