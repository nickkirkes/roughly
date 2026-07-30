# E07 — Epic Review

**Reviewed:** 2026-07-30 · **Reviewer:** Roughly epic-reviewer · **Epic:** [E07-codification-closeout-and-release-gate-repair.md](E07-codification-closeout-and-release-gate-repair.md) · **Tree state:** branch `docs/v1.9.0-planning`, `main` tip `121ea6b`

## Verdict: **Needs Revision**

The epic's structure is sound — the release thesis is honest, the risk register is the best in the series, and the critical path (S1→S2→S7) is correctly identified. The problems are concentrated in the ACs, and they are the specific failure mode this epic exists to codify: **two verify commands do not work as written, one AC directs an edit whose premise is false, one AC's catalog contradicts the canonical catalog it claims to draw from and silently drops a documented shape, and one AC is already satisfied in the tree.** Separately, S2 has no defined outcome for the most likely real-world state (the API key is still unfunded), which puts the critical path on a branch the epic does not cover. All are fixable in a revision pass; none require rescoping.

---

## Claim verification

| Claim | Status | Actual |
|---|---|---|
| `skills/build/SKILL.md` 281/300 | VERIFIED | 281 |
| `skills/fix/SKILL.md` 286/300 | VERIFIED | 286 |
| `skills/help/SKILL.md` 161/300 | VERIFIED | 161 |
| `skills/setup/SKILL.md` 286/300 (Stub 1) | VERIFIED | 286 |
| `CONTRIBUTING.md` 231 lines | VERIFIED | 231 |
| `agents/doc-writer.md` 649/650 (L276) | **WRONG** | **647**/650. R5 states the correct figure (649→647); L276 repeats the stale one |
| `CHANGELOG.md:3` = `## [0.1.9] — 2026-07-27` | VERIFIED | exact |
| v0.1.9 CHANGELOG section contains only #80 | VERIFIED | single `### Removed` entry |
| `plugin.json` at 0.1.8 | VERIFIED | `"version": "0.1.8"` |
| ROADMAP L3 `**Current:** v0.1.8` | VERIFIED | `**Current:** v0.1.8 · **Updated:** 2026-06-10` |
| ROADMAP L19 release-map row | VERIFIED | exact text as quoted |
| ROADMAP v0.1.9 `**Status:** SCOPING (draft…)` | VERIFIED | at L141, verbatim |
| ROADMAP DoD list carries all 5 windows | VERIFIED | L199–203 |
| `CONTRIBUTING.md` L87 / L99 section anchors | VERIFIED | `## Cross-epic AC amendments` L87, `## Epic Open Question resolution` L99 |
| ci-dogfood smoke ladder at L77–86 | VERIFIED | exact — both exit branches |
| plugin-load probe at L105–131 | VERIFIED | `PLUGIN_OUT` L105, assertion ladder ends L131 |
| Cost arithmetic $0.05 + $1.00 + 6×$1.50 = $10.05 | VERIFIED | budgets at L75, L106, and 6× at L146/281/382/438/507/590 |
| `grep -c 'max-budget-usd 1.50'` = 6 (S1.AC5) | VERIFIED | returns 6 |
| `6405652` repaired probe + removed `push:` | VERIFIED | `chore/66 harden pipeline gates (#69)`; `dogfood.yml` triggers are now `pull_request: [labeled, synchronize, reopened]` + `workflow_dispatch` only |
| `workflow_dispatch` is the only path to a `main` run | VERIFIED | label path is PR-ref only |
| `grep 'slated for unification review' skills/fix/SKILL.md` matches | VERIFIED | L119 |
| Build `--ci` recovery loop = 2 verdicts + structured marker | VERIFIED | build L104 |
| Stage 4 verdict displayed + context-preserved, persisted nowhere | VERIFIED | build L118 "Preserve: … PASS verdict"; no file write in either pipeline |
| Stage 1 silently accepts epic-shaped input | VERIFIED | build L29, fix L36 — resolve-and-proceed, no classification |
| S4.AC4 grep matches in `spec-candidate-escalation.md` | **WRONG** | Matches `build:211` and `fix:218`, **not** the shared reference. The shared file has "**T**he appended entry is the evidence" — case-sensitive grep misses it. See Blocker 1 |
| E06 deviation notes at L90 and L314 | VERIFIED | both exist at the cited lines |
| E06 W1/W2 cite build L205 / fix L208 | VERIFIED | E06 L555, L557 |
| "E06 self-identifies four distinct shapes across five instances" | **WRONG** | E06 L601 states **"nine instances … six distinct shapes"**, enumerated as Shapes 1–6 at L601–606. ROADMAP L124 confirms. See Major 1 |
| README:52 Quick Start pipes a **multi-story** epic file | **WRONG** | The heredoc contains **one** story (`## Story 1: GET /health`). See Major 2 |
| README `### Epic files` L182–201 shows a two-story example | VERIFIED | heading L180, two-story example, names `/roughly:build` as a consumer |
| Runbook `## When to run it` lacks the dispatch/`main` distinction | PARTIAL | Section already documents both triggers incl. `workflow_dispatch`; the **`main`-vs-PR-ref** distinction is genuinely absent. See Major 3 |
| Runbook `## Cost` lacks the derived ceiling | **WRONG** | `## Cost` already carries the per-step table ($0.05 / $1.00 / 6×$1.50). Only the $10.05 total row is missing. See Major 3 |
| Next free ADR is ≥021 (ADR-010, 016–018, 020 reserved) | VERIFIED | ADR-020 is the differential-gate Spec 2 renumber (`docs/planning/differential-gate-allocation-specs.md:45`, `ADR-019:19`). Note `CLAUDE.md:18` omits ADR-020 from its reserved list — see Minor 3 |
| `CONTRIBUTING.md` `## CI conventions` behavioral-assertion rule (S1.AC2) | VERIFIED | L170 |
| Dogfood history "6 successes / 138 failures" | UNVERIFIABLE | GH API not reachable from this session; workflow-file state is consistent with the narrative |

---

## Findings

### 1. Technical accuracy

**Blocker 1 — S4.AC4's verify command fails against a correct implementation.** The AC specifies `grep -n 'the appended entry is the evidence' skills/build/SKILL.md skills/shared/spec-candidate-escalation.md` "returns matches in both." It does not. The shared reference's sentence begins the clause (`The appended entry is the evidence that the finding was recorded.`), so the lowercase-`the` pattern misses it; the two matches that *do* exist are `skills/build/SKILL.md:211` and `skills/fix/SKILL.md:218`. Worse, the build match is inside the **cubic-termination** paragraph, which carried evidence-artifact language *before* #72 — so even a passing grep would not evidence W2's closure. **Revision:** replace with two commands that verify the actual claim —

```sh
grep -c 'appended entry is the evidence' skills/shared/spec-candidate-escalation.md   # = 1
grep -c 'SPEC-REVISION-CANDIDATE ESCALATION' skills/build/SKILL.md skills/fix/SKILL.md # >= 2 each
```

The second is what actually demonstrates W1/W2's resolution mechanism: both Stage 6 paragraphs route to one named procedure that carries the evidence contract.

**Blocker 2 — S2 has no defined outcome for "cannot dispatch."** AC1's dispositions are CLOSE (3 consecutive green) or CARRY (count reached + failing scenario + diagnosis). Neither covers the state the tree is actually in: the last executed run died on `Credit balance is too low`, and nothing in the epic establishes the key has been refunded. S1.AC2 has the same unstated precondition — it requires two live `claude` sessions against a funded key. As written, S1 and S2 both stall with no specified outcome, on the critical path. **Revision:** add a precondition line to S2 ("Confirm `ANTHROPIC_API_KEY` is funded before dispatch; if not, S2 halts at this line") and a third AC1 disposition: **BLOCKED-NO-EVIDENCE → CARRY**, recorded identically to a CARRY across AC5's three surfaces, with the v0.1.10 stub naming key funding as the gating action. This is the difference between an honest CARRY and a story that hangs.

**Major 1 — S4.AC2 contradicts E06's canonical catalog and drops a documented shape.** AC2 asserts "E06 self-identifies four distinct shapes across five instances; the two remaining come from E06.S3." E06 L601 states the opposite explicitly: *"nine instances across all seven shipped stories, six distinct shapes"*, enumerated as Shapes 1–6 at L601–606; ROADMAP L124 repeats it. The epic's derived six then **omits Shape 5 entirely** (E06.S7.AC1 — factually-wrong example / inherited false claim, the only shape covering executable defects in normative AC content) while splitting Shape 4's `E06.S3.AC2` sub-variant into a standalone shape and reducing Shape 6 to its `S3.AC1` half (dropping `S3.AC4`). An implementer following AC2 ships a catalog that is neither E06's nor complete. **Revision:** rewrite AC2 to adopt E06 L601–606's Shapes 1–6 verbatim, preserving E06's numbering and its nine cited instances, and add a verify step asserting each of the six catalog entries cites a location resolvable in the E06 epic file. Drop the "four shapes across five instances" premise sentence.

**Major 2 — S6.AC4 directs a no-op edit on a false premise (and R2 inherits it).** AC4 says "Rewrite the Quick Start example to a single story." [README.md:41-50](../../../README.md) already contains exactly one story — the heredoc emits `# Add Health Endpoint` + `## Story 1: GET /health` and nothing else. R2's framing ("Quick Start pipes a multi-story epic file into `/roughly:build`") is wrong, and the AC1 detector as specified (two or more story-form headings) would **not** fire on it. The genuine collision is the `### Epic files` section alone ([README.md:180-201](../../../README.md)), whose two-story example is documented as a `/roughly:build` input. **Revision:** strike the Quick Start clause from AC4 and correct R2 to name only the `### Epic files` section. Then fix AC4's verify step — "no example under a `/roughly:build` invocation in `README.md` contains two or more story headings" does not describe the actual location (the two-story block sits under a prose section that *names* `/roughly:build`, not under an invocation). Replace with a concrete assertion, e.g. *the `### Epic files` example contains exactly one `## Story` heading, and the section states `/roughly:build` takes one story while `/roughly:review-epic` and `/roughly:audit-epic` take the whole epic.*

**Major 3 — S1.AC3 is ~70% already done; as written it directs rewriting correct content.** [docs/runbooks/dogfood-ci.md:7-17](../../runbooks/dogfood-ci.md) already documents both trigger paths including `workflow_dispatch`, and `## Cost` (L18-28) already carries the per-step budget table ($0.05 / $1.00 / 6×$1.50), derived from the script — not a remembered figure. The two real gaps are narrow: (a) the runbook never says the `ci:dogfood` label path produces **PR-ref runs only**, so `workflow_dispatch` is the sole route to a `main` run — the fact the whole risk track depends on; (b) the table has no total row, so the $10.05 ceiling is left as arithmetic. **Revision:** narrow AC3 to those two additions and delete the "rather than a remembered figure" clause, which mischaracterizes the current text.

**Minor 1 — stale count at epic L276.** The v0.1.10 candidate for `agents/doc-writer.md` says "(649/650)"; actual is 647/650, which R5 itself states correctly. Trivially fixed, but it is the same citation-rot class E06 catalogued as a standing candidate.

**Minor 2 — S1 verification cost is understated.** "two short `claude` sessions (~$1)" — AC2 requires the plugin-load probe (budgeted $1.00 alone) *plus* a negative-control run of the same probe, so the floor is ~$2 before the smoke session. Not material to the release, but S1 is the story that exists to make cost legible.

### 2. Best practices

**Major 4 — S6.AC2 as worded pushes toward the enumerated-list anti-pattern.** AC2 requires the new prose to "carry that constraint explicitly at the point of the new prompt, not rely on the pipeline-level gate-protocol reference alone." Both SKILL.md files already carry a closed-world prohibition at L11, and `skills/shared/gate-protocol.md` Rule 1 states the canonical closed-world test. `CLAUDE.md` is explicit that the prohibition "must stay closed-world … not an enumerated list" — an inline restatement at a new gate is precisely where a contributor re-enumerates tool names and narrows it. **Revision:** require the new prose to state the closed-world *test* and cite `skills/shared/gate-protocol.md` Rule 1 by name, explicitly forbidding a fresh enumeration of tool names.

**Major 5 — S6's Verification step and S6.AC2 are mutually unsatisfiable as written.** Verification asserts `grep -c 'AskUserQuestion' skills/build/SKILL.md skills/fix/SKILL.md` "unchanged from baseline"; baseline is **1 and 1** (both at L11), a value the epic never records. If AC2's "explicitly at the point of the new prompt" prose names the tool, the count goes to 2 and Verification fails; if it does not name it, AC2's "explicitly" is arguable. **Revision:** record the baseline (1/1) in the AC, and — paired with Major 4 — assert the count stays at exactly 1 in each file, which makes the grep a real guard on the enumeration anti-pattern rather than a tautology.

**Major 6 — S6.AC1's placement can hang `--ci` in the fix pipeline.** AC1 says to classify "after resolving the input." In [skills/build/SKILL.md:29](../../../skills/build/SKILL.md) file resolution and `--ci` detection are the same sentence, so `CI_MODE` is set before any gate. In [skills/fix/SKILL.md:36-38](../../../skills/fix/SKILL.md) they are **separate paragraphs**: resolution at L36, `CI_MODE` assignment at L38. A gate inserted "after resolving the input" in fix lands before `CI_MODE` exists and will block a CI run — the exact hang AC3 claims to rule out. AC3's assurance ("verify the new gate is covered by the existing `--ci` auto-proceed rule") does not survive this ordering. **Revision:** state the insertion point positionally — *after the `CI_MODE` assignment and before the existing `Ask:` gate, in both files* — and add to AC3's verify: in `skills/fix/SKILL.md`, the new classification prose appears at a line number greater than the `CI_MODE=true` assignment.

**Minor 3 — while editing the `CLAUDE.md` ADR table (S6.AC6), fix its reserved list.** [CLAUDE.md:18](../../../CLAUDE.md) reserves ADR-010 and ADR-016–018 but omits **ADR-020**, which is reserved for the differential-gate Spec 2 renumber (`docs/planning/differential-gate-allocation-specs.md:45`; `ADR-019:19`). The epic's "≥021" is correct *because* of that reservation, but a contributor reading only `CLAUDE.md` would claim 020. One-line addition to the row S6.AC6 already opens.

**Minor 4 — S6.AC1/AC2 do not say whether the new gate takes the Rule 3 header block.** `gate-protocol.md` Rule 3 mandates a `Stage [N] of [M]` header block at numbered stage gates and exempts a closed list of sub-gates (override, discard, maturity offers, abort menus) that a new intake-granularity prompt does not join. A second gate inside Stage 1 is genuinely ambiguous under that rule. **Revision:** decide it in the AC — recommend treating it as a sub-gate (Rules 1/2/4, no header block), since two `Stage 1 of 8` blocks in one stage is noise, and add the case to Rule 3's exemption list in the same story.

### 3. Risks

**Major 7 — the budget figures disagree across the epic.** The header says "3 paid dogfood dispatches (~$30 ceiling)"; S2's Verification says "1 discovery dispatch + up to 3 proving dispatches (~$40 ceiling)". At the verified $10.05/run ceiling, S2's figure is right (~$40.20) and the header understates by a full dispatch. R1 also says "each defect it surfaces costs another ~$10 dispatch to re-test," which is uncapped — if the discovery run surfaces two defects in sequence, the true ceiling is ~$60. **Revision:** correct the header to 4 dispatches / ~$40, and give S2 an explicit spend cap with CARRY as the defined outcome on reaching it (e.g. "6 dispatches / ~$60, then CARRY regardless of count reached"). Without a cap, R1's mitigation ("CARRIES rather than burning the release window") has no trigger.

**Major 8 — no story owns CHANGELOG heading contention.** Seven ACs write `CHANGELOG.md` (S1.AC6, S2.AC5, S3, S4.AC6, S5, S6, S7.AC4). S3.AC1 reverts the heading `## [0.1.9] — 2026-07-27` → `## [Unreleased] — v0.1.9`, but S3 is declared to gate nothing and is sequenced "first in Track B" only. If S1 or S5 merges first, its entry lands under a heading that is about to be rewritten, and the two changes touch adjacent lines. **Revision:** make S3 a hard predecessor of every other CHANGELOG-writing story (it is one file, one hour, and it is already front-loaded), or state that entries land under whatever heading is current and S3 normalizes — but pick one. The sequencing diagram should show S3 preceding S1, not sitting parallel to it.

**Minor 5 — S2 and S4 both write to the E06 epic file.** S2.AC5 annotates E06's risk register; S4.AC3/AC4/AC5 annotate E06's deviation notes and `## v0.1.9 candidates` block. Both are declared parallel. Different sections, so not a correctness problem — but flag the rebase in the sequencing note.

**Info — the spec-candidate escalation target resolves correctly for this epic.** E07 is the only root-level epic (`complete/` holds the rest), so per `CLAUDE.md` any Stage 6 spec-revision candidate surfacing during an E07 build appends to E07's candidates section. Epic L260 states exactly this. No action.

### 4. Overengineering

**Minor 6 — S2.AC5's three-surface recording is proportionate; S2.AC6 is redundant with it.** Recording five dispositions across CHANGELOG + ROADMAP DoD + originating epic is justified — the DoD boxes at [ROADMAP.md:199-203](../../ROADMAP.md) are the standing record and the epic risk registers are where the next PM looks. But AC6 ("every CARRY produces a v0.1.10 stub") is a fourth surface stated as a separate AC when it is one clause of AC5's consistency requirement. Fold it into AC5 as a fourth bullet; five windows × four surfaces is easier to verify as one checklist than as two ACs.

**Info — S5's bundling rationale holds.** Both changes edit the same Stage 4 section in the same two files under 14 lines of headroom; splitting them means two cap negotiations over the same lines. Correct call.

**Info — S4's shape catalog is not overengineered** once Major 1 is applied — it is transcription of an existing E06 artifact, not new taxonomy work. The overengineering risk is precisely in *re-deriving* it, which is what the current AC2 does.

### 5. Acceptance criteria quality

**Major 9 — S2.AC1's discovery scope is unbounded and the precedent cited does not bound it either.** "Whatever the 6 scenarios surface after seven weeks dark is in scope for this story to fix" invokes the E06.S3 precedent, but E06.S3's bundling rule applied to *fixture-authoring* discoveries in a story whose job was authoring fixtures. Here it authorizes unbounded pipeline repair inside a close-out release, in the story that is already the long pole. **Revision:** bound it by kind — harness/script/fixture defects are in scope; a defect in `skills/build/SKILL.md` or `skills/fix/SKILL.md` behavior is a CARRY with a v0.1.10 stub unless the human explicitly rescopes. That keeps R1's "discovery run" honest without letting the release absorb a pipeline regression at tag time.

**Minor 7 — three ACs verify by assertion rather than command.** S2.AC2 and AC3 ("Cite the evidence examined, not a recollection") specify the *standard* but no procedure: there is no stated way to enumerate stop-hook or Check 8 false positives across the #66–#91 bundle. **Revision:** name the mechanism — e.g. `git log --oneline 6405652..121ea6b` for the change set plus the specific `.claude/hooks/verify-all.sh` check output to inspect — or downgrade both to "record the method used and its result," which is at least reproducible.

**Minor 8 — S5.AC1's parity verify has no defined subject.** "`diff` of the two added blocks is empty" — nothing specifies how the two blocks are delimited for extraction. E06.S5 established byte-identical parity by quoting the shipped prose; do the same here, or specify extraction anchors (e.g. the `## Review-plan verdict` directive sentence through the end of the paragraph) so the check is runnable.

**Minor 9 — two ACs depend on a human decision not yet made.** S7.AC2 carries OQ7's theme wording, and S6.AC1's "epic-shaped" threshold is explicitly deferred to implementer discretion (OQ8). OQ8's deferral is well-formed — it names the corpus and the annotation convention. OQ7 is not: S7.AC2 cannot execute until the wording is fixed. See Open Questions below.

### 6. Dependencies

**Major 10 — S7.AC6 makes the tag depend on S2 completing, which the epic elsewhere downplays.** The sequencing note says Track B and C "gate nothing" and R1's mitigation frames CARRY as protecting the release window — but S7.AC6 requires all five dispositions *recorded*, and four of the five are S2 outputs, two of which (E05 Risk 1, E04 Risk 5) are downstream of AC1's dispatch outcome per AC4. So the tag is gated on S2 reaching a disposition, which is gated on either a funded key or Blocker 2's BLOCKED-NO-EVIDENCE branch. The epic states the critical path correctly (S1→S2→S7); it just does not connect that to the funding precondition. Resolving Blocker 2 resolves this — with the third disposition, S2 can always reach a recorded outcome and S7 is never hard-blocked.

**Minor 10 — S1 and S2 both write `docs/runbooks/dogfood-ci.md`.** S1.AC3/AC4 add two sections; S2 records the Risk 3 count into the section S1.AC4 creates. Correctly ordered (S2 depends on S1), just worth noting the file is sequential, not parallel.

**Info — S5-before-S6 line-budget ordering is correct and sufficient.** Verified headroom: build 281/300 (19 lines), fix 286/300 (14 lines). S5's ADR-012 off-ramp being pre-authorized in-AC is the right pattern and removes the mid-build decision.

---

## Open questions — RESOLVED 2026-07-30

All five were answered by the maintainer in the review session. Recorded here as the source for the epic revision pass.

1. **OQ7 theme wording — CONFIRMED as recommended.** Adopt `E06 codification close-out + release-gate repair + epic-vs-story intake guard + obsolete-\`ruckus\`-checks removal`. The epic's originally proposed row dropped `obsolete-\`ruckus\`-checks removal`, which **did** ship (#80, PR #88) and is the only user-visible removal in the release. S7.AC2 carries the edit.

2. **`ANTHROPIC_API_KEY` is funded.** Confirmed 2026-07-30. S1.AC2 and S2's dispatches can execute. Blocker 2's BLOCKED-NO-EVIDENCE disposition is retained as a **contingency** (a key can deplete mid-story — the 2026-07-18 failure is the precedent), not as the expected path.

3. **S2 spend cap — 6 dispatches / ~$60, agreed.** Hard ceiling; on reaching it, CARRY regardless of green count. The epic header's "3 paid dispatches (~$30)" is corrected to match (Major 7).

4. **OQ3 — keep the ADR-013 amendment.** No discrete ADR. E07.S5.AC4 adds the dated `## Amendment (v0.1.9)` section.

5. **S2.AC1 discovery scope — pipeline-behavior defects are to be addressed, bounded by the Class A/B/C rule below.**

---

## Discovery-scope boundary (resolves Major 9)

Sizing was done against the actual regression surface rather than the epic's "seven weeks dark" framing. Two findings reframe R1:

**The scenario contracts did not drift.** All five marker strings the harness asserts — `[--ci] plan review verdict: PASS`, `… NEEDS REVISION`, and `cannot proceed: auto-fix cap reached on` ([scripts/ci-dogfood.sh:164,398,457,542,550,623,631](../../../scripts/ci-dogfood.sh)) — are byte-unchanged since the last green base `94ba772`. `git diff 94ba772 main -- skills/build/SKILL.md | grep -c 'auto-fix cap reached'` returns **0**: #73's reframing changed narrative wording ("exit non-zero" → "halt — that marker is the CI signal"), not the asserted marker text.

**The live surface is concentrated and identified.** 31 changed lines per pipeline file since `94ba772`, of which the behaviorally-new part is `${CLAUDE_PLUGIN_ROOT}` runtime-`Read` directives going **1 → 4** in each file (gate-protocol, stage-8-wrap-up, spec-candidate-escalation added alongside abort-handling). That is what has never executed in CI.

| Class | What | Likelihood | Fix cost | Disposition |
|---|---|---|---|---|
| **A** | `${CLAUDE_PLUGIN_ROOT}` / shared-reference path resolution under `--bare --plugin-dir`. Fails every scenario at the first gate. Mechanical fix across 4 directives × 2 files. `6eaa04a` (#67) already performed this repair once — never CI-validated. | High | ~0.5 day + 1 dispatch | **IN SCOPE for S2** |
| **B** | Gate-protocol prose behavior under `CI_MODE`. Rule 4 already specifies "render no header block and ask nothing," so the contract exists; risk is gate *sequencing* drift from the extraction. Prose repair in one shared file. | Medium | ~0.5–1 day + 1 dispatch | **IN SCOPE for S2** |
| **C** | Genuine stage-logic regression in `skills/build/SKILL.md` / `skills/fix/SKILL.md` — subagent dispatch, stage sequencing, Stage 5c cap semantics. Unbounded by nature. | Low | Unbounded | **CARRY + v0.1.10 stub, unless the human explicitly rescopes at that point** |

**A + B ≈ 1–2 days and ~2 dispatches ($20)** on top of S2's 4-dispatch baseline — landing at exactly the 6-dispatch / $60 cap approved above. The cap already covers Classes A and B; it is Class C that would breach it, which is why Class C is a decision made with evidence in hand rather than a commitment made now.

---

## Suggested revision order

1. Blocker 1 (S4.AC4 grep) and Blocker 2 (S2 no-dispatch disposition) — both are single-paragraph edits.
2. Major 1 (S4.AC2 catalog → E06 Shapes 1–6 verbatim) and Major 2 (S6.AC4 README premise) — both remove work an implementer would otherwise do wrong.
3. Major 3 (narrow S1.AC3), Major 7 (budget reconcile), Major 8 (S3 as predecessor) — cheap, and they fix the sequencing diagram.
4. Majors 4/5/6 (S6 gate prose, grep baseline, insertion point) — one coherent pass over S6.
5. Minors and open questions.
