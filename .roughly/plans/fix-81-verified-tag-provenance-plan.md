# Fix Plan: #81 — codify "verified"-tag provenance discipline

Plan-format-version: 1

## Root Cause

No convention in `CONTRIBUTING.md` distinguishes **observed-facts** (what was actually witnessed) from **inferred-mechanisms** (what is suspected from an outcome), so an audit can tag an inference as "verified DATE" and that false claim propagates unquestioned through downstream hops (audit → PM codification → build → normative doc), because each review hop validates cross-references and intent rather than the underlying observation. Concrete instance: an E05 audit (2026-05-31) inferred a `gh pr edit --body-file` silent-no-op from the sole observation that PR #54's body lacked its audit table, tagged it "verified 2026-05-31," which was codified in E06.S7's AC1 and shipped into `CONTRIBUTING.md` before external review caught it (E06.S7 "Second post-merge correction," 2026-06-09). This is a documentation-convention codification, not a code bug — purely additive, two single-paragraph insertions.

## Scope / decisions
- Two files only: `CONTRIBUTING.md` (`## Audit conventions`) + `.roughly/known-pitfalls.md` (`## Documentation Hygiene`). No code/skill/agent changes.
- The exact CONTRIBUTING wording is pre-drafted at `docs/planning/epics/complete/E06-anchoring-closure-and-ci-coverage.md:577` (this ticket promotes it). Cite the **E06.S7 "Second post-merge correction (2026-06-09)"** as the precipitating evidence — NOT "E05 audit rec #4" (that rec is about the audit-table-in-PR-body convention, a different rule; the provenance defect is the downstream consequence).
- House style (verified in investigation): `## Audit conventions` = plain rule paragraph + a bold-labelled incident paragraph; no `###` subheadings. New CONTRIBUTING content = one bold-lead-in paragraph appended to the section. known-pitfalls `## Documentation Hygiene` entries = `- **bold lead-in.** body + concrete origin + **Pattern:** sentence`.
- Cross-reference the two additions to EACH OTHER **by section name, not line number** (the entry sitting directly above the insertion point is literally the "line-number citations rot silently" pitfall — obey it).

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| CONTRIBUTING.md | Modify (append 1 paragraph to `## Audit conventions`) | T1 |
| .roughly/known-pitfalls.md | Modify (append 1 entry to `## Documentation Hygiene`) | T2 |

## Baseline facts (captured 2026-07-27, branch `fix/81-86-contributing-convention-bundle`, at parity `main`)
- `CONTRIBUTING.md` `## Audit conventions` at L95: body = L97 main-rule paragraph, L99 `**Pitfall:**` paragraph, L100 blank, `## Tooling Pitfalls` at L101. Insert the new paragraph as a new L100 (after the L99 `**Pitfall:**` paragraph, before the existing blank), so a blank line separates it from `## Tooling Pitfalls`. CONTRIBUTING has no line-cap.
- `.roughly/known-pitfalls.md` `## Documentation Hygiene` at L110: last entry ends L122 ("Doc claims that cite specific line numbers… rot silently"), L123 blank, `## Planning & Scoping` at L124. Append the new bullet after L122, before the L123 blank. File is 192 lines; threshold 300 (108 headroom) — verify-all stays clean.
- No grep/rg shims found, but use `command grep` defensively (session convention).

## Tasks

### T1: Add the "verified"-tag provenance convention to CONTRIBUTING.md (~4 min)
**Files:** CONTRIBUTING.md
**Action:** Append one bold-lead-in paragraph to the end of the `## Audit conventions` section (after the existing `**Pitfall:**` paragraph, before the blank line preceding `## Tooling Pitfalls`).
**Details:** Insert this exact paragraph as a new paragraph immediately after the line that ends `…An E05 audit (2026-05-31) found PR #54's body missing its audit table.` (the `**Pitfall:**` paragraph), keeping one blank line before it and one blank line after it (before `## Tooling Pitfalls`):

`**"Verified DATE" provenance.** When marking a claim "verified DATE," cite the actual observation that supports it — the command that was run, the output captured, the behavior witnessed. Distinguish **observed-facts** (what was seen) from **inferred-mechanisms** (what is suspected): "verified DATE" applies only to observed-facts; an inferred mechanism must be marked \`inferred from <observation>\` or "hypothesized," never "verified." Tagging an inference as verified launders a hypothesis into a fact that then travels unquestioned across downstream hops — an unverified \`gh pr edit --body-file\` silent-no-op inference tagged "verified 2026-05-31" in an E05 audit propagated through E06.S7's AC1 into this file before external review caught it (E06.S7 "Second post-merge correction," 2026-06-09). See \`.roughly/known-pitfalls.md\` § "Documentation Hygiene" for the propagation-pattern lesson.`

Do not modify the existing two paragraphs, the section heading, or `## Tooling Pitfalls`.
**Verify:**
```
cd "$(git rev-parse --show-toplevel)"
command grep -qF '**"Verified DATE" provenance.**' CONTRIBUTING.md || { echo FAIL-not-added; exit 1; }
command grep -qF 'observed-facts' CONTRIBUTING.md || { echo FAIL-no-distinction; exit 1; }
command grep -qF 'inferred from <observation>' CONTRIBUTING.md || { echo FAIL-no-inferred-marker; exit 1; }
# it must sit inside ## Audit conventions, before ## Tooling Pitfalls:
awk '/^## Audit conventions/{a=1} /^## Tooling Pitfalls/{a=0} a && /Verified DATE. provenance/{found=1} END{exit !found}' CONTRIBUTING.md || { echo FAIL-wrong-section; exit 1; }
# existing Audit-conventions content preserved:
command grep -qF "PR #54's body missing its audit table" CONTRIBUTING.md || { echo FAIL-existing-lost; exit 1; }
echo "T1 PASS"
```
**UI:** no

### T2: Add the companion propagation-pattern entry to known-pitfalls (~4 min)
**Files:** .roughly/known-pitfalls.md
**Action:** Append one bullet entry to the end of the `## Documentation Hygiene` section (after the "Doc claims that cite specific line numbers… rot silently" entry, before the blank line preceding `## Planning & Scoping`).
**Details:** Insert this exact bullet as a new entry immediately after the line that ends `…add a self-test that runs the cited grep and asserts the count.` (the last Documentation-Hygiene entry), keeping one blank line before it and one blank line after it (before `## Planning & Scoping`):

`- **A "verified" tag on an inferred mechanism propagates a false claim across every downstream consumer.** An audit that infers a mechanism from an outcome and tags it "verified DATE" — without running the command or witnessing the behavior — launders a hypothesis into a fact. The tag then travels unquestioned (audit → PM codification → build → normative doc) because each hop validates *cross-references and intent*, not the underlying observation. Concrete origin: an E05 audit (2026-05-31) inferred that \`gh pr edit --body-file\` silently no-ops from the sole observation that PR #54's body lacked its audit table; the inference was tagged "verified 2026-05-31," codified in E06.S7's AC1, and shipped into \`CONTRIBUTING.md\` before external review caught it 5 hops later (E06.S7 "Second post-merge correction," 2026-06-09). **Pattern:** when tagging "verified DATE," cite the observation (command + output + witnessed behavior); mark anything inferred as \`inferred from <observation>\` or "hypothesized." Have reviewers validate a claim's *provenance*, not just its plausibility — that is the catch that closes the loop. Codified in \`CONTRIBUTING.md\` § "Audit conventions".`

Do not modify any other entry, the section heading, or `## Planning & Scoping`.
**Verify:**
```
cd "$(git rev-parse --show-toplevel)"
command grep -qF 'A "verified" tag on an inferred mechanism propagates a false claim' .roughly/known-pitfalls.md || { echo FAIL-not-added; exit 1; }
# must sit inside ## Documentation Hygiene, before ## Planning & Scoping:
awk '/^## Documentation Hygiene/{a=1} /^## Planning & Scoping/{a=0} a && /verified. tag on an inferred mechanism/{found=1} END{exit !found}' .roughly/known-pitfalls.md || { echo FAIL-wrong-section; exit 1; }
# existing last entry preserved:
command grep -qF 'cite specific line numbers in cross-referenced files rot silently' .roughly/known-pitfalls.md || { echo FAIL-existing-lost; exit 1; }
n=$(wc -l < .roughly/known-pitfalls.md); [ "$n" -le 300 ] || { echo "FAIL-over-threshold $n"; exit 1; }
out=$(bash .claude/hooks/verify-all.sh 2>&1); [ -z "$out" ] || { echo "FAIL-verify-not-clean: $out"; exit 1; }
echo "T2 PASS ($n lines)"
```
**UI:** no

## Blast Radius
- **Do NOT modify:** the existing `## Audit conventions` two paragraphs or `## AC authoring conventions`; any other known-pitfalls entry (esp. the "line-number citations rot" entry directly above the insertion — and honor it: the two new cross-refs use section NAMES, not line numbers); any code/skill/agent file; the E06 epic (historical — it's the source, not a target).
- **Watch for:** (a) the two cross-references must cite each other by `§ "section name"`, never line number; (b) insert at the section END (before the next `##`), not mid-section; (c) CONTRIBUTING has no line cap; known-pitfalls must stay < 300 (192→~194, fine).

## Conventions
- No build/test harness — inline `command grep`/`awk`/`bash -n` + verify-all-clean Verify blocks are the validation.
- Bundle note: #82–#87 append to the same two files' section ends on this same branch; sequential — no conflict with this insertion.
