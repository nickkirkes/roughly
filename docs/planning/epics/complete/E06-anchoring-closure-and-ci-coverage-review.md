# Epic Review: E06 — anchoring closure + CI coverage + reviewer-brief codification

**Reviewed:** 2026-06-02 (two-pass + cubic iteration)
**Reviewer:** Roughly epic-reviewer (opus, ADR-008) + cubic review (post-revision verification)
**Epic file:** [E06-anchoring-closure-and-ci-coverage.md](E06-anchoring-closure-and-ci-coverage.md)
**Verdict at first-pass review:** **Needs Revision** (3 blockers + 4 observations + 5 polish items)
**Verdict at second-pass review:** **Ready** (all 12 targeted revisions verified; 3 new cosmetic NOs surfaced — NO-1 + NO-2 applied, NO-3 accepted as shorthand)
**Cubic review:** Iterated 3 cycles to clean — `{"issues": []}` at final cycle.
**Disposition (2026-06-02):** All first-pass blockers (3) and observations (4) and polish items (5) addressed in same-day epic revisions; 14 targeted edits across the 12 findings. Second-pass review verdict Ready with 3 cosmetic harmonization observations — NO-1 (AC2 word-range harmonization to 71–98) and NO-2 (DoD cumulative-assumption note) applied; NO-3 (known-pitfalls L70 secondary-mention shorthand in E06.S2) explicitly accepted as cosmetic per reviewer classification. Cubic review surfaced 2 P1 findings in subsequent iterations (re-amendment trail inconsistency in Files Touched section; install-marker base-ID-vs-lifecycle-suffix ambiguity in E06.S6.AC1); both resolved. This review file is retained as the historical record of the pre-implementation review process for E06.

---

## Summary

E06 closes Risk 1 (E05 inherited, all-fail-branch anchoring misfire) as its primary substantive work, bundles CI coverage that has been a v0.1.6+v0.1.7 carry-forward, and codifies four small spec-quality conventions. The epic is structurally sound at first-pass: matches E05's template, carries forward the line-cap budget contract correctly, citations spot-check accurately (doc-writer 649/650 at 80 lines; verify-all.sh 148/150; all skill line counts match HEAD). However, the first-pass review surfaced three blockers in E06.S1 — the most complex story — that warranted resolution at the epic level rather than deferral to plan-write: (1) AC1(a)/(b) and AC7 misframed the L41 MUST as partial-success-specific when it is universal (covers all three branches); (2) the AC1 word-budget estimate (~30–50 words) was a significant under-estimate against realistic prose (~71–98 words), making the AC2 trim target structurally tight; (3) AC4's "no-edit-in-place" rule conflicted with AC5(b)'s requirement to add an adjacent forward-pointer line. After the same-day revision pass, all three blockers landed clean and the second-pass review classified E06 as Ready. Cubic review's two subsequent P1 findings caught a Files Touched section that hadn't been updated to match AC4's revised preserve-hops convention, and an E06.S6.AC1 ambiguity about whether the install-marker recognition list uses base-IDs or lifecycle-suffixed forms — both fixed in the same review cycle.

---

## Findings by Dimension

### Technical accuracy

Clean overall — citations spot-checked against HEAD as of 2026-06-02:

- `agents/doc-writer.md` confirmed at **649 words / 80 lines** (matches epic's `649/650` claim throughout).
- L41 MUST sentence verified as universal (covers all three branches in branch-selection-rule form): `"Your return summary MUST literally begin with one of the three templates below... Pick template by outcome: 0 failed → all-success; ≥1 failed and ≥1 succeeded → partial-success; 0 succeeded → all-fail."`
- L48 partial-success code fence, L52 all-fail code fence, L55 `(no error output)` fallback, L57 universal first-line post-emit self-check all confirmed.
- `.claude/hooks/verify-all.sh` at 148/150 soft cap; `skills/build/SKILL.md` 268/300; `skills/fix/SKILL.md` 269/300; `skills/review-plan/SKILL.md` 117/300; `skills/help/SKILL.md` 163/300.
- E04 epic `Amended in E05.S2` back-pointer count of 3 verified at lines 442, 448, 452 (matches AC5(a) post-revision verify command expectations).
- `tests/fixtures/review-plan/` discipline (PASS + NEEDS REVISION + BORDERLINE-PASS triple per E05.S3 + E05.S7c) confirmed established.
- `scripts/ci-dogfood.sh` `out=$(timeout N cmd 2>&1) && OUT_EXIT=0 || OUT_EXIT=$?` ladder pattern at L74/L100/L140 with explicit 124-timeout FAIL arm at L77/L103/L144 (matches E06.S2.AC3 and E06.S3.AC4 mirror requirements).

### Best practices

Epic structure matches E04/E05 templates: header (date/status/target version/effort/dependencies), Release thesis, Risk register (4 risks each with mitigation + close criterion), Line-cap budget contract, Stories (3 clusters), Open questions (7 resolved + 9 implementer-discretion carry), v0.1.9 candidates, Sequencing, Definition of done. No structural drift.

AC quality is consistently high. Most ACs name files explicitly, cite line ranges, and include `grep -Fn` / `grep -Fc` verify commands. E06.S1 ACs in particular are detailed and surface trim semantics (4-column trim table) without overspecifying.

### Risks

All 4 risks are specific to v0.1.8 (not generic). Each has explicit mitigation + close criterion:

- **Risk 1 (AC4 second-swing cost-of-failure)** — mitigated by three-outcome ship policy mirroring E05.S2's pattern; T2 re-run is binary gate.
- **Risk 2 (cap-relief trim degradation surface)** — mitigated by 4-coverage-group preservation enumeration in AC2; plan-write produces 4-column trim table.
- **Risk 3 (negative-path CI harness fragility)** — mitigated by E05.S3 triple-discipline + per-fixture pre-merge subagent dispatch validation; 3-consecutive-runs close criterion.
- **Risk 4 (cross-epic re-amendment trail readability)** — mitigated by preserve-hops convention extension in CONTRIBUTING.md (revised from initial overwrite-form per Observation 4); recursive-application sentence covers 3+ hop chains.

### Overengineering

E06.S4 + E06.S5 split correctly motivated. S4 is a `skills/review-plan/SKILL.md` + CONTRIBUTING.md + fixture-triple touch; S5 is a build/fix Stage 6 prose touch. Different verification surfaces, different file sets, different fixture requirements. Collapse to bundle would muddy the review-plan-vs-Stage-6 boundary.

E06.S6 and E06.S7 are appropriately scoped as micro-stories.

E06.S1 is large but defensibly so. It bundles AC4 substantive tightening + cap-relief trim + cross-epic re-amendment convention extension + first multi-hop application. Bundling is justified because the trim is structurally required (cap pressure) and the convention extension is the structural foundation enabling AC5 trail update.

### AC mutual satisfiability (Dimension #7 from E05.S6)

All AC pairs jointly satisfiable post-revisions:

- **E06.S1.AC1 ↔ AC7** (universal-MUST framing): AC1(a) explicitly framed as additive below L41/L57 (not relocation or edit); both ACs hold byte-identical preservation of L41 and L57.
- **E06.S1.AC4 ↔ AC5(a) ↔ AC5(b)** (preserve-hops form): 4-artifact convention is internally consistent; verify counts (3 + 1 in E04 epic; ≥1 in E05 epic) match convention text; historical-record claim is mechanically supported by AC5(b) gloss.
- **E06.S1.AC2 ↔ AC7** (cap-relief vs no-regression): trim envelope preserves E05.S2.AC2's L41/L48/L57 forms; 4-column trim table at plan-write enforces protection.
- **E06.S2.AC1 ↔ AC5** (CI flag prose vs line-cap): three non-interactive default branches fit within ≤8-line tightened budget.
- **E06.S3.AC4 ↔ AC1/AC2/AC3** (124-timeout-as-FAIL across ALL scenarios): real abort emits scenario-specific exit code (not 124); timeout-killed runs classify FAIL. No contradiction.
- **E06.S5.AC3 ↔ Line-cap budget contract**: cumulative arithmetic 269 + 8 + 6 = 283 ≤ 300 with ≥17-line headroom matches DoD target.

---

## First-pass findings (resolved)

### Blockers (3)

| # | Finding | Resolution |
|---|---|---|
| 1 | E06.S1.AC1(a)/(b) + AC7 misframe the L41 MUST as partial-success-specific. The actual L41 sentence is **universal** — covers all three template selections via the branch-selection rule. Lifting the branch-selection clause OUT of L41 either edits L41 (violates AC7) or duplicates it (violates AC2 in spirit). | AC1(a) reframed as additive "strengthening MUST + post-emit self-check pair" below L41 (L41 preserved byte-identical); AC1(b) parenthetical fixed; AC7 explicit about L41/L57 universality. |
| 2 | E06.S1 word budget reconciliation: AC1 additions estimated ~30–50 words; AC2 trim target ~30–50 words. Realistic prose lands at ~71–98 words; at upper bound the trim envelope expands beyond conservative slack candidates. | AC2 word-budget breakdown locked at epic level: AC1(a) ~33–52 + AC1(b) ~14–18 + AC1(c) ~24–28 = cumulative ~71–98 words; AC2 trim target matched. Plan-write OQ-S1-word-budget preserved for trim-table authoring. |
| 3 | E06.S1.AC4's "no-edit-in-place" rule conflicts with AC5(b)'s requirement to add a forward-pointer line below E05.S2.AC4 prose (strict reading: adding a line is editing the file). | AC4 clarified: "intermediate-amender entries' AC prose MUST NOT be edited in-place; additive forward-pointer lines placed adjacent to the AC prose are explicitly permitted and required by this rule." AC5(b) cross-references the clarified scope + adds historical-record-preservation mechanism gloss. |

### Observations (4)

| # | Finding | Resolution |
|---|---|---|
| 4 | AC4 convention with "overwrite original back-pointer with latest amender" form severs the discovery path from original → intermediate → latest. Reader following E04.S8.AC5 back-pointer to E06.S1 has no way to know an intermediate amendment in E05.S2 existed. | Convention switched to **preserve-hops** form. Original back-pointer preserved unchanged; new forward-pointer line added immediately below it. Risk 4 mitigation rewritten to match; AC4 convention text + AC5(a) verify command + AC6 cross-reference all updated. |
| 5 | AC5(a) scope ambiguity: why only AC5's back-pointer updates, not AC2 or AC4 (also amended in E05.S2). | Explicit sentence added: "AC2 and AC4 back-pointers in E04.S8 remain unchanged because they are not re-amended in E06.S1 — only AC5's location gains the additional re-amendment forward-pointer; E06.S1 re-amends AC5's downstream descendant E05.S2.AC4." |
| 6 | E06.S2.AC1 cites `.roughly/known-pitfalls.md` L70 by line number — line numbers in known-pitfalls churn per known-pitfalls' own L102 doc-citation-rot pitfall. | Primary citation at AC1 desensitized to topic-form ("`## Skill & Agent Authoring` section on `$ARGUMENTS` standalone-token flag-detection"). Secondary mentions at L183/L193/L199 retained as line-number shorthand (accepted per second-pass NO-3 — see below). |
| 7 | Cumulative line-cap projection (fix/SKILL.md) used both stories' upper bounds simultaneously, leaving zero slack at the projection itself. | Estimates tightened: E06.S2 ~5–8 lines (from ~5–10); E06.S5 ~5–6 lines each (from ~5–7). Cumulative ≤283 with ≥17-line headroom under 300. Line-cap budget contract + AC5 + AC3 + DoD targets all updated consistently. |

### Polish items (5)

| # | Finding | Resolution |
|---|---|---|
| 8 | E06.S3.AC4 case-ladder spec lacks explicit 124-timeout FAIL arm clarification in inverted-success scenarios. | Added: "**124-timeout MUST classify as FAIL across ALL scenarios, including inverted-success scenarios where non-zero is expected** — timeout indicates the scenario didn't complete, not that the expected abort fired." |
| 9 | Risk 4 mitigation lacks recursive-application rule for 3+ hop chains. | Added: "**Recursive application:** for chains of 3+ hops, every prior amender's pointers are preserved; only the new latest-amender forward-pointer is added... the chain remains fully discoverable through preserved hops." Worked example for hypothetical v0.1.9 E07.Sn re-amendment included. |
| 10 | AC4 convention text quoted in epic body would itself trigger E06.S4's new AC quoted-wording marker check if S4 ships first — self-validation gap. | Added explicit `verbatim:` tag note: "Convention text above is tagged `verbatim:` for E06.S4 sequencing — the text must land in CONTRIBUTING.md byte-for-byte modulo whitespace and link formatting." |
| 11 | AC5(b) "historical record" claim could be read as contradiction (E05.S2 file additively modified yet "preserved as historical record"). | Added mechanism gloss: "Although the E05.S2 epic file is additively modified (one new line added below AC4), the AC4 prose text itself remains byte-identical to its E05.S2-ship state, so the historical record of the AC4 contract as it stood at E05.S2 ship is preserved verbatim in its original surrounding context." |
| 12 | DoD `wc -l` recording set omits `agents/doc-writer.md` line count (currently 80 lines, expected +1–2 from AC1(a) MUST insertion). | DoD target line updated: "agents/doc-writer.md (post-S1; target ≤650 words / current 80 lines, expected +1–2 lines from AC1(a) MUST insertion; net-zero word delta)." |

---

## Second-pass findings (Ready verdict)

Second-pass review verified all 12 first-pass revisions landed correctly per verify-able criteria. Three new cosmetic observations surfaced, classified by reviewer as "Not a blocker — Cosmetic only":

| # | Finding | Disposition |
|---|---|---|
| NO-1 | AC2 prose says "~70–95 words" but breakdown sub-bullet says cumulative ~71–98. 3-word mismatch at upper bound creates 3-word overshoot risk at 1-word starting headroom. | **Applied.** AC2 trim range harmonized to "~71–98 words" matching the breakdown. |
| NO-2 | Line-cap arithmetic at upper-bound (269 + 8 + 6 = 283) is exact; projection assumes both S2 and S5 land at tightened upper bounds simultaneously. | **Applied.** DoD line annotated: "assumes both S2 and S5 land at their tightened upper bounds, cumulative tightens proportionally if either lands lower." |
| NO-3 | E06.S2 still cites "known-pitfalls L70" at 3 secondary mentions (L183/L193/L199) and "L28" at L187 after primary citation at L176 was desensitized to topic-form. | **Not applied — accepted as shorthand.** Reviewer explicitly classified as "Cosmetic only" since primary citation at L176 establishes the topic-form anchor and downstream mentions function as line-number shorthand. Plan-write may propagate topic-form if desired. |

---

## Cubic review iteration findings (resolved)

Post-second-pass-review cubic iteration surfaced two P1 findings that escaped both review-epic passes:

| # | Iteration | Finding | Resolution |
|---|---|---|---|
| C1 | 1 | E06.S1 "Files touched" section still described re-amendment trail as `E04.S8.AC5 back-pointer updated from "Amended in E05.S2" to "Amended in E06.S1"` (the old overwrite-form). AC4/AC5 had been updated to preserve-hops form (Observation 4 resolution), but the Files Touched section was missed. | Updated Files Touched bullets to match preserve-hops: original back-pointer "preserved unchanged"; new forward-pointer line added immediately below. AC1's "lift" wording also harmonized to "add a strengthening" per Blocker 1 resolution. |
| C2 | 2 | E06.S6.AC1 recognition list uses base ID `plan-mode-gate-v1`, but `.roughly/workflow-upgrades` actually stores lifecycle-suffixed forms (`plan-mode-gate-v1-added <date>`). AC could be read as "literal-marker-entry match" form, which wouldn't match real marker entries — the feature wouldn't solve the categorization problem. | AC1 clarified: maturity-check categorization logic matches by **base ID prefix** (stripping `-added`/`-declined` lifecycle suffix); install-marker recognition list uses the same prefix-match logic. Recognition list contents are base IDs without lifecycle suffix; the matching logic handles the lifecycle suffix at runtime. Verify command + manual dispatch acceptance criterion added. |
| C3 | 3 | — | Clean: `{"issues": []}`. |

---

## Final disposition

Epic landed at commit `5caf5ec` on `main` (2026-06-02). Pre-implementation review process exercised the spec at three quality gates (review-epic v1 + v2 + cubic iteration); 16 of 17 review-epic findings applied + 2 of 2 cubic findings applied + 1 second-pass cosmetic observation explicitly accepted as shorthand. Epic file is ready for plan-write. Recommended first story: **E06.S1** (highest-priority risk close; T2 synthetic re-run is binary verification gate per three-outcome ship policy).
