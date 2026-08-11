# E07 — Codification close-out + release-gate repair

**Target version:** v0.1.9 · **Target effort:** ~6–8 days engineering + 3–6 paid dogfood dispatches (~$30–$60 at the verified $10.05/run — 3 to E07.S2 Phase 1, plus 3 reserved proving runs that execute only if Phase 1 reaches green; see S2.AC1) · **Status:** SCOPED — freezes v0.1.9. Revised 2026-07-30 per `/roughly:review-epic` ([review](E07-codification-closeout-and-release-gate-repair-review.md)); corrected 2026-08-10 (Phase 2 predecessor set, dispatch-budget allocation, harness invocation count, issue-brief refresh rule).

**Depends on:** E06 (codification carry-forward; the E06 `## v0.1.9 candidates` block is this epic's scope source) · E05 (Risk 1, Risk 2 windows) · E04 (Risk 3, Risk 5 windows).

## Release thesis

v0.1.9 is a close-out, not a feature release. Its declared scope shipped across PRs #88 / #90 / #91, and what remains is two conventions, one intake guard, and a contract cleanup. **The release is evidence-gated, and the evidence apparatus has not produced a green run since the pipeline scenarios landed.** The dogfood workflow has 6 successes all-time — all on 2026-05-08, against the E03.S11a scaffolding that predates the real scenarios — against 138 failures. Its last executed run (2026-07-18) died in 11 seconds on `Credit balance is too low`; the run before it (2026-07-17, on `main`) died on the plugin-load probe's model-enumeration false-negative. #66 repaired that probe two days after the credit ran out, so the repair has never executed against a funded key. #66 also removed the `push:` trigger, so nothing produces a run on `main` any more without a manual dispatch.

E07 therefore treats the evidence track as the work, not the footnote: repair the harness diagnostics, dispatch deliberately against `main`, and record each of the five inherited risk windows as CLOSE or CARRY with the evidence that actually exists. The three feature stories are parallel and gate nothing.

## Reconciliation

**Shipped — verified closed on `main` (tip `121ea6b`), not re-planned:** Cluster A #81–#86 (PR #90) · #87 known-pitfalls reorg (PR #90) · #80 ruckus cleanup (PR #88) · #89 OQ-resolution enforcement (PR #91) · #72 → ADR-019 spec-candidate escalation · #73 `--ci` marker-primary reframing (closes the ROADMAP v0.1.8 out-of-scope item "`--ci` 'exits non-zero' aspirational-language reframing") · #74 known-pitfalls threshold 80→300. No open GitHub issues remained from the pre-E07 backlog when this reconciliation was taken (2026-07-30). E07's own stories and deferred stubs were filed as #93–#102 (stories #93–#99 on 2026-08-07; stubs #100–#102, the last on 2026-08-10) and are open by design — see `## Story tracking`.

**In scope:** B2 granularity guard (S6) · 3a intra-epic AC amendment codifier (S4) · residual verdict-persistence + `--ci` NEEDS-REVISION parity (S5) · CHANGELOG backfill (S3) · dogfood harness diagnostics + validation (S1) · risk-window disposition (S2) · tag-prep (S7).

**Out of scope, wholesale:** B3 external issue-tracker intake (v0.1.10 — see stubs) · the differential-gate spec set including Spec 1 gate-log · DI-001 systematic pitfall-into-briefs pass · epic→story decomposition loop · review-epic / audit-epic external-fetch wiring · fix-side negative-path CI scenarios (would add paid scenarios to a harness that has not produced a green) · install-marker producer generalization.

## Risk register

**R1 — The 6 pipeline scenarios have not executed since 2026-06-10 — but the regression surface is narrow and identified.** The plugin-load probe is repaired (`6405652`) but unvalidated against a funded key, and everything downstream of it — build, fix, build-abort, build-abort-control, plan-revision, plan-clean — has been dark for seven weeks while `skills/build/SKILL.md` and `skills/fix/SKILL.md` accumulated the #66–#91 changes.

Two measurements taken at review time (2026-07-30) bound this risk more tightly than "seven weeks dark" implies:

- **The scenario contracts did not drift.** Every marker string the harness asserts — `[--ci] plan review verdict: PASS` / `… NEEDS REVISION` and `cannot proceed: auto-fix cap reached on` — is byte-unchanged since the last green base `94ba772`. `git diff 94ba772 main -- skills/build/SKILL.md | grep -c 'auto-fix cap reached'` returns **0**; #73's reframing changed narrative wording ("exit non-zero" → "halt — that marker is the CI signal"), not asserted text.
- **The live surface is concentrated.** 31 changed lines per pipeline file, of which the behaviorally-new part is `${CLAUDE_PLUGIN_ROOT}` runtime-`Read` directives going **1 → 4** in each file (gate-protocol, stage-8-wrap-up, spec-candidate-escalation joined abort-handling). That is what has never executed in CI, and `6eaa04a` (#67) already repaired this exact class once without CI validation.

The first funded dispatch is still a discovery run, not a proving run, and each defect it surfaces costs another ~$10 dispatch to re-test. *Mitigation:* S1 lands diagnostics that make a failed dispatch legible on first read; S2 classifies discovery findings by the Class A/B/C rule in its AC1 and carries a hard 6-dispatch / ~$60 ceiling, CARRYing rather than burning the release window if the scenarios do not converge.

**R2 — B2's detector false-positives on Roughly's own documented input format.** [README.md:180-201](../../../README.md) documents "Epic files" as a first-class `/roughly:build` input with a worked **two-story** example, which the S6.AC1 detector flags. A guard that flags "a file enumerating multiple child stories" therefore contradicts the manual. *(Corrected at review: the [README.md:41-50](../../../README.md) Quick Start heredoc contains only **one** story and would **not** trip the detector — the earlier "multi-story Quick Start" framing was wrong, and S6.AC4 no longer directs an edit there.)* *Mitigation:* S6's AC set requires the README correction to land in the same story as the detector — the guard and the docs it contradicts are one change, not two.

**R3 — Line-cap collision in `skills/fix/SKILL.md`.** At 286/300 with 14 lines of headroom, and two E07 stories add prose to it (S5 at Stage 4, S6 at Stage 1), cumulatively ~8–12 lines. `skills/build/SKILL.md` at 281/300 has the same exposure. Whichever story merges last may find the headroom consumed. *Mitigation:* S5 and S6 each carry an ADR-012 extraction off-ramp in their ACs, and S5 (the smaller delta) sequences first so S6 inherits a known budget rather than the reverse.

**R4 — Two of the codifier's four named back-application targets are moot.** E06.S5 W1 (scope-naming ambiguity) and W2 (missing evidence-artifact language) were substantially resolved by #72's extraction to `skills/shared/spec-candidate-escalation.md`: the two Stage 6 paragraphs now route to one named procedure, the cubic paragraph carries an explicit scope preamble, and the shared reference states "the appended entry is the evidence" — W2's exact ask. Their cited locations (build L205 / fix L208) no longer hold that prose. An implementer applying the E06 candidates block mechanically will edit text that moved. *Mitigation:* S4 replaces those two amendments with two verified close-out annotations, specified in its ACs.

**R5 — CHANGELOG backfill is written ~3 weeks post-merge from PR diffs, not build context.** The E06 audit found an inaccurate word-count claim in an entry written *with* fresh context (S1's 649→649 vs actual 649→647). Eight issues' worth of entries reconstructed cold will be worse. *Mitigation:* S3 sequences first, while the PRs are the most recent thing in the log, and its ACs require each entry to cite the merging PR and name the files it touched so claims are checkable against the diff.

## Story tracking

Each story is filed as a GitHub issue carrying a self-contained implementer brief. **This epic remains canonical for acceptance criteria** — the issues summarize and link, they do not duplicate AC text. If an issue and the epic disagree, amend the epic; a second normative source is the drift class E07.S4 exists to codify against.

**Refresh obligation.** Precedence alone is not enough — it resolves a conflict already noticed, and does nothing to surface one. So: **when an epic change alters a story's scope, sequencing, files touched, or budget, the issues it invalidates are re-synced as part of the same change-set — before the epic commit is pushed — and the commit message names them.** A GitHub edit cannot literally be inside a Git commit, so the convention cannot be enforced by the commit boundary; make staleness *detectable* instead. **Each issue brief ends with the short SHA of the epic commit it was derived from, and the `## Story tracking` table records the same SHA per row.** A brief whose stamp is behind the epic's last content-changing commit is presumed stale, and `git log --oneline <stamp>..HEAD -- <epic path>` shows exactly what it missed. This is a convention with a check, not an automated gate — no CI enforces it. An issue that is merely summarizing stays as-is; an issue whose *instructions* have changed is stale the moment the epic lands without it. This rule exists because the pattern drifted on its first exercise: the 2026-08-10 corrections invalidated the harness invocation count in #94 and #95, the Phase 2 predecessor set in #95, and #98's claim that S4 gates Phase 2 — all three had to be re-synced by hand. Treat a stale brief as a defect in the epic's own convention, not as a stale ticket.

| Story | Issue | Brief derived from | Wave | Constraint |
|---|---|---|---|---|
| E07.S3 — CHANGELOG backfill + heading revert | [#93](https://github.com/nickkirkes/roughly/issues/93) | `3f5a0ce` | 1 | Before every other story (rewrites the heading their entries land under) |
| E07.S1 — Dogfood harness diagnostics | [#94](https://github.com/nickkirkes/roughly/issues/94) | `3f5a0ce` | 2 | After S3 |
| E07.S2 **Phase 1** — discovery dispatch | [#95](https://github.com/nickkirkes/roughly/issues/95) | `3f5a0ce` | 3 | Opens once S1 merges; **runs concurrently with wave 4** |
| E07.S5 — Stage 4 contract | [#96](https://github.com/nickkirkes/roughly/issues/96) | `3f5a0ce` | 4 | After S3; before S6 (line budget, R3) |
| E07.S6 — Granularity guard + ADR-021 | [#97](https://github.com/nickkirkes/roughly/issues/97) | `3f5a0ce` | 4 | After S5 |
| E07.S4 — Intra-epic AC codifier | [#98](https://github.com/nickkirkes/roughly/issues/98) | `3f5a0ce` | 4 | Unordered within the wave; **optional** — first cut if the dispatch budget compresses |
| E07.S2 **Phase 2** — 3 proving runs | [#95](https://github.com/nickkirkes/roughly/issues/95) | `3f5a0ce` | 5 | After S1, S5, S6 have merged (AC1's predecessor set). S4 not required |
| E07.S7 — Tag-prep wrap | [#99](https://github.com/nickkirkes/roughly/issues/99) | `3f5a0ce` | 6 | Last; after S2's disposition is recorded |

Deferred: [#100](https://github.com/nickkirkes/roughly/issues/100) (B3, v0.1.10) · [#101](https://github.com/nickkirkes/roughly/issues/101) (DI-001, v0.2.0-adjacent) · [#102](https://github.com/nickkirkes/roughly/issues/102) (ADR-009/010 cleanup, v0.2.0) — all three briefs derived from `3f5a0ce`, same as the story rows above.

**Wave** groups stories that may proceed concurrently; **Constraint** states the actual dependency. Waves are a partial order, not a queue — everything in wave 4 is unordered except S5-before-S6, and S2 Phase 1 (wave 3) overlaps all of wave 4 rather than blocking it. `# Sequencing` holds the authoritative graph; this table summarizes it. *(Replaced a single integer "Sequence"/"Dispatch order" column 2026-08-10. Integers implied a total order that contradicts the overlap — and read as paid-dispatch numbering besides, making S2's "7" look like a seventh dispatch against a six-dispatch budget. Paid dispatches are counted only in E07.S2.AC1.)*

**Brief derived from** is the staleness check. **Scope is that story's own section *plus* the epic's shared normative sections** — not the epic's overall tip (too broad: every row goes stale on any change), and not the story section alone (too narrow: it misses policy that governs the story from outside it). *(Both errors were made in turn — global watermark 2026-08-10, then section-only in the same day's correction. This is the scope that is actually right.)* The shared sections are `# Sequencing`, this `## Story tracking` block, the `## Risk register`, and E07.S2.AC1's class table and dispatch budget — a change to any of them can alter a story's ordering, scope, or cost without touching its section, and re-stamps **every** brief it governs. To check one row: `git log --oneline <sha>..HEAD -- <epic path>` for candidates, then `git diff <sha>..HEAD -- <epic path>` and look for changes inside that story's `## E07.SN` block; changes confined to other stories do not make this brief stale. **Re-stamp only the rows whose story actually changed** — bumping every row on every commit destroys the signal. *(Corrected 2026-08-10: a single global watermark marked all ten briefs stale on any change to any one story. The stamps have moved as the scope rule intends: uniform at `0e27c40` (that commit touched every story), then diverging to `1933bfb` for S2 and S6 alone when only those two sections changed, then uniform again whenever a commit edits this shared block — which re-stamps every brief it governs. **Read the table for the current values; this sentence describes the pattern, not the present state.** Divergence is normal and expected; uniformity means a shared section moved.)* **A change to this table's `Wave` or `Constraint` cells does advance the stamps it affects** *(corrected 2026-08-11)*. Those two columns are normative — they state dependencies — so a table-only edit can alter a story's sequencing while leaving its brief untouched. The earlier carve-out ("commits that only touch this table do not advance any stamp") was written when the table held nothing but issue links and a cosmetic order number; making `Wave`/`Constraint` normative invalidated it, and the exemption was not revisited. Only the non-normative columns are exempt: the issue link and the `Brief derived from` cell itself, so a re-stamp commit does not immediately re-stale everything it just stamped.

---

# Track A — Release-gate repair (critical path)

## E07.S1 — Dogfood harness diagnostics + local validation

**Maps to:** E06 Risk 3 dogfood gate (unblocking) · **Issue:** [#94](https://github.com/nickkirkes/roughly/issues/94)

**Files touched:** `scripts/ci-dogfood.sh` · `docs/runbooks/dogfood-ci.md` · `.roughly/known-pitfalls.md` · `CHANGELOG.md`

**Acceptance criteria**

- **AC1 — Account-state failures are distinguishable from code failures.** The smoke-step failure ladder in `scripts/ci-dogfood.sh` (L77–86) currently emits `FAIL — smoke step claude exited $SMOKE_EXIT` and dumps output, so `Credit balance is too low` reads identically to a genuine pipeline regression. Add a classification branch that detects account-state failures (insufficient credit, invalid/revoked key, rate limit) in the captured output and emits a distinct marker — `ci-dogfood: FAIL — API account state: <classification>` — naming the condition and stating that no Roughly behavior was exercised. Applies to the smoke step and the plugin-load step. Verify: inject each condition via a stubbed `claude` on `PATH` and assert the account-state marker fires, and that a non-account non-zero exit still produces the existing generic ladder.
- **AC2 — Plugin-load probe validated against a funded key.** The probe at L105–131 was repaired in `6405652` after the 2026-07-17 false-negative but has never executed with credit available. Run it locally via `claude --bare --plugin-dir <repo>` against a funded key and capture the output in the CHANGELOG entry. Pair it with a negative control: the same probe against `--plugin-dir` pointed at a directory containing no `skills/`, which must FAIL. Both arms required — structural assertion plus behavioral control, per the `## CI conventions` behavioral-assertion rule shipped in #82.
- **AC3 — `docs/runbooks/dogfood-ci.md` states which trigger produces a run on `main`.** Scoped narrowly at review: the runbook's `## When to run it` (L7–17) **already** documents both trigger paths including `workflow_dispatch`, and `## Cost` (L18–28) **already** carries the per-step budget table derived from the script ($0.05 / $1.00 / 6 × $1.50) — neither needs rewriting. Two gaps remain, and only these two are in scope: **(a)** neither section states that the `ci:dogfood` label path produces **PR-ref runs only**, so `workflow_dispatch` is the sole route to a `main` run — the fact the entire Risk 3 track depends on; **(b)** the cost table has no total row, leaving the $10.05 ceiling as unstated arithmetic. Add both. Do not restate or re-derive the trigger list or the per-step budgets.
- **AC4 — The E06 Risk 3 counter mechanics are written down.** Add a `## Risk 3 consecutive-green accounting` section to the runbook covering three things: what resets the counter, what a qualifying run is (a `workflow_dispatch` against `main` that reaches a green `dogfood-build-cycle` conclusion), and where the count is recorded. Without this the counter is re-derived by memory every release, which is how it reached 0 unnoticed.

  **State the reset rule as the canonical criterion, not as a file list** *(corrected 2026-08-07 — an earlier draft of this AC enumerated "the workflow, `scripts/ci-dogfood.sh`, or the fixtures," which is narrower than the criterion it was transcribing and silently dropped the largest input class)*. [docs/ROADMAP.md:202](../../ROADMAP.md) and the E06.S3 close criterion both read: *"Counter restarts after every `main` change touching the workflow **or its inputs**."* The runbook must reproduce that scope. **The pipeline skill bodies are inputs** — `scripts/ci-dogfood.sh` invokes the pipelines six times (five `/roughly:build`, one `/roughly:fix`), so a change to `skills/build/SKILL.md`, `skills/fix/SKILL.md`, or any `skills/shared/*.md` they `Read` at runtime changes what the scenarios execute and resets the count. Enumerating an input list here recreates the closed-world-vs-enumerated-list failure `CLAUDE.md` warns about; write the rule so it covers inputs added later, and give the current membership only as a non-exhaustive illustration.
- **AC5 — No new paid scenarios.** `scripts/ci-dogfood.sh` scenario count stays at 6; no new `claude` dispatches added. Verify: `grep -c 'max-budget-usd 1.50' scripts/ci-dogfood.sh` = 6.
- **AC6 — Pitfall captured + CHANGELOG entry.** Add a `.roughly/known-pitfalls.md` entry under the CI domain for the class this story fixes: a paid CI harness whose first failure rung collapses account-state and code failures into one message will read as a code regression for as long as the account is broken. Cross-reference the existing L28 entry on `set -e` assertion masking — same family, different rung.

**Verification.** Everything in this story is verifiable locally, with no dogfood dispatch. Cost: the AC1 stub injections are free; AC2 needs the plugin-load probe run twice (positive arm + negative control) at its $1.00 budget cap each, plus one smoke session — **~$2 floor, ~$2.05 ceiling**. `bash .claude/hooks/verify-all.sh` clean.

**Precondition:** `ANTHROPIC_API_KEY` funded (confirmed 2026-07-30). AC2 cannot execute without it; AC1, AC3, AC4, AC5, and AC6 can.

**Dependencies:** E07.S3 for the AC6 CHANGELOG entry only (S3 reverts the section heading this entry lands under — see S3). No functional dependency. First story in the epic otherwise.

**Out of scope for this story.** Running the dogfood workflow (S2). Fixing anything the 6 pipeline scenarios surface (S2). Re-adding a `push:` trigger — the label gate exists because per-push dogfooding is what exhausted the account; it stays.

---

## E07.S2 — Risk-window disposition: dispatch, assess, record

**Maps to:** release-gating DoD (all five windows); E06 Risk 3 dogfood gate · **Issue:** [#95](https://github.com/nickkirkes/roughly/issues/95)

**Files touched:** `CHANGELOG.md` · `docs/ROADMAP.md` (v0.1.8-retrospective DoD checkboxes) · `docs/planning/epics/complete/E04-path-consolidation-and-process-codification.md` · `docs/planning/epics/complete/E05-doc-writer-hardening-and-spec-quality-gates.md` · `docs/planning/epics/complete/E06-anchoring-closure-and-ci-coverage.md` (risk-register status annotations) · `docs/runbooks/dogfood-ci.md`

*Conditional — only if AC1's discovery dispatch surfaces an in-scope defect:* `skills/build/SKILL.md`, `skills/fix/SKILL.md` (Class A `${CLAUDE_PLUGIN_ROOT}` runtime-`Read` directives only — Class C stage-logic changes are explicitly out of scope) · `skills/shared/gate-protocol.md` (Class B) · `scripts/ci-dogfood.sh`, `tests/fixtures/**`, `.github/workflows/dogfood.yml` (harness-side, per the E06.S3 bundling precedent).

**Acceptance criteria**

- **AC1 — E06 Risk 3: dispatch, iterate, then call it. The story runs in two separated phases.** *(Phase split added 2026-08-07; the AC previously read as one continuous dispatch sequence, which would have produced an invalid CLOSE — see the sequencing note below.)*

  **Phase 1 — discovery, early.** Dispatch the dogfood workflow against `main` via `workflow_dispatch` as soon as S1 merges. Its purpose is to find out what seven weeks dark actually broke, classify it A/B/C/H per the table below, and land the in-scope repairs. Green here is welcome but does not count toward the gate — any subsequent pipeline-touching merge would reset it.

  **Phase 2 — proving runs, last.** Run three dispatches against `main` with no intervening change to the workflow or any of its inputs. Only these three count.

  **Predecessor set — E07.S1, E07.S5, E07.S6** *(named exactly, corrected 2026-08-10; an earlier draft said "every other E07 story," which was both cyclic and over-broad — it swept in S7, which depends on this phase, and imposed a constraint on S3/S4, which do not touch inputs at all)*. The set follows mechanically from the reset rule: S1 edits `scripts/ci-dogfood.sh` (the harness itself), S5 and S6 edit `skills/build/SKILL.md` and `skills/fix/SKILL.md` (scenario inputs). **S3 and S4 are not gating** — S3 writes only `CHANGELOG.md`, S4 only docs and the E06 epic; neither resets the counter, though landing both first is still preferable so nothing rebases mid-phase. **S7 is explicitly excluded** and runs after: it is downstream of this story's disposition, and its `plugin.json` version bump is a manifest change with no effect on pipeline behavior, so it is not a behavioral input and does not invalidate a CLOSE recorded before it. **CLOSE** on 3 consecutive green; **CARRY to v0.1.10** otherwise, recording the count reached, the failing scenario, and the diagnosis. A third disposition, **BLOCKED-NO-EVIDENCE → CARRY**, applies if dispatches cannot execute at all (key depletion mid-story — the 2026-07-18 `Credit balance is too low` failure is the precedent); record it across the same surfaces as any other CARRY, with the stub naming key funding as the gating action. All three outcomes are acceptable ship states — the tag is gated on a *recorded disposition*, never on CLOSE.

  **Discovery scope is bounded by class** (resolved at review 2026-07-30; supersedes an earlier unbounded "whatever the scenarios surface is in scope" framing, which authorized open-ended pipeline repair inside a close-out release):

  - **Class A — shared-reference / `${CLAUDE_PLUGIN_ROOT}` path resolution under `--bare --plugin-dir`.** **IN SCOPE.** The highest-probability failure: 3 of the 4 runtime-`Read` directives in each pipeline file are new since the last green run, and a resolution failure kills every scenario at the first gate. Mechanically fixable across 4 directives × 2 files; `6eaa04a` (#67) is the precedent repair.
  - **Class B — gate-protocol prose behavior under `CI_MODE`.** **IN SCOPE.** `skills/shared/gate-protocol.md` Rule 4 already specifies "render no header block and ask nothing," so the contract exists; the risk is gate-sequencing drift introduced by the extraction. Prose repair in one shared file.
  - **Class C — stage-logic regression in `skills/build/SKILL.md` or `skills/fix/SKILL.md`** (subagent dispatch, stage sequencing, Stage 5c cap semantics). **CARRY with a v0.1.10 stub, unless the human explicitly rescopes at that point.** Unbounded by nature; this is the class that breaches the ceiling.
  - **Class H — harness-side defects** in `scripts/ci-dogfood.sh`, the fixtures, or `.github/workflows/dogfood.yml`. **IN SCOPE** per the E06.S3 precedent (modifications discovered during scenario execution bundle with the run that surfaces them). *(Promoted to a named class 2026-08-10 — it was previously an unlettered trailing bullet, so the budget's "Class A/B repairs" allowance did not visibly cover it and a harness defect had no stated retry rule.)*

  **Budget: 6 dispatches / ~$60 total, allocated per phase** *(re-allocated 2026-08-10 — the ceiling was authored before the phase split, as a flat cap over one undifferentiated sequence. Applied flatly it contradicts the CLOSE rule: if Phase 1 spent all three, the proving runs are dispatches 4–6, and reaching 6 with three greens satisfies "CLOSE on 3 consecutive green" and "CARRY on reaching the ceiling" simultaneously)*:

  - **Phase 1 is capped at 3 dispatches** — one discovery plus up to two re-dispatches, available for a repair of **any IN-SCOPE class (A, B, or H)**. The allowance is keyed to disposition, not to a class letter: if a class is IN SCOPE its repair may consume a re-dispatch. **Exhausting this cap without reaching green is the CARRY trigger**, and it is the only spend-based one.
  - **Phase 2's three proving runs are reserved, not unconditional.** "Reserved" means Phase 1 cannot spend them — it does **not** mean they always execute. They are what CLOSE is measured on, so the budget must never be able to consume them.

  **Control flow between the phases** *(specified 2026-08-10 — the prior wording made Phase 1 exhaustion a CARRY trigger and Phase 2 "always funded" without saying whether Phase 2 still runs, leaving both the final disposition and the paid-dispatch count ambiguous)*:

  - **Phase 1 reaches green → Phase 2 runs.** Three proving runs; CLOSE on three consecutive green, CARRY otherwise. Total spend **4–6 dispatches** — Phase 1 costs at least its one discovery run, so the floor is 1 + 3, not 0 + 3. *(Corrected 2026-08-10 from an erroneous "2–6," which undercounted the discovery dispatch and contradicted the 3–6 envelope in the header.)*
  - **Phase 1 exhausts its 3-dispatch cap without green → CARRY, and Phase 2 does not run.** The proving runs exist to demonstrate a *stable* green; there is nothing to prove when the scenarios have not gone green once. This CARRY is **terminal for v0.1.9** — it is not provisional and Phase 2 cannot supersede it, because Phase 2 never executes. Total spend is exactly 3 dispatches (~$30), not 6.
  - Either way the disposition is recorded per AC5, and E07.S7 proceeds — the tag is gated on a recorded disposition, never on CLOSE.

  Total stays 3 + 3 = 6 / ~$60 at the verified $10.05/run. Class C is the only class with no retry allowance — it CARRIES by default precisely because it is unbounded, and rescoping it is a decision made with evidence rather than a commitment made here.
- **AC2 — E04 Risk 3 (stop-hook drift, 30-day window elapsed).** Assess false-positive accumulation on `main`: the drift check has run on every Stop event across the #66–#91 bundle. Zero false positives → CLOSE. Any → CARRY with the mitigation-tightening candidate promoted to the v0.1.10 stub list. **Method (required, not optional — "cite the evidence, not a recollection" needs a procedure):** enumerate the change set with `git log --oneline 94ba772..main`, then run `bash .claude/hooks/verify-all.sh` against the current tree and record its drift-check output verbatim. State the method used and its result; a bare assertion of "zero false positives" does not satisfy this AC.
- **AC3 — E05 Risk 2 (off-ramp shared-reference Check 8 drift, 30-day window elapsed).** Same shape as AC2 against Check 8, using the same method and the same record-the-procedure requirement. Zero false positives → CLOSE; any → CARRY with either the Check 8 mechanic tightening or a per-skill carve-out named as the v0.1.10 candidate.
- **AC4 — E05 Risk 1 and E04 Risk 5 both depend on AC1's outcome.** Risk 1 (doc-writer runtime-cache T2 confirmation) and Risk 5 (real-dogfood multi-file doc-writer exercise) can only close on evidence a green dogfood run produces. If AC1 CARRIES, both CARRY — state that dependency explicitly rather than asserting an independent assessment. If AC1 CLOSES, inspect the run transcripts for a multi-file doc-writer invocation; an E06.S1 T2 synthetic re-run does **not** satisfy Risk 5.
- **AC5 — Dispositions are recorded on four surfaces, consistently.** Each of the five windows gets: **(1)** a CHANGELOG line under the v0.1.9 section stating CLOSE or CARRY with its evidence; **(2)** a checked or annotated box in the ROADMAP v0.1.8-retrospective DoD list ([docs/ROADMAP.md:199-203](../../ROADMAP.md)); **(3)** a status annotation on the originating epic's risk-register entry; and **(4)** for every CARRY (including BLOCKED-NO-EVIDENCE), a corresponding entry in this epic's `## v0.1.10 candidates` section naming what would close it. A window recorded on one surface and not the others is the failure mode this AC exists to prevent — verify as one pass: five windows × four surfaces, all agreeing.

**Verification.** Paid, and the total depends on the outcome: **Phase 1 is capped at 3** (1 discovery + up to 2 re-dispatches for any IN-SCOPE class A/B/H). If it never reaches green, spend stops at **3 dispatches / ~$30** and the disposition is a terminal CARRY — Phase 2 does not run. If it reaches green, Phase 2's **3 reserved proving runs** follow, for **6 / ~$60** at the verified $10.05/run. See AC1 for the allocation and the control flow. The disposition record itself is verifiable by inspection — for each of the five windows, the four surfaces named in AC5 must state the same outcome.

**Precondition:** `ANTHROPIC_API_KEY` funded (confirmed 2026-07-30). On mid-story depletion, AC1's BLOCKED-NO-EVIDENCE disposition applies rather than an open-ended stall.

**Dependencies.** *Phase 1 (discovery):* E07.S1 (its diagnostics are what make a failed dispatch legible); E07.S3 for the AC5 surface-1 CHANGELOG lines. Begin as soon as S1 merges — this is the long pole, and a dispatch that surfaces defects needs runway before tag. *Phase 2 (proving runs):* **the predecessor set named in AC1 — E07.S1, E07.S5, E07.S6 — and only those.** AC1 is the single source for that set; do not restate it here or in the Sequencing section. S3/S4 are non-gating and S7 is excluded (it depends on this story). This story therefore opens early and closes last.

**Out of scope for this story.** Feature work of any kind. Adding scenarios. Class C stage-logic repair absent an explicit human rescope (AC1). Closing a window on evidence that does not exist — CARRY is the correct answer when the evidence is absent, and an honest CARRY beats a green asserted from a synthetic re-run.

**Note on file contention.** AC5 surface 3 annotates the risk registers inside `docs/planning/epics/complete/E04-*.md`, `E05-*.md`, and `E06-*.md`. E07.S4 also writes to the E06 file (its deviation notes and `## v0.1.9 candidates` block). Different sections, so no correctness conflict — expect a rebase if the two stories land close together.

---

# Track B — Codification finish (parallel; gates nothing)

## E07.S3 — CHANGELOG v0.1.9 backfill + heading revert

**Maps to:** tag-prep DoD (front-loaded) · **Issue:** [#93](https://github.com/nickkirkes/roughly/issues/93)

**Files touched:** `CHANGELOG.md`

**Acceptance criteria**

- **AC1 — Heading reverted to the pre-tag form.** `CHANGELOG.md:3` currently reads `## [0.1.9] — 2026-07-27`: renamed early, against the DoD's "rename at tag time" rule, and dated two days *before* PRs #90 and #91 merged. Revert to `## [Unreleased] — v0.1.9`, matching the E06 post-audit precedent (Rec 2, 2026-06-10, where the identical premature rename was reverted for v0.1.8). Verify: `grep -c '^## \[Unreleased\] — v0.1.9' CHANGELOG.md` = 1.
- **AC2 — #81–#86 entries written.** The v0.1.9 section records only #80. Add entries for the Cluster A CONTRIBUTING bundle delivered by PR #90 — #81 verified-tag provenance, #82 CI assertion authoring, #83 spec-example command validation, #84 mirror-verbatim + negative-grep self-test, #85 CI job-key naming, #86 OQ-resolution annotation — under `### Added`. Each entry names the sections it created or extended in `CONTRIBUTING.md` and cites PR #90.
- **AC3 — #87 and #89 entries written.** #87 (known-pitfalls navigability reorg, PR #90) and #89 (`agents/code-reviewer.md` Process step 8 OQ-resolution enforcement, PR #91). The #89 entry states that build and fix inherit the check via `/roughly:review` rather than implying it is build-only.
- **AC4 — Every entry is checkable against its diff.** Each new entry cites the merging PR number and names at least one file it touched. Verify by spot-diff: for each entry, `git show` the merge commit and confirm the named file appears in the diff. This AC exists because the E06 audit caught an inaccurate claim in an entry written with fresh context; these are written cold.
- **AC5 — Entry ordering follows house convention.** Existing `### Removed` (#80) stays; new entries group under `### Added` and `### Changed` as appropriate, matching the v0.1.8 section's structure.

**Verification.** Inspection + spot-diff per AC4. `bash .claude/hooks/verify-all.sh` clean.

**Dependencies:** none — and it is a **hard predecessor of every other story in this epic**, not merely "first in Track B." Seven ACs across S1, S2, S4, S5, S6, and S7 write `CHANGELOG.md`; AC1 rewrites the section heading all of them land under. Merging S3 first means every subsequent entry is written under the final heading and no two stories contend for adjacent lines. S3 is one file and roughly an hour — there is no reason to run it in parallel.

**Out of scope for this story.** The tag-time re-date itself, `plugin.json`, and the ROADMAP Current marker — all S7. Entries for work this epic has not yet shipped.

---

## E07.S4 — Intra-epic AC amendment convention codifier + back-applications

**Maps to:** 3a intra-epic codifier (ROADMAP v0.1.8 out-of-scope item 1; E06 audit main systemic finding) · **Issue:** [#98](https://github.com/nickkirkes/roughly/issues/98)

**Files touched:** `CONTRIBUTING.md` · `docs/planning/epics/complete/E06-anchoring-closure-and-ci-coverage.md` · `.roughly/known-pitfalls.md` · `CHANGELOG.md`

**Acceptance criteria**

- **AC1 — New `## Intra-epic AC amendments` section in `CONTRIBUTING.md`.** Placed between `## Cross-epic AC amendments` (L87) and `## Epic Open Question resolution` (L99), per the section-cluster rationale that resolved OQ-S4 and OQ-S7. Specifies the back-annotation form for amending an AC's text **within the same epic** during a build: the epic's story entry gains a dated deviation note adjacent to the AC (never an in-place edit of the AC text), the note states what shipped versus what the AC specified and why, and the CHANGELOG entry cross-references the AC and the note. Must state its boundary against the cross-epic convention explicitly — same epic, in-flight, versus a later epic amending shipped work.
- **AC2 — Shape catalog: transcribe E06's canonical Shapes 1–6, do not re-derive them.** *(Corrected at review 2026-07-30. The earlier framing — "E06 self-identifies four distinct shapes across five instances; the two remaining come from E06.S3" — was wrong: E06's `**Epic AC verbatim-text back-annotation form**` bullet in its `## v0.1.9 candidates` block ([L600](complete/E06-anchoring-closure-and-ci-coverage.md)) states* **"nine instances across all seven shipped stories, six distinct shapes:"** *and enumerates them in the six sub-bullets beneath it (L601–606); [ROADMAP.md:124](../../ROADMAP.md) carries the same figures as "9 instances across all 7 stories spanning 6 distinct shapes". The earlier derived list also dropped Shape 5 entirely and split Shape 4's sub-variant into a standalone shape.)* Adopt E06's catalog **with its numbering preserved**, so the codifier and its source agree:
  - **Shape 1 — Narrative-vs-literal omission** (in-flight amendment): E06.S1.AC1(a) + E06.S4.AC1
  - **Shape 2 — Spec-revision-candidate escalation** (deferred-not-amended): E06.S5 Stage 6 W1 + W2
  - **Shape 3 — AC-internal contradiction**: E06.S2.AC1
  - **Shape 4 — Premise-false spec / consumer-only-scope insufficient**: E06.S6.AC1, with the architectural-redesign sub-variant E06.S3.AC2 (via ADR-013)
  - **Shape 5 — Factually wrong example / inherited false claim in normative AC content**: E06.S7.AC1 (i) malformed `gh api PATCH` example, (ii) unverified `gh pr edit --body-file` claim — the only shape covering executable defects in shipped guidance
  - **Shape 6 — Pipeline-architecture or tooling-semantics misunderstood at spec time**: E06.S3.AC1 (Stage 6 max-cycles → Stage 5c retarget) + E06.S3.AC4 (exit-code → marker-primary reframe)

  Each entry names the story, the shape, and the deviation note that records it. Verify: all six cite locations resolvable in the E06 epic file, and the catalog's shape count and instance count match the 6 and 9 stated in E06's `**Epic AC verbatim-text back-annotation form**` bullet.
- **AC3 — Back-applied to E06.S1.AC1(a) and E06.S4.AC1.** Both already carry post-merge deviation notes (E06 epic L90 and L314). Re-express each in the new convention's normative form and add the shape label from AC2's catalog. Additive only — existing note text is preserved, not rewritten.
- **AC4 — E06.S5 W1 and W2 closed out, not amended.** Both were substantially resolved by #72's extraction to `skills/shared/spec-candidate-escalation.md`: the Stage 6 disposition paragraph and the cubic-termination paragraph now both route to one named procedure (`**SPEC-REVISION-CANDIDATE ESCALATION**`), the cubic paragraph opens with an explicit scope preamble ("Cubic iterations (post-merge re-runs …)"), and the shared reference states that the appended entry is the evidence — W2's exact ask, now inherited by both call sites through the routing. Their cited locations ([E06 L555, L557](complete/E06-anchoring-closure-and-ci-coverage.md) → build L205 / fix L208) no longer hold that prose. Annotate both entries in the E06 `## v0.1.9 candidates` block as resolved-by-#72 with the verifying quotation, rather than applying amendments to text that moved.

  **Verify** *(corrected at review 2026-07-30 — the previously specified command did not work: it used a lowercase-`the` pattern against a sentence-initial "**T**he appended entry is the evidence" in the shared reference, so it never matched there; and its two real matches sat in the* **cubic** *paragraph, which carried evidence-artifact language before #72 and therefore evidences nothing about W2)*:

  ```sh
  # W2's evidence contract lives in the shared reference — case-insensitive, sentence-initial:
  grep -ci 'appended entry is the evidence' skills/shared/spec-candidate-escalation.md   # = 1
  # W1's disambiguation mechanism: both Stage 6 call sites route to the one named procedure:
  grep -c 'SPEC-REVISION-CANDIDATE ESCALATION' skills/build/SKILL.md   # >= 2
  grep -c 'SPEC-REVISION-CANDIDATE ESCALATION' skills/fix/SKILL.md     # >= 2
  ```

  The second and third commands are what actually demonstrate the closure: routing both paragraphs through a single named procedure is the mechanism that resolved W1's "no prose signals which gate applies" finding.
- **AC5 — E06.S2.AC1 and E06.S6.AC1 cross-referenced, not amended.** Both already carry adequate deviation notes and are catalogued in AC2; add a one-line pointer from each to the new convention so the trail is discoverable, without restructuring shipped notes.
- **AC6 — CHANGELOG entry + `CONTRIBUTING.md` line budget.** Entry names the new section, the six catalogued shapes, and the two back-applications plus two close-outs. `CONTRIBUTING.md` has no hard cap but is at 231 lines; state the post-merge count in the entry.

**Verification.** `grep -n '^## Intra-epic AC amendments' CONTRIBUTING.md` = 1 match, positioned between L87's and L99's sections (both anchors verified present at review). Each of AC2's six catalog citations resolves to a real location in the E06 epic file, and the catalog reproduces E06's Shape numbering. The three greps in AC4. `bash .claude/hooks/verify-all.sh` clean.

**Dependencies:** E07.S3 (CHANGELOG heading, per AC6). Otherwise parallel with S5 and S6. Shares the E06 epic file with S2 — see S2's file-contention note.

**Out of scope for this story.** Editing any shipped AC text in place — the whole point of the convention is that this never happens. Amending E06.S5 W1/W2 (AC4 closes them instead). Any change to `skills/` — this is a docs-and-epic story.

---

## E07.S5 — Stage 4 contract: verdict persistence + build/fix `--ci` parity

**Maps to:** residual verdict-persistence gap (E06 audit Rec 4, partially satisfied by #72); ADR-013 unification follow-up (ROADMAP v0.1.8 out-of-scope item 3) · **Issue:** [#96](https://github.com/nickkirkes/roughly/issues/96)

Bundled because both changes edit the same Stage 4 section in the same two files under a 14-line headroom in `skills/fix/SKILL.md`. Splitting them means two rounds of edits to the same lines and two independent cap negotiations.

**Files touched:** `skills/build/SKILL.md` · `skills/fix/SKILL.md` · `docs/adrs/ADR-013-build-ci-runs-review-plan.md` · `CONTRIBUTING.md` · `CHANGELOG.md` · *conditional:* `skills/shared/stage-4-verdict.md` (new — only if AC6's line-cap off-ramp is taken)

**Acceptance criteria**

- **AC1 — The review-plan verdict is written to the plan file.** Both pipelines currently display the Stage 4 verdict and preserve it in context ("Preserve: … PASS verdict") but persist it nowhere; E06.S7.AC3 shipped with the PASS verdict recorded only in a commit message, and E06.S5.AC5 with a self-attestation in the plan's AC-mapping section. Add a directive to Stage 4 in both files: on PASS (or on confirmed override), append the verdict block verbatim to the plan file under a `## Review-plan verdict` heading, dated, before proceeding to the gate. Byte-identical between build and fix, per the E06.S5.AC2 parity precedent.

  **Verify** *(extraction anchors specified at review — "`diff` of the two added blocks is empty" had no defined subject, so the check was not runnable)*: the added prose is a single contiguous paragraph beginning `**Verdict persistence:**` and ending at the next blank line, in both files. Extract and compare:

  ```sh
  diff <(grep -A2 '^\*\*Verdict persistence:\*\*' skills/build/SKILL.md) \
       <(grep -A2 '^\*\*Verdict persistence:\*\*' skills/fix/SKILL.md)   # empty
  ```

  If the shipped prose spans more lines, adjust `-A` to cover it and state the value used in the CHANGELOG entry. Alternatively satisfy parity by quoting the shipped paragraph verbatim in the CHANGELOG entry, per the E06.S5.AC2 precedent.
- **AC2 — Escalation and verdict persistence are distinguishable.** `skills/shared/spec-candidate-escalation.md` (ADR-019) persists Stage 6 spec-revision *candidates* to `.roughly/spec-candidates.md`. This story persists the Stage 4 *verdict* to the plan file. Different artifact, different trigger, different destination. The new prose must not route through the escalation procedure or reference the candidates ledger. Verify: the added Stage 4 text contains no reference to `spec-candidates.md`.
- **AC3 — `--ci` NEEDS-REVISION handling unified.** Build `--ci` runs a recovery loop (up to 2 NEEDS REVISION verdicts, then a structured marker and halt); fix `--ci` halts on the first. Port build's recovery loop to fix so both pipelines behave identically, and delete the asymmetry disclaimer from `skills/fix/SKILL.md` Stage 4 — the sentence currently ships a promise ("a known asymmetry, slated for unification review in v0.1.9") that becomes false at tag if left. Verify: `grep -c 'slated for unification review' skills/fix/SKILL.md` = 0, and both files' `--ci` Stage 4 blocks specify the same 2-verdict cap and the same marker form.
- **AC4 — ADR-013 amended, not superseded.** ADR-013 already claims to unify build `--ci` with fix `--ci`; the unification was partial in the opposite direction. Add a dated `## Amendment (v0.1.9)` section recording that fix `--ci` now carries the recovery loop and that the unification is complete. Do not mint a new ADR — this completes ADR-013's stated intent rather than deciding something new. ADR-010 stays reserved; the next free number remains ≥021.
- **AC5 — Verdict-persistence convention codified.** Add the rule to `CONTRIBUTING.md` `## AC authoring conventions`: a gate outcome cited as evidence must exist as an artifact, not as an attestation in prose. Names the plan-file verdict block as the canonical instance and cross-references E06 audit cross-cutting finding #4.
- **AC6 — Line caps held, with an off-ramp.** `skills/build/SKILL.md` 281/300 and `skills/fix/SKILL.md` 286/300 at story start. Post-merge both ≤300. If either would exceed, extract the Stage 4 verdict-persistence prose to `skills/shared/stage-4-verdict.md` and reference it via a runtime `Read` directive using `${CLAUDE_PLUGIN_ROOT}`, per ADR-012 — the off-ramp is pre-authorized by this AC and does not require a new decision mid-build. Verify: `wc -l` on both ≤300.

**Verification.** `diff` parity check per AC1; the two greps in AC3 and AC2; `wc -l` per AC6. Behavioral verification of the `--ci` recovery loop depends on the `plan-revision` dogfood scenario, which is part of S2's dispatch — note the dependency, do not block on it. `bash .claude/hooks/verify-all.sh` clean.

**Dependencies:** none blocking. Sequence before S6 within Track B so S6 inherits a known line budget (R3).

**Out of scope for this story.** Fix-side negative-path CI scenarios (would add paid scenarios). Persisting Stage 6 review verdicts or T2 transcripts — E06 audit finding #4 names three gap shapes and this story closes the plan-file verdict shape only; the transcript shape stays a v0.1.10 candidate. Any change to `skills/shared/spec-candidate-escalation.md`.

---

# Track C — Intake guard (parallel; gates nothing)

## E07.S6 — Epic-vs-story granularity guard

**Maps to:** B2 granularity guard (ROADMAP Cluster B) · **Issue:** [#97](https://github.com/nickkirkes/roughly/issues/97)

**Files touched:** `skills/build/SKILL.md` · `skills/fix/SKILL.md` · `skills/help/SKILL.md` · `skills/shared/gate-protocol.md` (Rule 3 exemption list, per AC3b) · `README.md` · `docs/adrs/ADR-021-epic-vs-story-intake-guard.md` (new) · `CLAUDE.md` (ADR table row + ADR-020 reserved-list correction) · `docs/adrs/README.md` (ADR index) · `.roughly/known-pitfalls.md` · `CHANGELOG.md` · *conditional:* `skills/shared/intake-granularity.md` (new — only if AC7's line-cap off-ramp is taken)

**Acceptance criteria**

- **AC1 — Stage 1 detects epic-shaped input and asks.** Both pipelines currently resolve a referenced file and proceed ([build L29](../../../skills/build/SKILL.md), [fix L36](../../../skills/fix/SKILL.md)); feeding an epic silently treats it as one monolithic feature. Add to Stage 1 in both files: classify the resolved input as epic-shaped if it enumerates multiple child stories (two or more headings matching a story-heading form, or an explicit story-ID enumeration). On a positive classification, warn and ask the human to narrow to one story or confirm monolithic treatment. Byte-identical between build and fix.

  **Insertion point is positional, not descriptive** *(specified at review — "after resolving the input" is unsafe)*: place the classification and its prompt **after the `CI_MODE=true` assignment and before the existing `Ask:` gate**, in both files. In `skills/build/SKILL.md` file resolution and `--ci` detection share one sentence, so either order works; in `skills/fix/SKILL.md` they are **separate paragraphs** (resolution L36, `CI_MODE` L38), and a gate inserted after resolution but before L38 executes before `CI_MODE` exists — hanging every `--ci` run at the new prompt, which is exactly the failure AC3 claims to rule out. Verify: in `skills/fix/SKILL.md`, the new classification prose appears at a line number **greater than** the `CI_MODE=true` assignment.
- **AC2 — The prompt is a verbatim plain-text gate.** Per ADR-015 and `skills/shared/gate-protocol.md`, the question is asked as plain text in the reply. This is the surface the 2026-07-16 unauthorized-push incident came through; a new gate is exactly where the substitution recurs. **State the constraint at the point of the new prompt by naming the closed-world test and cross-referencing `skills/shared/gate-protocol.md` Rule 1 — do not enumerate tool names.** Both pipeline files already carry a closed-world prohibition at L11 and `CLAUDE.md` is explicit that it "must stay closed-world … not an enumerated list"; a fresh inline enumeration at a new gate is how that prohibition gets narrowed to whatever tools were current when it was written.
- **AC3 — Detection is advisory, never a hard abort.** A false positive must cost one keystroke, not a re-run. Confirming monolithic treatment proceeds with today's exact behavior. Under `CI_MODE=true` the prompt auto-proceeds with its default like every other gate in the pipeline — this follows from Stage 1's existing "every human gate in this pipeline auto-proceeds with its default (yes)" rule and `gate-protocol.md` Rule 4, **provided AC1's positional insertion point is honored**. Verify no CI hang by desk-checking both files' Stage 1 ordering per AC1.
- **AC3b — The new prompt is a sub-gate, not a numbered stage gate.** `gate-protocol.md` Rule 3 mandates a `Stage [N] of [M]` header block at numbered stage gates and exempts a closed list of sub-gates (override confirmation, `discard` confirmation, maturity-check offers, abort menus) that a second in-Stage-1 prompt does not join — a genuine ambiguity. **Resolution: treat it as a sub-gate** — Rules 1, 2, and 4 apply in full; no Rule 3 header block (two `Stage 1 of 8` blocks in one stage is noise). Add the intake-granularity prompt to Rule 3's exemption list in `skills/shared/gate-protocol.md` in this same story, so the decision is recorded where the next gate author will look.
- **AC4 — README `### Epic files` corrected in the same story.** *(Scope corrected at review 2026-07-30: the [README.md:41-50](../../../README.md) Quick Start heredoc contains only* **one** *story (`## Story 1: GET /health`) and would* **not** *trip the AC1 detector. The earlier instruction to "rewrite the Quick Start example to a single story" directed a no-op on a false premise — dropped.)* The real collision is [README.md:180-201](../../../README.md), which documents epic files as a `/roughly:build` input with a two-story worked example. Rewrite `### Epic files` to state that `/roughly:build` takes one story while `/roughly:review-epic` and `/roughly:audit-epic` take the whole epic, and reduce its example to a single story. Verify: the `### Epic files` example contains exactly one `## Story` heading, and the section names the one-story-vs-whole-epic split explicitly.
- **AC5 — Rule surfaced in `/roughly:help`.** Add "feed story IDs, not epic IDs" to the `## STEP 1: COMMANDS BY CLUSTER` Pipeline entries for `/roughly:build` and `/roughly:fix` — one clause each, within the existing "one short line of purpose" format. `skills/help/SKILL.md` is 161/300; state the post-merge count.
- **AC6 — ADR-021 written.** A Stage-1 gating-behavior change meets the `docs/adrs/README.md` criterion "changes the pipeline stage structure (number, order, or gating behavior)." Record: why advisory-and-ask rather than hard-abort; why detection is heuristic rather than schema-based (Roughly parses unstructured epic files by design — see `### Epic files`); the false-positive posture from AC3; the sub-gate decision from AC3b; and the decomposition-loop boundary. Add the row to the `CLAUDE.md` ADR table and the entry to `docs/adrs/README.md`. **While editing [CLAUDE.md:18](../../../CLAUDE.md), add ADR-020 to its reserved list** — it is reserved for the differential-gate spec set's Spec 2 (renumbered 015→020; see `docs/planning/differential-gate-allocation-specs.md:45` and `ADR-019:19`) but is currently omitted from that row, so a contributor reading only `CLAUDE.md` would wrongly claim it. ADR-010 stays reserved; B3's intake ADR takes ≥022.
- **AC8 — Executable behavioral check of the detector, run locally** *(added 2026-08-10 — desk-check alone left the guard's core path with no executable verification of any kind, in a story that ships a user-visible prompt to both pipelines)*. Documenting the CI coverage gap does not test the guard; run it. Two arms against a funded key, mirroring the S1.AC2 positive-plus-negative-control pattern:
  - **Positive — one arm per accepted heading form, not one arm total** *(broadened 2026-08-11; a single E06-shaped arm let a detector that recognizes only `####`-with-colon pass every explicit test while missing most real epics)*. **Resolve OQ8 before running AC8** — the set of accepted forms is what makes these arms derivable — then run one invocation per accepted form and require the prompt to fire on each. The four forms present in this repo:
    - `#### E06.SN:` (h4, colon) — `docs/planning/epics/complete/E06-anchoring-closure-and-ci-coverage.md`, seven headings
    - `## E07.SN —` (h2, em-dash) — this epic file, seven headings
    - `### E06.SN —` (h3, em-dash) — `docs/planning/epics/complete/E06-anchoring-closure-and-ci-coverage-audit.md`, seven headings
    - `## Story N:` (h2, "Story" literal) — the form the README documents and therefore the one a consumer is most likely to write; construct a scratch file from the `### Epic files` example

    Any form the shipped heuristic does **not** accept must be named in OQ8 as a deliberate exclusion with a reason — never left silently unsupported. A form declared accepted but without a passing arm here fails this AC. *(Path corrected 2026-08-10; the earlier example said `epics/complete/E0*.md`, which does not resolve from the repo root.)*
  - **Negative control:** the same invocation against a single-story input — write the README Quick Start heredoc (one `## Story 1:` heading) to a scratch file and pass that. The prompt must **not** fire and Stage 1 must proceed exactly as today. A scratch file is fine; do **not** commit a fixture.
  - **Feed the result back into OQ8.** The repo contains at least three story-heading forms — `#### E06.S1:` (E06), `## E07.S1 —` (E07), `## Story 1:` (README example) — plus `### E06.S1 —` in the audit files. A detector recognizing only one of these passes the positive arm above and still misses most real epics. Record which forms the shipped heuristic accepts when annotating OQ8.

  Abort at the prompt in both arms; this verifies intake classification, not a full pipeline run, so cost is one short session per arm (~$2 total, same order as S1.AC2). Capture both outcomes in the CHANGELOG entry. **This is a local check, not a CI scenario** — it adds nothing to the dogfood budget and does not touch `scripts/ci-dogfood.sh`, so the no-new-paid-scenarios constraint holds.
- **AC7 — Line caps held, with an off-ramp.** Both pipeline files ≤300 post-merge, accounting for S5's prior additions. If either would exceed, extract the Stage 1 classification prose to `skills/shared/intake-granularity.md` and reference it via a runtime `Read` with `${CLAUDE_PLUGIN_ROOT}`, per ADR-012 — pre-authorized by this AC.

**Verification.** Parity `diff` of the added Stage 1 blocks (use the same anchor-extraction approach S5.AC1 specifies); `wc -l` on all three skill files; the `### Epic files` check in AC4; the fix-side ordering check in AC1. For AC2, the enumeration guard is **`grep -c 'AskUserQuestion'` staying at exactly 1 in each of `skills/build/SKILL.md` and `skills/fix/SKILL.md`** — that is the verified baseline (both at L11), and holding it at 1 is what proves the new prose cited `gate-protocol.md` Rule 1 rather than re-enumerating tool names. *(Previously stated as "unchanged from baseline" with the baseline never recorded, which made the check unrunnable and put it in direct tension with AC2's "state the constraint explicitly.")* Behavioral verification against a two-story fixture is desk-check only — no new paid CI scenario (adding one is out of scope per the epic's standing constraint). **Be explicit about what E07.S2's proving runs do and do not cover here** *(added 2026-08-10)*: all six dogfood scenarios pass an **inline description**, never a file, so **neither** classification path runs in CI — not the positive one and not the negative one, because the file-resolution branch AC1 hooks into is never reached. *(Corrected 2026-08-10: an earlier revision claimed the negative path was covered. It is not — inline input does not exercise resolved-file classification at all.)* What the proving runs **do** cover is that the added Stage 1 prose does not hang or otherwise break `--ci` on inline input: a gate inserted before the `CI_MODE` assignment would surface as a 124 timeout across every scenario. That is a real but narrow guarantee, and it is the only one they provide for this story. A classifier that fails to detect a genuine epic file, or that emits a malformed prompt when it does, ships on desk-check alone and three green proving runs would not catch it. **AC8 closes the executable-verification gap locally** — the positive path is exercised against a real epic file before merge, so the guard does not ship untested; what remains unclosed is *CI regression* coverage, which only a paid scenario would give. Record that residual in the CHANGELOG entry rather than letting green runs imply coverage they do not provide, and file the epic-input fixture as a v0.1.10 candidate (see `## v0.1.10 candidates`). `bash .claude/hooks/verify-all.sh` clean.

**Precondition:** `ANTHROPIC_API_KEY` funded — AC8's two arms need it (~$2). Every other AC in this story is free.

**Dependencies:** E07.S5 (line budget, per R3); E07.S3 (CHANGELOG heading). No functional dependency on S5.

**Out of scope for this story.** Any epic→story decomposition loop — that needs live intake and is deferred with B3. External issue-tracker ID/URL resolution (B3, v0.1.10). `review-epic` / `audit-epic` intake — both correctly take whole epics and are untouched. A new CI scenario exercising the guard.

---

# Track D — Tag

## E07.S7 — Tag-prep wrap

**Maps to:** tag-prep DoD · **Issue:** [#99](https://github.com/nickkirkes/roughly/issues/99)

**Files touched:** `.claude-plugin/plugin.json` · `docs/ROADMAP.md` · `CHANGELOG.md`

**Acceptance criteria**

- **AC1 — `plugin.json` bumped.** `"version"` `0.1.8` → `0.1.9`. Verify: `grep '"version"' .claude-plugin/plugin.json` shows `0.1.9`.
- **AC2 — ROADMAP Current marker moved.** `docs/ROADMAP.md:3` `**Current:** v0.1.8` → `v0.1.9`, with `**Updated:**` set to the tag date. The v0.1.9 release-map row (L19) already exists — no promotion needed — but its theme text must be corrected per OQ7: B3 left the release, so "consumer-project intake hardening" overstates what shipped. **Confirmed replacement text** (OQ7 resolved 2026-07-30) — the literal cell content, backticks included:

  > E06 codification close-out + release-gate repair + epic-vs-story intake guard + obsolete-`ruckus`-checks removal

  Retaining the `ruckus`-removal clause is deliberate — #80 shipped it via PR #88 and it is the release's only user-visible removal; an earlier draft of this replacement dropped it.
- **AC3 — v0.1.9 ROADMAP status line finalized.** The section header currently reads `**Status:** SCOPING (draft — not yet frozen; Cluster B intake items PROPOSED pending confirmation)`. Replace with the shipped disposition, naming B3's move to v0.1.10.
- **AC4 — CHANGELOG heading re-dated.** `## [Unreleased] — v0.1.9` → `## [0.1.9] — <actual tag date>`. The date must be the tag date, not an earlier one — the premature-and-wrong date this epic reverted in S3 is the second occurrence of this error in two releases (E06 audit finding #3 was the first).
- **AC5 — The three surfaces agree.** `plugin.json`, the ROADMAP Current marker, and the CHANGELOG heading must all state v0.1.9. Verify all three in one pass; the E06 audit's "inconsistent version triad" finding exists because they were checked separately.
- **AC6 — Executed after S2's disposition call.** All five risk-window dispositions from S2.AC5 must be recorded before this story runs — CLOSE, CARRY, or BLOCKED-NO-EVIDENCE. A CARRY does not block the tag; an *unrecorded* window does. Because S2.AC1 now guarantees a reachable disposition in every branch (including "could not dispatch"), this AC can always be satisfied and never hard-blocks the tag on external state.

**Verification.** The three greps in AC5. `bash .claude/hooks/verify-all.sh` clean. Git tag creation is a maintainer action, not part of this story.

**Dependencies:** all of S1–S6. Last story in the epic.

**Out of scope for this story.** Writing CHANGELOG content (S3 did that). Creating the git tag or a GitHub release. Any code or convention change.

---

# Sequencing

```text
S3 ──► S1 ──┬──► S2 Phase 1 ································┐
 CHANGELOG   │    discovery dispatch — overlaps wave 4,      │
 heading     │    blocks nothing, may find Class A/B/H work  │
 (before     │                                               │
  all)       ├──► S5 ─────► S6 ─────────────────────────────┴──► S2 Phase 2 ──► S7
             │    Stage 4    granularity guard                    3 proving runs   tag-prep
             │    contract   (line budget: S5 first)              (counter starts    (last)
             │                                                     here)
             └──► S4 codifier ·····► optional — NOT a Phase 2 predecessor;
                                     may be cut entirely

Phase 2 predecessors are S1, S5, S6 and nothing else (S2.AC1 is the source).
S3 precedes every story. S4 gates nothing. S7 runs after Phase 2 and can
never be a predecessor of it.
```

**S3 goes first, ahead of everything.** *(Revised at review — S3 was previously drawn parallel to S1.)* Seven ACs across S1, S2, S4, S5, S6, and S7 write `CHANGELOG.md`, and S3.AC1 rewrites the section heading all of them land under. Running S3 first means every later entry is authored under the final heading, with no two stories contending for adjacent lines. It is one file and about an hour.

**The proving runs go last, after every other story has merged.** *(Added 2026-08-07. The prior sequencing — "start S2 the moment S1 merges" — was written against S1.AC4's too-narrow reset rule and does not survive the corrected one.)* Under the canonical criterion the counter restarts on any `main` change touching the workflow **or its inputs**, and the pipeline skill bodies are inputs: `scripts/ci-dogfood.sh` invokes the pipelines six times (five `/roughly:build`, one `/roughly:fix`). **S5 and S6 both edit `skills/build/SKILL.md` and `skills/fix/SKILL.md`**, so three greens banked before either merges are void — a CLOSE recorded on them would be false at tag, which is the exact class of unearned-green claim this epic exists to stop. Hence S2's phase split: discovery keeps its runway, only Phase 2 counts, and nothing may merge between its three runs.

**Critical path is S3 → S1 → S2 Phase 1 → (S5 → S6, S4) → S2 Phase 2 → S7.** S2 remains the long pole and the only story with an external dependency (paid dispatches). Phase 1 still starts the moment S1 merges — finding Class A/B defects early is what buys the runway, and discovering them at tag crunch is how the tag slips.

**Track B and C gate nothing functionally; of them, only S5 and S6 gate Phase 2 temporally** (S1 also gates it, from Track A — the full predecessor set is S1/S5/S6, per S2.AC1)**.** *(Corrected 2026-08-10 — this paragraph previously required "all of S4/S5/S6 merged before Phase 2 opens" while also calling S4 the first cut whose removal "removes nothing from Phase 2's precondition," making S4 simultaneously required and optional.)* **AC1 is the single source for the Phase 2 predecessor set (S1, S5, S6);** this paragraph does not restate it. S4 and S5→S6 are parallel with each other and with Phase 1 once S3 has landed. Ordering constraints: S3 before all (CHANGELOG), S5 before S6 (line budget, R3), **S1/S5/S6 — and only those — before Phase 2** (they touch the workflow or its inputs), and everything before S7. **S4 is genuinely optional with respect to the gate** — it touches no dogfood input, so dropping it changes neither the counter nor Phase 2's precondition. That is exactly why it is the designated first cut if Phase 1 consumes the dispatch budget: it is dogfooding-internal with no consumer-facing effect. Landing it before Phase 2 is preferred only to avoid a rebase on the E06 epic file, which S2 also writes.

**Pre-implementation review.** Run `/roughly:review-epic` against this epic before dispatching any story. Budgeted as an explicit step — it has caught real blockers every prior round.

---

# v0.1.10 tracking stubs

Not stories in this epic. All three are filed as GitHub issues — Stub 1 → [#100](https://github.com/nickkirkes/roughly/issues/100), Stub 2 → [#101](https://github.com/nickkirkes/roughly/issues/101), Stub 3 → [#102](https://github.com/nickkirkes/roughly/issues/102). *(Corrected 2026-08-10 — an earlier edit changed "Fileable" to "Filed" across a three-stub section after only two had been filed, implying the deferred list was fully tracked externally when Stub 3 had no issue.)*

**Stub 1 — B3: external issue-tracker intake, wholesale.** *(Filed as [#100](https://github.com/nickkirkes/roughly/issues/100).)* Deferred from v0.1.9 in full. Its exit criterion is a confirmed working fetch tool, which needs PM-tool MCP OAuth and cannot complete in a non-interactive session; splitting the scaffolding across two releases strands it away from what it enables. Sub-tasks: (a) **fetch-contract survey + ADR ≥022** across Linear / Jira / Shortcut, deciding the tool-agnostic intake-resolution mechanism — Roughly ships the mechanism and config, never a specific tracker; (b) **setup config surface** — STEP 4 issue-source declaration question with advisory MCP detection that never blocks setup, a new 5f writing the intake block to `.roughly/config`, and a versioned `issue-intake-v1` maturity check at STEP 6 re-offered via build/fix Stage 8; (c) **Stage-1 classifier + inline fallback**, with live fetch deferred — resolution order local-file → configured-pattern → inline, degrading to exactly today's behavior when no config exists. **Constraint:** `skills/setup/SKILL.md` is at 286/300; the 5f write logic and the `.roughly/config` schema go to `skills/setup/templates/` plus a shared reference per ADR-012, not inline. Operational toggles unify in `.roughly/config`; content artifacts (`known-pitfalls`, `verify-rules`, `spec-candidates`) stay separate files.

**Stub 2 — DI-001: systematic pitfall-into-briefs pass.** *(Filed as [#101](https://github.com/nickkirkes/roughly/issues/101).)* `docs/deferred-investigations.md` DI-001 — surface `.roughly/known-pitfalls.md` patterns into the three Stage-6 agent briefs. #89 did this for one pitfall (OQ-resolution annotation → `agents/code-reviewer.md` step 8); the systematic pass is unstarted. Natural seed for the Spec 3 review-cell work in the differential-gate set, so it wants a v0.2.0-adjacent home rather than a v0.1.10 slot. Re-evaluate freshness before picking it up — DI-001 was noticed 2026-05-05 and its evidence base is a single story's cubic history.

**Stub 3 — ADR-009 / ADR-010 stale-reference cleanup.** *(Filed as [#102](https://github.com/nickkirkes/roughly/issues/102).)* Doc-only, flagged in the ROADMAP Reconciliation section. Deferred out of v0.1.9 per the OQ resolution below.

---

# Open questions

**OQ1 — Residual verdict-persistence gap: VERIFIED OPEN, scoped to one shape.** ~~Does ADR-019's ledger cover the Stage-4 review-plan verdict, or only the Stage-6 escalation path?~~ **Resolved at epic authoring (2026-07-30): escalation only.** `skills/shared/spec-candidate-escalation.md` covers Stage 6 spec-revision candidates and cubic option (c), routing both to `.roughly/spec-candidates.md`. Stage 4 in both pipelines displays the verdict and preserves it in context but writes it nowhere. E06 audit Rec 4 named three gap shapes (S1.AC3 transcripts, S7.AC3 plan-file verdict, S5.AC5 self-attestation); #72 closed none of them. E07.S5 closes the plan-file verdict shape as a micro-convention. The T2-transcript shape stays a v0.1.10 candidate. Spec 1 and the differential-gate set are not reopened.

**OQ2 — Does B2 warrant an ADR?** ~~Lightweight ADR ≥021 vs convention-only.~~ **Resolved at epic authoring: ADR-021.** A Stage-1 gating-behavior change meets the `docs/adrs/README.md` criterion directly, and the advisory-not-abort posture plus the heuristic-detection choice are decisions a future contributor would otherwise have to reverse-engineer. B3's intake ADR moves to ≥022. ADR-010 stays reserved.

**OQ3 — Does the `--ci` unification warrant its own ADR?** ~~New ADR-022 vs ADR-013 amendment.~~ **Resolved at epic authoring: amendment. Confirmed by the maintainer at review (2026-07-30) — keep the amendment, no discrete ADR.** ADR-013 already states it unifies build `--ci` with fix `--ci`; the unification was partial in the opposite direction. Completing it is that ADR's stated intent, not a new decision. E07.S5.AC4 adds a dated amendment section. Supporting evidence: ADR-013 is 30 lines and already carries a dated correction note, so a second dated section matches how that file is maintained. The discoverability tradeoff is absorbed by the `CLAUDE.md` ADR-table row text.

**OQ4 — Release shape.** ~~Minimal (B2 + risk track + tag-prep) vs +3a codifier.~~ **Resolved at scoping: codifier in.** Its back-applications are fully specified in the E06 candidates block, the context that makes it cheap is decaying, and #81–#86 shipped orphaned of their parent codifier. It remains the designated first cut if S2's discovery dispatch consumes the effort budget.

**OQ5 — Risk-window disposition.** Open until E07.S2 executes. **`ANTHROPIC_API_KEY` funding confirmed 2026-07-30** — the dispatches can proceed, and BLOCKED-NO-EVIDENCE is a contingency rather than the expected path. Current evidence: **E06 Risk 3 count on `main` is 0** — 6 successes all-time, all 2026-05-08 against pre-scenario scaffolding, against 138 failures; no run has executed since 2026-07-18, and none on `main` since 2026-07-17. Since `6405652` removed the `push:` trigger, reaching 3 requires 3 deliberate `workflow_dispatch` runs against `main`, preceded by at least one discovery dispatch. **E04 Risk 3** and **E05 Risk 2** are assessable now from `main` history without spend, per S2.AC2's stated method. **E05 Risk 1** and **E04 Risk 5** are strictly downstream of a green dogfood run and CARRY if Risk 3 does.

**OQ6 — Does the ADR-009 / ADR-010 stale-reference cleanup ride v0.1.9?** **Recommendation: no — defer to the v0.2.0 scoping pass** (Stub 3). It is doc-only and cheap, but v0.1.9 is already carrying two ADR edits (new ADR-021, amended ADR-013) plus the `CLAUDE.md` and `docs/adrs/README.md` index updates that come with them. Folding a third ADR-surface change into the same release makes the ADR diff harder to review for no release-gating benefit, and ADR-010 must stay reserved either way. Overrule if you want the ADR surface clean at tag.

**OQ7 — Theme re-characterization.** ~~Recommendation: adopt.~~ **Resolved at review (2026-07-30): adopted, with the `ruckus` clause retained.** With B3 out, "consumer-project intake hardening" reduces to a single advisory Stage-1 prompt and overclaims in both the ROADMAP release-map row (L19) and the v0.1.9 section header. **Confirmed row text** (see E07.S7.AC2 for the literal cell content). The originally proposed text dropped the `ruckus`-removal clause, which #80 actually shipped (PR #88) and which is the release's only user-visible removal — review caught the omission. E07.S7.AC2 carries the edit.

**OQ8 — Resolve before E07.S6.AC8 runs: what counts as "epic-shaped" in E07.S6.AC1.** *(Upgraded 2026-08-11 from "carried for implementer discretion" — AC8's positive arms are derived from this answer, so it must be settled first, and its resolution must **enumerate** the accepted heading forms plus any deliberate exclusions with reasons.)* Two or more story-form headings is the obvious heuristic, but the threshold and the heading forms recognized are a judgment call best made against real files — `docs/planning/epics/complete/E06-*.md` and the README examples are the available corpus. Resolve at plan-write and annotate this OQ per the `## Epic Open Question resolution` convention shipped in #86.

---

## v0.1.10 candidates

Items deliberately out of v0.1.9 scope. Pull from this list when scoping v0.1.10. Stage 6 spec-revision candidates surfaced during E07 builds append here, per `CLAUDE.md` and ADR-019.

- **B3 external issue-tracker intake, wholesale** — see Stub 1.
- **DI-001 systematic pitfall-into-briefs pass** — see Stub 2; v0.2.0-adjacent.
- **ADR-009 / ADR-010 stale-reference cleanup** — see Stub 3 ([#102](https://github.com/nickkirkes/roughly/issues/102)).
- **T2-transcript persistence** — the second of E06 audit finding #4's three gap shapes. E07.S5 closes the plan-file verdict shape only; capturing full T2 transcripts as artifacts rather than first-line outputs plus a methodology note is unaddressed.
- **Fix-side negative-path CI scenarios** (Stage 5c abort + NEEDS REVISION recovery) — unblocked by E06.S2 but deliberately withheld from v0.1.9: adding paid scenarios to a harness that has not produced a green run since 2026-06-10 increases the cost of every dispatch without increasing confidence. Revisit once E06 Risk 3 closes.
- **Install-marker producer generalization** — apply the E06.S6 write-on-install plus back-fill-from-artifact pattern to other always-installed components (formatter PostToolUse hook, settings entries beyond hook registrations). Includes the audit-noted jq edge case: `upgrade` STEP 6's back-fill assumes a nested `.hooks[].hooks[]` shape and silently skips on a foreign `UserPromptSubmit` entry lacking an inner array; no fixture covers it.
- **Dogfood-self template-sync mechanism** — carried from v0.1.7.
- **Cubic-readable known-issues mechanism for accepted violations** — carried from v0.1.7 (E04.S8).
- **Preamble + Stage 1 extraction to `skills/shared/`** — carried from v0.1.7; E07.S5 and E07.S6 both pre-authorize narrower ADR-012 extractions, which may supply the forcing function.
- **Other-agents multi-file failure-handling audit** — investigator, discovery, code-reviewer, silent-failure-hunter, static-analysis, epic-reviewer.
- **`set -uo pipefail` audit of `.claude/hooks/verify-all.sh`** — carried from v0.1.7.
- **Setup Step 5b/5e defensive `mkdir -p` consistency** — E05.S4.5 candidate #1.
- **Stage 8 step 6 doc-writer dispatch-side escalation** on `doc-writer: all writes failed —` returns — E05.S4.5 candidate #2.
- **Cross-epic AC re-amendment: 4-hop recursive clarity** — E06.S1 SFH Info #5; hypothetical until a 4-hop chain exists.
- **doc-writer self-check ordering / authoritative tiebreaker** — E06.S1 SFH Concern #1; requires a ~5–10 word trim elsewhere in `agents/doc-writer.md` (**647/650** — verified at review; the earlier 649 figure was the stale pre-E06 count that R5 already flags as the inaccurate CHANGELOG claim).
- **Epic-input dogfood fixture for the E07.S6 granularity guard** — every current scenario passes an inline description, so the classifier's positive path never executes in CI. E07.S6.AC8 verifies that path *locally* before merge, so this is a **regression**-coverage gap, not an untested-on-ship one: nothing would catch a later change that breaks the detector. Withheld from v0.1.9 under the no-new-paid-scenarios constraint; revisit once E06 Risk 3 closes and the per-dispatch cost is justified by a harness with a green baseline.
- **AC quoted-wording marker trigger-enumeration expansion** — E06.S4 SFH W2; `{{PLACEHOLDER}}` and square-bracket `[text]` slots are unenumerated metasyntactic forms.
- *(Risk-window carries from E07.S2 append here per S2.AC5 surface 4.)*
