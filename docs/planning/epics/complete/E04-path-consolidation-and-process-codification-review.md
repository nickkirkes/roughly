# Epic Review: E04 — Path consolidation + process codification

**Date:** 2026-05-14
**Reviewer:** Roughly epic-reviewer (Opus, dispatched via `/roughly:review-epic`)
**Epic under review:** [E04-path-consolidation-and-process-codification.md](E04-path-consolidation-and-process-codification.md)

---

## Verdict

**Needs Revision** — substantive but cheap-to-fix issues in technical claims (Risk register counts, AC scoping in S1, AC verifier in S3, AC3.5 known-pitfalls.md state), plus a sequencing inconsistency. None are blockers; all are catchable with localized edits.

---

## Summary

The epic is strongly structured: tight cluster framing, an explicit line-cap budget contract, a 5-item risk register with mitigation closure conditions, and a sequencing table with parallelism notes. The PM round visibly produced higher-fidelity ACs than the average pre-implementation epic (AC1.1–3.5 in S5; AC3a in S1). Two categories of issue are worth fixing before branch-cut: a handful of factual claims about current state are slightly off in ways that show up in verify commands, and one cross-story dependency in the sequencing table is reversed from the Depends-on lines. The bundling decisions for S5, S6, and S9 are defensible. The S7/ADR-011 ceremony question is worth surfacing but not blocking.

---

## Findings by dimension

### 1. Technical accuracy

- **[REVISE] Risk 1 and Risk 2 say "16-ish runtime references"; the actual count is 15 across the 4 named skill bodies (E04.S1).** `rg -Fn "docs/plans" skills/` returns: build 2, fix 2, help 10, audit-epic 1 → 15 total. The "L85, L91, L102, L105, L108, L115, L118, L125, L134, L146" enumeration in S1's Files Touched is the same count (10 in help) and matches. Either change "16-ish" to "15" (cleaner) or keep "~15" / "ish". Right now S1's enumeration and the risk-register count disagree by one.

- **[REVISE] S1 AC1 wording understates scope.** AC1 says "All `docs/plans/` references across the 4 skill bodies … flipped" — but `rg -Fn "docs/plans" skills/` after implementation must return zero, and the verify command is set as zero matches. The verify command is correct; the AC prose just needs to also cover the historical-plans `git mv` and the scripts/README/CHANGELOG references so the verify-command surface and the AC scope line up. As written, a reader could read AC1 and miss that `scripts/ci-dogfood.sh` references count toward "zero matches under `rg -Fn`" (they're covered by AC5 separately, but the global zero-matches command in AC1 only scopes `skills/`). Suggest tightening AC1's verify command to `rg -Fn "docs/plans" skills/` (already correct, narrow scope) and AC5's to `rg -Fn "docs/plans" scripts/ README.md CONTRIBUTING.md CHANGELOG.md` so the two commands together fully cover the surface area, with CHANGELOG carved out because line 106 / 242 are historical references that must NOT be flipped.

- **[BLOCKER for AC] CHANGELOG.md has 2 references to `docs/plans/` at L106 and L242 that are historical-fact and must NOT be migrated.** L106 says "`docs/plans/**` historical implementation plans retain their original naming as historical fact" — and L242 documents the original plan naming convention. The current global "zero matches" framing in AC1's verify command (`rg -Fn "docs/plans" skills/`) avoids this trap because it's scoped to `skills/`, but the README.md L214 reference (which AC8 covers) needs a similar carve-out. Add to S1 ACs: explicit list of files that should retain `docs/plans/` references as historical artifacts (CHANGELOG.md L106, L242; commit messages; the `docs/planning/epics/complete/E03-*` historical references).

- **[VERIFIED OK] Line-cap budget claims match current state.** build 298, fix 299, setup 287, help 163, upgrade 164, review-plan 92, audit-epic 141, verify-all 80, review 88 (epic says 87 — 1 off), review-epic 64 (epic says 94 — 30 off). Two minor errors:
  - **[REVISE]** Epic line 39 says `review 87/300` — actual is 88. Off-by-one.
  - **[REVISE]** Epic line 39 says `review-epic 94/300` — actual is 64. Off-by-30. This is a meaningful budget-misrepresentation; check if 94 was a transposition of audit-epic's 141 or review-plan's 92.

- **[VERIFIED OK] `.roughly/known-pitfalls.md` is 82 lines, matching AC3.5's claim ("82/80 lines as of v0.1.5 release").** Check 3 will fire on merge as advertised.

- **[VERIFIED OK] The current 4 checks in `.claude/hooks/verify-all.sh` claim** matches what's in the file at L17–40: path drift (`.ruckus/known-pitfalls` in agents/), skill line cap (300), agent word cap (500), HTML comment integrity on agent-preamble. S5's context paragraph names them correctly.

- **[VERIFIED OK] `set -e` is at line 6 and `git rev-parse` is at line 9, unguarded.** S4's bug description is accurate.

- **[VERIFIED OK] 25 historical plans in `docs/plans/`** per `ls | wc -l = 25`. AC5 of S3 (`grep -L … | wc -l` returns 0 on 25 files) is the right shape.

- **[REVISE] `rg -c "Legacy" skills/*/SKILL.md` returns 8 not 9 — but only 8 SKILL.md files report results (review-epic shows 1, setup shows 2, all others 1).** Risk 1 says "returns 8 today." That matches — but the count for the file at `skills/upgrade/SKILL.md` returns 0 (upgrade is the migration tool, not a hard-abort skill; no pre-flight needed). So 8 is correct; just note that `setup` returns 2 because of soft-abort + legacy text, not because of two pre-flight blocks. This is technically accurate but a footnote in the epic might help future readers.

- **[VERIFIED OK] doc-writer.md is 58 lines and Process step 5 currently has the two-part-gate** with both organize-suggestion and test-integration-suggestion as bullet sub-items. S8 AC4's "two-part-gate preserved" claim is verifiable as written. doc-writer also currently references `docs/adr/` (singular, line 24) — a known typo per v0.1.7 candidates list.

### 2. Best practices

- **[POLISH] ADR-011 (S7) does not match the ADR template's section ordering used by ADR-009/008.** Looking at the ADR-009/008 naming pattern (`ADR-009-plan-mode-detection.md`), the proposed filename `ADR-011-skill-flags-as-public-api.md` is fine. AC1 names "Status; Context; Decision; Consequences" — typical four-section ADR format — but ADR-009 in practice may have a slightly different structure. Verify ADR-011 follows the same heading order as ADR-009 before merge (not a blocker; just a consistency check).

- **[VERIFIED] Bidirectional sync comments (S5 AC3.4) are consistent with ADR-003's shared-reference pattern.** The agent-preamble.md pattern is unidirectional (preamble is canonical; agents inline-sync from it). The threshold case is genuinely bidirectional (two consumers, neither canonical) so a different comment shape is correct. The PM resolution OQ8 (signal-source-only) explicitly classifies threshold-`80` as a policy parameter not a signal source — that's the right call. Good treatment.

- **[POLISH] Strictly-additive contract in S8 AC2 is correct but the verify command is unusually narrow.** `git diff agents/doc-writer.md` "shows zero `-` lines outside the addition site" is testable but assumes a single contiguous addition. If the implementer needs to add an HTML-comment marker around the new clause, the diff would technically have `-` lines at the marker boundaries. Suggest rewording: "git diff agents/doc-writer.md shows only `+` lines net within Process step 5; existing steps 1–4 and 6 are byte-identical pre/post-edit." That's what the AC actually wants to enforce.

- **[VERIFIED] Migration patterns cited (v0.1.2, v0.1.4 precedents)** check out via the existing `skills/upgrade/SKILL.md` (164 lines covering two prior migrations). The "3-point structure vs v0.1.4's 10-point" claim in S1 AC3 is plausible at face value but not verified line-by-line. If the planning author isn't certain about the 10-point count, soften to "smaller than v0.1.4's existing migration step."

### 3. Risks

- **[REVISE] Risk 3's "30-day post-merge dogfood window" closure for false-positive accumulation is appropriately honest** about what pre-release verification can't catch. The mitigation explicitly distinguishes pre-release (correctness at merge) from post-release (false-positive accumulation), and names v0.1.7 retrospective as the closure point. This is the right shape. No revision needed.

- **[REVISE] Risk 5's "opportunistic close" pattern is also honest** — the guard only exercises on actual multi-file dogfood writes. The "do not manufacture a pitfall write" instruction is correct. One small gap: the risk register doesn't name what happens if v0.1.6 ships and v0.1.7 dogfood ALSO doesn't exercise the guard. Suggest adding a tail clause: "If two release cycles pass without exercise, promote to a synthetic CI-test story in v0.1.8." Otherwise the risk stays open indefinitely.

- **[QUESTION] Risk 4 (ADR-011 lock-in) names a "Haiku-routing override env var" carve-out but the carve-out is hypothetical.** The risk and mitigation are well-framed, but the rhetorical question is: should ADR-011 ship with a real (or near-future) carve-out example rather than an invented one? If v0.2.0 plan-format-v2 work has surfaced any actual env-var-acceptable case during planning, citing it instead of the hypothetical is stronger. If not, the hypothetical is fine.

- **[REVISE] Risk register has no entry for line-cap budget breach.** The line-cap budget contract is a separate section (lines 35–46), which is the right structural choice. But the risk register's Risk 2 (line-cap under additive pressure) overlaps the contract. Suggest either: (a) remove Risk 2 since the contract is the primary mechanism, or (b) keep Risk 2 but explicitly say "this risk is operationalized via the line-cap budget contract; see lines 35–46." Currently the relationship is implicit.

- **[POLISH] Cross-story risk not surfaced: S5 AC1.1 depends on S1 AC4's "canonical two-form template block" being defined.** S5 lands after S1 per the sequencing table, so this is the right order — but the dependency is more than "S1 must ship first." S5's Check 1 is testing the existence of the canonical block that S1 creates. If S1's AC4 implementation chooses a different canonical block shape than S5's Check 1 expects (e.g., S1 inlines the block per-skill rather than templating it), S5 has no anchor to compare against. Suggest adding to S1 AC4: "canonical block shape is captured as a verifiable artifact (e.g., `tests/fixtures/canonical-preflight-block.txt` or equivalent) so S5's Check 1 can `diff` against it." Right now Check 1 is "sort -u must return 1 line" — that works if the blocks are short enough that "1 unique line under sort -u" is the right shape, but if the canonical block is multi-line, the verify command needs adjustment.

### 4. Overengineering

- **[QUESTION on bundling] S5 bundles 3 separate drift checks into one PR.** The bundling rationale is sound (same file, same mechanics, identical risk profile, one cycle of false-positive validation). The cost of bundling is that all three must be reviewed together; the benefit is sharing the `emit_drift_json` integration and the verification log. Verdict: bundling is the right call. No revision.

- **[QUESTION on bundling] S6 bundles 3 process codifications.** AC1 (no-confirm-during-edit), AC2 (signal-source naming), AC3 (case-dispatch convention) target different artifact types (review-plan SKILL.md for AC1/AC2; CONTRIBUTING.md for AC3). The bundling rationale ("case-dispatch convention is short enough that a separate story risks silent deprioritization") is honest. Verdict: defensible, but consider whether AC3 could ship as a single-PR "convention" story attached to the next pipeline-touching story for free. If you keep the bundle, no change needed.

- **[QUESTION on bundling] S9 bundles 2 CI patches.** Same file, same shape — sound. No revision.

- **[QUESTION] S7 (ADR-011) is ceremony for a principle already proven in S11b-2.** The case for ADR-011 in the epic (anchor for v0.2.0's complexity flag, multi-release discoverability, gives ADR-010 a referenceable foundation) is reasonable but ADR-driven. If the actual readership is "Nick + maybe one collaborator," the discoverability argument is weak. If v0.2.0 will introduce additional user-facing flags and the precedent question will come up multiple times, ADR-011 has compounding value. Given the PM round resolved this iteratively (OQ2), the decision is well-considered — I'd say keep it, but note that the "foundation-shaped, not content-shaped" framing in OQ9 is the right discipline. **POLISH:** AC1's "Status: Accepted" should match whatever phrasing ADR-009/008 use exactly — "Accepted" or "Approved" or another verb.

- **[REVISE] S8 AC1 locks 60+ words verbatim. Is this load-bearing?** The wording-locked clause is detailed enough that a meaningful word change (e.g., "abort the other writes" → "abort remaining writes") would technically violate AC1. The author's intent is clearly "the semantics are locked" rather than "the prose is locked," but as written AC1 reads as prose-locked. Suggest reframing AC1 as: "Multi-file failure-handling clause covers all of [N] semantic points: (a) per-file independent Edit; (b) per-file outcome capture; (c) non-abort on single-file failure; (d) partial-success summary; (e) explicit success/failure naming with reason; (f) never claim full success on partial failure. Wording is implementation-flexible; semantics are AC-locked." Then AC5 (template format) is the place to lock the exact wording — and AC5 already does this for the summary template specifically.

- **[POLISH] S3 AC1's Status block format ("Historical — implemented and merged in commit <SHA> on <YYYY-MM-DD>") may be a cubic-behavior false start.** AC1 fully specifies the block format; AC verification (cubic --json) is a blocking gate that could reject the format. If cubic rejects, S3 doesn't ship until the format is adjusted. The PM-round sequencing decision to land S3 last is the right risk mitigation, but consider whether the verify-against-cubic step should happen earlier (e.g., as a pre-implementation spike at the start of v0.1.6) so the format risk is bounded before the rest of the story body is written. As-is, S3 is appropriately structured but carries non-trivial format-iteration risk.

### 5. Acceptance criteria quality

- **[REVISE] S3 AC2 verify command is unreliable.** `git diff` on the plan file showing "only added lines, no `-` lines" is testable, but the Edit tool's contract is `old_string` → `new_string`, where `old_string` is by definition removed (a `-` line in diff). Even an additive prepend produces a `-` line if `new_string` ≠ `old_string`. The author seems to assume `Edit` with `old_string = "first line"` and `new_string = "Status block\nfirst line"` produces a diff with only `+` lines — but `git diff` will show `-first line` / `+Status block` / `+first line`. Suggested rewording: "git diff shows the plan title line replaced by `[Status block] + [blank] + [original title]`; no other content removed." Or use `diff` with `--ignore-blank-lines` and assert no content removed below the prepended block.

- **[BLOCKER for AC] S1 AC4 verify command is incomplete.** "Define a canonical two-form template block; `diff` each skill's pre-flight section against the canonical block must return zero." The AC needs to specify: (a) where the canonical block lives (file path, or as a heredoc in CONTRIBUTING.md, or as the first occurrence in alphabetical skill order); (b) how `diff` extracts the pre-flight block from each skill (presumably between marker comments like `<!-- pre-flight:start -->`/`<!-- pre-flight:end -->`, but no such markers are mentioned). Without these specifics, S5 Check 1 (which depends on this) has no anchor.

- **[REVISE] S5 AC1.2 / AC2.2 / AC3.2 drift entry format includes literal `\n`** which works in shell echo / printf contexts but may produce literal `\n` in JSON output if the hook's `issues="${issues}- ...\n"` interpolation doesn't expand the escape. Verify the existing 4 checks' format works as expected before committing to this format for the new 3. (The current hook at L19 uses `issues="${issues}...\n"` and emits via `jq -nc --arg m "$m"` — `jq` will not interpret `\n` inside `--arg` as a newline; it'll be literal. So drift entries in the JSON output have literal `\n` strings. This may already be a known quirk, but flag it.)

- **[REVISE] S5 AC1.1 verification ("sort -u must produce 1 unique line") assumes the pre-flight check is exactly one line.** Today's pre-flight checks are multi-line blocks (each skill has a `Legacy` paragraph with context, conditional, and abort prose). The `sort -u` test will count unique LINES, not unique BLOCKS — which means it'll fire false-positive if the same multi-line block is repeated identically across all 7 skills (each line of the block appears 7× → `sort -u` returns N unique lines where N = lines per block). Suggest rewording: extract each skill's pre-flight block (sed range or grep -A context), `md5sum` each, `sort -u` the hashes; expected unique-hash count = 1.

- **[POLISH] S9 AC1 verify command:** "`rg -Fn '$TIMEOUT' scripts/ci-dogfood.sh` returns 3 invocation matches" — `rg -F` treats `$TIMEOUT` as a literal string including the `$`, which is what you want. But the detection block contains the literal text `command -v timeout` (without `$`) so that line will NOT match `$TIMEOUT`. The AC text already calls this out ("internal `command -v timeout` checks are intentionally not asserted against"), but consider also asserting the script does NOT contain unbound literal `timeout` invocations: `rg -Fn '^[[:space:]]*timeout ' scripts/ci-dogfood.sh` returns zero matches.

- **[POLISH] S5 AC6 says "documented in PR description … no formal cap" for verify-all.sh line count.** Current hook is 58 lines; S5 projects "~75 lines." Consider adding a soft cap (e.g., 150) so the hook doesn't grow unbounded over future releases — this matches the SKILL.md 300-line cap discipline.

- **[VERIFIED OK] S8 AC5's locked summary template format is specific, testable, and includes failure reason.** Good shape.

- **[VERIFIED OK] S6 ACs each have named canonical positive AND negative examples** — this is unusually disciplined. AC5 explicitly requires it. Good.

### 6. Dependencies

- **[BLOCKER for sequencing] Sequencing-table position vs Depends-on lines disagreement for S2.** The sequencing table row 7 says "S2 depends on S1." Story body Dependencies says "E04.S1 must ship first." Consistent. **But the table also says rows 1–4 (S4, S6, S7, S8) are mutually independent and independent of S1; rows 6–9 depend on S1.** That implies row 5 (S1) gates rows 6–9. Verify: S2 (row 7), S5 (row 8), S3 (row 9), S9 (row 6) — all four. Yes, all four list S1 as a dependency. Internally consistent. The remaining question is: does row order 6→9 reflect required sequencing (S9 → S2 → S5 → S3) or just convenience? S9 has "recommended after S1" (convenience); S2/S5/S3 each have hard "must ship first" relationships on S1. So row 6 (S9) could in principle land before row 5 (S1) — but only if the path update in S1's CI script is staged separately. The sequencing table's narrative is ambiguous here; either reorder so S9 follows S1 (and label it that way explicitly) or move S9 above S1 with a footnote.

- **[REVISE] S5 depends on "S1 + S4" per sequencing table, but S5's story body lists both as hard dependencies.** Verified. The story body says "S4 must ship first" and "S1 must ship first." Consistent. No revision — but the critical-path note ("S1 → S2 → (S5 if S4 not yet merged) → S3") is slightly misleading: S5 is gated on S4 unconditionally per the story body, not conditionally per the critical-path note. Either reword the critical path to "S1 → S2 → S5 (after S4) → S3" or relax the story-body dependency to match the conditional framing.

- **[QUESTION] S3 (plan self-marking) lands last "because the cubic-behavior blocking gate may force iteration."** This is defensible — the cubic-format-iteration risk is real, and landing last keeps it off the critical path. But consider: if S3 fails the cubic gate, the rest of v0.1.6 ships without plan-self-marking, and S3 becomes a v0.1.7 carry-forward. That's an acceptable outcome (the risk register doesn't list cubic-format-rejection as a Risk 6). Optional: add a Risk 6 entry "S3 cubic-behavior blocking gate may force defer to v0.1.7; mitigation: format iteration is the story-body fallback, with `<!-- CUBIC-IGNORE -->` markers as the named alternative." Currently the cubic-format-iteration trade-off is buried in the AC, not surfaced as a risk.

- **[REVISE] DoD checklist mentions "All 9 stories merged" but does not specify "Risk 3 / Risk 5 may close post-release."** The DoD has bullets for Risk 3 and Risk 5 acknowledgments, but the wording "All 9 stories merged" implies all-or-nothing. If S3 defers to v0.1.7 per the cubic gate, the DoD as written cannot be satisfied. Suggest: "All 9 stories merged OR S3 explicitly deferred to v0.1.7 with reason recorded in the v0.1.6 retrospective." This matches the PM-round's iterative resolution discipline.

---

## Prioritized recommendations

1. **[BLOCKER]** S1 AC4 needs the canonical-block storage location + extraction mechanism specified — both S1 implementation and S5 Check 1 depend on this anchor existing.
2. **[BLOCKER]** S1 needs explicit carve-out for CHANGELOG.md L106 / L242 (historical references that must not be migrated). Add to AC1 prose or as new AC1a.
3. **[REVISE]** Risk register counts: "16-ish" → "15" (or footnote the discrepancy); review 87 → 88; review-epic 94 → 64. The 30-line review-epic gap is the most important correction.
4. **[REVISE]** S3 AC2 verify command doesn't match `Edit` tool semantics — reword to "title line replaced by status-block + blank + title" with no other deletions.
5. **[REVISE]** S5 AC1.1 sort-u test assumes single-line pre-flight blocks; current blocks are multi-line. Switch to md5sum-of-extracted-block.
6. **[REVISE]** S8 AC1 60-word lock is over-specified; switch to semantic AC + keep AC5's template lock.
7. **[REVISE]** Critical-path note "S1 → S2 → (S5 if S4 not yet merged) → S3" should reflect S4 as unconditional, not conditional.
8. **[POLISH]** Add tail-clause to Risk 5 covering "two release cycles without exercise → promote to synthetic CI-test."
9. **[POLISH]** Add explicit Risk 6 covering S3 cubic-gate-rejection → defer-to-v0.1.7 path; update DoD to allow this branch.
10. **[QUESTION]** Verify ADR-011 (S7) header structure against actual ADR-009 to ensure consistency before merge; consider citing a real env-var carve-out case rather than hypothetical Haiku-routing.

The epic is well above the bar for "implementation-ready after a localized revision pass." Most findings here are AC-precision adjustments that the implementing subagent will encounter and probably resolve in-flight; surfacing them now turns silent in-flight resolution into explicit pre-cut decisions.

---

## Files used to verify claims

- `docs/planning/epics/E04-path-consolidation-and-process-codification.md`
- `.claude/hooks/verify-all.sh`
- `agents/doc-writer.md`
- `skills/*/SKILL.md` (line counts)
- `docs/adrs/` (ADR-001 through ADR-009)
- `.roughly/known-pitfalls.md` (82 lines confirmed)
- `docs/plans/` (25 plans confirmed)
- `CLAUDE.md` (ADR-001 through ADR-009 in table)
- `CHANGELOG.md` (L106, L242 historical references)
- `scripts/ci-dogfood.sh` (L153, L156 confirmed)
- `skills/setup/templates/` (hook templates confirmed)
