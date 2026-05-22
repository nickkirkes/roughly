# E04: Path consolidation + process codification

**Date:** 2026-05-14 (PM + review-epic + remediation)
**Status:** **In progress (2026-05-14).** PM round resolved 9 open questions through iterative review (S7 deferral, ADR-011 vs CONTRIBUTING-only, DI-001 disposition, negative-path CI deferral, S3 separation, "6 vs 7 pipeline skills" count, signal-source/policy-parameter distinction, ADR-011 forward-reference shape, Cluster B vs Cluster D placement of `.roughly/known-pitfalls.md` organize-suggestion). One PM-phase proposed addition (Risk 6 codification-overshoot) was drafted then retracted on PM-author review. `/roughly:review-epic` dispatched 2026-05-14 returned **Needs Revision** with 10 prioritized findings (2 blockers, 7 revisions, 5 polish items, 3 question items) — all addressed in commit `eca5535`. Risk register at 6 post-remediation (Risk 6 cubic-gate format rejection added during remediation per P2 — distinct from the retracted PM-phase Risk 6). **Shipped: E04.S4** ✅ merged 2026-05-14 via PR #39 (`3017861`); 3 coordinated edits to `.claude/hooks/verify-all.sh` (1 more than originally enumerated — see backport-completeness pitfall captured in known-pitfalls.md L80). **E04.S6** ✅ merged 2026-05-15 via PR #40 (`9a18161`); review-plan/SKILL.md at 96/300 + new `## Skill authoring conventions` section in CONTRIBUTING.md + 7 synthetic fixtures in `tests/fixtures/review-plan/`. 2 review cycles converged (cycle 1 caught fabricated worked-example prose; cycle 2 caught carve-out over-permission). **E04.S7** ✅ merged 2026-05-15 via PR #41 (`b92e16f`, 3 commits — `92516b2` feat + `cef0c27` bold-grep pitfall + `0d2edb2` architect review refinements); ADR-011 shipped (49 lines), CLAUDE.md ADR enumeration updated to `(ADR-001 through ADR-009, ADR-011; ADR-010 reserved for v0.2.0 plan-format-v2)`, ADR-010 reservation placeholder added to `docs/adrs/README.md`, CONTRIBUTING.md cross-reference in S6's new section, 1 new pitfall captured (bold-decorated markdown grep). **E04.S8** ✅ merged 2026-05-18 via PR #42 (`ecae83f`, 6 commits); multi-file failure handling clause added to `agents/doc-writer.md` Process step 5 with inline gate-override prefix; **AC3 word cap violation accepted as Path B at +42 (542/500)** — structural impossibility under strict AC2; 2 new pitfalls captured; 5 new v0.1.7 candidates surfaced forming a coherent doc-writer-failure-handling cluster + 3 process observations. **E04.S1** ✅ merged 2026-05-20 via PR #43 (`4939875`, 8 commits — main feat + 7 cubic review-fix iterations); the anchor migration shipped. 30 plans relocated `docs/plans/ → .roughly/plans/` via `git mv` (29 historical + S1's own plan); 17 path substitutions across 5 skill bodies (build/fix/help/audit-epic/**review-plan** — the 2 review-plan refs were unenumerated in original spec and discovered at Stage 2); pre-flight signal evolved through 4 designs to settle on `*-plan.md` filename detection (canonical hash `8c03ed35...`); marker-at-source idiom adopted; setup .roughly/plans/ creation reverted; AC1 documented as intent-correct verify (`grep -v` exclusions for documented self-reference sites); 2 new pitfalls captured; **Risk 1 closes**. **E04.S5** ✅ merged 2026-05-20 via PR #44 (`bd8e37c`, 6 commits — main feat + 1 plan + 1 pitfalls + 3 cubic review-fix iterations); Stop hook drift coverage expansion shipped. `.claude/hooks/verify-all.sh` grew 57 → 114 lines (well under 150 soft cap) with 3 new structural checks; cross-platform `shasum`/`sha1sum` fallback; fixture-existence + per-skill marker-presence + tooling-unavailable defensive guards; Check 2 broadened mid-review from byte-identity-only to three-level cascade (template missing → hook missing → drift) per ADR-009 silent-protection-unregistration risk. 3 new pitfalls captured; **Risk 3 enters 30-day dogfood window**. Remaining stories: S2, S3, S9 (all unblocked, parallel-eligible).
**Target version:** v0.1.6
**Target effort:** 5–6 weeks part-time (medium release; 9 stories across 5 clusters; no new skills, no new agents, no new hooks)
**Dependencies on prior epics:**

- **E01** (directory rename + pipeline hardening) — provides the `docs/claude/` → `.ruckus/` directory-migration pattern that E04.S1 follows for `docs/plans/` → `.roughly/plans/`. The pre-flight migration check pattern E04.S1 extends to two-form was established in E01 and broadened in E03.S4.
- **E02** (rename Roughly) — provides the `git mv` precedent (E02.S2.6) for preserving git-log continuity across directory renames. E04.S1 uses the same `git mv` idiom on the 25 historical plans.
- **E03** (trust hardening + ergonomics + CI) — primary input; the v0.1.6 candidates list at the bottom of [E03-trust-and-ergonomics.md](complete/E03-trust-and-ergonomics.md) is the source for all 9 E04 stories. E03 artifacts consumed unmodified: S2's stop-hook-v1 template (E04.S5 extends the dogfood hook only, not the template), S4's pre-flight migration check pattern (E04.S1 extends to two-form), S9's abort-prose contract (preserved byte-verbatim through any build/fix touches), S11a's CI scaffold (E04.S1 updates the assertion path only).

---

## Release thesis

v0.1.5 closed the largest known enforcement holes — plan-mode hijack, stop-hook templating completion, abort-prose specificity — and proved the pipeline can test itself in CI. v0.1.6 settles two kinds of debt that were visible during v0.1.5 execution but kept out of frozen scope: runtime-state path sprawl (Roughly writes to both `docs/plans/` and `.roughly/` today, with no single root the user can gitignore or whitelist in PR review tools) and the retrospective-finding patterns that produced extra review-fix cycles in S8, S9, and S11b-2 (case-dispatch fall-through, "confirm during edit" footnotes that masked real edit sites, ungrounded runtime-signal references). Both are upstream of v0.2.0 — the path change is a one-shot migration that v0.2.0's plan-format-v2 should not have to carry, and the process-discipline rules anchor the skill-flags-as-public-API precedent that v0.2.0's complexity flag inherits. Nothing in v0.1.6 changes pipeline semantics; everything is plumbing, drift-hardening, or codification of patterns already proven in v0.1.5 retrospectives.

---

## Risk register

1. **Plan-path migration dual-state surprise.** ✅ **CLOSED 2026-05-20 post-E04.S1.** E04.S1 moves 15 runtime references across 4 skills (verified `rg -Fn "docs/plans" skills/`) + 25 historical plans, plus adds a new `/roughly:upgrade` migration step. Risk: a skill is missed during the sweep and silently reads or writes to the old `docs/plans/` path post-merge, while the user's plans were already moved by `/roughly:upgrade` — producing a dual-state where the user's plans are at the new path but a skill still reads the old one (silent empty-file-on-missing-path per the E02.S2.3/S2.6 known pitfall). Compounding with v0.1.4's `.ruckus/` legacy state is the realistic residual: the migration check now has to identify two distinct pre-v0.1.6 legacy states. Mitigation: extend the existing pre-flight migration check pattern (proven across v0.1.4 + v0.1.5 — 8 skill files carry the canonical pre-flight block; setup's soft-abort form is the documented 8th and has additional unrelated `Legacy` mentions that the `rg -c` count summing to 10 reflects) to a two-form check; blocking abort if either `.ruckus/` or `docs/plans/` is detected without the corresponding migrated state. CI dogfood asserts the post-migration state. **Closure (2026-05-20):** S1 shipped (PR #43, `4939875`); 17 substitutions across 5 skill bodies (review-plan unenumerated discovery — caught at Stage 2 via AC1's verify command); pre-flight extended to two-form across 7 hard-abort skills + setup soft-abort with new `<!-- pre-flight:start --> / <!-- pre-flight:end -->` delimiters; canonical-block hash `8c03ed35`; CI assertion-path updated and green on `main`. One narrow accepted-limitation: a project with unrelated `docs/plans/*-plan.md` files using the same naming convention will hit a false-positive abort; workaround is straightforward (rename collision files). v0.1.7 content-inspection upgrade (e.g., grep for `Plan-format-version:` or `## Tasks` heading) tracked as v0.1.7 candidate if user count grows.

2. **Line-cap budget under additive pressure.** v0.1.5 end-state: `skills/build/SKILL.md` 298/300, `skills/fix/SKILL.md` 299/300 (1-line headroom on fix is binding). E04.S1 changes 15 runtime references in skills; most are path-string substitutions (net-zero), but Stage 3 plan-naming prose may need expansion to disambiguate `.roughly/plans/<feature>-plan.md` from the v0.1.5 convention, and E04.S3 (plan self-marking historical) adds Stage 7 prose. Risk: a story lands and pushes build or fix past 300, breaking the dogfood Stop hook (which enforces the cap at `verify-all.sh:25`). Mitigation: substitution-only discipline proven in S1, S9, S10 (each shipped within ±2 lines); if forced, the "refactor build/fix preamble + Stage 1 + Stage 8 into shared reference" candidate from E03's v0.1.6 list is the prepared off-ramp (same shared-reference pattern as `agents/agent-preamble.md` and ADR-003). Operationalized via the Line-cap budget contract section below. Closes when all build/fix-touching stories ship without breach.

3. **Stop hook drift-coverage expansion silently misfires.** E04.S5 adds three new checks to `.claude/hooks/verify-all.sh`: pre-flight wording byte-identity across the 7 hard-abort skills, canonical-vs-template hook-pair byte-identity for `plan-mode-gate.sh`, and `.roughly/known-pitfalls.md` organize-suggestion threshold. The Stop hook is non-blocking and informational per ADR-005's stop-hook-v1 contract. Risk: a check fires false positives (e.g., a legitimate intentional asymmetry — setup's soft-abort form is the documented 8th — gets flagged each run) or false negatives (a glob misses a target file), and the Stop hook's non-blocking nature means contributors learn to ignore it. Mitigation: each new check uses the same `wc -l` / `diff` / `grep -c` mechanics already proven in the existing 4 checks (lines 25–30 of dogfood verify-all.sh); each is verified against both a known-good and a deliberately-broken sample before merge; setup's soft-abort intentional-divergence is explicitly excluded from the 7-skill byte-identity scope (codified by the existing known-pitfall). Closes when 30-day post-merge dogfood shows zero false-positive entries on `main`. Closure is by design post-release: a pre-release alternative would verify each check against known-good and deliberately-broken samples at PR review (covering correctness at merge) but cannot verify false-positive accumulation in real use. The 30-day dogfood window is the only test for the latter; risk stays technically open at v0.1.6 release and closes at the v0.1.7 retrospective.

   **Status update (2026-05-20, post-S5):** Pre-merge correctness mitigation **fulfilled** per Stage 7 + Stage 8 verification logs and the four-scenario Check 2 verification matrix (template missing → hook missing → drift detected → both present clean) added in cubic round 4. Defensive precondition guards layered during review — fixture-existence guard (Check 1), per-skill marker-presence pre-check (Check 1), tooling-unavailable branch when both `shasum` and `sha1sum` are absent (Check 1), three-level presence cascade (Check 2) — surface catastrophic-state failures rather than silently collapsing to `unique=1` (the empty-hash collapse silent-failure-hunter caught at Stage 6). Cross-platform fix surfaced at implementation: `wc -l <` produces BSD-padded output on macOS (`"      90"`) that breaks AC3.2's verbatim format string `"is 90 lines"`; resolved via `$((n))` arithmetic expansion in the drift message. Risk enters 30-day dogfood window per the by-design closure contract above; closes at v0.1.7 retrospective on zero false-positive accumulation evidence. **Pre-existing condition acknowledged (not regressed):** `agents/doc-writer.md` word cap drift entry now fires (557/500) — Path B inherited from E04.S8 (542 baseline + 15 from T4's bidirectional sync HTML comment for Check 3); the cap-revision v0.1.7 candidate is the structural resolution.

4. **ADR-011 framing locks v0.2.0 into a flag-only model prematurely.** E04.S7 codifies "skill flags as public API; env vars are debug-only" as ADR-011 and names v0.2.0's complexity flag (`Task N (Complexity: simple|standard|complex)`) as the first downstream consumer. Risk: v0.2.0's design surfaces a case where an env var is actually the right interface (e.g., a Haiku-routing override for cost-sensitive teams operating below a budget threshold), and ADR-011 makes that decision look like a violation requiring an ADR amendment rather than a documented carve-out. Mitigation: ADR-011's Consequences/Negative section explicitly carves out the env-var-acceptable case (debug-only, contributor-facing, no user-facing skill behavior change); the v0.2.0 ADR has license to footnote-extend rather than amend. Closes when ADR-011 ships and v0.2.0 plan-format-v2 work begins without an immediate contradiction.

5. **Doc-writer Process-step expansion regresses S3's two-part-gate.** E04.S8 adds an explicit multi-file-invocation failure-handling clause to `agents/doc-writer.md` (closes the S3 AC2 quality finding from the v0.1.5 audit). Risk: the addition modifies Process step ordering or the conditional-trigger logic for the organize-suggestion / test-integration suggestions that replaced retired `pitfalls-organized-v1` and `test-verify-v1` maturity checks, regressing the two-part-gate (user-confirmed pitfall AND doc-writer actually writes). Mitigation: strictly additive — a new "if multi-file write fails" branch alongside existing branches; touches no step-numbering or existing conditional logic; before/after diff must show zero edits to Process steps 1–5; agent body stays under 500 words. Closure is opportunistic on actual multi-file pitfall writes during the release window — the guard only exercises when the doc-writer agent is dispatched to update both `.roughly/known-pitfalls.md` and `CLAUDE.md` (or equivalent) in one invocation. If no such write occurs during v0.1.6, the risk stays open until v0.1.7 dogfood. Do not manufacture a pitfall write to force the close; opportunistic close is the right shape for an additive failure-handling clause. If two release cycles (v0.1.6 + v0.1.7) pass without exercise, promote to a synthetic CI-test story in v0.1.8 that exercises the multi-file path deliberately under controlled conditions.

   **Status update (2026-05-18, post-S8):** E04.S8 shipped the clause but with two relevant deviations from the original mitigation contract: (1) **AC3 500-word cap violated** (542/500 — Path B accepted at Gate 4 as the cleanest tradeoff against AC5 + AC1 + AC2 strict-additivity; the strict cap was unmaintainable under the combined constraints); (2) **clause reachability is hedged**, not structurally guaranteed — strict AC2/AC4 forbid placing the clause outside step 5, but step 5's outer gate is success-conditional on the file that may be FAILING in the target scenario, so the clause is structurally unreachable for its own target case under strict AC reading. Inline gate-override prefix `(always — overrides step 5's outer gate)` was added in `ecf7147` as a best-effort hedge depending on LLM-holistic prompt reading. **T2 synthetic test result:** agent did NOT emit the verbatim AC5 template — returned free-form prose with correct information but wrong format. Consistent with either the unreachable-clause hypothesis or the weak-anchoring hypothesis (or both). Risk does not close at S8 ship; it stays in the original opportunistic-close shape for v0.1.6 dogfood + the new v0.1.7 candidate cluster (AC2/AC4-AC1 contradiction + AC5 anchoring strength) provides a structural-resolution path. Recommend pulling the candidate cluster forward in v0.1.7 PM as the natural close path for Risk 5.

6. **E04.S3 cubic-gate format rejection.** E04.S3's blocking pre-merge gate requires `cubic review --json` to not surface retro-marked plans as actionable. Risk: cubic treats the Status block as actionable despite the markings, blocking S3 indefinitely while format candidates are iterated. Mitigation: format iteration is the story-body fallback (candidate adjustments include `<!-- CUBIC-IGNORE: historical -->` markers, switching to a different blockquote shape, or relocating the Status block); defer-to-v0.1.7 is an explicit acceptable outcome if format iteration does not converge within the release window. Risk closes when S3 either ships with a cubic-compatible format OR is explicitly deferred and the deferral is recorded in the v0.1.6 retrospective per the DoD allowance below.

---

## Line-cap budget contract

Carried forward from E03 with refreshed starting state.

**Starting state (post-v0.1.5):** build 298/300, fix 299/300, setup 287/300, help 163/300, upgrade 164/300, review-plan 92/300, audit-epic 141/300, review 88/300, verify-all 80/300, review-epic 64/300. (Verified via `wc -l skills/*/SKILL.md` 2026-05-14.)

- After each story merges, the implementer records `wc -l` deltas for any touched skill body in the PR description.
- E04.S1 and E04.S3 are the only stories projected to net-positive-touch build/fix. Both must operate via substitution-only or invoke the off-ramp (extract preamble / ABORT HANDLING / Stage 8 prose into a shared reference) before merging.
- Hard cap remains 300, enforced by `.claude/hooks/verify-all.sh:25`. A story whose merge would exceed 300 cannot ship.
- The implementer may at any time decide to land a refactor-only story (no behavior change, prose extraction only) ahead of the next pipeline-touching story if they project the budget will not hold. Such a refactor story is in scope for v0.1.6 even though it is not in the original story list.

This contract supersedes any per-story "No skill body exceeds 300 lines" ACs.

---

## Stories

Stories are grouped by cluster. Sequencing — which is by dependency, not cluster order — appears in the final [Sequencing](#sequencing) section.

### Cluster A — Path consolidation

#### E04.S1: Plan-path consolidation `docs/plans/` → `.roughly/plans/`

**Status:** ✅ **Merged 2026-05-20** via PR #43 (`4939875`, 8 commits — `3b2b542` main feat + `bb7168c` 2 new pitfalls + 6 cubic-review-fix iterations: `cdfaa9a` marker-at-source / destination-conflict, `ba8491b` setup baseline (later partially reverted), `ce7a671` setup conditional create, `622c903` final `*-plan.md` signal design, `02d9551` upgrade `mkdir -p` + plan count arithmetic, `ca1045f` marker-write failure handling + plan T2/T4 ordering). All 9 ACs met. **Spec drift caught at Stage 2:** original AC1 enumerated 4 skill bodies / 15 refs; actual scope was **5 bodies / 17 refs** — review-plan/SKILL.md was missed in PM-phase enumeration and surfaced only via AC1's `rg -Fn "docs/plans" skills/` verify command. Validates E04.S6's "every edit site enumerated" check and suggests a paired check (see v0.1.7 candidates: "AC verify command scope must match spec's enumerated file list"). **AC1 is now intent-correct, not literal:** the literal `rg -Fn "docs/plans" skills/` returns 14, not 0, because the new pre-flight block intentionally names `docs/plans/` as legacy-state detection, setup's soft-abort prose names it, and skills/upgrade/SKILL.md's new v0.1.6 migration step names it as the legacy source path. Documented intent-correct verify: `rg -Fn "docs/plans" skills/ | grep -v "pre-flight" | grep -v "setup/SKILL.md" | grep -v "upgrade/SKILL.md"` → 0. **Pre-flight signal redesign (4 iterations):** (1) bare `docs/plans/` directory presence → false-positive for unrelated planning trees; (2) added `.roughly/` co-existence + `.roughly/plans/`-absence → still defeatable; (3) required `.roughly/plans/` absence as third signal → defeated by setup auto-creating the dir; (4) **final**: `.roughly/` exists AND `docs/plans/*-plan.md` filename pattern exists → cubic accepted with one narrow accepted-limitation (project with unrelated `*-plan.md` files using same naming convention; workaround: rename collision files). Canonical block hash evolution: `cc6eb904 → aba9d38a → da9e25e1 → 8c03ed35`. **Other key design decisions:** marker file at SOURCE (`docs/plans/.migration-in-progress`), not destination — writing to destination would create `.roughly/plans/` and break the directory rename; v0.1.4 marker-at-source idiom is the correct precedent. Setup creates ONLY `.roughly/` — not `.roughly/plans/`; build/fix Stage 3 `mkdir -p` creates the plans dir on-demand (added per silent-failure-hunter Stage 6 finding; codified as new pitfall). Final line counts: build 298/300, fix 299/300 (both unchanged — substitution-only discipline preserved per Risk 2), upgrade 164 → 172 (+8 for new migration step), all other skills unchanged. Known-pitfalls.md: 86 → 90 lines (+4 for 2 new pitfalls; still well-organized, no re-organize triggered). **CHANGELOG entry already added** in feat commit per AC8.

**Maps to v0.1.6 candidate:** "Plan-path consolidation: `docs/plans/` → `.roughly/plans/` (raised 2026-05-13)" — the locked anchor candidate.

**Pre-locked decisions inherited from v0.1.5 (not re-litigated):**
- v0.1.6 timing
- Blocking pre-flight abort across the existing 7 hard-abort skills + 1 soft-abort skill (the candidate text's "6 pipeline skills" count was an off-the-cuff number in candidate prose, not a deliberate locked decision; match the existing 7-hard-abort + 1-soft-abort surface — asymmetry is the pitfall to avoid)
- `git status --porcelain` safety check in `/roughly:upgrade` for uncommitted plan work, with `--force-plans` opt-in

**Files touched:**

- `skills/build/SKILL.md` (L85, L122 — 2 refs; inline substitution-only)
- `skills/fix/SKILL.md` (L96, L129 — 2 refs)
- `skills/help/SKILL.md` (L85, L91, L102, L105, L108, L115, L118, L125, L134, L146 — 10 refs; densest consumer because Step 3's in-progress-detection logic scans `docs/plans/`)
- `skills/audit-epic/SKILL.md` (L44 — 1 ref)
- `skills/upgrade/SKILL.md` — new v0.1.6 plans-migration step alongside existing v0.1.2 + v0.1.4 steps. ~3-point structure (vs v0.1.4's 10-point) since plans are read-only files
- Pre-flight migration check in the 7 hard-abort skills (audit-epic, build, fix, review, review-plan, review-epic, verify-all) extended from one-form `.ruckus/` to two-form (`.ruckus/` OR `docs/plans/`)
- Setup's soft-abort form gets the same two-form check, preserving its "(proceed anyway / abort)" override
- `scripts/ci-dogfood.sh` (L153, L156 — assertion path update)
- `tests/fixtures/hello-roughly/` — fixture's reflected plan-path expectations
- `README.md` (L214 — prose)
- `CONTRIBUTING.md` — v0.1.6 plans-migration note appended under existing `## Migration`-style prose
- `CHANGELOG.md` — `### Changed`, `### Added` (migration step), `### Migration` subsection per v0.1.4 precedent
- `git mv docs/plans/ .roughly/plans/` — 25 historical plans relocated (`git mv` preserves history per E02.S2.6 precedent)
- `tests/fixtures/canonical-preflight-block.txt` — new fixture file; canonical two-form pre-flight block (single source of truth for AC4 verification and E04.S5 Check 1)
- **No new ADR.** Rationale lives in this epic + CHANGELOG, matching v0.1.2's `docs/claude/` → `.ruckus/` and v0.1.4's `.ruckus/` → `.roughly/` precedents (both shipped without ADRs).

**Acceptance criteria:**

- **AC1** — All `docs/plans/` references across the 4 skill bodies (`build`, `fix`, `help`, `audit-epic`) flipped to `.roughly/plans/`. Verify: `rg -Fn "docs/plans" skills/` returns zero matches.
- **AC1a (historical-fact carve-out, deliberate):** References to `docs/plans/` in historical-fact contexts MUST be preserved (NOT migrated). Allowlist: `CHANGELOG.md` (all entries are frozen history at release time — verified 4 references at L13, L51, L106, L242 by content match); `docs/planning/epics/complete/*` (completed-epic record, ~30 references across E01/E02/E03); `docs/planning/prompts/*` (PM prompts cite the path that existed at PM time); `docs/planning/archive/*` (archived planning artifacts); plan files in `docs/plans/` themselves (their internal references stay as documenting-the-state-at-write-time — `git mv` moves the files but their content is preserved verbatim); commit-message body text and PR descriptions. Verify post-migration: `rg -Fn "docs/plans" CHANGELOG.md` returns 4 matches by content (L-numbers may shift); `rg -Fn "docs/plans" docs/planning/epics/complete/ docs/planning/prompts/ docs/planning/archive/` match counts identical to pre-migration. A naive "zero matches anywhere" sweep would corrupt the historical record; AC1's zero-matches scope is `skills/` only.
- **AC2** — `git mv docs/plans/ .roughly/plans/` preserves history for all 25 historical plans. Verify: `git log --follow .roughly/plans/E03-S8-help-command-plan.md` shows the full pre-rename history (E02.S2.6 precedent).
- **AC3** — New v0.1.6 plans-migration step in `skills/upgrade/SKILL.md`. Three-point structure: (1) detect `docs/plans/` presence + `git status --porcelain docs/plans/` with `--force-plans` opt-in when dirty; (2) `git mv docs/plans/ .roughly/plans/` inside a git repo, plain `mv` fallback otherwise; (3) idempotency — skip entirely if `docs/plans/` absent. Marker file at `.roughly/plans/.migration-in-progress` for partial-failure resume per v0.1.4 pattern.
- **AC3a (design decision, deliberate):** No fallback-on-failure between `git mv` and `mv`. If git is detected but `git mv` fails, abort and surface the error verbatim; do NOT silently retry with plain `mv`. Inherits v0.1.4's idiom: post-failure recovery via plain `mv` produces confusing error output that complicates the user's mental model of which tool moved what. Recorded as a design decision, not implementation detail.
- **AC4** — Each of the 7 hard-abort skill bodies (audit-epic, build, fix, review, review-plan, review-epic, verify-all) contains a two-form pre-flight check (`.ruckus/` legacy state OR `docs/plans/` legacy state). The canonical two-form block is stored at `tests/fixtures/canonical-preflight-block.txt` (new file created in this story; single source of truth for the byte-identical contract). Each skill's pre-flight block is delimited by HTML comments `<!-- pre-flight:start -->` and `<!-- pre-flight:end -->` for reliable extraction. Verification: extract each skill's block via `awk '/<!-- pre-flight:start -->/,/<!-- pre-flight:end -->/' <skill>`, compute `md5sum` on each, plus `md5sum tests/fixtures/canonical-preflight-block.txt`; `sort -u` of the 8 hashes returns exactly 1 unique value. Setup's soft-abort form is the documented 8th and is explicitly excluded from this verification per the existing E03.S4 known-pitfall ("setup's soft-abort form must NOT be normalized to the canonical hard-abort form").
- **AC5** — `scripts/ci-dogfood.sh` assertion path updated (L153, L156 → `.roughly/plans/`); CI dogfood happy-path passes against the new path with the existing `--max-budget-usd 1.50` ceiling held. Verify on active surfaces only (historical surfaces excluded per AC1a): `rg -Fn "docs/plans" scripts/ README.md CONTRIBUTING.md` returns zero matches.
- **AC6** — S11b-2's full-scenario assertion block in `scripts/ci-dogfood.sh` (L100–210; currently 6 assertions — synthetic-PASS marker at L143, plan-file-exists at L153–156, `## Tasks` at L163, `### T1` at L174, `NAME=` in `greeter.sh` at L187, `echo` with `$NAME` at L204) all hold against the new `.roughly/plans/` path. The plan-file-exists assertion at L153/156 is the line updated; the other 5 are unchanged. Token cost held within the existing `--max-budget-usd 1.50` ceiling.
- **AC7** — `tests/fixtures/hello-roughly/` updated so the synthetic-PASS build cycle lands its plan in `.roughly/plans/`.
- **AC8** — CHANGELOG `## [0.1.6]` entry under `### Changed` documents the path move; new `### Migration` subsection per v0.1.4 precedent describes the user action ("Run `/roughly:upgrade` from each project to migrate `docs/plans/` → `.roughly/plans/`; `--force-plans` overrides the dirty-tree safety check"). README L214 and CONTRIBUTING.md `## Migration` brought current.
- **AC9** — No new ADR. Rationale lives in this epic + CHANGELOG, matching v0.1.4's `.ruckus/` → `.roughly/` precedent. CLAUDE.md ADR count unchanged at 9 by this story (E04.S7 bumps to 10).

**Verification:**

- **Local dogfood:** clone repo at v0.1.5-main, install this branch as the plugin, run `/roughly:upgrade` against a test project with `docs/plans/*-plan.md` present; confirm migration step executes and plans are moved to `.roughly/plans/` with `git log --follow` history preserved. Repeat with a dirty `docs/plans/*-plan.md` (uncommitted edit) to confirm the `git status --porcelain` safety check triggers and `--force-plans` overrides it.
- **CI dogfood:** S11b-2's happy-path scenario runs unmodified; assertion-path update is the only CI change. Token cost held within `--max-budget-usd 1.50`.
- **Negative dogfood:** run `/roughly:build` from a project still on v0.1.5 state (with `docs/plans/` populated but no `.roughly/plans/`) — pre-flight migration check fires with the two-form abort prose and redirects to `/roughly:upgrade`.

**Dependencies on other E04 stories:** None — anchor.

**Out of scope:**
- Renaming `docs/planning/` (the user-authored epics dir stays; this story only moves `docs/plans/`)
- Any plan-format content changes (plan-format-v2 is v0.2.0)
- Plan-file self-marking historical at completion — separate concern in E04.S3 (different surface area)
- ADR-011 — that's E04.S7's surface, separate from path consolidation per the candidate prose
- A separate ADR for the path change — established precedent (v0.1.2 and v0.1.4) is no-ADR-for-path-renames

---

#### E04.S2: Marker-aware resume reporting in `/roughly:upgrade`

**Maps to v0.1.6 candidate:** "Marker-aware resume improvements in `skills/upgrade/SKILL.md`"

**Context:** Today's v0.1.2 and v0.1.4 migration steps use a `.migration-in-progress` marker file for resume-after-partial-failure. The mechanism is correct, but resume is silent — the user sees the migration "just continue" without a clear "resuming from step 5 of 10" summary. E04.S1's new v0.1.6 plans-migration step inherits the marker pattern. v0.1.6 is the right release to add explicit resume-step reporting across all three migration steps (one shared idiom, three landing sites).

**Files touched:**
- `skills/upgrade/SKILL.md` — three migration steps gain a one-line resume-step report when `.migration-in-progress` is detected; one shared abort message addendum when a step aborts mid-migration. Current 164/300; projected ~10 net lines added.
- No agent file changes, no test fixture changes.

**Acceptance criteria:**

- **AC1** — Each of the three migration steps (v0.1.2 `docs/claude/` → `.ruckus/`, v0.1.4 `.ruckus/` → `.roughly/`, v0.1.6 `docs/plans/` → `.roughly/plans/`) emits a one-line resume report when it detects an existing `.migration-in-progress` marker. Canonical format: `"Resuming v0.1.X migration from step N of M (marker dated YYYY-MM-DD; steps 1-{N-1} already ran)."` The marker file's contents (ISO date + plugin version, per existing v0.1.4 spec) provide the date.
- **AC2** — Resume-report emits before any mutation in the step; if the user has reverted the partial state manually, the user can read the report and abort.
- **AC3** — When a migration step aborts mid-step (conflict prompt → user chooses abort, or `mv` returns non-zero), the existing abort message gains a `"Marker preserved at <path-to-marker> for resume on next /roughly:upgrade."` suffix. One shared suffix, three landing sites.
- **AC4** — Skill body remains ≤300 lines (current 164; ~10-line projection well within).
- **AC5** — Existing migration-summary line on successful completion (no resume needed) is unchanged.

**Verification:**

- **Manual dogfood — v0.1.4 step:** create `.ruckus/.migration-in-progress` in a test project, run `/roughly:upgrade`, confirm the resume-line emits with correct step number, M total, and marker date.
- **Manual dogfood — v0.1.6 step (post-E04.S1):** same with `.roughly/plans/.migration-in-progress`.
- **Manual dogfood — abort path:** trigger a conflict at v0.1.4 step 5 (`keep .ruckus` branch) by populating both `.ruckus/` and `.roughly/`; choose abort at the prompt; verify the marker-preserved suffix appears in the abort message.

**Dependencies on other E04 stories:** E04.S1 must ship first (E04.S1 introduces the v0.1.6 plans-migration step; E04.S2 adds the shared resume idiom across all three steps).

**Out of scope:**
- Changing the marker file format, location, or contents. Marker file format is unchanged from v0.1.4 spec (one line: ISO date + plugin version); this story reads the marker for the resume-step report but does not write or modify the format.
- Automatic recovery from "marker exists but both source and destination missing" data-loss path — current behavior (abort with marker preserved) is correct
- Reformatting existing migration summaries beyond the one-line resume addition and the abort-suffix addition

---

#### E04.S3: Plan-file self-marking historical at completion

**Maps to v0.1.6 candidate:** "Plan-file self-marking historical at completion (S8 deferral)"

**Context:** S8 retrospective surfaced that plan files become stale post-implementation — cubic reads them as active instructions; root cause for two late P2 findings during S8 review. S8's one-off mitigation was an explicit Status block at the top of `.roughly/plans/E03-S8-help-command-plan.md` (post-rename per E04.S1). Generalize: every implementation plan self-marks historical at completion. Right insertion point is build/fix Stage 7 (commit + wrap-up) — when the implementation is done, the orchestrator prepends a Status block to the plan before the final commit.

**Files touched:**
- `skills/build/SKILL.md` — Stage 7 prose addition instructing the orchestrator to prepend a Status block to the plan before the final wrap-up commit. ~3–4 net lines projected.
- `skills/fix/SKILL.md` — same Stage 7 addition. ~3–4 net lines.
- `CONTRIBUTING.md` — short subsection documenting the Status block format under existing `## Plan files`-style prose (or new subsection) so future contributors recognize it.
- `.roughly/plans/*.md` (post-E04.S1) — all 25 existing historical plans get retro-marked with the Status block via a one-shot Edit sweep in the same PR.
- **Not delegated to doc-writer.** Decision at PM time: keep the marking in Stage 7's inline prose rather than dispatching doc-writer. Rationale: doc-writer's current Process steps are organize-suggestion + test-integration suggestion (conditional on a known-pitfalls.md write); plan-historical-marking is unconditional on every successful build/fix completion. Different trigger surface, different conditional shape — inline is cleaner.

**Acceptance criteria:**

- **AC1** — `skills/build/SKILL.md` and `skills/fix/SKILL.md` Stage 7 instruct the orchestrator to prepend a Status block to the plan file before the final commit. Block format is fully specified — no LLM creative writing: `> **Status:** Historical — implemented and merged in commit <SHA> on <YYYY-MM-DD>. This plan was an active build/fix artifact; treat as historical reference only.` SHA is the wrap-up commit's parent (the implementation feat commit), date is the current date.
- **AC2** — Block insertion is via `Edit` (not `Write`) per the known append-only pitfall — `old_string` is the file's current first line (the plan title); `new_string` is the Status block + blank line + the plan title. Verify: `git diff` on the plan file in the wrap-up commit shows the original plan title line replaced by [Status block] + [blank line] + [original title line]; no other content removed or modified below the prepend site. (The diff naturally has `-<title>` / `+<Status block>` / `+<blank>` / `+<title>` due to `Edit`'s old_string/new_string semantics; the AC checks intent — only the title-line region is replaced — not literal zero `-` lines.)
- **AC3** — `skills/build/SKILL.md` and `skills/fix/SKILL.md` line counts post-merge ≤300. If the additive lines breach the cap on either file, invoke the line-cap budget contract's prose-extraction off-ramp (preamble / Stage 1 / Stage 8 shared reference) before adding Stage 7 content.
- **AC4** — `CONTRIBUTING.md` gains a `## Plan-file lifecycle` subsection (or appends to the existing plan-files section) documenting: format of the Status block, when it's added (Stage 7), what it signals to external review tools (cubic and similar treat as historical, not actionable). 10–15 content lines.
- **AC5** — All 25 existing historical plans in `.roughly/plans/` (post-E04.S1) get retro-marked with a Status block via a one-shot Edit sweep in the same PR. Each plan's SHA + date come from `git log --diff-filter=A --format='%H %ad' --date=short -- <plan-file> | tail -1` (first-add commit; the plan's earliest existence in repo). Verify: `grep -L "^> \*\*Status:\*\* Historical" .roughly/plans/*.md | wc -l` returns 0.

**Verification:**

- **CI dogfood:** S11b-2's happy-path build cycle against `hello-roughly` fixture — confirm the resulting plan file under `.roughly/plans/` has the Status block prepended in the wrap-up commit. S11b-2's existing structural assertions (plan exists, contains `## Tasks`, contains `### T1`) all hold; add one new assertion: plan contains `^> \*\*Status:\*\* Historical` after Stage 7.
- **Cubic-behavior validation is a blocking pre-merge gate.** Invoke `cubic review --json` against 2–3 retro-marked plans on the PR branch before merge. Required outcome: cubic does not surface the plan content as actionable findings. If cubic still flags marked plans as actionable, the Status block format is wrong and the story does not ship until the format is adjusted — candidate adjustments include `<!-- CUBIC-IGNORE: historical -->` markers, switching to a different blockquote shape, or relocating the Status block. The premise of E04.S3 is that the Status block solves the cubic-reads-plans-as-active problem; falsification means the story changes shape, not its commit posture.

**Dependencies on other E04 stories:** E04.S1 must ship first (the retro-mark sweep operates on `.roughly/plans/*.md`).

**Out of scope:**
- Changing plan-file content beyond the prepended Status block (plan-format-v2 is v0.2.0)
- Marking review-plan findings, spike docs, or audit reports as historical — separate concern
- Automated re-marking on plan-file mutation post-completion (Status block goes in once at Stage 7; subsequent edits don't re-mark)
- Delegating the marking step to doc-writer (decided against above)

---

### Cluster B — Drift hardening on `.claude/hooks/verify-all.sh`

#### E04.S4: Dogfood `.claude/hooks/verify-all.sh` cleanup

**Status:** ✅ **Merged 2026-05-14** via PR #39 (`3017861`, 5 commits — `9e665f2` initial fix + `614fe6a` cd guard backport + 3 follow-ups including `3e0a88d` final annotation). AC1, AC2, AC4, AC5 met as specified; AC3 ("no other body changes") soft-expanded to include the cd guard at L12 — `cd "$ROOT" 2>/dev/null || exit 0  # exit-0 contract: silent no-op on cd failure (see template L16–25)`. The third edit was missed at plan-write, plan-review (cycle 2 PASS), all three Stage 6 reviewers (silent-failure-hunter flagged but classified negligible), and Stage 7 verify-all — surfaced only by post-commit cubic review. Classified as backport-completeness rather than scope creep: the template's own comment block names cd failure as the exact class `set -e` removal makes you responsible for guarding. New pitfall recorded at `.roughly/known-pitfalls.md` L80: backport-from-template stories must verify against the reference end-to-end, not per-edit. Final line count: 57 lines (down 1 from 58 pre-S4). Pitfalls reorganized post-merge into 6 sections (29 entries; final 80 lines).

**Maps to v0.1.6 candidate:** "Dogfood `.claude/hooks/verify-all.sh` cleanup — apply S2's template fixes (`set -e` removal + `|| true` on `git rev-parse`) to the project-specific dogfood hook. Same latent bug pattern as the original S2 template; out of S2 scope per AC. One-shot cleanup commit."

**Context:** The dogfood Stop hook at `.claude/hooks/verify-all.sh` carries the same `set -e` + unguarded-`git rev-parse` latent bug that the original S2 template had before E03.S2 fixed it for the template. Today the hook starts with `set -e` (line 6) followed immediately by `ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"` (line 9). Under `set -e`, when invoked outside a git repo, `git rev-parse` exits non-zero with the suppressed stderr; bash's `set -e` semantics on assignment-from-command-substitution then kill the script before the `if [ -z "$ROOT" ]` guard at line 10 runs. The hook silently dies with a non-zero exit code instead of taking its intended no-op path. The bug surface is narrow — the dogfood hook only fires inside this repo's worktree — but the pattern is the same defect that S2 already fixed in the template, and the cost of backport is trivial.

**Files touched:**
- `.claude/hooks/verify-all.sh` — two changes:
   1. Drop `set -e` from line 6 (preserve `shopt -s nullglob` on line 7 as-is)
   2. Add `|| true` to the `git rev-parse` command substitution at line 9 to make the fail-soft explicit even without `set -e`

Net diff: 1 line removed (`set -e`), 1 line modified (`|| true` suffix). No other behavior changes.

**Acceptance criteria:**

- **AC1** — Line 6 of `.claude/hooks/verify-all.sh` no longer contains `set -e`. The `shopt -s nullglob` on line 7 is preserved verbatim.
- **AC2** — Line 9's command substitution is `ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"`. Defensive `|| true` makes the fail-soft explicit; the existing `if [ -z "$ROOT" ] || [ ! -f "$ROOT/.claude-plugin/plugin.json" ]` guard now reliably runs in the non-git case.
- **AC3** — No other changes to the hook body. The four existing checks (path drift, line cap, agent word cap, HTML comment integrity) and the `emit_drift_json` fallback chain are untouched.
- **AC4** — Hook still emits valid JSON via `jq → python3` fallback when drift is present; still exits 0 unconditionally; still silent no-op outside the plugin repo.
- **AC5** — No `set -uo pipefail` added — out of scope for this story (would surface unrelated latent issues; address only if a separate audit motivates it).

**Verification:**

- **Inside-repo invocation:** trigger the Stop hook by completing a Claude turn in this repo's worktree; confirm drift detection still fires when a known-bad state is staged (e.g., temporarily add a `.ruckus/known-pitfalls` reference to an agent file → hook emits drift; revert).
- **Outside-repo invocation:** copy `.claude/hooks/verify-all.sh` to a non-git directory (e.g., `/tmp`), invoke with `bash /tmp/verify-all.sh < /dev/null` — must exit 0 with no output. Pre-fix: script dies on line 9. Post-fix: hits the `if [ -z "$ROOT" ]` guard and exits cleanly.
- **No structural-assertion regression:** existing dogfood Stop-hook drift output during the v0.1.6 dev cycle should remain stable (same drift entries on the same conditions).

**Dependencies on other E04 stories:** None — independent. Recommend landing **before** E04.S5 so the drift-coverage expansion in S5 starts from the corrected base.

**Out of scope:**
- Adding `set -uo pipefail` (different audit; v0.1.7 candidate if motivated)
- Refactoring the four existing checks into a different shape
- Modifying the `emit_drift_json` fallback chain
- Backporting any non-S2-template changes from the templated stop-hook

---

#### E04.S5: Stop hook drift coverage expansion

**Status:** ✅ **Merged 2026-05-20** via PR #44 (`bd8e37c`, 6 commits — main feat + 1 plan record + 1 pitfalls record + 3 cubic review-fix iterations). All 8 ACs met. **Final line count:** `.claude/hooks/verify-all.sh` 57 → 114 (soft cap 150). **Design evolution through 4 cubic rounds + 1 silent-failure-hunter intervention:** (1) `md5sum` initial mechanic rejected as macOS-incompatible (round 3 P1) → switched to `shasum` → added `sha1sum` fallback (round 3 P2) for BusyBox/Alpine minimal containers; detection via `command -v` chain at script setup. (2) **Catastrophic-state silent-failure-hunter Critical at Stage 6:** when all 8 hash inputs produce the empty-string hash (e.g., all skills missing markers) they collapse to `unique=1`, masking a workspace-broken state as PASS → fixture-existence guard added; round 1 P2 layered a per-skill marker-presence pre-check producing a directed `pre-flight markers missing in skills: <list>` entry over the generic `unique blocks` entry; round 3 added a tooling-unavailable branch when both `shasum` and `sha1sum` are absent. (3) **Check 2 scope broadened mid-review** per ADR-009 silent-protection-unregistration risk — from byte-identity-only to three-level cascade (template missing → hook missing → byte-identity drift), surfacing the exact failure ADR-009 was written to prevent rather than silently skipping (round 4 P2). (4) Round 2 P3 ×2 — out-of-scope-pair clarification (verify-all-stop-hook ↔ dogfood verify-all.sh) reworded with grammatical contrast ("a DIFFERENT pair ... intentionally NOT checked"; "a separate, unrelated pair ... intentionally NOT enforced") after both inline comment + CONTRIBUTING.md item proved misreadable. (5) Round 3 P3: doc-writer.md sync comment dropped "Check 3" (no such label existed in verify-all.sh) in favor of the unique `PITFALLS_ORGANIZE_THRESHOLD` constant name as the grep anchor; this also enforced the broader principle from `.roughly/known-pitfalls.md` L72 (citing labels that don't exist in the target file is silent doc rot). **Cross-platform fix surfaced at implementation time:** macOS BSD `wc -l <` emits left-padded output (`"      90"`); naive `$n` interpolation breaks AC3.2's verbatim format string. Resolved via `$((n))` arithmetic expansion in the drift message — strips padding cross-platform without affecting the existing GNU-only L24/L30 sites (which never fire today and stay out of scope per AC8). **AC8 boundary observation (process learning, recorded as v0.1.7 candidate):** the story scoped checks 1/2/3 to specific invariants ("no new invariants enforced beyond the three named"), but two rounds of review pushed defensive precondition guards into what could be read as existence enforcement (Stage 6 fixture-existence guard for Check 1; round 4 Check 2 presence cascade). Right reading: defensive precondition guards for an existing invariant are NOT new invariants — they treat "files missing" as "check cannot run" with directed diagnostics, not as new structural rules. AC8 preserved in spirit. **3 new pitfalls captured** in `.roughly/known-pitfalls.md` (+12 lines on capture; file now at 108 lines and intentionally triggering Check 3 every run as designed — closes the E03.S3 manual-edit coverage gap by exhibiting the threshold behavior): (1) `md5sum` not portable on stock macOS — use `shasum` with `sha1sum` fallback; (2) empty-hash collapse in extract|hash|sort -u pipelines — precondition guards + tooling-unavailable branch as fix; (3) `wc -l <` BSD padding leaks into format-equality tests — `$((n))` arithmetic expansion fix. **Pre-existing condition (not regressed):** `agents/doc-writer.md` 557/500 word cap entry continues to fire — Path B inherited from E04.S8 (542 baseline + 15 from T4's bidirectional sync HTML comment for Check 3); v0.1.7 cap-revision candidate is the structural resolution. **Risk 3 enters 30-day dogfood window** per epic L27 by-design closure contract.

**Maps to v0.1.6 candidates (3 bundled per Cluster B reorganization):**
1. "Pre-flight wording drift detection in `.claude/hooks/verify-all.sh` — today's hook checks line caps and HTML comment integrity but not skill-prose uniformity"
2. "Drift checker for the canonical-vs-template hook pair — `.claude/hooks/plan-mode-gate.sh` and `skills/setup/templates/plan-mode-gate.sh.template` are kept in sync manually; a `verify-all.sh` check would catch drift"
3. "Manual-edit detection for `.roughly/known-pitfalls.md` — pushing organize-suggestion logic into the Stop hook so manual edits are caught" (closes the S3 coverage gap where doc-writer-only triggers miss manual edits)

**Context:** Today's `.claude/hooks/verify-all.sh` carries four checks: path drift, skill line cap, agent word cap, HTML comment integrity. Three additional uniformity invariants are currently enforced only by manual `rg`/`diff` audits (the pre-flight wording invariant from E03.S4; the canonical-vs-template hook-pair invariant from E03.S1) or by a one-trigger conditional in `agents/doc-writer.md` that misses manual edits (the `.roughly/known-pitfalls.md` organize-suggestion from E03.S3). Bundling all three into one PR is the right shape — same file, same `wc -l` / `diff` / `grep -c` mechanics, identical risk profile, one cycle of false-positive validation.

**Files touched:**
- `.claude/hooks/verify-all.sh` — three new check blocks appended after the existing HTML comment integrity check, before `emit_drift_json`. Each block is ~10 lines (scan + compare + emit). Projected post-merge: current 45 lines → ~75 lines.
- `agents/doc-writer.md` — bidirectional sync comment naming `.claude/hooks/verify-all.sh` and its `PITFALLS_ORGANIZE_THRESHOLD` constant alongside doc-writer's matching prose conditional. No conditional-logic change.
- `CONTRIBUTING.md` — `## Stop hook drift checks` subsection (or expansion of existing `## CI`) enumerates the 7 checks with one-line descriptions. ~15–20 content lines. For the dogfood-`verify-all.sh` ↔ template-`verify-all-stop-hook.sh.template` divergence: **cite-and-link, do not restate.** Cite section `#### E03.S2: Stop-hook-v1 maturity check completion` (under `### Trust hardening cluster`) of [E03-trust-and-ergonomics.md](complete/E03-trust-and-ergonomics.md), quoted phrase `"The dogfood [...] stays as-is (project-specific drift checks for the plugin's own development); this story produces a separate, project-agnostic template."` This phrasing appears verbatim twice in the E03 epic — citation by quoted phrase survives reformatting even if line numbers shift.

**Acceptance criteria:**

**Check 1 — Pre-flight wording byte-identity across 7 hard-abort skills:**
- **AC1.1** — New check block fires when the 7 hard-abort skill bodies' pre-flight migration check blocks (extended in E04.S1 to two-form, delimited by E04.S1's `<!-- pre-flight:start -->` / `<!-- pre-flight:end -->` markers) do not produce a single unique hash. Extraction per file: `awk '/<!-- pre-flight:start -->/,/<!-- pre-flight:end -->/' <skill>`; pipe to `md5sum`; include `md5sum tests/fixtures/canonical-preflight-block.txt` in the set; `sort -u` of the 8 hashes returns exactly 1 unique value. The naive `sort -u` on raw block content is wrong for multi-line blocks (it counts unique LINES, not unique BLOCKS) — extract-then-hash is the correct mechanic. The check scans the 7 named skill files only (audit-epic, build, fix, review, review-plan, review-epic, verify-all); setup is explicitly excluded per the E03.S4 known-pitfall ("setup's soft-abort form must NOT be normalized to the canonical hard-abort form").
- **AC1.2** — Drift entry format on failure: `"- pre-flight wording drift: <N> unique blocks across 7 hard-abort skills (expected 1)"`.
- **AC1.3** — Verification: temporarily edit one skill's pre-flight block (e.g., change `.ruckus/` to `.RUCKUS/`); confirm the check emits the drift entry. Revert.

**Check 2 — Canonical-vs-template hook-pair byte-identity (`plan-mode-gate.sh` only):**
- **AC2.1** — New check block fires when `.claude/hooks/plan-mode-gate.sh` and `skills/setup/templates/plan-mode-gate.sh.template` are not byte-identical (`diff` returns non-zero).
- **AC2.2** — Drift entry format on failure: `"- plan-mode-gate hook drift: .claude/hooks/plan-mode-gate.sh and skills/setup/templates/plan-mode-gate.sh.template differ (run \`diff\` for details)"`.
- **AC2.3** — Verification: temporarily edit one line of the canonical hook; confirm check emits drift. Revert.
- **AC2.4** — The `verify-all-stop-hook.sh.template` ↔ dogfood `verify-all.sh` pair is **explicitly out of scope** for this check. The dogfood hook is project-specific by design (E03.S2 documents the divergence — see CONTRIBUTING.md citation in this story's Files Touched). Only the `plan-mode-gate.sh` pair is byte-identical-by-contract.

**Check 3 — `.roughly/known-pitfalls.md` organize-suggestion threshold:**
- **AC3.1** — New check block fires when `.roughly/known-pitfalls.md` is above 80 lines (`wc -l > 80`, strict greater-than). Threshold matches the existing doc-writer Process step 5 conditional from E03.S3 (verified 2026-05-14 against `agents/doc-writer.md:33` which uses `if line count > 80`).
- **AC3.2** — Drift entry format on failure: `"- .roughly/known-pitfalls.md is <N> lines (>80 threshold) — consider organizing"`.
- **AC3.3** — Check fires regardless of whether the most recent edit came from doc-writer (the agent-triggered organize-suggestion) or a manual `Edit` (the gap surfaced in E03.S3's coverage analysis). This is the coverage-completion that closes the manual-edit gap.
- **AC3.4** — Threshold is a single named constant in the script (`PITFALLS_ORGANIZE_THRESHOLD=80`). **Bidirectional sync comments**, not one-way. In `.claude/hooks/verify-all.sh`, the constant is preceded by a comment naming `agents/doc-writer.md` (specific file + section) as the matching policy-parameter site. In `agents/doc-writer.md`, the matching `>80` conditional is preceded by a similar comment naming `.claude/hooks/verify-all.sh` (specific file + constant name). Each consumer points at the other. Drift between them is visible to both manual `grep` audit and to whichever consumer is being edited at the time. A v0.1.6+ candidate for a shared-constant mechanism is listed in [v0.1.7 candidates](#v017-candidates).
- **AC3.5** — Verification uses a deliberately-broken sample (consistent with the cross-cutting verification pattern in this story): temporarily append 1+ extra line(s) to `.roughly/known-pitfalls.md` to push it above 80 lines (e.g., back to 82 for parity with the pre-S4 state before doc-writer's organize pass brought the file to exactly 80); confirm the check fires with the AC3.2 drift entry format; revert. The file at 80 lines post-S4 (verified 2026-05-14) sits at the boundary, not above it — under the `>80` strict semantic, at-boundary is not a fire condition. Post-merge in normal use, the check fires whenever new pitfalls push the file above 80, until the next organize pass brings it back to ≤80.

**Cross-cutting:**
- **AC4** — All three new checks emit one-line drift entries in the same format as existing checks (`- <description>\n`); the existing `emit_drift_json` pipeline handles them unchanged.
- **AC5** — Hook still exits 0 unconditionally per the non-blocking informational contract.
- **AC6** — `.claude/hooks/verify-all.sh` line count post-merge: documented in PR description for the line-cap budget tracking pattern. Soft cap of 150 lines on this hook (matches the SKILL.md 300-line discipline at proportionate scale for a single-purpose hook). **Current 57 lines post-S4** (re-baselined 2026-05-14; pre-S4 was 58, S4 net `-1` from `set -e` removal — original baseline of "45 lines" in this AC pre-S4 was wrong); projected ~87 post-S5 if all three new check blocks land at ~10 lines each; soft cap leaves headroom for ~6 more drift checks across future releases before triggering a refactor.
- **AC7** — `CONTRIBUTING.md` subsection enumerates all 7 checks with one-line descriptions; cites E03.S2's divergence documentation by section heading + quoted phrase (form survives reformatting).
- **AC8** — No new pitfalls or invariants enforced beyond the three named.

**Verification (against deliberately-broken samples per Risk 3 mitigation):**

For each of the three checks, the PR includes a "verification log" in the description showing the check's behavior against:
- A known-good state (baseline `main`): check does not fire.
- A deliberately-broken state (temporary edit reverted before commit): check fires with the expected drift entry format.

For Check 3 specifically, known-pitfalls.md is at 80 lines post-S4 — at the `>80` strict threshold boundary, not above it. A deliberately-broken sample is needed: temporarily append 1+ line(s) to push the file above 80 (e.g., back to 82 for parity with the pre-S4 state before doc-writer's wrap-up organize pass), confirm the check fires with the AC3.2 drift entry format, revert. Aligns with AC3.5.

**Plan-write guidance (carried forward from S4 + S6 retrospectives, 2026-05-14/15):**

- **Diff result against reference, not just per-edit (from E04.S4).** S5 is backport-shaped — it imports three new check patterns into `.claude/hooks/verify-all.sh` based on the canonical pre-flight block fixture and the template hook pair. The plan must add an explicit Stage 7 step that diffs the resulting hook block against the reference, not just verify per-edit completeness. The S4 plan enumerated 2 edits when the template had 3 coordinated changes; the missed third edit passed plan-review, Stage 6, and Stage 7 verify-all, surfaced only by post-commit cubic review. Reference: `.roughly/known-pitfalls.md` L80 backport-completeness entry.
- **Grep-verify cited examples at plan-write time (from E04.S6).** Any worked-example prose that quotes content from another file (canonical-example citations in ACs, paragraph snippets in CONTRIBUTING.md, fixture content) must be grep-verified against source at plan-write time. S6's cycle-1 plan cited setup/SKILL.md Branch 4 with quoted transition tokens that did not exist in source; the plan's own verify-steps only checked the new bullet's lead phrases, not the cited examples themselves. Pattern: every cited quote in a plan needs a paired `grep -Fn` verify command against the source file.

**Dependencies on other E04 stories:**
- **E04.S4 must ship first.** S5 adds to the hook body; S4 fixes the latent `set -e` bug. Adding new check blocks to a hook that dies on line 9 outside git would mask the new behavior.
- **E04.S1 must ship first.** Check 1 verifies the two-form pre-flight block created in S1; without S1, Check 1 has no canonical block to compare against.

**Out of scope:**
- Adding a 4th, 5th, or further drift check to the hook in this PR (no matter how appealing during review)
- Converting the dogfood Stop hook into something byte-identical to the user-facing template (intentional divergence, documented in E03.S2)
- Promoting Stop hook to blocking-mode (`exit 1` on drift) — explicitly deferred per `docs/ROADMAP.md` "Deferred" section ("Breaking change for contributors. No scheduled release.")
- Replicating any of these checks in CI (`.github/workflows/dogfood.yml`) — current contract is "Stop hook is informational; CI is enforcement." Splitting is a separate v0.1.7+ design discussion.
- Modifying the `emit_drift_json` jq/python3/no-emit fallback chain
- Test-config detection or test-integration suggestions from the retired `test-verify-v1` check (S3 folded those into doc-writer; not in scope here)
- Single-source `PITFALLS_ORGANIZE_THRESHOLD` mechanism — v0.1.7 candidate

---

### Cluster C — Process codification

#### E04.S6: Plan-discipline codification

**Status:** ✅ **Merged 2026-05-15** via PR #40 (`9a18161`, 2 commits — `2823030` feat + `9d61030` post-pipeline correction). All 6 ACs met. Two cycles of post-implementation review: **cycle 1** caught fabricated worked-example prose — the initial CONTRIBUTING.md sequential-structure carve-out cited `skills/setup/SKILL.md` Branch 4 with quoted transition tokens ("then snapshot/apply/promote") that did not exist in source; code-reviewer and silent-failure-hunter both flagged independently. **Cycle 2** caught carve-out over-permission introduced by the cycle-1 fix — "functional role labels per step" as a standalone qualifier let mutually-exclusive case structures claim the sequential carve-out; fix tightened to require an invariant clause OR explicit previous/next-step references. **Post-PR desk-check** caught a third issue the pipeline missed: the fixtures README documented `claude /roughly:review-plan <path>` as an invocation example, but the skill is `disable-model-invocation: true` per ADR-001 — the example wouldn't run. Silent-failure-hunter flagged this in cycle 1 as Info; implementer downgraded as cosmetic; user-led desk-check caught the gap; commit `9d61030` corrected to manual desk-check + subagent dispatch paths. Two new v0.1.7 candidates surfaced (see [v0.1.7 candidates](#v017-candidates)).

**Maps to v0.1.6 candidates (3 bundled):**
1. "Plan-template check: enumerate every edit site, no 'confirm during edit' footnotes (S9 deferral)"
2. "Spec runtime-signal-source requirement at plan-write time (S8 deferral)"
3. "Multi-branch case-dispatch language convention (S8 deferral)"

**Context:** Three retrospective patterns from v0.1.5 — S9's missed decision-table summary lines (build L185 / fix L192) needing review-fix cycle 1, S8's 9 cubic cycles to converge on the branch-association heuristic for "in-progress plan" detection, and S8's first-draft fall-through prose in the Case A/B/C/D/E dispatch — all surfaced as deferred candidates. Each is preventable by a small process artifact: two `/roughly:review-plan` AC additions (catch in pre-implementation review) and one CONTRIBUTING.md convention (catch in skill-authoring discipline). Bundling into one story keeps the codifications atomic — the case-dispatch convention is short enough that a separate story risks silent deprioritization.

**Files touched:**
- `skills/review-plan/SKILL.md` — two new AC additions to the review checklist (current 92 lines; +~15–20 projected, comfortably under 300)
- `CONTRIBUTING.md` — new `## Skill authoring conventions` subsection (or append to existing convention prose) documenting case-dispatch language with named exception for genuinely-sequential structures

**Acceptance criteria:**

**AC1 — Enumerate every edit site (no "confirm during edit" footnotes).**
- `skills/review-plan/SKILL.md` gains a check entry: "When a task description enumerates a list of edit sites (line numbers, file ranges, named blocks), every site must appear as a separately numbered entry in the task. 'Confirm during edit' footnotes are rejected."
- **Bright-line carve-out:** when the plan documents structural uniformity with named rationale, consolidated enumeration is allowed. The bright line: the plan body must contain the words "structural uniformity" (or equivalent explicit phrase) AND name the count and pattern (e.g., "27 abort-prose sites, byte-identical canonical block"). Canonical positive example: E03.S9 implementation plan. Outside this exact form: no carve-out; per-site enumeration is required.
- Cite as canonical positive example: E03.S9 implementation plan's enumerated 27 sites. Cite as negative example: E03.S9 cycle-1 stranded summary at build L185 / fix L192 (the surfacing failure).

**AC2 — Name the runtime-signal source.**
- `skills/review-plan/SKILL.md` gains a check entry: "Any task that performs runtime detection (mtime, branch name, file content, JSON field, command output) MUST name the observable signal source — the specific command, file path, or field whose output the conditional reads."
- **The principle is rooted in a real difference of kind, not a convenience trade-off:** signal source is a correctness property — a conditional that does not name its data source is unverifiable, so the review gate catches an actual class of bug (E03.S10 first-draft "if Stage 5c was hit by changes to test files" was exactly this — no mechanism existed to detect "test files"). Policy parameters (thresholds, comparators, target values) are a maintenance property — a duplicated `80` is a low-severity, greppable, non-silent drift risk. Different problem classes, different mechanisms. The review-plan gate covers the correctness class only. As secondary support: requiring single-source policy parameters at this AC would cascade single-source mechanisms across the codebase before the shared-constant infrastructure is built (tracked separately as v0.1.7 candidate).
- **Bright-line carve-out:** signal source = WHERE data comes from (the command/file/field whose output is read); policy parameter = WHAT decides the conditional outcome (thresholds, comparators, target values). Naming the signal source is required; single-source enforcement of policy parameters is explicitly NOT required by this AC. Both consumers of E04.S5 Check 3 read the same signal source from the same file — compliant. The duplicated `80` threshold is a policy parameter, not a signal source.
- Cite as canonical positive example: E03.S10's "if the failure output contains assertion errors or test-runner output" (command-output signal). Cite as negative example: E03.S10 first-draft "if Stage 5c was hit by changes to test files" (no detection mechanism — ungrounded).

**AC3 — Multi-branch case-dispatch language convention.**
- `CONTRIBUTING.md` gains a `## Skill authoring conventions` subsection (or appends to existing prose) documenting: multi-branch case-partition prose in skill bodies must explicitly state "evaluate top-to-bottom; execute only the first matching case" and reject fall-through prose.
- **Bright-line carve-out:** structure must use ordered enumeration (Step A → Step B → Step C → Step D) AND explicit "after Step N completes, proceed to Step N+1" transition prose to qualify as genuinely sequential. Canonical example: `skills/setup/SKILL.md` Step 5d Branch 4 transactional commit (Steps A → B → C → D). Outside this exact form: case-dispatch language is required.
- Cite canonical case-dispatch example: `skills/help/SKILL.md` Step 3 (Cases A–E, post-E03.S8 form). 10–15 content lines.

**Cross-cutting:**
- **AC4** — `skills/review-plan/SKILL.md` post-merge ≤300 lines (current 92; +~15-20 projected).
- **AC5** — Each new AC has at least one named canonical positive example AND one named negative example (sourced from v0.1.5 retrospective material).
- **AC6** — Self-verification: run `/roughly:review-plan` against a synthetic plan that exercises each AC's PASS and NEEDS REVISION variants before merge.

**Verification:**

- **Synthetic plan verification (pre-merge):** craft three pairs of small synthetic plans (PASS + NEEDS REVISION) — one pair per AC. Run `/roughly:review-plan` against each. Required outcome: all three PASS plans return PASS; all three NEEDS REVISION plans return NEEDS REVISION with the AC cited by name in the verdict.
- **Negative-control:** craft a plan that has the structured-uniformity carve-out language. Run `/roughly:review-plan`; required outcome PASS (carve-out applies, not a false-positive flag).
- **CI dogfood:** S11b-2's happy-path build cycle continues to PASS — the new ACs do not break the existing fixture's plan structure.

**Dependencies on other E04 stories:** None. Independent of Cluster A/B. Pairs with E04.S7 (ADR-011) as codification cluster but no shared files.

**Out of scope:**
- ADR-011 (separate story E04.S7; different artifact layer)
- Single-source policy-parameter mechanism (v0.1.7 candidate; out of scope per S6's signal-source-only AC scope)
- Plan-format-v2 conventions (v0.2.0)
- Refactoring existing review-plan checks beyond the two AC additions
- Modifying any pipeline skill (build, fix, etc.) to enforce the case-dispatch convention at runtime — convention is contributor-facing, not LLM-enforced
- Enforcing the case-dispatch convention via `verify-all.sh` — out of E04.S5's scope; future v0.1.7+ candidate if a forcing function appears

---

#### E04.S7: ADR-011 — Skill flags as public API, env vars as debug-only

**Status:** ✅ **Merged 2026-05-15** via PR #41 (`b92e16f`, 3 commits — `92516b2` feat + `cef0c27` bold-grep pitfall capture + `0d2edb2` post-merge architect review refinements). All 5 ACs met. ADR-011 file at 49 lines (`docs/adrs/ADR-011-skill-flags-as-public-api.md`). Pipeline: plan-review PASS first iteration; 2 Stage 6 review cycles (cycle 1 found 4 issues including Alternatives label mismatch, CLAUDE.md count-drift implying ADR-010 exists, missing negative carve-out example, README gap; cycle 2 clean). Post-merge architect re-review (feature-dev:code-architect) returned 3 "Consider" + 1 actionable Nit — all applied: Decision section gains explicit threshold test for "user-facing"; carve-out criterion stated as a rule (not example-only); Forward References drops v0.2.0 syntax detail to honor "frame forward refs by role only" convention; Negative consequence split from one dense paragraph into four scannable bullets. **Notable decision during build:** plan-file inclusion (silent-failure-hunter flagged AC5's "doc-only" framing) resolved by E04.S6 precedent — `docs/plans/` is doc scaffolding, not skill/agent/hook/script/test/template. 1 new pitfall captured at `.roughly/known-pitfalls.md` L80: bold-decorated markdown field labels break literal-substring greps (sibling of the metachar pitfall; distinct failure mode — pattern is fine, haystack decoration silently breaks the match).

**Maps to v0.1.6 candidate:** "'Skill flags as public API; env vars are debug-only' principle (S11b-2 OQ1 deferral)"

**Context:** S11b-2 OQ1 (resolved 2026-05-08) chose `--ci` flag over a `ROUGHLY_CI_AUTO_PASS` env var on DX grounds: flags are part of skill public API (visible in invocation history, self-documenting in scripts), whereas env vars are side doors that can silently leak from CI debug sessions into local development. The principle is implicit in S11b-2's option (c) choice but not codified. Codifying as ADR-011 (a) anchors the precedent for v0.2.0's complexity flag (`Task N (Complexity: simple|standard|complex)`), (b) is more discoverable than a CONTRIBUTING.md note alone for a multi-release precedent, (c) gives the v0.2.0 ADR (ADR-010, reserved for plan-format-v2) a referenceable foundation.

**Files touched:**
- `docs/adrs/ADR-011-skill-flags-as-public-api.md` — new file. Format matches existing ADRs (Status, Context, Decision, Consequences). Target ~150–200 words content.
- `CLAUDE.md` — Key Design Decisions table gains an ADR-011 row; narrative ADR count bumps 9 → 10.
- `docs/adrs/README.md` — Current ADRs list adds ADR-011 with one-line summary.
- `CONTRIBUTING.md` — one-line pointer added to existing skill-authoring conventions prose (or to the new convention section created by E04.S6 if that story merges first).

**Acceptance criteria:**

- **AC1 — ADR file created at `docs/adrs/ADR-011-skill-flags-as-public-api.md`:**
   - Format matches existing ADR-009 / ADR-008 structure. Top-of-file metadata: `**Status:** Accepted` (verified — matches ADR-008 and ADR-009 value verbatim, not "Approved") plus a date stamp. Section headings in this order matching ADR-009 precedent: `## Context`, `## Decision`, `## Consequences`, `## Alternatives Considered`. Optional additional sections between `## Decision` and `## Consequences` if rationale warrants (ADR-009 uses this pattern for `## Empirical Verification`, `## Spike-Doc Correction`, etc.).
   - **Context:** Cites S11b-2 OQ1 resolution (2026-05-08) and the three options considered (heredoc-fed stdin / override-token env var / flag). Names the silent-leak failure mode of env vars as the primary motivation.
   - **Decision:** User-facing skill behavior changes are flags in `$ARGUMENTS`, not environment variables. Flags are part of skill public API: visible in invocation history, self-documenting in CI scripts, harder to silently leak across contexts.
   - **Consequences/Positive:** Explicit invocation surface (auditable via `claude` invocation history); self-documenting in CI scripts and rerun history; flag-detection follows the standalone-token form documented in `.roughly/known-pitfalls.md`.
   - **Consequences/Negative:** Flag proliferation risk on long-lived skills. Env-var-acceptable carve-out: debug-only, contributor-facing, no user-facing skill behavior change. Cites a hypothetical Haiku-routing budget threshold for cost-sensitive teams as an example of an env-var case that v0.2.0 might land. The example is explicitly hypothetical at ADR-write time — no real v0.2.0 env-var case has surfaced yet; if one does, ADR-011 may need amendment or carve-out extension at v0.2.0 ADR-write time.
   - **Forward references:** v0.2.0's complexity flag is named as the first downstream consumer. The ADR covering plan-format-v2 (currently slotted as ADR-010) should treat ADR-011 as foundational for its own user-facing-flag-vs-env-var decisions. ADR-011 does not specify ADR-010's internal structure, citation form, or content placement — only the relationship: v0.2.0's user-facing surface inherits ADR-011's principle. v0.2.0 honors the relationship however it wants.

- **AC2 — `CLAUDE.md` ADR count updated:**
   - Key Design Decisions table gains a new row: `ADR-011 | User-facing skill behavior changes are flags, not env vars`.
   - CLAUDE.md narrative ADR count bumps 9 → 10. Verify by `grep -Fn` (per the regex-metachar pitfall) against the specific stale phrasings: `"9 ADRs"`, `"ADR-001 through ADR-009"`, `"ADR-009 in CLAUDE.md"`, `"9 Architecture Decision Records"`. Each grep result must be either zero hits (phrase did not exist) or replaced with the post-update phrasing. No regex range expressions.

- **AC3 — `docs/adrs/README.md` index updated:**
   - Current ADRs list adds ADR-011 with one-line summary matching the CLAUDE.md row.

- **AC4 — `CONTRIBUTING.md` cross-reference:**
   - Existing skill-authoring conventions prose (or the new `## Skill authoring conventions` section created by E04.S6 if that story merges first) gains: "User-facing skill behavior changes are flags, not environment variables (see [ADR-011](docs/adrs/ADR-011-skill-flags-as-public-api.md))." 1 line.

- **AC5 — No skill, agent, hook, template, script, fixture, or test changes:**
   - ADR-011 is doc-only. Verify: `git diff --stat` on the PR shows only `docs/adrs/`, `CLAUDE.md`, and `CONTRIBUTING.md` paths.

**Verification:**

- **Pre-merge:** `/roughly:review-plan` dispatched on the ADR draft (treated as the plan for an ADR-creation task). Required PASS conditions: S11b-2 OQ1 cited by name; v0.2.0 complexity flag named as first downstream consumer; env-var carve-out present in Consequences/Negative; relationship to ADR-010 stated by role (not by content/structure).
- **Post-merge readability (test the artifact against the question a future reader actually brings to it):** a new contributor reads ADR-011 in isolation (without external context) and can answer: "Is `ROUGHLY_HAIKU_BUDGET_USD=1.00` allowed?" Expected answer: depends — if it's a debug-only contributor knob with no user-facing skill behavior change, the carve-out applies; if it changes how `/roughly:build` behaves for end users, it should be a flag.
- **v0.2.0 cross-reference compatibility check:** validate that ADR-011's framing does not contradict any reasonable form of a future v0.2.0 ADR that introduces a complexity flag. Thought-experiment test cases: can a v0.2.0 ADR justify the complexity flag as a flag (not an env var) by citing ADR-011's role? Can a v0.2.0 ADR justify a contributor-facing env-var override under ADR-011's carve-out without amending ADR-011? If both answers are "yes," ADR-011 is foundation-shaped; if either is "no," reword. Do NOT pre-draft ADR-010's paragraph — validate compatibility, not content.

**Dependencies on other E04 stories:** None. Independent. Pairs with E04.S6 (same codification cluster) but no shared files; can land in either order.

**Out of scope:**
- The v0.2.0 ADR (ADR-010 plan-format-v2) — separate epic
- Codifying ADR-011 in any skill body (no skill enforces it; convention only)
- Forking existing skill flags into env vars or vice versa — no behavior changes in v0.1.6
- Linting / `verify-all.sh` enforcement of ADR-011 in CI or Stop hook — manual convention only
- Renaming ADR-010 to make room — explicitly out per the PM prompt's hard constraints

---

### Cluster D — Audit follow-through

#### E04.S8: doc-writer multi-file-invocation guard

**Status:** ✅ **Merged 2026-05-18** via PR #42 (`ecae83f`, 6 commits — `c760a31` feat + plan artifact, `8694830` 2 new pitfalls in known-pitfalls.md L54/L56, `ac5ddf0` AC5 outer double-quotes fix (cubic P2), `ecf7147` inline gate-override prefix (cubic P1 best-effort), `22e180f` 5 v0.1.7 candidates recorded in epic, `188236d` plan file post-implementation addenda). **AC outcomes: 4 PASS / 1 accepted violation.** AC1 (a)–(f) coverage met; AC2 strict additivity met (steps 1–4, step 5 intro, both existing sub-bullets, step 6+ byte-identical); **AC3 word cap FAIL by +42 — Path B accepted at Gate 4** (542/500 final; structural impossibility under strict AC2; the v0.1.7 amendment path is recommended option (b) revise project-wide cap to 550 or 600 in `.claude/hooks/verify-all.sh:28`); AC4 two-part-gate preserved; AC5 verbatim template met post-`ac5ddf0` outer-quote fix. **Gate decisions:** Gate 4 Path B (cap violation accepted; prose-hoist saved only −4 words net, full removal would create the same gap the story closes); Gate 6 Option 1 (Risk 5 deferral — T2 synthetic test showed agent did NOT emit AC5 verbatim template, returned free-form prose with correct information; the weak-anchoring hypothesis or the unreachable-clause hypothesis or both; deferred to v0.1.7 dogfood); Gate 6 review accepted 3 warnings as v0.1.7 candidates (scope-mismatch, empty-error fallback, all-fail branch). **Post-merge cubic iteration** terminated by acknowledgment (not suppression) — the AC2/AC4-AC1 contradiction was escalated to v0.1.7 spec amendment cluster; cubic still flags structurally on `agents/doc-writer.md:35`, expected to match the v0.1.7 candidate entry below as known-deferred. **5 new v0.1.7 candidates** captured under the "Surfaced during E04 implementation" sub-cluster — stack as a coherent doc-writer-failure-handling cluster for v0.1.7 landing. **2 new pitfalls** captured at known-pitfalls.md L54 (LLM agents under-honor "Emit this exact summary" instructions) and L56 (peer sub-bullet inherits outer step's gate). **3 process observations** recorded as v0.1.7 candidates (AC mutual satisfiability check; plan-implementation drift handling; cubic-readable known-issues mechanism). Risk 5 status update: see Risk register update below.

**Maps to v0.1.6 candidate:** S3 AC2 quality concern from the v0.1.5 audit. From the audit recommendations: "Address S3 doc-writer multi-file-invocation guard gap — AC2 specified explicit failure-handling for multi-file invocations; current implementation handles missing CLAUDE.md and Read failure but not multi-file."

**Context:** E03.S3 retired `test-verify-v1` and `pitfalls-organized-v1` maturity checks and folded their triggers into `agents/doc-writer.md` Process step 5 (post-write organize-suggestion + test-integration suggestion). The audit found that doc-writer handles missing CLAUDE.md and `Read` failures explicitly but lacks the multi-file invocation case. Multi-file invocations happen when doc-writer is dispatched to update both `.roughly/known-pitfalls.md` AND `CLAUDE.md` in a single Stage 8 wrap-up call (the normal case when both new pitfalls AND a CLAUDE.md update are confirmed). Today, if one of the two `Edit` calls fails (permission denied, file locked, parse-time conflict), doc-writer has no explicit branch — the LLM falls back to heuristic behavior. Per the known pitfall "LLM agent conditionals need explicit failure-handling clauses," the implicit failure path is the bug shape S3 was supposed to close.

The clause locks complete-what-you-can semantics: when one of N writes fails, doc-writer completes the successful writes and emits a partial-success summary naming both outcomes. This is a deliberate choice over abort-all (revert the successful writes if any fail). Rationale: doc-writer has no native revert mechanism — it would have to invert each `Edit` it just performed, which is more failure surface than the original write. A loud partial state with named files succeeded/failed is a better failure shape than a silent revert that may itself fail mid-rollback. The trade-off (user has to manually finish the failed write) is acceptable because the partial-success summary makes the gap visible.

**Files touched:**
- `agents/doc-writer.md` — new failure-handling clause for the multi-file invocation case. Strictly additive — no edits to existing Process steps 1–4 or 6+ (Risk 5's mitigation contract).

**Acceptance criteria:**

- **AC1 — Multi-file failure-handling clause added (semantic-locked, not verbatim-locked).** `agents/doc-writer.md` Process step 5 (or the equivalent post-write step) gains an explicit branch covering all of: (a) per-file independent `Edit` invocation when multiple files are dispatched in one call; (b) per-file outcome capture; (c) non-abort on single-file failure (do not roll back successful writes); (d) emission of a partial-success summary; (e) explicit naming of each succeeded path AND each failed path with the failure reason captured from `Edit`'s error output; (f) never claim full success when any write partially failed. Implementation may vary wording while preserving (a)–(f) semantics. AC5 separately locks the partial-success summary FORMAT verbatim.

- **AC2 — Strictly additive.** Existing Process steps 1–4 and 6+ byte-identical pre/post-edit; new content only within the step 5 addition site (or wherever Process step 5's failure-handling additions live). Verify via `git diff agents/doc-writer.md` inspection: no content removed or modified outside the addition site. HTML comment markers around the new clause are acceptable and do not trigger a violation.

- **AC3 — Agent word cap held.** `wc -w agents/doc-writer.md` post-edit ≤500. New clause is ~60 words; pre-edit count plus addition stays under cap.

- **AC4 — Two-part-gate preserved.** S3's existing two-part-gate (organize-suggestion + test-integration suggestions fire only when (a) user confirms new pitfalls/conventions at wrap-up AND (b) doc-writer actually writes to `.roughly/known-pitfalls.md`) is preserved. The new multi-file failure-handling clause does NOT gate the suggestions — when a partial-success summary is emitted, the suggestions still fire based on the SUCCESSFUL-write outcome only. Verification: read Process step 5 pre/post; confirm the two-part-gate conditional is unchanged.

- **AC5 — Partial-success summary format specified, not free-form.** The summary template is locked: `"doc-writer: partial success — wrote to: <comma-separated list of successful paths>; failed to write: <comma-separated list of failed paths with one-line failure reason each, format '<path>: <reason from Edit error output>'>."` Implementation does not invent alternate formats.

**Verification:**

- **Pre-merge synthetic test:** craft a fixture where doc-writer is dispatched to write both files but one file is intentionally permission-denied (e.g., `chmod 000 .roughly/known-pitfalls.md`). Confirm the partial-success summary names the success + failure paths correctly per AC5's template. Revert chmod.
- **Risk 5 dependency (acknowledged):** per the risk register, this story's risk close depends on real-dogfood multi-file invocations occurring during v0.1.6's release window. The synthetic pre-merge test verifies correctness at merge; real-world close is opportunistic and may stay open into v0.1.7 dogfood. Do not manufacture a pitfall write to force closure.
- **Two-part-gate regression check:** invoke doc-writer with a normal single-file pitfalls write, with both files succeeding; confirm organize-suggestion still fires when conditions are met. No regression in the existing happy path.

**Dependencies on other E04 stories:** None — independent. Can land in parallel with Cluster A/B/C.

**Out of scope:**
- Modifying existing Process step ordering or the two-part-gate conditional logic (Risk 5 specifically protects against this)
- Adding new triggers, conditionals, or write targets to doc-writer beyond the failure-handling clause
- Inventing alternate partial-success summary formats (AC5 locks the template)
- Retroactively auditing other agents (investigator, discovery, code-reviewer, silent-failure-hunter, static-analysis, epic-reviewer) for similar multi-file failure-handling gaps — separate audit work, v0.1.7+ candidate if any agent surface justifies it
- Lifting any of doc-writer's failure-handling clauses into `agents/agent-preamble.md` — agent-preamble is shared-context, not failure-handling
- Changing how Stage 8 wrap-up dispatches doc-writer (build/fix Stage 8 prose untouched by this story)

---

### Cluster E — CI ergonomics polish

#### E04.S9: CI dogfood polish — macOS `gtimeout` + `ANTHROPIC_API_KEY` empty-guard

**Maps to v0.1.6 candidates (2 bundled):**
1. "CI dogfood (`ci-dogfood.sh`) local-run portability on macOS (S8 observation). Requires GNU `timeout`; pure-macOS contributors can't run the script locally."
2. "Explicit `ANTHROPIC_API_KEY` empty-guard before invoking `claude` (S11b-1 deferral). Silent-failure-hunter's I2 finding from S11b-1 review: a 1-line defensive check before the `claude` invocation would produce a clearer 'secret not configured' diagnostic than relying on `claude --bare`'s 'Not logged in' output. Real CI hit this exact case post-merge."

**Context:** Both candidates are small defensive patches to `scripts/ci-dogfood.sh`. Bundling because (a) same file, (b) same risk profile (script-only, no behavior change to the assertion logic), (c) bundling avoids two PRs of trivial polish that risk silent deprioritization in solo-dev cadence.

**Files touched:**
- `scripts/ci-dogfood.sh` — two small additive changes near the top of the script (after the existing repo-guard at L4–11, before any `claude` invocation):
   1. `$TIMEOUT` detection block selecting `timeout` (Linux/CI) or `gtimeout` (macOS via coreutils) with a friendly diagnostic if neither is available. Replace the three literal `timeout` invocations (smoke ~L62, plugin-load ~L88, full-scenario ~L129) with `$TIMEOUT`.
   2. `ANTHROPIC_API_KEY` empty-guard exiting 1 with a friendly diagnostic if the variable is unset or empty.
- `CONTRIBUTING.md` `## CI` section — one-line note about `gtimeout` requirement for macOS local repro.

**Acceptance criteria:**

- **AC1 — `$TIMEOUT` detection block added.** Detection runs after the repo-guard and before any `claude` invocation. Form: `if command -v timeout >/dev/null 2>&1; then TIMEOUT=timeout; elif command -v gtimeout >/dev/null 2>&1; then TIMEOUT=gtimeout; else echo "ci-dogfood: FAIL — no timeout binary available (install coreutils on macOS via 'brew install coreutils')" >&2; exit 1; fi`. Verify: `rg -Fn '$TIMEOUT' scripts/ci-dogfood.sh` returns 3 invocation matches replacing the original literal-`timeout` lines (the smoke ~L62, plugin-load ~L88, and full-scenario ~L129 invocations). The detection block's own internal `command -v timeout` checks are intentionally not asserted against — they reference the binary name as an argument, not as an invocation.

- **AC2 — `ANTHROPIC_API_KEY` empty-guard added.** Runs after the repo-guard and `$TIMEOUT` detection, before any `claude` invocation. Form: `if [ -z "${ANTHROPIC_API_KEY:-}" ]; then echo "ci-dogfood: FAIL — ANTHROPIC_API_KEY not set or empty (configure in GitHub Settings → Secrets and variables → Actions, or export for local repro)" >&2; exit 1; fi`. Note: the `${ANTHROPIC_API_KEY:-}` form prevents `set -u` (if ever added) from killing the script before the guard message; matches the defensive idiom established in E03.S11b-1.

- **AC3 — Auth-failure regression step still passes.** `.github/workflows/dogfood.yml`'s auth-failure step sets `ANTHROPIC_API_KEY=invalid-key-xyz` (non-empty) at step scope. The empty-guard passes through (key is non-empty) and the existing assertion against `Invalid API key` / `Not logged in` continues to fire as before. Verify post-merge: auth-failure step exits 0 with the expected assertion output.

- **AC4 — Happy-path CI passes.** S11b-2's full-scenario block passes against `main` post-merge with the real secret configured. Token cost held within `--max-budget-usd 1.50`.

- **AC5 — `CONTRIBUTING.md ## CI` section gains the gtimeout note.** One line: "macOS contributors running `scripts/ci-dogfood.sh` locally need `gtimeout` from `brew install coreutils`."

- **AC6 — No workflow file changes.** Verify: `git diff --stat` on the PR shows only `scripts/ci-dogfood.sh` and `CONTRIBUTING.md`. `.github/workflows/dogfood.yml` untouched.

**Verification (test the artifact against the question a future reader actually brings to it):**

The question a macOS contributor brings to this script: "Why doesn't `scripts/ci-dogfood.sh` work on my Mac?"
- **Pre-coreutils install:** run on macOS without GNU coreutils. Required outcome: exits 1 with the friendly diagnostic naming `brew install coreutils`. The contributor can resolve from the error alone, no doc lookup needed.
- **Post-coreutils install:** install coreutils; re-run with a valid `ANTHROPIC_API_KEY`. Required outcome: `gtimeout` detected, full scenario runs to completion (subject to network + budget).

The question a CI debugger brings to a failing run: "Why is the script exiting with no diagnostic?"
- **Empty secret:** unset `ANTHROPIC_API_KEY`; run. Required outcome: exits 1 with the friendly diagnostic, no opaque `claude` failure mode.
- **Invalid secret:** export `ANTHROPIC_API_KEY=invalid-key-xyz`; run. Required outcome: passes the empty-guard; `claude` invocation fails with `Invalid API key` per existing auth-failure pattern. Empty-guard does NOT mask the real auth-failure path.

**Dependencies on other E04 stories:** None — independent. Pairs naturally with E04.S1's CI assertion path update (`docs/plans/` → `.roughly/plans/`) but no required ordering. Recommendation: land after E04.S1's CI assertion change so the `gtimeout` portability work doesn't conflict-merge with the path update. Order is convenience, not correctness.

**Out of scope:**
- Replacing `realpath`, `sed -i`, or any other macOS-vs-Linux coreutils divergence not surfaced as a candidate
- Adding friendly diagnostics for other secrets (none exist beyond `ANTHROPIC_API_KEY` today)
- Modifying the auth-failure regression step's behavior or its scoped `invalid-key-xyz` value
- Adding negative-path CI scenarios (out of scope per OQ4 deferral to v0.1.7)
- Caching `node_modules` or Claude session state between runs (explicit defer per E03 candidate: "Caching node_modules / Claude state between runs — v0.1.6 candidate (correctness first, perf later)")
- Cross-platform fixture / assertion divergence (CI assertion logic runs on Ubuntu; macOS support is for local script-execution only, not for assertion validation)

---

## Open questions

All resolved during PM round (2026-05-13 to 2026-05-14). Recorded here as the design-decision trail; no items remain open at epic-write time.

1. **Should former S7 (in-session maturity offers at Stage 1) ship in v0.1.6?** **Resolved: defer to v0.1.7.** S7 is ergonomics; v0.1.6 is debt cleanup + codification — mixing dilutes both. Recorded in [v0.1.7 candidates](#v017-candidates) with the explicit "until measured signal exists (Stage 8 decline rate or in-the-wild missed-offer reports)" criterion.

2. **Skill-flags-as-public-API: ADR-011 or CONTRIBUTING note?** **Resolved: ADR-011** (E04.S7). Discoverability for a multi-release precedent (v0.2.0 complexity flag inherits) outweighs the lighter CONTRIBUTING-only option. ADR-011 explicitly names v0.2.0's complexity flag as first downstream consumer.

3. **DI-001 (Stage 6 review depth) investigation: v0.1.6 or stay in `docs/deferred-investigations.md`?** **Resolved: stay deferred.** Promoting a hypothesis sweep to a release commitment is the wrong direction. Investigations get promoted to stories when one hypothesis has signal, not before. Rule reinforced for future PM cycles.

4. **Negative-path CI scenarios: ship all/one/none in v0.1.6?** **Resolved: none.** Happy-path CI is now stable; negative-path scenarios materially expand the fixture/assertion surface and pair more naturally with fix-side `--ci` in v0.1.7 as a clean CI-coverage cluster. The "highest-signal one" fallback was explicitly rejected to avoid committing to a fixture/assertion pattern that a future CI-coverage release may want to reshape.

5. **Plan-file self-marking historical (E04.S3): bundled into E04.S1 or separate?** **Resolved: separate.** Different surface areas (path/migration vs plan-file lifecycle); separate stories means cleaner ACs and verification. Rollback granularity argument was decisive: S3's cubic-behavior blocking gate may force format iteration; bundling would tangle that with S1's git-mv hash.

6. **"6 vs 7 pipeline skills" count for E04.S1's pre-flight scope.** **Resolved: match existing 7-hard-abort + 1-soft-abort surface.** The candidate text's "6" was off-the-cuff, not a deliberate locked decision. The "do not re-litigate locked decisions" rule applies to deliberate decisions, not imprecise counts surfaced for the first time in candidate entries. Asymmetry is the pitfall.

7. **Risk 6 — codification overshoot (Cluster C rules narrowing future patterns).** **Considered then retracted.** PM-author proposed during risk-register review; clean mitigation was draftable (each codification artifact names its bright-line carve-out with canonical example). Retracted on second-pass review: Risk 4 (ADR-011 lock-in) already covers the codification-prematurely-constraining-future-design-space surface at the ADR layer; the AC-layer concern is mitigated structurally by each carve-out's bright-line framing in E04.S6 itself, not as a risk-register entry. Risk register holds at 5.

8. **E04.S6 AC2 — signal-source-only vs single-source-policy-parameters?** **Resolved: signal-source-only.** The principle is rooted in a real difference of kind: signal source is a correctness property (a conditional that does not name its data source is unverifiable); policy parameter is a maintenance property (a duplicated `80` is a low-severity, greppable, non-silent drift risk). Different problem classes, different mechanisms. The review-plan gate covers the correctness class only. Single-source policy-parameter mechanism tracked separately as v0.1.7 candidate.

9. **E04.S7 ADR-011 forward references — by content or by role?** **Resolved: by role.** ADR-011 names v0.2.0 plan-format-v2 as the first downstream consumer and states the relationship (foundational); does not specify ADR-010's internal structure, citation form, or content placement. Role references can't go stale because they're claims about the relationship; v0.2.0 honors the relationship however it wants.

---

## v0.1.7 candidates

Items surfaced during E04 PM work that are deliberately out of v0.1.6 scope. The list is unprioritized; pull from it when scoping v0.1.7.

**Carried forward from E03 v0.1.6 candidates (still applicable):**

- **Docs cluster (former S12a, S12b) — separate repo/epic.** Originally scoped as four roughly.dev pages in v0.1.5; deferred 2026-05-08 via E03.S12.0 option (c). Will land in a separate repo/epic post-v0.1.5; no v0.1.6 release-cycle dependency. Path-to-v1.0 criterion #5 is the long-term home.
- **In-session maturity offers at Stage 1 (former S7).** OQ1 resolution. Until measured signal exists (Stage 8 decline rate or in-the-wild missed-offer reports), stays deferred.
- **DI-001: Stage 6 review depth vs external review tools.** Stays in `docs/deferred-investigations.md` per OQ3. Promoted to story only when one hypothesis has signal.
- **Negative-path CI scenarios + fix-side `--ci` flag.** Pair as v0.1.7 CI-coverage cluster. Includes build-cycle NEEDS REVISION recovery, Stage 6 max-cycles abort, /roughly:fix happy-path.
- **Stage 6 review-fix cycles cap conversion-to-prompt.** OQ3 disposition #5 from E03.S10. Promote if v0.1.6 dogfood shows cycles 2-3 landing legitimate fixes regularly.
- **ExitPlanMode interactive semantics empirical test.** S1 deferral; not load-bearing unless a future story wants in-skill self-recovery.
- **Hook-event suppression audit under plan mode for non-`UserPromptSubmit` events.** Informational.
- **Formatter+existing-`settings.json` merge behavior** as a 4th merge-style branch.
- **Per-client plan-mode toggle mapping.** Ergonomics polish.
- **Per-field maturity-check organization beyond v1 IDs.** Deferred per S3.
- **CI coverage for `/roughly:fix`, `/roughly:setup`, `/roughly:upgrade`.** Per-command CI scenarios.
- **Pre-existing typo `docs/adr/` (singular) at `agents/doc-writer.md:24`.** One-line fix; slot into the next doc-cleanup story.
- **Pre-existing markdown lint sweep across `docs/ROADMAP.md`, `docs/planning/epics/*`, `agents/doc-writer.md`.** Candidate for a one-shot lint-cleanup story when convenient.
- **ADR-005 footnote terminology drift.** Cosmetic vocabulary mismatch between user-response (`add`/`decline`) and plugin-action (`version-bump`) terminology in the v0.1.5 retirement footnote.
- **General-pattern lift from E03.S2 review** — "every conditional branch enumerates state cleanup" and "validate prerequisites before mutations" patterns may warrant a short ADR or stronger surfacing in agent briefs (DI-001 hypothesis #4).
- **Refactor build/fix preamble + Stage 1 + Stage 8 prose into a shared reference.** Surfaced by the line-cap budget contract. Prepared off-ramp if E04.S1 or E04.S3 forces it; if not invoked during v0.1.6, still a debt to retire when the next big additive story lands.

**New from E04 PM work:**

- **Single-source `PITFALLS_ORGANIZE_THRESHOLD` mechanism.** Today (post-E04.S5) the 80-line threshold is duplicated as a literal in two consumers: `.claude/hooks/verify-all.sh` (bash constant) and `agents/doc-writer.md` (prose conditional). Bidirectional sync comments are the v0.1.6 mitigation; the v0.1.7+ work is a shared constant mechanism both a markdown agent file and a bash script can source (e.g., a `.roughly/thresholds.env` or similar). Real work, not a one-line patch — its own small story, not a cross-cutting AC.
- **`set -uo pipefail` audit of `.claude/hooks/verify-all.sh`.** E04.S4 backports S2's template-fixes only (drop `set -e`, `|| true` on `git rev-parse`). Adding `set -uo pipefail` would catch additional latent issues across the whole hook body including the four existing checks and `emit_drift_json` — that's new hardening work, not S2 backport. v0.1.7 candidate only if a forcing function appears; "could be more hardened" isn't one.
- **Other-agents multi-file failure-handling audit.** E04.S8 closes doc-writer's gap. Other agents (investigator, discovery, code-reviewer, silent-failure-hunter, static-analysis, epic-reviewer) may have similar gaps. Separate audit work; v0.1.7+ candidate if any agent surface justifies it.

**New from post-v0.1.5 dogfood (2026-05-14):**

- **Dogfood-self template-sync mechanism.** Surfaced 2026-05-14 when attempting to upgrade THIS repo (plugin source) to v0.1.5 via `/roughly:upgrade`. The upgrade flow correctly aborted — it's scoped for consumer projects, not the plugin's own source repo (the upgrade compares installed-plugin templates against project state, but here the project state IS the upgrade source; the operation is circular). The actual gap that prompted the upgrade attempt: S1 shipped `plan-mode-gate.sh` to both `skills/setup/templates/` (for users) and `.claude/hooks/` (for this repo), but the corresponding `UserPromptSubmit` registration only landed in `skills/setup/templates/settings.json.template` — `.claude/settings.json` in this repo wasn't pair-updated, leaving plan-mode protection silently off in the dogfood repo until 2026-05-14. The audit didn't catch this because S1 ACs were scoped to "user-project install path," not "dogfood-self pairing." Class of bug: any story that ships a `skills/setup/templates/` change requires a paired `.claude/` update; the pairing is currently manual convention with no enforcement. Three remediation options considered: (a) manual pairing convention documented in CONTRIBUTING.md + drift check in `.claude/hooks/verify-all.sh` (low cost, relies on contributor discipline); (b) explicit `scripts/sync-dogfood-from-templates.sh` script (one-shot tool, run after any setup-template change; lower friction than convention); (c) new mode in `/roughly:upgrade` that detects plugin-source-repo state and applies dogfood-relevant updates only (more clever, more surface to maintain). **Recommended: option (b)** — a sync script. Pairs naturally with the existing dogfood-vs-template distinction codified in E04.S5's `verify-all.sh` checks. Immediate gap patched manually 2026-05-14 (`.claude/settings.json` UserPromptSubmit registration added in this repo); the systemic fix belongs in v0.1.7.

- **`/roughly:help` "Unknown" categorization for non-maturity-check install markers.** Surfaced 2026-05-14 during v0.1.5 UAT in a consumer project (post-upgrade `/roughly:help` output). The maturity-check state section listed `? plan-mode-gate-v1 — unknown check (2026-05-14)` — categorized as "Unknown" because `/roughly:help` has a hardcoded list of known maturity-check IDs (`stop-hook-v1`, `test-verify-v1`, `pitfalls-organized-v1`) and the plan-mode-gate marker isn't on it. Root cause: E03.S1's plan-mode-gate install writes a `plan-mode-gate-v1-added <date>` marker to `.roughly/workflow-upgrades` using the same `<id>-added <date>` suffix pattern maturity checks use (per E03.S2's `stop-hook-v1-added` precedent), but plan-mode-gate isn't a maturity check — it's an unconditional install marker. The schema mixes both concepts under one suffix convention with no distinguishing field. Three remediation options considered: **(a)** `/roughly:help` learns to categorize install markers separately from maturity checks — non-breaking, small, but adds list-maintenance burden every time a new install marker ships; **(b)** install markers use a distinct suffix (`-installed` vs `-added`) — requires a one-shot `.roughly/workflow-upgrades` migration for existing v0.1.5 markers; **(c)** `.roughly/workflow-upgrades` schema adds a per-entry kind field (`type: maturity-check` vs `type: install-marker`) — most-correct, largest change, requires migration. **Recommended: option (a)** for v0.1.7 — non-breaking, defers the schema decision until E04.S1's plans-migration marker, E04.S2's resume reporting, and any future install markers accumulate enough surface to justify (b) or (c). Class of bug: every new install marker hits the same "Unknown" treatment unless help's known-list is manually synced — a third instance of the cross-file drift pattern E04.S5 Check 3 hardened against (the first two: `PITFALLS_ORGANIZE_THRESHOLD` constant duplicated between hook and doc-writer; pre-flight wording byte-identity across 7 skills). Immediate mitigation: none required — output is cosmetically misleading but functionally correct (marker is recorded; hook is registered as expected).

**Surfaced during E04 implementation:**

- **README/doc invocation examples must align with skill frontmatter.** Surfaced 2026-05-15 post-E04.S6 desk-check. E04.S6's `tests/fixtures/review-plan/README.md` initially documented `claude /roughly:review-plan <path>` as an invocation example, but `skills/review-plan/SKILL.md` is `disable-model-invocation: true` per ADR-001 — the example wouldn't actually run. Silent-failure-hunter flagged this in cycle 1 as Info; the implementer downgraded as cosmetic; user-led desk-check post-PR caught the gap (commit `9d61030` corrected the README to manual desk-check + subagent dispatch paths). Pattern: any README or doc that documents `/roughly:<skill>` as user-invocable must cross-check the skill's frontmatter `disable-model-invocation` field. Could land as a future `/roughly:review-plan` AC ("any doc invocation example matches the cited skill's frontmatter") or as a `verify-all.sh` drift check. v0.1.7 candidate.

- **Stronger output-mandatory wording in `skills/review-plan/SKILL.md`.** Surfaced 2026-05-15 during E04.S6 Stage 4 dispatch. The review-plan agent stopped mid-investigation ("Let me check the remaining key items: ..." then no output). Re-dispatching with an explicit "produce the verdict block, no exceptions" instruction recovered. The skill body could include stronger output-mandatory wording to self-prevent this — every dispatch must produce a verdict block (PASS or NEEDS REVISION), no early termination allowed. Small surgical edit to the skill body, contributor-facing. v0.1.7 candidate.

- **E04.S8 — AC2/AC4 vs AC1-reachability spec contradiction.** Surfaced 2026-05-17/18 across multiple cubic review iterations on E04.S8. AC1 requires the multi-file failure-handling clause to fire on multi-file failure including when `.roughly/known-pitfalls.md` is the failing file. AC2 forbids modifying steps 1-4 or 6+ AND restricts new content to "the step 5 addition site." AC4 forbids modifying step 5's outer gate ("run after any Write or Edit to `.roughly/known-pitfalls.md`"). Under strict readings of all three, the clause MUST live inside step 5 — but step 5's outer gate is success-conditional on the file that may be FAILING in the target scenario. The clause is therefore structurally unreachable for its own target case under strict AC reading. Mitigation attempted in commit `ecf7147` via inline gate-override prefix "(always — overrides step 5's outer gate)" on the sub-bullet heading — best-effort hedge that depends on LLM-holistic prompt reading rather than sequential gate evaluation; cubic continues to flag it structurally because the sub-bullet is still nested inside step 5. T2 synthetic test (commit `c760a31` pre-merge) showed the runtime LLM did NOT emit the verbatim AC5 template, consistent with either the unreachable-clause theory OR the weak-anchoring theory. **Resolution requires epic-level AC amendment** in v0.1.7: (a) amend AC2 to permit clause placement outside step 5, (b) amend AC4 to permit changing step 5's gate to non-success-conditional ("after any attempted Write or Edit"), or (c) restructure agent file's step 5 to nest the gated suggestions under an unconditional outer layer. Recommended (a). **Future cubic runs on `agents/doc-writer.md:35` should match this entry and close the structural finding as known-deferred.** Stack with the AC3 cap-hardening, AC5 anchoring, empty-error fallback, and all-fail branch items below — all five are spec-level gaps in the same surface.

- **E04.S8 — AC3 500-word cap accepted violation (Path B at +42).** `agents/doc-writer.md` post-E04.S8 = 542 words, exceeding the project-wide 500-word agent cap (`.claude/hooks/verify-all.sh:28`) by 42 — 35 from the initial clause + 7 from the `ecf7147` gate-override prefix. Accepted at gate 4 (Path B) as the cleanest tradeoff against AC5's ~30-word verbatim template + AC1's (a)-(f) minimum coverage + AC2 strict-additivity (no trimming of existing prose). v0.1.7 cap-hardening options: (a) trim `agents/doc-writer.md` existing prose under a separate non-additive story (E04.S8 forbids this; the v0.1.7 amendment is a clean unblock), (b) revise the project-wide 500-word cap to 550 or 600 (single-line constant edit in `.claude/hooks/verify-all.sh`), (c) per-agent cap. Recommended (b) — the 500-word cap predates the failure-handling additions and may be tighter than necessary for agents with mature failure-handling.

- **E04.S8 — AC5 strict-format LLM-anchoring.** T2 synthetic test (commit `c760a31` pre-merge) showed `agents/doc-writer.md` at runtime did NOT produce the verbatim AC5 partial-success summary template — it returned free-form prose containing the right INFORMATION (success path, failed path, EACCES reason, "partial success" phrase) but ignoring the locked format. Codified as generalizable pitfall in `.roughly/known-pitfalls.md` L54 ("LLM agents under-honor `Emit this exact summary: <template>` instructions"). The clause's existing "Emit this exact summary: `<template>`" anchoring is too weak; stronger imperative wording ("MUST literally begin with…"), a code-fenced template on its own line, or a post-emit self-check pattern would be more reliable. Word cost: ~5-15 additional words; pairs with cap-hardening. v0.1.7 candidate.

- **E04.S8 — Empty `Edit` error-output fallback.** Silent-failure-hunter Stage 6 finding (commit `c760a31`). The AC5 template slot `<reason from Edit error output>` has no fallback when Edit returns with empty/missing error text. LLM will hallucinate a reason, emit the literal placeholder string, or omit the path entirely — recreating the silent-failure shape the story closes. Fix: extend the clause with "if Edit's error output is empty, write `(no error output)` in the reason slot." Word cost: ~10 words; pairs with cap-hardening. v0.1.7 candidate.

- **E04.S8 — All-fail branch missing from AC5 template.** Silent-failure-hunter Stage 6 finding (commit `c760a31`). The AC5 template literally reads "partial success — wrote to: …; failed to write: …" which is internally contradictory when every write in a multi-file dispatch fails (`wrote to:` list is empty; "partial success" is false). Fix: extend the clause with an explicit all-fail branch using an alternate phrasing (e.g., "doc-writer: all writes failed — …"). Word cost: ~15-25 words depending on whether the all-fail format is also AC5-locked. v0.1.7 candidate; pairs with cap-hardening.

**Process observations from E04.S8 (recorded as v0.1.7 candidates 2026-05-18):**

- **Epic-reviewer / plan-reviewer "AC mutual satisfiability" check pass.** The AC2/AC4-AC1 contradiction in E04.S8 was not caught at epic-review or plan-review iteration 2 — it surfaced only through cubic's structural framing of the same finding across post-merge iterations. Current epic-reviewer and plan-reviewer brief each AC in isolation; neither checks that all ACs are jointly satisfiable when they reference each other or reference the same surface (file, step, prose region). v0.1.7 candidate: add a "for each pair of ACs that reference overlapping prose or constraints, verify joint satisfiability" pass to the epic-reviewer or plan-reviewer agent briefs. Stack with the AC2/AC4-AC1 spec amendment cluster.

- **Plan-implementation drift at Stage 8 wrap-up.** The Stage-3 plan for E04.S8 was committed before post-merge cubic fixes (`ac5ddf0`, `ecf7147`) modified the shipped code; cubic itself flagged the drift on the plan file. E04.S3 (plan-file self-marking historical) marks the plan as historical post-implementation but does not update plan content to reflect post-merge state. Two options for v0.1.7: (a) build pipeline Stage 8 wrap-up includes an explicit "update plan artifact to reflect post-merge state" step, OR (b) plans are explicitly marked as Stage-3 snapshots not maintained post-implementation (paired with the E04.S3 Status block, this is mostly already implied — make it explicit). Recommend (b) for v0.1.7 — drift-tolerant by design is simpler than continuous-update.

- **Cubic-readable known-issues mechanism for accepted-violations.** Cubic re-flagged the same finding across iterations even after deferral was documented in commit messages and the epic's v0.1.7 candidates section. Cubic does not read commit messages or epic docs; it operates on the current state of the codebase. Closing the loop required documenting in the canonical v0.1.7 candidates section so a HUMAN reviewer can match cubic's output against the known-deferred entry. v0.1.7 candidate: introduce a CUBIC-readable known-issues mechanism — `.cubicignore` file, inline `// cubic-ignore: <reason or v0.1.7 reference>` annotations, or a `docs/known-cubic-deferrals.md` index keyed by file/line. The mechanism's blast radius is small (no behavior change) but the contributor-experience improvement is meaningful — cubic-iterations on a clean codebase shouldn't surface the same known finding repeatedly.

**Surfaced during E04.S1 (2026-05-20):**

- **E04.S1 — Pre-flight signal content-inspection upgrade (accepted false-positive case).** S1's pre-flight signal uses `*-plan.md` filename pattern as the Roughly-plans marker — accepted with one narrow limitation: a project with unrelated `docs/plans/*-plan.md` files following Roughly's naming convention will hit a false-positive abort. Workaround is straightforward (rename collision files or move them out of `docs/plans/`). Accepted given v0.1.x's single-known-user adoption. v0.1.7 candidate if user count grows: extend pre-flight detection with content inspection — e.g., `grep -l "^Plan-format-version:"` or `grep -l "^## Tasks"` against `docs/plans/*-plan.md` files — to distinguish Roughly plans from non-Roughly planning documents using the same naming convention. Low-cost upgrade (single check addition); only worth doing when there's evidence of the collision case affecting a real user.

- **E04.S1 — AC verify-command scope must match spec's enumerated-file-list (validation paired with E04.S6).** S1's PM-phase enumeration named 4 skill bodies with `docs/plans/` references (build, fix, help, audit-epic) for 15 total refs; actual scope was 5 bodies / 17 refs — `skills/review-plan/SKILL.md` was missed in the enumeration. Discovery caught it via AC1's `rg -Fn "docs/plans" skills/` verify command, which is scope-agnostic (returns matches across all skills, not just the enumerated ones). Validates E04.S6's "every edit site enumerated" review-plan AC. v0.1.7 candidate: tighten review-plan to also flag mismatches between AC verify-command scope and spec-enumerated file list — when an AC says "verify against skills/" but the spec enumerates only specific files, review-plan should detect the asymmetry and flag it pre-implementation. Would have caught the review-plan gap at plan-review instead of Stage 2 discovery.

- **E04.S1 — Pre-flight `rg -Fn` verify-command self-defeat pattern.** When a story extends a detection check (e.g., pre-flight block) to detect a new legacy state (e.g., adds `docs/plans/` to a check that previously only detected `.ruckus/`), the spec's literal `rg -Fn "<legacy-state>" skills/` verify command becomes self-defeating: the new detection prose itself contains the literal being searched for. S1 documented this and shipped with an intent-correct verify (`grep -v` exclusions for documented self-reference sites: pre-flight blocks, setup soft-abort, upgrade migration step). Partially captured as pitfall at `.roughly/known-pitfalls.md` (post-S1). v0.1.7 candidate: codify the pattern as a CONTRIBUTING.md AC-authoring convention — "when an AC's verify command searches for a literal that is intentionally present in the new detection prose, use `grep -v` exclusions or restructure to a count-based or hash-based check."

- **E04.S1 — Cubic-iteration termination criteria.** S1 went through 6 cubic-fix iterations post-merge before clean, with progressively narrower findings and diminishing severity. The build pipeline's Stage 6 spec doesn't address what to do when post-merge cubic surfaces increasingly contrived edge cases. v0.1.7 candidate: document a stopping rule in build/SKILL.md Stage 6 — e.g., "accept-as-documented after N cycles, OR when severity drops below P1, OR when the finding can only be addressed by spec amendment (escalate as v0.1.7 candidate)." Would prevent analysis paralysis on stories where additional cubic iterations chase diminishing returns. Pairs with the existing "Cubic-readable known-issues mechanism" candidate.

- **E04.S1 — Stage 3 `mkdir -p` audit across skills writing to `.roughly/` subpaths.** S1 added an explicit `mkdir -p .roughly/plans/` instruction to build/fix Stage 3 after silent-failure-hunter caught that the `Write` tool doesn't create parent directories. The new pitfall at `.roughly/known-pitfalls.md` generalizes. Other skills that may write to under-`.roughly/` paths (e.g., E04.S5's `.roughly/known-pitfalls.md` updates from doc-writer; future stories writing under `.roughly/`) may have the same parent-dir issue. v0.1.7 candidate: audit-pass across all skills/agents that perform `Write` to under-`.roughly/` paths to ensure explicit parent-dir creation. Low-cost audit, would close a latent failure class.

**Surfaced during E04.S5 (2026-05-20):**

- **E04.S5 — AC8 "no new invariants" boundary erosion under iterative defensive review.** S5's AC8 forbade adding invariants beyond the three named (Check 1, 2, 3), but two rounds of review pushed defensive precondition guards into what could be read as existence enforcement: Stage 6 silent-failure-hunter Critical added a fixture-existence guard for Check 1 to prevent empty-hash collapse; round 4 cubic added a three-level presence cascade for Check 2 to surface the ADR-009 silent-protection-unregistration class. Both fixes preserved AC8 in spirit (treating "files missing" as "check cannot run" with directed diagnostics, not as new structural rules), but the boundary was relitigated twice in the same story without an explicit rule. **v0.1.7 candidate:** codify the "defensive guard vs new invariant" distinction as a `/roughly:review-plan` AC — pair with E04.S6's "every edit site enumerated" check. Specifically: when an AC bounds the scope of new invariants ("no new X beyond the named Y"), defensive precondition guards for the named Y are explicitly in-scope; the rule should be stated as "no new structural rules" rather than "no new behavior at the named site," so reviewers can confidently land guards without re-litigating scope.

---

## Sequencing

Order is by dependency, not roadmap or cluster number. Stories #1–4 are mutually independent and independent of S1; stories #6–9 depend (directly or by recommended landing order) on S1.

| # | Story | Cluster | Depends on | Why this position |
|---|---|---|---|---|
| 1 | **E04.S4** (dogfood `verify-all.sh` cleanup) ✅ merged | B | None | Smallest blast radius (latent bug fix); lands first so subsequent Stop-hook touches start from corrected base. Pair-ordering with S5 satisfied. Merged 2026-05-14 via PR #39 (`3017861`). Shipped 3 edits vs 2 enumerated (cd-guard backport completeness; pitfall recorded). |
| 2 | **E04.S6** (plan-discipline codification) ✅ merged | C | None | Process codification lands early so subsequent stories' `/roughly:review-plan` cycles inherit the new ACs. Carve-outs validated through 2 review cycles. Merged 2026-05-15 via PR #40 (`9a18161`). 2 v0.1.7 candidates surfaced from review cycles. |
| 3 | **E04.S7** (ADR-011) ✅ merged | C | None | ADR doc-only; fast PR. Lands before S1 so the skill-vs-env-var decision surface for S1's `--force-plans` flag is already codified. Merged 2026-05-15 via PR #41 (`b92e16f`). 1 plan-review cycle PASS + 2 Stage 6 review cycles + post-merge architect review refinements. 1 new pitfall captured (bold-decorated markdown grep). |
| 4 | **E04.S8** (doc-writer multi-file guard) ✅ merged | D | None | Land early to maximize the opportunistic Risk 5 close window. Real-dogfood multi-file invocations during v0.1.6's 5–6 week cycle close the risk; the longer the guard is in place, the better the chance of exercise. Merged 2026-05-18 via PR #42 (`ecae83f`). AC3 cap violation accepted (Path B at +42; 542/500). 5 v0.1.7 candidates + 3 process observations + 2 new pitfalls surfaced. |
| 5 | **E04.S1** (path consolidation) ✅ merged | A | None (anchor) | The migration. CI assertion-path update lands in same PR. Post-merge CI passes against `.roughly/plans/`. Merged 2026-05-20 via PR #43 (`4939875`). 30 plans relocated, 17 substitutions across 5 bodies (review-plan was an unenumerated discovery), pre-flight signal redesigned 4 times to `*-plan.md` filename pattern, marker-at-source idiom adopted. Risk 1 closed. |
| 6 | **E04.S9** (CI dogfood polish) | E | (preferred) S1 | CI script polish. Lands after S1's CI assertion change to avoid path-conflict merge. Could land in parallel with S1 if branches are managed carefully; sequential is simpler. |
| 7 | **E04.S2** (marker-aware resume) | A | S1 | Resume-step reporting across the three migration steps (v0.1.2, v0.1.4, v0.1.6 plans). Augments the v0.1.6 step S1 introduces. |
| 8 | **E04.S5** (Stop hook drift expansion) ✅ merged | B | S1, S4 | Check 1 verifies the two-form pre-flight block from S1; Check 2 sits on S4's corrected `verify-all.sh` base. Merged 2026-05-20 via PR #44 (`bd8e37c`). 57 → 114 lines. 4 cubic rounds + 1 silent-failure-hunter intervention shaped final design: `shasum`/`sha1sum` fallback, fixture-existence + per-skill marker + tooling-unavailable guards, Check 2 three-level cascade. 3 new pitfalls captured. Risk 3 enters 30-day dogfood window. |
| 9 | **E04.S3** (plan self-marking historical) | A | S1 | Plan retro-mark sweep + Stage 7 prose addition. Lands last because the cubic-behavior blocking gate may force Status-block format iteration; bundling adjacency keeps that iteration off the critical path. |

**Critical path:** S4 → S1 → S2 → S5 → S3. S5 unconditionally requires S4 merged first per its story body (S5 adds checks to a hook whose latent bug S4 fixes). ~5 sequential PRs minimum if S6, S7, S8 are parallelized into the early window and S9 lands post-S1; 9 PRs sequential if not.

**Parallelism notes (if multi-stream development is feasible):**

- Stories #1–4 (S4, S6, S7, S8) are mutually independent and independent of S1. Can land in any order or in parallel.
- Stories #6 (S9) and #7 (S2) only depend on S1 and are independent of each other. Can land in parallel post-S1.
- Stories #8 (S5) and #9 (S3) only depend on S1 (S5 also on S4). Can land in parallel post-S1 if S4 is merged.

---

## Definition of done

- [ ] **All 9 stories merged OR S3 explicitly deferred to v0.1.7** (S1, S2, S4, S5, S6, S7, S8, S9 are unconditionally required; S3 may defer per Risk 6 if cubic-gate format iteration does not converge within the release window — defer reason recorded in the v0.1.6 retrospective)
- [ ] **v0.1.6 tag pushed**: `git tag v0.1.6 && git push origin v0.1.6`
- [ ] **CHANGELOG entries cover Added / Changed / Migration for each story** under `## [0.1.6] — YYYY-MM-DD`
- [ ] **ROADMAP.md updated** to reflect v0.1.6 shipped + v0.1.7 candidates surfaced; ROADMAP header `**Current:**` bumped from v0.1.5 → v0.1.6
- [ ] **CI dogfood passing on `main`** against the new `.roughly/plans/` assertion path with `--max-budget-usd 1.50` held
- [ ] **ADR-011 merged**; `CLAUDE.md` ADR count updated 9 → 10; `docs/adrs/README.md` index updated
- [ ] **After every merge**, `wc -l skills/build/SKILL.md skills/fix/SKILL.md` is recorded in the PR description; final values ≤ 300 each
- [ ] **Risk 3** acknowledged as opportunistic post-release close at 30-day dogfood window; will be assessed at v0.1.7 retrospective
- [ ] **Risk 5** acknowledged as opportunistic; closes only if real-dogfood multi-file invocations occur during the v0.1.6 release window; do not manufacture writes to force close
- [ ] **v0.1.7 candidates list reviewed** and prep next epic PM prompt
- [ ] **Plugin version bump**: `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` `version` field → `0.1.6`
- [ ] **CHANGELOG heading rename**: `## [Unreleased] — v0.1.6` → `## [0.1.6] — YYYY-MM-DD` at tag time
- [ ] **Audit `.roughly/workflow-upgrades` for retired-check markers before tag.** S4 wrap-up wrote `pitfalls-organized-v1-added 2026-05-14` to this repo's dogfood workflow-upgrades file even though E03.S3 retired that check. Marker left in place for v0.1.6 (defaulted 2026-05-14 — defect surface for the v0.1.7 install-marker schema candidate). At v0.1.6 tag time: decide remove vs keep based on whether the v0.1.7 schema fix has shipped (if shipped: marker can be re-categorized; if not: remove the dogfood marker to keep the retirement clean).
