# Epic Audit: E04 — Path consolidation + process codification

**Audit date:** 2026-05-23
**Epic file:** [E04-path-consolidation-and-process-codification.md](E04-path-consolidation-and-process-codification.md)
**Stories audited:** 9 / 9 (all merged)
**Acceptance criteria evaluated:** ~75 across 9 stories — **MET: 71 · PARTIAL: 2 · NOT MET (accepted/deferred): 2**

---

## Summary

E04 shipped feature-complete on schedule, with all 9 stories merged across PRs #39–#47. The audit confirms the epic's own Status-block claims hold up against direct file inspection: AC1's intent-correct verify returns 0; the AC4 7-skill pre-flight + canonical fixture hash-set returns exactly 1 unique value; the 34 plans in `.roughly/plans/` all carry first-line Status blocks with no literal `<SHA>` / `<YYYY-MM-DD>` placeholders surviving; the bidirectional sync between `verify-all.sh:88` and `doc-writer.md:33` is in place pointing each consumer at the other.

Two ACs land as PARTIAL: **S1.AC5** (CONTRIBUTING.md has 2 explanatory references to `docs/plans/` that the AC's literal verify catches — same self-defeating-verify pattern S1 already captured as v0.1.7 candidate, epic L609) and **S6.AC6** (self-verification of the synthetic fixtures is achievable only via manual desk-check or subagent dispatch per the post-`9d61030` correction — verified the fixtures exist but cannot confirm a runtime PASS/NEEDS REVISION outcome from the audit alone).

Two ACs are accepted/deferred violations already enumerated in the epic: **S8.AC3** word cap (now 557 / 500, +57 over — drifted +15 beyond the +42 documented at S8 ship because S5 added a bidirectional sync HTML comment in `doc-writer.md:33`; tracked as v0.1.7 cap-revision candidate) and the ABORT HANDLING coverage gap for S3's 2-commit Stage 8 window (low practical impact — no human gate exists between commits 1 and 2 — but the spec gap is real; deferred per the fix/SKILL.md at-cap constraint).

No regressions found. Cross-cutting concerns (line-cap binding at fix=300/300, doc-writer word-cap drift, Risk 3 30-day dogfood window, Risk 5 opportunistic-close window) are all documented in the epic and tracked.

---

## Per-Story Results

### E04.S1: Plan-path consolidation `docs/plans/` → `.roughly/plans/`

| AC | Status | Evidence |
|----|--------|----------|
| AC1 — all 4 (actually 5) skill bodies flipped | MET | Intent-correct `rg -Fn "docs/plans" skills/ \| grep -v pre-flight \| grep -v setup \| grep -v upgrade` returns 0; literal returns 14 (all in documented self-reference sites). Review-plan/SKILL.md included (5-body discovery from S1 implementation). |
| AC1a — historical carve-outs preserved | MET | `CHANGELOG.md` has 8 historical references; no sweep into `docs/planning/epics/complete/` or `docs/planning/archive/`. |
| AC2 — `git mv` preserves history | MET | `git log --follow .roughly/plans/E03-S8-help-command-plan.md` returns 3 commits across the rename. |
| AC3 — v0.1.6 plans-migration step in upgrade | MET | `skills/upgrade/SKILL.md` L62 carries 3-point structure (detect+safety, git-mv with marker-at-source, idempotency); `--force-plans` standalone-token detection present. |
| AC3a — no fallback between git mv and mv | MET | Upgrade step prose: git availability detected via `git rev-parse --git-dir`; plain `mv` only on non-git, no silent retry on `git mv` failure. |
| AC4 — 7-skill pre-flight byte-identity | MET | All 7 skills have `<!-- pre-flight:start -->` markers; `sort -u` of 8 hashes (7 skills + `tests/fixtures/canonical-preflight-block.txt`) yields **1** unique value: `98ac9282…`. |
| AC5 — active-surface zero check | **PARTIAL** | `rg -Fn "docs/plans" scripts/ README.md CONTRIBUTING.md` returns **2** matches: `CONTRIBUTING.md:87` (migration prose explaining the relocation), `CONTRIBUTING.md:103` (S3 retro-mark sweep prose explaining `--follow` need). Both are intentional historical-explanatory references — same self-defeating-verify shape as the AC1 pattern S1 documented and captured at epic L609 as a v0.1.7 candidate. The spirit of AC5 (no active-runtime references to legacy path) is met; the literal verify command needs the same `grep -v` exclusion treatment AC1 received. |
| AC6 — S11b-2 full-scenario assertions hold | MET | `scripts/ci-dogfood.sh` Assertion block L100–210 references `.roughly/plans/`; no `docs/plans/` in active script lines. |
| AC7 — `tests/fixtures/hello-roughly/` reflects new path | MET | Fixture's reflected plan-path expectations updated in S1 PR per `git show --stat 4939875`. |
| AC8 — CHANGELOG / README / CONTRIBUTING migration prose | MET | CHANGELOG.md `## [0.1.6]` entry with `### Changed` + `### Migration`; README.md L214 updated; CONTRIBUTING.md `## Migration` section present. |
| AC9 — no new ADR | MET | `git show --stat 4939875 -- docs/adrs/` returns empty. ADR count went 9→10 only via S7's ADR-011, not S1. |

**Quality notes:** AC5's literal verify command is self-defeating in the same way AC1's was — S1 already documented this pattern at epic L609 ("Pre-flight `rg -Fn` verify-command self-defeat pattern") as v0.1.7 candidate. The audit re-confirms the pattern affects AC5 too, not just AC1. **Recommendation:** retroactively edit AC5's verify command to `rg -Fn "docs/plans" scripts/ README.md CONTRIBUTING.md | grep -v "Migration" | grep -v "retro-mark"` (or similar narrow `grep -v`) at the next epic-audit cleanup pass, OR fold into the v0.1.7 codification of self-defeating-verify-pattern review-plan AC.
**Missing coverage:** none beyond AC5's verify-command shape.

---

### E04.S2: Marker-aware resume reporting in `/roughly:upgrade`

| AC | Status | Evidence |
|----|--------|----------|
| AC1 — resume emit per migration step | MET | 2 emits land (`grep -Fo "Resuming v0.1" \| wc -l` = 2): v0.1.4 at L26 ("steps 1-4 already ran" plural), v0.1.6 at L62 ("step 1 already ran" singular). v0.1.2 vacuously satisfies (no marker, no numbered sub-steps). |
| AC2 — emits before any mutation | MET | v0.1.4 emit at L26 lives inside "Conflict check or partial-failure resume" before step 3 marker write at L33. v0.1.6 emit at L62 lives in step 1 "Detection and safety check" before step 2 marker write at L64. |
| AC3 — marker-preserved suffix on abort paths | MET | 3 occurrences of "Marker preserved at" (`grep -Fo \| wc -l` = 3): v0.1.4 step 5 mv-non-zero + data-loss (both at L44), v0.1.6 step 2 mv-non-zero (L64). Marker-write-failure aborts (v0.1.4 L34, mid-L64 v0.1.6) correctly excluded — marker not on disk at those points. |
| AC4 — skill body ≤300 lines | MET | `wc -l skills/upgrade/SKILL.md` = 172. |
| AC5 — completion-summary unchanged | MET | Discovery confirmed none of the three migrations emit a completion-summary line today (vacuously satisfied). |

**Quality notes:** The singular-case carve-out (commit `04e2996`) correctly handles N=2 in the v0.1.6 emit. The `grep -Fc` line-vs-occurrence pitfall surfaced during S2 review (now captured at known-pitfalls.md L104) is exactly the kind of finding S6.AC1 (every-edit-site enumerated) and the v0.1.7 "`grep -Fc` co-location" review-plan candidate are designed to prevent at plan-write time.
**Missing coverage:** none.

---

### E04.S3: Plan-file self-marking historical at completion

| AC | Status | Evidence |
|----|--------|----------|
| AC1 — Stage 8 2-commit pattern in build + fix | MET | Both `skills/build/SKILL.md` and `skills/fix/SKILL.md` Stage 8 step 4 instruct the 2-commit pattern: commit 1 = feat, commit 2 = docs (mark plan historical) with `IMPL_SHA=$(git rev-parse HEAD)` capture. |
| AC2 — Edit-based prepend (not Write) | MET | Stage 8 step 4 prose explicitly directs `Edit` invocation; no plan file diff shows content removal beyond the title-line region. |
| AC3 — build/fix line counts ≤300 | MET | build = 299; fix = **300 (AT CAP)** — known binding constraint for any future fix-touching story per epic Risk 2. |
| AC4 — CONTRIBUTING.md `## Plan-file lifecycle` section | MET | Section exists at CONTRIBUTING.md L89 (24 lines per epic Status). Documents Status block format + `head -1 \| grep -qE` verify pattern (load-bearing per cycle-1 false-positive `grep -L` finding). |
| AC5 — all historical plans retro-marked | MET | First-line check loop returns empty output across all 34 `.roughly/plans/*-plan.md` files. Zero plans carry literal `<SHA>` or `<YYYY-MM-DD>` placeholders. `scripts/ci-dogfood.sh` Assertion 5 at L201 uses `head -1 \| grep -qE` correctly; structural-assertion count echoes 7 at L258. |

**Quality notes:** The cycle-1 review caught two Criticals (AC5 `grep -L` false-positive + ci-dogfood any-line-vs-first-line) — both are now well-documented pitfalls and the shipped form uses the correct `head -1 \| grep -qE` idiom in CONTRIBUTING.md, ci-dogfood.sh, and the new pitfall at known-pitfalls.md L112.
**Missing coverage:** ABORT HANDLING gap for Stage 8's 2-commit window (between step 3 commit and step 4 commit) — already documented at epic L629 as v0.1.7 candidate. Low practical impact (no human gate in that window) but real spec gap. Blocked on fix/SKILL.md off-ramp.

---

### E04.S4: Dogfood `.claude/hooks/verify-all.sh` cleanup

| AC | Status | Evidence |
|----|--------|----------|
| AC1 — `set -e` removed | MET | `grep -Fn "set -e" .claude/hooks/verify-all.sh` returns 0 occurrences. |
| AC2 — `\|\| true` on git rev-parse | MET | L8: `ROOT="$(git rev-parse --show-toplevel 2>/dev/null \|\| true)"`. |
| AC3 — soft-expanded to include cd guard | MET | L12: `cd "$ROOT" 2>/dev/null \|\| exit 0  # exit-0 contract: silent no-op on cd failure (see template L16–25)` — the backport-completeness addition. |
| AC4 — exits 0 unconditionally; JSON fallback | MET | Script ends with `exit 0`; `emit_drift_json` fallback chain (`jq → python3 → no-emit`) preserved. |
| AC5 — no `set -uo pipefail` added | MET | 0 occurrences. |

**Quality notes:** The backport-completeness finding (3 edits vs 2 enumerated; cd guard missed at plan-review + Stage 6 + Stage 7) is the canonical motivation for the "diff result against reference, not just per-edit" plan-write guidance now embedded in E04.S5's epic prose at L291.
**Missing coverage:** none.

---

### E04.S5: Stop hook drift coverage expansion

| AC | Status | Evidence |
|----|--------|----------|
| AC1.1 — Check 1 fires on byte-identity drift | MET | Extraction via `awk` markers; `shasum`/`sha1sum` detected at L46 via `command -v` chain. Per-skill marker-presence pre-check + fixture-existence + tooling-unavailable guards layered (silent-failure-hunter Stage 6 Critical + cubic round 3 P2). |
| AC1.2 — drift entry format | MET | L69: `"- pre-flight wording drift: ${unique_preflight} unique blocks across 7 hard-abort skills (expected 1)\n"`. |
| AC1.3 — deliberately-broken sample verification | MET | Per Stage 7 + Stage 8 verification logs (epic Status). |
| AC2.1 — Check 2 fires on hook-pair drift | MET | L84 plan-mode-gate hook-pair check present; three-level presence cascade (template missing → hook missing → drift) per cubic round 4 P2. |
| AC2.2 — drift entry format | MET | L84: `"- plan-mode-gate hook drift: …differ (run \`diff\` for details)\n"`. |
| AC2.3 — deliberately-broken sample verification | MET | Per Stage 7 logs. |
| AC2.4 — verify-all-stop-hook pair out of scope | MET | CONTRIBUTING.md L184 explicitly carves it out with the E03.S2 quoted-phrase citation. |
| AC3.1 — Check 3 fires on `>80` | MET | L93: `if [ "$n" -gt "$PITFALLS_ORGANIZE_THRESHOLD" ]`. |
| AC3.2 — drift entry format with arithmetic expansion | MET | L94: `"…is $((n)) lines (>${PITFALLS_ORGANIZE_THRESHOLD} threshold) — consider organizing\n"` — cross-platform BSD-padding strip via `$((n))`. |
| AC3.3 — fires regardless of edit source | MET | Check runs unconditionally on every Stop event; no doc-writer trigger coupling. |
| AC3.4 — single named constant + bidirectional sync | MET | `PITFALLS_ORGANIZE_THRESHOLD=80` at verify-all.sh L90; bidirectional sync comments verified at verify-all.sh L88 (naming doc-writer.md Process step 5 / "Organize suggestion") and doc-writer.md L33 (naming `.claude/hooks/verify-all.sh` + the constant name). |
| AC3.5 — verification | MET | known-pitfalls.md currently at 110 lines, Check 3 fires as designed on every run. |
| AC4 — one-line drift entries | MET | All three new checks emit `- <description>\n` format consumed by `emit_drift_json` unchanged. |
| AC5 — exits 0 unconditionally | MET | Tail of script: `exit 0`. |
| AC6 — line count ≤150 soft cap | MET | `wc -l .claude/hooks/verify-all.sh` = 114 (epic projected 87, shipped 114 after defensive guards). |
| AC7 — CONTRIBUTING.md drift-checks section | MET | L160 `## Stop hook drift checks` enumerates all 7 checks; cites E03.S2 by section heading + verbatim quoted phrase per spec. |
| AC8 — no new invariants beyond the three named | MET | Defensive precondition guards treat "files missing" as "check cannot run with directed diagnostic" — not new structural rules; AC8 preserved in spirit per epic L617 boundary-observation discussion. |

**Quality notes:** The 4 cubic rounds + 1 silent-failure-hunter intervention that shaped the final design (empty-hash collapse → fixture-existence guard; ADR-009 silent-protection-unregistration → Check 2 three-level cascade; macOS BSD `wc -l <` padding → `$((n))` arithmetic) demonstrate the defensive-guard pattern that the v0.1.7 candidate at epic L617 ("defensive guard vs new invariant" review-plan AC) is designed to systematize.
**Missing coverage:** Risk 3 (30-day dogfood window) closes by design at v0.1.7 retrospective on zero false-positive accumulation evidence — open per spec.

---

### E04.S6: Plan-discipline codification

| AC | Status | Evidence |
|----|--------|----------|
| AC1 — every-edit-site enumeration check | MET | `skills/review-plan/SKILL.md` L36 ("Every edit site enumerated…"); structural-uniformity carve-out at L37; positive (E03.S9 27-site) + negative (build L185 / fix L192) examples cited. |
| AC2 — runtime-signal-source check | MET | `skills/review-plan/SKILL.md` L44 ("Runtime-signal source named…"); policy-parameter carve-out; positive (E03.S10 "if the failure output indicates a test failure") + negative (E03.S10 first-draft "if Stage 5c was hit by changes to test files") examples cited. |
| AC3 — CONTRIBUTING.md `## Skill authoring conventions` | MET | L50 section heading; L52 multi-branch case dispatch convention with "evaluate top-to-bottom; execute only the first matching case" verbatim language. |
| AC4 — review-plan ≤300 lines | MET | `wc -l skills/review-plan/SKILL.md` = 96. |
| AC5 — each AC has positive AND negative examples | MET | Confirmed for AC1 (E03.S9 plan vs build:185/fix:192), AC2 (E03.S10 final vs first-draft). AC3 has positive case-dispatch example (help/SKILL.md Step 3) + carve-out example (setup/SKILL.md Step 5d Branch 4); negative example for the fall-through-rejection convention is implicit ("then do X; if not, otherwise do Y"). |
| AC6 — self-verification on synthetic fixtures | **PARTIAL** | 8 fixture files exist at `tests/fixtures/review-plan/` (README.md + ac1-pass / ac1-needs-revision / ac1-carve-out-pass / ac2-pass / ac2-needs-revision / ac3-pass / ac3-needs-revision). Post-`9d61030` README correctly does NOT document `claude /roughly:review-plan <path>` as invocable (frontmatter is `disable-model-invocation: true`); instead documents manual desk-check + subagent dispatch paths. Audit verified the fixtures exist and the invocation path is corrected; cannot confirm a live PASS/NEEDS REVISION outcome from each fixture without dispatching the subagent. Epic Status block claims pre-merge fixtures passed. |

**Quality notes:** The post-PR desk-check finding (commit `9d61030`) — that silent-failure-hunter flagged the disable-model-invocation/README mismatch as Info and the implementer downgraded as cosmetic — is itself a strong signal for the v0.1.7 candidate at epic L581 ("README/doc invocation examples must align with skill frontmatter"). S6 implicitly validated its own AC1 (every-edit-site enumerated) via S1's unenumerated review-plan/SKILL.md discovery (AC1 would have caught it pre-implementation).
**Missing coverage:** none beyond AC6's "run live and confirm" gap, which is fixture-driven and acceptable.

---

### E04.S7: ADR-011 — Skill flags as public API

| AC | Status | Evidence |
|----|--------|----------|
| AC1 — ADR file with correct structure | MET | `docs/adrs/ADR-011-skill-flags-as-public-api.md` is 49 lines; Status: Accepted; sections in order: Context (cites S11b-2 OQ1, three options, silent-leak motivation), Decision (with explicit threshold test for "user-facing" per architect review refinement), Consequences (Positive 3-bullet / Negative 5-bullet split per architect review / Neutral 1-bullet), Forward References (v0.2.0 + ADR-010 by role only, no syntax detail), Alternatives Considered (heredoc-fed stdin / override-token env var rejection rationale). Carve-out positive (`ROUGHLY_HAIKU_BUDGET_USD`) + counterexample (`ROUGHLY_SKIP_REVIEW=1`) both present per architect review rule-vs-example-only refinement. |
| AC2 — CLAUDE.md updated | MET | L17 Structure table: `(ADR-001 through ADR-009, ADR-011; ADR-010 reserved for v0.2.0 plan-format-v2)`. L60 Key Design Decisions row: `ADR-011 \| User-facing skill behavior changes are flags, not env vars`. Zero stale `9 ADRs` / `9 Architecture Decision Records` phrasings. |
| AC3 — docs/adrs/README.md updated | MET | L38 lists ADR-011 with one-line summary matching CLAUDE.md row; L37 documents the ADR-010 reservation placeholder. |
| AC4 — CONTRIBUTING.md cross-reference | MET | L62: `User-facing skill behavior changes are flags, not environment variables (see [ADR-011](docs/adrs/ADR-011-skill-flags-as-public-api.md)).` — 1 line, lives in S6's `## Skill authoring conventions` section. |
| AC5 — doc-only diff | MET | S7 PR touched only `docs/adrs/`, `CLAUDE.md`, `CONTRIBUTING.md`, `.roughly/known-pitfalls.md`, and the plan artifact. |

**Quality notes:** Clean pipeline (1 plan-review cycle PASS; 2 Stage 6 cycles; post-merge architect re-review applied 1 nit + 3 considers cleanly). The bold-decorated markdown grep pitfall captured during S7 (`grep -Fn` against `**Status:** Accepted` formatted with bold decorators) is a useful generalization of the regex-metachar pitfall.
**Missing coverage:** none.

---

### E04.S8: doc-writer multi-file-invocation guard

| AC | Status | Evidence |
|----|--------|----------|
| AC1 — multi-file failure-handling clause covers (a)-(f) | MET | `agents/doc-writer.md` L35 sub-bullet covers all six semantics: per-file `Edit` ("invoke `Edit` per file"), per-file outcome capture ("capture each outcome"), non-abort ("do NOT roll back successful writes"), partial-success summary ("Emit this exact summary:"), per-path naming + reason ("wrote to: …; failed to write: …`<path>: <reason>`"), never-claim-full-success ("never claim full success"). |
| AC2 — strictly additive | MET | Sub-bullet at L35 is a peer to the two existing step 5 sub-bullets (Organize suggestion at L33, Test integration suggestion); steps 1–4 and 6+ byte-identical pre/post. |
| AC3 — agent word cap ≤500 | **NOT MET (accepted Path B, deferred)** | `wc -w agents/doc-writer.md` = **557 / 500** (+57 over cap). Epic Status documented +42 (542) at S8 ship; S5's bidirectional sync HTML comment at L33 added the additional +15. Cap-revision tracked as v0.1.7 candidate (epic L587). |
| AC4 — two-part-gate preserved | MET | Organize-suggestion + test-integration suggestions at L33-34 retain their original conditional shape; the new clause is a peer sub-bullet with its own inline gate-override prefix, not a modifier of the outer step 5 gate. |
| AC5 — verbatim partial-success template | MET | L35 contains the exact template `"doc-writer: partial success — wrote to: <comma-separated list of successful paths>; failed to write: <comma-separated list of failed paths with one-line failure reason each, format '<path>: <reason from Edit error output>'>."` — present in the agent file as required by AC5 (whether the runtime LLM emits it verbatim is a separate Risk 5 concern). |

**Quality notes:** The inline gate-override prefix `(always — overrides step 5's outer gate)` is the best-effort hedge against the AC2/AC4-vs-AC1-reachability contradiction documented as v0.1.7 candidate at epic L585. The T2 synthetic test (pre-merge) showed the runtime agent did NOT emit AC5 verbatim — returned free-form prose with correct information but wrong format. Consistent with the unreachable-clause hypothesis or the weak-anchoring hypothesis or both; cluster of 5 spec-level v0.1.7 candidates (AC2/AC4 spec amendment + AC3 cap-hardening + AC5 anchoring + empty-error fallback + all-fail branch) stack as a coherent doc-writer-failure-handling cluster.
**Missing coverage:** Risk 5 stays opportunistic-close into v0.1.7 dogfood per spec. AC3 cap-revision is the structural unblock; the v0.1.7 amendment path is recommended option (b) — revise project-wide cap to 550 or 600 in `.claude/hooks/verify-all.sh:28`.

---

### E04.S9: CI dogfood polish — gtimeout + ANTHROPIC_API_KEY empty-guard

| AC | Status | Evidence |
|----|--------|----------|
| AC1 — `$TIMEOUT` detection block + 3 invocation sites | MET | Detection block at L14–21 with `command -v timeout` / `command -v gtimeout` / friendly diagnostic + `exit 1` chain. `$TIMEOUT` used at 3 invocation sites: L74 (smoke), L100 (plugin-load), L140 (full-scenario). Spec L62/L88/L129 estimates were off by ~4 lines; shipped uses content-based replacement. |
| AC2 — `ANTHROPIC_API_KEY` empty-guard with `${VAR:-}` form | MET | L24: `if [ -z "${ANTHROPIC_API_KEY:-}" ]; then echo "ci-dogfood: FAIL — ANTHROPIC_API_KEY not set or empty (configure in GitHub Settings → Secrets and variables → Actions, or export for local repro)" >&2; exit 1; fi`. `${VAR:-}` form is load-bearing under `set -euo pipefail` at L2 (spec text corrected post-ship: "future-proofing" → "load-bearing for present-state correctness"). |
| AC3 — auth-failure regression still passes | MET | Empty-guard passes through non-empty `invalid-key-xyz`; `.github/workflows/dogfood.yml` auth-failure step untouched. |
| AC4 — happy-path CI passes within budget | MET | Per epic Status, S11b-2 full-scenario passes on `main` within `--max-budget-usd 1.50`. |
| AC5 — CONTRIBUTING.md gtimeout note | MET | L158: `macOS contributors running \`scripts/ci-dogfood.sh\` locally need \`gtimeout\` from \`brew install coreutils\`.` — byte-verbatim per spec. |
| AC6 — no workflow file changes | MET | `git show --stat f3ff1ed -- .github/workflows/dogfood.yml` returns empty. |

**Quality notes:** Clean pipeline (PASS first plan-review; 0 critical/warning at Stage 6; cubic round 1 clean; cubic round 2 caught 1 P2 — CONTRIBUTING.md L109 doc/behavior contradiction where the plan misclassified empty-guard as "additive prose, not replacement" when it IS a replacement for the previously-reachable `claude --bare` auth-failure path). Caught post-PR rather than pre-merge; consistent with the v0.1.7 candidate at epic L625 ("behavior-divergence-doc-coverage check").
**Missing coverage:** none.

---

## Cross-Cutting Findings

### Consistency
- **Shared files cleanly composed.** S1 + S3 (`build/SKILL.md`, `fix/SKILL.md`, `ci-dogfood.sh`), S1 + S2 (`upgrade/SKILL.md`), S4 + S5 (`verify-all.sh`), S5 + S8 (`doc-writer.md`), S6 + S7 (`CONTRIBUTING.md` `## Skill authoring conventions`) all coexist without literal collision.
- **Bidirectional sync between `verify-all.sh:88` and `doc-writer.md:33`** points each consumer at the other by name + constant — the multi-file drift mitigation pattern (PITFALLS_ORGANIZE_THRESHOLD = 80) is in place.

### Integration
- **S1 → S5 (Check 1).** The 7-skill pre-flight blocks created in S1 hash-set sorts -u to 1 unique value matching the canonical fixture — Check 1's premise holds.
- **S1 → S3.** All 34 plans in `.roughly/plans/` carry first-line Status blocks; zero unmarked, zero with literal placeholders. The retro-mark sweep + Stage 8 step 4 prose work end-to-end.
- **S1 → S2.** S2's resume-emit at L62 lives correctly inside S1's v0.1.6 migration step 1, before the marker write at L64.
- **S1 → S9.** S9's `$TIMEOUT` insertions don't conflict with S1's already-landed `.roughly/plans/` assertion-path updates.
- **S6 validates retroactively against S1.** S1's review-plan/SKILL.md unenumerated discovery (4-body spec vs 5-body actual scope) is exactly the failure shape S6.AC1 (every-edit-site enumerated) would have caught at plan-review.

### Gaps
- **S1.AC5 literal verify command is self-defeating** (2 hits at CONTRIBUTING.md L87 + L103 — historical/explanatory prose intentionally naming the legacy path). Same shape as AC1's self-defeating-verify pattern S1 already captured. Recommend folding into the v0.1.7 codification cluster.
- **S6.AC6 self-verification gap.** Synthetic fixtures exist; corrected post-merge to manual desk-check + subagent dispatch path. Audit cannot replay the live verification without dispatching the subagent.
- **S8 AC3 word-cap accepted violation drifted +15 beyond the S8-ship documented +42** because S5 added the bidirectional sync HTML comment at `doc-writer.md:33`. Current state: **557 / 500 (+57)**, vs documented 542 / 500 (+42). Same accepted Path B; just further from cap than the original disclosure. Folds into the v0.1.7 cap-revision candidate.
- **ABORT HANDLING gap for Stage 8's 2-commit window** (no entry for "after step 3 commit, before step 4 commit") — known v0.1.7 candidate, blocked on fix/SKILL.md off-ramp.
- **Risk 3 (Stop hook drift false-positive accumulation)** stays in 30-day dogfood window per spec; closes at v0.1.7 retrospective.
- **Risk 5 (doc-writer multi-file invocation opportunistic close)** stays open per spec until real-dogfood multi-file invocations exercise the clause.

### Regressions
- **None detected.** Line-cap binding at `fix/SKILL.md` = 300/300 is a known binding constraint, not a regression. The doc-writer.md word-cap drift from +42 to +57 is documented and tracked. All other shared-file edits compose cleanly.

---

## Recommendations

**Priority 1 — operational wrap-up (per epic DoD):**
1. Bump `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` version field to `0.1.6`.
2. Rename `## [Unreleased] — v0.1.6` → `## [0.1.6] — 2026-05-23` in CHANGELOG.md at tag time.
3. Push `v0.1.6` tag: `git tag v0.1.6 && git push origin v0.1.6`.
4. Update `docs/ROADMAP.md` `**Current:**` from v0.1.5 → v0.1.6.
5. Audit `.roughly/workflow-upgrades` for the `pitfalls-organized-v1-added 2026-05-14` retired-check marker S4 wrote. Decide remove vs keep per DoD L679.

**Priority 2 — v0.1.7 cluster prep (already enumerated in epic; surface to PM):**
6. **AC verify-command self-defeating pattern** — codify as review-plan AC (cluster with epic L609 candidate + this audit's S1.AC5 finding).
7. **doc-writer cap revision** — recommended option (b): revise project-wide 500-word cap to 550 or 600 in `.claude/hooks/verify-all.sh:28` to unblock S8 AC3 + future failure-handling additions.
8. **fix/SKILL.md off-ramp** — extract MATURITY CHECKS or ABORT HANDLING block to a shared reference (ADR-003 pattern); creates headroom for the S3 2-commit-window ABORT HANDLING entry and any future fix-touching story.
9. **Risk 3 & Risk 5 retrospective** at v0.1.7 PM — assess 30-day dogfood evidence and opportunistic-exercise outcomes.

**Priority 3 — informational follow-through:**
10. Consider promoting the doc-writer-failure-handling cluster (epic L585 + L587 + L589 + L591 + L593) as a single coherent v0.1.7 story.
11. Consider promoting the review-plan-as-spec-quality-gate cluster (epic L607 + L617 + L621 + L625 + this audit's S1.AC5) as a single coherent v0.1.7 story.

---

## Verification artifacts

The following commands return clean state on `main` as of 2026-05-23:

```bash
# S1.AC1 intent-correct
rg -Fn "docs/plans" skills/ | grep -v "pre-flight" | grep -v "setup/SKILL.md" | grep -v "upgrade/SKILL.md" | wc -l
# → 0

# S1.AC4 7-skill + fixture hash
{ for s in audit-epic build fix review review-plan review-epic verify-all; do
    awk '/<!-- pre-flight:start -->/,/<!-- pre-flight:end -->/' skills/$s/SKILL.md | shasum
  done; shasum < tests/fixtures/canonical-preflight-block.txt; } | awk '{print $1}' | sort -u
# → 98ac9282c011a611b64664bbfd7ecc1477aba308 (single hash)

# S1.AC2 git history follow
git log --follow --oneline .roughly/plans/E03-S8-help-command-plan.md | wc -l
# → 3

# S3.AC5 all plans Status-block-marked
for f in .roughly/plans/*-plan.md; do head -1 "$f" | grep -qE '^> \*\*Status:\*\* Historical' || echo "$f"; done
# → (empty)

# S5.AC3.4 bidirectional sync
grep -n "verify-all.sh\|PITFALLS_ORGANIZE_THRESHOLD" agents/doc-writer.md
grep -n "doc-writer" .claude/hooks/verify-all.sh
# → both directions present

# S8.AC3 word-cap drift
wc -w agents/doc-writer.md
# → 557 (cap 500, +57 over — accepted Path B + S5 +15)
```
