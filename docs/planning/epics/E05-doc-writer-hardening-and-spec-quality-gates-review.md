# Epic Review: E05 — doc-writer hardening + review-plan codification + structural off-ramp

**Reviewed:** 2026-05-26
**Reviewer:** Roughly epic-reviewer (opus)
**Epic file:** [E05-doc-writer-hardening-and-spec-quality-gates.md](E05-doc-writer-hardening-and-spec-quality-gates.md)
**Verdict at review time:** **Needs Revision**
**Disposition (2026-05-26):** All 6 blockers + 6 lower-confidence observations addressed in the same-day epic revision; S4.AC7 mkdir-p audit extracted into a new E05.S4.5 micro-story (epic now 7 stories total). See the epic file (now 531 lines, up from 463) for the resolved spec. This review file is retained as the historical record of the pre-implementation review.

---

## Summary

E05 is technically solid and well-sourced — every citation spot-checked (build L223–299, fix L226–300, doc-writer 557 words, fix at 300/300 binding, ecf7147 commit, ADR enumeration in CLAUDE.md, E04 epic line references L583/L585/L587/L607/L609/L611/L613/L617/L621/L625/L629, absence of `skills/shared/`) verified accurately. The release thesis is coherent (debt + amendment, not new feature surface), risk register is unusually thorough (5 risks each with explicit close conditions), and sequencing is correct.

However, the epic has **one structural problem** that warrants pre-implementation revision: E05.S4 bundles three distinct concerns (mechanical off-ramp + new ADR + mkdir-p audit) into a single story, which is the same overengineering shape E04 retrospectives warned against — and E05.S6.AC6's "Required outcome: PASS or NEEDS REVISION with documented carve-outs" is not a verifiable gate (any output satisfies it). The math on E05.S2's word projection is also tight enough to fail on first try.

---

## Findings by Dimension

### Technical accuracy

Clean overall. Citations verified:
- `fix/SKILL.md` confirmed at 300/300; `build/SKILL.md` at 299/300.
- ABORT HANDLING at build L277–299 and fix L278–300; Stage 8 heading at build L223 / fix L226.
- `agents/doc-writer.md` confirmed at 557 words.
- E04 epic L585, L587, L607, L609, L617, L621, L625, L629 match the epic's claims; L581 + L583 confirmed for fold-ins.
- Commit `ecf7147` confirmed.
- ADR enumeration in CLAUDE.md L17 matches E05.S4 AC6's claim.
- `skills/shared/` does not currently exist.
- `skills/review-plan/SKILL.md` is 96 lines as claimed.

**Concerns:**

1. **E05.S4 Stage 8 line-range overstatement (epic L221).** The "Stage 8 WRAP-UP" prose itself ends at build L238 (only 6 steps; sections after L238 are MATURITY CHECKS and ABORT HANDLING). The epic claims "Stage 8 WRAP-UP at build L223–276 (~54 lines)" but the actual Stage 8 prose is L223–238 (~16 lines). The L223–276 range silently includes the MATURITY CHECKS section, which OQ11 explicitly resolves as *not* in scope. Implementer needs to clarify: are MATURITY CHECKS being extracted (contradicts OQ11) or only Stage 8 steps 1–6 (~16 lines per skill)? If only Stage 8 prose proper, the **~75-line extraction estimate is roughly 50% too large**, and the "≤240 lines projected" target in AC2/AC3 is not achievable from Stage 8 alone — closer to ~16-line recovery per file, leaving build at ~283 and fix at ~284. This is a **planning blocker for AC2/AC3 satisfiability** and cascades into E05.S6.AC3/AC4 which assume the headroom exists.

2. **E05.S2 word-budget projection is at the cap edge (epic L115).** AC2's three concurrent reinforcements (MUST + code-fenced + self-check) plus AC3's empty-error fallback plus AC4's all-fail branch realistically land at **610–625 words**, breaching the new 600 cap by 10–25 words. AC5's escape hatch is documented but a second cap breach in the same surface on the same release is a normalization-precedent risk the epic itself flags. Suggestion: bump E05.S1 to **650** to provide actual headroom, OR resolve OQ-AC5-trim-vs-second-bump explicitly in favor of trim before S2 starts.

### Best practices

Clean overall — the epic inherits E04.S6 conventions, the 2-commit Stage 8 idiom, ADR-011's flags-as-public-API pattern, and the AC mutual-satisfiability framing E04.S8 surfaced. Two observations:

1. **E05.S4.AC1's "highest-fidelity union" mechanic is underspecified (epic L238).** The runtime LLM Reading the shared file has no marker for "I'm executing build vs fix" beyond which SKILL.md it's running inside. The directive "Build-specific sub-steps (if any) are tagged in the shared file" begs the question. AC1 should specify a concrete tagging convention (e.g., `<!-- build-only -->` markers, or two separate files) OR demonstrate that build/fix Stage 8 prose is byte-identical apart from the commit-message template (it largely is — only `feat:` vs `fix:` differs).

2. **E05.S2.AC1's relocation choice is left open (epic L107).** "Either as a new Process step 6 or as a dedicated `## Failure handling` section." This is a load-bearing structural decision (renumbering breaks any external references to step 6+) and should be resolved at PM stage, not deferred to implementer. Recommend pre-resolving in favor of `## Failure handling`.

### Risks

Risk register is unusually thorough. Specific scrutiny:

1. **Risk 1 (LLM weak-anchoring) is realistic but optimistic.** Self-check is post-hoc and depends on the same LLM that just deviated being willing to flag its own deviation. Hedge is correctly captured.

2. **Risk 2 (shared-reference drift) — AC5 verify-all check is sufficient for path drift, insufficient for content drift.** The check confirms the SKILL.md files contain a Read directive pointing at the shared files — but doesn't confirm the shared files haven't been inline-replaced or that no contributor pasted duplicate inline prose. The original E04.S5 Check 1 (canonical-fixture byte-identity sha hash) is the stronger pattern.

3. **Risk 3 (review-plan false positives) — 5 paired fixtures sufficient for named carve-outs, blind to long-tail.** Suggested addition: each AC should ship with at least one "borderline-but-legitimate" fixture (third fixture per AC, so 15 total).

4. **Risk 4 (cross-epic AC amendment) — chicken-and-egg problem.** E05.S2 is simultaneously the **first amendment** and the **codifier of the amendment convention** in CONTRIBUTING.md. Cleaner: land the CONTRIBUTING.md convention as part of E05.S3's `## Skill authoring conventions` work — E05.S3 has no hard dependency on E05.S2, so the convention can land first.

5. **Risk 5 (additive ABORT HANDLING entry) — accepted-as-additive is defensible.** This is the right call for v0.1.7.

**Missing risks to add:**

6. **Risk 6 (implicit): E05.S4 line-recovery target is contingent on Stage 8 line-range correctness.** See Technical Accuracy #1. Highest-impact unflagged risk in the epic.

7. **Risk 7 (implicit): the off-ramp introduces a runtime Read in the hot path.** Every build pipeline run now Reads `skills/shared/stage-8-wrap-up.md` at Stage 8 entry; ABORT HANDLING Read can fire reactively at any stage's abort gate. CI dogfood at `--max-budget-usd 1.50` should pass but should be measured specifically.

### Overengineering

1. **E05.S4 bundles three concerns into one story.** ADR-012 + ABORT HANDLING/Stage 8 extraction + verify-all drift check + Stage 3 `mkdir -p` audit + CONTRIBUTING.md convention + CLAUDE.md updates + ADR README + CHANGELOG. The AC7 mkdir-p audit is bundled by file-touch coincidence (Stage 3 prose is adjacent to Stage 8), which is the same shape as bundling-by-proximity that the epic correctly avoids elsewhere. **Recommended: extract AC7 mkdir-p audit into a separate micro-story** or fold into E05.S6 since it's prose-level.

2. **E05.S3's 5 ACs could be consolidated to 4.** AC1 (verify-command scope vs enumeration) and AC5 (self-defeating verify pattern) are different lenses on the same class of failure. Defensible to keep them separate for canonical-example clarity. **Lower-confidence observation, not a blocker.**

3. **E05.S6's bundling of 3 process improvements is appropriate.**

### Acceptance criteria quality

Apply E05.S6.AC1's mutual-satisfiability check to E05's own ACs:

1. **E05.S2.AC7 vs AC1 — mutual satisfiability risk (epic L119).** If AC1's "renumber existing steps 6+ to 7+" path is chosen, AC7's "no content modified outside the relocated clause's source/destination sites" is borderline. This is the same shape that E04.S8 surfaced. **Recommended fix: pre-resolve in favor of `## Failure handling` section.**

2. **E05.S5.AC2 verify-command self-defeat risk (epic L285).** `grep -B1 -A1 "2-commit window" skills/shared/abort-handling.md` — AC1's entry text literally contains "2-commit window." This is exactly the self-defeating-verify pattern E05.S3.AC5 is being added to catch. Recommended: position-aware verify (e.g., `awk '/Stage 8/{found=1} found && /2-commit window/{print NR; exit}'`).

3. **E05.S6.AC6 has a circular-validation problem (epic L340).** "Required outcome: PASS or NEEDS REVISION with documented carve-outs" is **not a verifiable required outcome**. Either require PASS only, OR specify which carve-outs are acceptable.

4. **E05.S4.AC5 carve-out incomplete (epic L246).** The drift check fires when "`skills/build/SKILL.md` does not contain a Read directive" — but doesn't define what counts as a "Read directive." A literal `grep -F "skills/shared/stage-8-wrap-up.md"` would match inline-replaced prose too. Specify the directive form (e.g., a marker comment like `<!-- shared:stage-8-wrap-up -->`).

5. **E05.S6.AC1 verify is path-restricted to one file (epic L330).** Low-risk self-reference; defensible because the new prose IS the target of the verify and the file is small enough to manually disambiguate.

6. **E05.S3.AC7c verify is degraded by E05.S3's own check additions on E05.S2's plan.** Recommendation: ship E05.S3 with 5+5 fixtures only as the AC7c gate; treat E05.S2/S6 plan reviews as informational dogfood, not gates.

7. **DoD L463 references audit step without operational definition.** "Audit `.roughly/workflow-upgrades` for retired-check markers" — clarify: inspect, remove, document?

### Dependencies

The sequencing table is internally consistent. Critical path S4→S5→S6 correct. S1→S2 parallel critical path correct.

**One missing dependency callout:**

1. **E05.S2 has a hidden soft dependency on E05.S3.** If Risk 4 mitigation Leg-d moves from S2 to S3 per Risks #4 above, then S3 must ship before or with S2's CONTRIBUTING.md update.

2. **E05.S6's "soft dependency on S3" is underweighted.** AC6's self-validation gate is the **only verification path** for AC1's epic-reviewer addition. Either harden the synthetic-plan exercise to cover AC1's epic-level check independently, or upgrade the soft dependency to hard.

---

## Recommendations

### High-confidence blockers — address before implementation starts

1. **E05.S4 — clarify Stage 8 line-range extraction scope.** Revise the L223–276 / L226–277 ranges to L223–238 / L226–242 (Stage 8 proper), OR expand OQ11 to include MATURITY CHECKS. Without this clarification, AC2/AC3's ≤240 projection is not achievable and E05.S6.AC3/AC4 cannot land.

2. **E05.S4.AC1 — specify the build-vs-fix divergence mechanic.** Resolve whether the shared file uses byte-identical prose, tagged conditional blocks, or two separate files.

3. **E05.S2.AC1 — pre-resolve relocation target.** Choose `## Failure handling` section over Process-step renumbering. Eliminates AC7 mutual-satisfiability risk.

4. **E05.S2.AC5 + E05.S1 — resolve word-budget tightness.** Either (a) bump E05.S1 cap target from 600 to 650, or (b) commit to AC5 trim escape hatch in advance and remove the Path B precedent from AC5 prose.

5. **E05.S5.AC2 — replace literal grep with position-aware verify.** Current is self-defeating per E05.S3.AC5's own framing.

6. **E05.S6.AC6 — make the required outcome verifiable.** "PASS or NEEDS REVISION" is not a gate.

### Lower-confidence observations — consider during implementation

7. **E05.S4.AC7 (mkdir-p audit) — extract into a separate micro-story.**
8. **Risk 4 mitigation Leg-d — move from E05.S2 to E05.S3.**
9. **Risk 2 mitigation — add a content-drift check, not just a path-presence check.**
10. **E05.S6 — upgrade S3 dependency from "soft" to "hard" OR add a synthetic dispatch exercise for AC1's epic-level check.**
11. **E05.S3.AC7c — add a third fixture per AC (borderline-but-legitimate).**
12. **E05.S2.AC2 — add a fallback for T2 synthetic test partial-PASS scenario.**

---

## Relevant files for implementation reference

- [agents/doc-writer.md](../../../agents/doc-writer.md)
- [skills/build/SKILL.md](../../../skills/build/SKILL.md)
- [skills/fix/SKILL.md](../../../skills/fix/SKILL.md)
- [skills/review-plan/SKILL.md](../../../skills/review-plan/SKILL.md)
- [.claude/hooks/verify-all.sh](../../../.claude/hooks/verify-all.sh)
- [CLAUDE.md](../../../CLAUDE.md)
- [docs/planning/epics/complete/E04-path-consolidation-and-process-codification.md](complete/E04-path-consolidation-and-process-codification.md)
- [docs/adrs/](../../adrs/) (ADR-003 sync-reference precedent for ADR-012 framing)
