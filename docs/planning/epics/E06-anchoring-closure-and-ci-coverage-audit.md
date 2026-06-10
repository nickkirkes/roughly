# Epic Audit: E06 — doc-writer all-fail anchoring + CI coverage + reviewer-brief codification

**Date:** 2026-06-10
**Stories audited:** 7 (E06.S1–S7, all merged)
**Acceptance criteria:** 37 — **35 MET, 2 PARTIALLY MET, 0 NOT MET**
**Audit method:** 7 parallel per-story review subagents (one per story, evidence-grounded against shipped-form-as-amended per the epic's 9 human-approved post-merge deviation notes) + orchestrator cross-cutting verification pass.

## Summary

E06 shipped all 7 stories with strong AC fidelity. Every verify command specified in the epic passes against the current tree, including the amended forms from the epic's post-merge deviation notes (AC1 retargets in S3, scope expansions in S6, post-ship corrections in S7). The two PARTIALLY MET findings are both documentation-artifact gaps, not functional defects: E06.S1.AC3 shipped first-line outputs + a methodology note rather than full T2 transcripts "mirroring the v0.1.7 audit-report format," and E06.S7.AC3's review-plan PASS verdict was never recorded in the plan file (only a code-review attestation in the commit message). The most substantive cross-cutting finding is an integration artifact between S2 and S3: ADR-013 (shipped in S3) reversed build's `--ci` skip-and-synthesize, which retroactively invalidated a comparison sentence S2 shipped in `skills/fix/SKILL.md` and left a real, undocumented behavioral asymmetry between the two pipelines' NEEDS REVISION handling. Separately, the release state is internally inconsistent ahead of tagging: the CHANGELOG heading is already renamed to `[0.1.8] — 2026-06-03` (a date that predates S3's 2026-06-09 ship), while `plugin.json` remains `0.1.7` and ROADMAP still shows v0.1.7 as current.

## Per-Story Results

### E06.S1 — doc-writer AC4 all-fail-branch anchoring + cap-relief trim + re-amendment convention (6 MET, 1 PARTIAL)

| AC | Status | Evidence |
|----|--------|----------|
| AC1(a) standalone branch-selection MUST + paired self-check | MET | `agents/doc-writer.md:43` (MUST), `:63` (3-way self-check per deviation note); L41 universal MUST preserved byte-identical |
| AC1(b) all-fail-specific MUST above code fence | MET | `agents/doc-writer.md:53`, immediately above all-fail fence at L55–57 |
| AC1(c) all-fail-specific post-emit self-check naming v0.1.7 misfire | MET | `agents/doc-writer.md:65` |
| AC2 cap-relief trim ≤650 words, 4 coverage groups preserved | MET | `wc -w` = 647 (≤650, 3-word slack); all four coverage groups verified at named locations |
| AC3 T2 re-run, transcripts appended to CHANGELOG | **PARTIALLY MET** | Both scenarios FULL PASS (prose-level), classification + first-line outputs in CHANGELOG. Literal requirement "T2 transcripts (both scenarios) appended… mirroring the v0.1.7 audit-report follow-up format" not fully satisfied — first-line quotes + methodology note shipped instead of full transcripts. Methodology limitation (inlined-prose vs installed-cache dispatch) transparently documented; runtime-level verification deferred to retrospective per epic policy. |
| AC4 CONTRIBUTING.md multi-hop re-amendment rule | MET | `CONTRIBUTING.md:93` — four-artifact requirement, recursive rule, named first instance all present |
| AC5 trail artifacts (E04 + E05 epics) | MET | E04 epic: "Amended in E05.S2" ×3 (unchanged), "Re-amended in E06.S1" ×1; E05 epic: forward-pointer at L118 below byte-identical AC4 prose |
| AC6 CHANGELOG five-item entry | MET (accuracy note) | All five items present. **Inaccuracy:** entry claims net-zero 649→649; actual is 649→647 (fix commit `7bad1f4` trimmed 2 words; its own commit message records 649→647 correctly). In implementer's favor; cap unaffected. |
| AC7 no regression to v0.1.7 contracts | MET | All three preservation greps pass (`6. **Deduplicate` at L35, `## Failure handling` at L37, `(no error output)` at L59) |

### E06.S2 — fix-side `--ci` flag (6 MET)

| AC | Status | Evidence |
|----|--------|----------|
| AC1 flag handling, CI_MODE, standalone-token detection, non-interactive gates | MET | `skills/fix/SKILL.md:34` (detection + CI_MODE), `:115` (Stage 4 verdict handling); negative grep `contains \`--ci\`` = 0 matches; verbatim-scoping deviation as amended |
| AC2 fix happy-path fixture | MET | `tests/fixtures/hello-roughly-bug/` complete (4 files); README enumerates stage transitions + exit signature; `$NMAE` typo bug reproducible |
| AC3 ci-dogfood.sh fix test function | MET | L261–358: exit-capture ladder, 124/non-zero/0 case ladder, F1–F5 structural + F6 behavioral assertion (regression test, exit 0) |
| AC4 dogfood.yml invocation, job key preserved | MET | Job key `dogfood-build-cycle` unchanged (rename reverted in `56020a6`); step name updated only |
| AC5 line cap | MET | `wc -l skills/fix/SKILL.md` = 275 ≤ 277 |
| AC6 CHANGELOG entry + cross-references | MET | All cross-references present (E03.S11b-2, known-pitfalls standalone-token, E04 carry-forward) |

### E06.S3 — build-side negative-path CI scenarios (6 MET, as amended)

| AC | Status | Evidence |
|----|--------|----------|
| AC1 build-abort fixture (retargeted to Stage 5c auto-fix-cap per deviation note) | MET | `hello-roughly-build-abort/`; assertion keys on `cannot proceed: auto-fix cap reached on` (ci-dogfood.sh L393), marker byte-consistent with `skills/build/SKILL.md` Stage 5c |
| AC2 plan-revision recovery fixture (expanded via ADR-013) | MET | `hello-roughly-plan-revision/`; ≥2 review-plan verdict markers asserted, NEEDS REVISION → PASS sequence (L480+); trigger fixed to deterministic `=2` co-located hazard in `43bd043`; documented v0.1.9 descope path if non-deterministic |
| AC3 paired controls | MET | `hello-roughly-build-abort-control/` + `hello-roughly-plan-clean/`; negative-path-not-taken assertions present; negative backstop (abort fixture must not reach Stage 8) present |
| AC4 harness assertion ladders, marker-primary, 124=FAIL everywhere | MET | 124-timeout FAIL arms at L382/L436/L505/L588 (all 4 scenarios); marker-primary per deviation note; verdict-count assignments guarded against `set -e` silent exit (`dc4a2fb`) |
| AC5 dogfood.yml budget audit | MET | Budget held at 1.50/dispatch with documented possible 2.00 bump for AC2 recovery; step comments document the now-larger dispatch set |
| AC6 CHANGELOG entry | MET | All 4 fixtures named; cross-references (E04 L559, E05 OQ4, E05.S3.AC2, E05.S6.AC3) + ADR-013 present |

ADR-013 surface: `docs/adrs/ADR-013-build-ci-runs-review-plan.md` exists; `CLAUDE.md` ADR table row added; build `--ci` dispatches review-plan with NEEDS-REVISION recovery loop; CI_MODE carve-outs at previously-interactive Stage 4 points; `wc -l skills/build/SKILL.md` = 270 ≤ 300.

### E06.S4 — AC quoted-wording marker convention (5 MET)

| AC | Status | Evidence |
|----|--------|----------|
| AC1 review-plan check + bright-line carve-out + marker-intent sub-carve-out | MET | `skills/review-plan/SKILL.md:48–49`; both carve-outs present per shipped-form-as-amended |
| AC2 CONTRIBUTING.md `## AC authoring conventions` | MET | L68–81: markers, examples, carve-out language, E05.S2 deferral cross-reference |
| AC3 fixture triple with trigger condition in all three | MET | All three fixtures trace to their intended verdicts under the shipped check text (PASS / NEEDS REVISION / BORDERLINE-PASS via sub-carve-out); BORDERLINE-PASS carries one rationale acknowledgment in `## Notes` |
| AC4 line cap + README inventory | MET | `wc -l` = 120 ≤ 300; README rows at L38–40 + desk-check reference at L60 |
| AC5 CHANGELOG entry | MET | All three cross-references present, with proactive stale-line acknowledgment (L80 → L86) |

### E06.S5 — Stage 6 SFH third-disposition gate (5 MET)

| AC | Status | Evidence |
|----|--------|----------|
| AC1 disposition in build Stage 6 | MET | `skills/build/SKILL.md:205`, all required content, adjacent to fix/defer context |
| AC2 byte-identical in fix Stage 6 | MET | `skills/fix/SKILL.md:212`; diff of the disposition blocks empty — parity holds **today**, post-E06.S3 build edits |
| AC3 line caps | MET | At merge: build 270 ≤ 274, fix 271 ≤ 283; current: build 270, fix 275 — both within cumulative caps |
| AC4 CHANGELOG entry + cross-references | MET | Functional cross-references present; stale epic line numbers (L78/L82 → actual L86/L88) explicitly acknowledged in entry — known cross-cutting pattern, already a v0.1.9 candidate |
| AC5 review-plan PASS | MET (caveat) | Self-attested in plan AC-mapping section (plan L140), not a quoted verdict block — matches the project's established lightweight convention; ties to deferred E05.S5 candidate #6 |

W1/W2 SFH findings correctly escalated as spec-revision-candidates to the epic's v0.1.9 section (the new disposition dogfooded on its own implementation).

### E06.S6 — `/roughly:help` install-marker schema fix (5 MET, incl. producer-side expansion)

| AC | Status | Evidence |
|----|--------|----------|
| AC1 recognition list + heading + producer side | MET | `skills/help/SKILL.md:67` (base-ID list), `:78` (Installed components); setup Step 5e writes marker on successful registration (L238, Branch-3-blocking-warning excluded); upgrade STEP 6 back-fills gated on jq structural check of settings.json registration (not file existence) |
| AC2 three-category output in order | MET | L71–86: Maturity-check state / Installed components / Unknown markers; Unknown remains reachable |
| AC3 schema decision documented | MET | CHANGELOG L65: option (a) vs (b)/(c) with rationale; tradeoff acknowledged |
| AC4 line cap | MET | `wc -l skills/help/SKILL.md` = 170 ≤ 173 |
| AC5 CHANGELOG entry | MET | Named files (incl. producer side), option, ship-time list, contributor-maintained note. Minor imprecision: entry says the hook *file* is the source of truth; implementation correctly requires file + registration. |

Repo back-fill applied: `.roughly/workflow-upgrades:4` = `plan-mode-gate-v1-added 2026-06-08`. setup 289/300, upgrade 174/300 — as documented.

### E06.S7 — audit-table-in-PR-body convention (2 MET, 1 PARTIAL)

| AC | Status | Evidence |
|----|--------|----------|
| AC1 convention in `## Audit conventions` (as twice-corrected) | MET | CONTRIBUTING.md L95–99; corrected `gh api --method PATCH … -F body=@<file>` grammar valid; false `gh pr edit --body-file` silent-no-op claim absent (`silently no-ops` = 0 hits, `verified 2026-05-31` = 0 hits); pitfall reframed as verify-the-body-changed; PR #54 fact retained without asserted cause |
| AC2 CHANGELOG entry | MET | Cross-references (E05.S4.5.AC3, E05 audit rec #4, OQ6) present; corrected syntax propagated to the entry |
| AC3 review-plan PASS recorded | **PARTIALLY MET** | No review-plan verdict artifact in `.roughly/plans/audit-table-in-pr-body-convention-plan.md`; commit `91f0b87` attests code-reviewer PASS (a different gate). The plan file was frozen historical with stale pre-correction text and no verdict stamp. AC3's outcome is plausible but unevidenced by any persistent artifact. |

## Cross-Cutting Findings

1. **[Integration — S2×S3] Stale comparison sentence + undocumented `--ci` asymmetry.** `skills/fix/SKILL.md:115` still reads "This intentionally differs from build's `--ci` skip-and-synthesize (build/SKILL.md Stage 4)" — invalidated when ADR-013 (E06.S3) reversed build's skip-and-synthesize. Worse, a *real* divergence now exists in the opposite direction and is documented nowhere: fix `--ci` exits non-zero on the **first** NEEDS REVISION (no revision loop), while build `--ci` runs a NEEDS-REVISION recovery loop (up to 2 verdicts). ADR-013 frames itself as "unifying with fix `--ci`" but the unification is partial. This is the only finding in this audit that misleads a future reader of normative skill text.
2. **[Consistency — S5] Build/fix Stage 6 parity holds post-S3.** The S5 disposition paragraph remains byte-identical between build and fix despite S3's later edits to build/SKILL.md. Three pre-existing Stage 6 structural differences (Invoke-line, fix-critical-findings sentence, feature-vs-issue summary) predate E06 and are out of scope.
3. **[Release state] Inconsistent version triad.** CHANGELOG heading already reads `## [0.1.8] — 2026-06-03` — renamed early (DoD says "at tag time") and dated 6 days before the final story shipped (S3, 2026-06-09). Meanwhile `.claude-plugin/plugin.json` = `0.1.7` and `docs/ROADMAP.md` shows `**Current:** v0.1.7`. Nothing is wrong functionally, but the three surfaces disagree about what version this tree is.
4. **[Gaps] Verdict-artifact gap is systemic, not story-specific.** Both PARTIAL findings (S1.AC3 transcripts, S7.AC3 verdict) plus the S5.AC5 caveat share one root: pipeline gate outcomes are attested in prose (CHANGELOG notes, commit messages, plan AC-mapping lines) rather than captured as verbatim artifacts. The already-deferred E05.S5 candidate #6 ("AC4 PASS verdict persistent-artifact convention") covers exactly this; E06 added two more data points for promoting it.
5. **[Gaps] Risk 1 closed at prose-level only.** T2 FULL PASS was run against source-tree prose, not the installed plugin cache (cache held v0.1.7 at test time). Runtime-level post-reinstall confirmation is correctly deferred to the v0.1.8 retrospective with a documented re-promotion criterion.
6. **[Regressions] None found.** S1's 97-word trim degraded no shipped AC coverage (AC7 greps all pass; T2 Scenario 1 regression check passed). S3's build/SKILL.md edits did not break S5's parity or S2's harness. CHANGELOG accuracy nit: S1 entry claims net-zero 649→649; actual 649→647 (benign, in-favor).
7. **[Open operational gates — not defects].** Risk 3 close requires 3 consecutive green dogfood runs on `main` without harness modification (in progress); Risk 2 window closes ~2026-06-27; E04 Risk 3 window ~2026-06-19; E04 Risk 5 promotes if no real-dogfood multi-file invocation lands; AC2 plan-revision trigger determinism confirmed per-fixture but watches the 3-run gate.

## Recommendations

1. **(P1, small) Fix `skills/fix/SKILL.md:115`** — remove/rewrite the stale "intentionally differs from build's `--ci` skip-and-synthesize" sentence and explicitly document (or unify) the fix-vs-build NEEDS-REVISION-loop asymmetry. Candidate home: the existing v0.1.9 "Build `--ci` contract unification follow-ups (ADR-013)" entry — extend it to name this asymmetry.
2. **(P1, operator) Reconcile the release triad before tagging:** bump `plugin.json` → 0.1.8, update `docs/ROADMAP.md`, and correct the CHANGELOG heading date to the actual tag date (current `2026-06-03` predates four of seven story ships).
3. **(P2, one-line) Correct the S1 CHANGELOG net-zero claim** (649→649) to the actual 649→647, matching commit `7bad1f4`'s own message.
4. **(P2, process) Promote E05.S5 candidate #6 (verdict persistent-artifact convention) for v0.1.9** — S1.AC3, S7.AC3, and S5.AC5 are three same-shaped evidence gaps in one epic; the convention would convert all three from attestation to artifact.
5. **(P3, monitor) Track the open gates at retrospective:** 3-consecutive-runs Risk 3 criterion, Risk 2/E04-Risk 3 30-day windows, E04 Risk 5 close-or-promote, runtime-level T2 confirmation post-reinstall.
6. **(P3, noted) S6 jq edge case:** upgrade STEP 6's back-fill query assumes the nested `.hooks[].hooks[]` shape; a foreign `UserPromptSubmit` entry without an inner `hooks` array silently skips the back-fill. No fixture covers this path. Acceptable as-is; bundle with the install-marker generalization candidate if it ships.

## Post-Audit Actions (2026-06-10)

Applied same-day on branch `test/E06-audit`:

- **Rec 1:** `skills/fix/SKILL.md` Stage 4 stale sentence rewritten to document the actual build-vs-fix `--ci` NEEDS-REVISION asymmetry; epic's "Build `--ci` contract unification follow-ups (ADR-013)" v0.1.9 candidate extended with the unification decision; superseded-note added to the E06.S2 CHANGELOG entry.
- **Rec 2:** CHANGELOG heading reverted to `## [Unreleased] — v0.1.8` (user decision) — heading rename, `plugin.json` bump, and ROADMAP update all deferred to tag time per DoD, after the Risk 3 CI gate closes.
- **Rec 3:** S1 CHANGELOG net-zero claim corrected to 649 → 647 with correction annotation.
- **Rec 4:** E05.S5 candidate #6 (verdict persistent-artifact convention) raised to v0.1.9 must-do in the epic's carry-forward list, citing the three E06 evidence gaps.
- **Rec 6:** jq edge-case audit note added to the epic's install-marker producer-generalization candidate. S6 CHANGELOG source-of-truth wording also corrected (file + registration, not file alone).
- **Rec 5 (monitor)** remains open: 3-consecutive-runs gate, Risk 2/E04-Risk 3 windows, E04 Risk 5, runtime-level T2 confirmation — all land at the v0.1.8 retrospective.
