# Epic Audit: E05 — doc-writer hardening + review-plan codification + structural off-ramp

**Date:** 2026-05-31
**Auditor:** `/roughly:audit-epic` (skill v0.1.6)
**Target version:** v0.1.7
**Stories audited:** 7 (E05.S1, S2, S3, S4, S4.5, S5, S6)
**Acceptance criteria evaluated:** 45 — **43 MET / 2 PARTIALLY MET / 0 NOT MET**

---

## Summary

E05 lands as a debt-and-amendment release that closes its intended scope cleanly. All seven stories merged with their primary acceptance criteria met; the two partial-met findings are documentation-grade gaps (an unenumerated plan-file artifact in S1's diff-stat scope; S4.5's audit table living in the plan appendix and commit body rather than directly in the GitHub PR description) — neither affects behavior or risk closure. The off-ramp refactor (S4) successfully recovered ~31 lines in both `skills/build/SKILL.md` (268/300) and `skills/fix/SKILL.md` (269/300), closing the v0.1.6 binding state and unblocking the post-window stories. The cap revision to 650 (S1) created the headroom that S2's three-form anchoring needed, though `agents/doc-writer.md` landed at 649/650 — zero practical headroom. Cross-epic AC amendment convention (Risk 4) is the cleanest win: codified in S3 before its first application in S2, with three back-pointer notes in the E04 epic. The T2 synthetic test (S2's runtime LLM template-adherence verification) was deliberately deferred to v0.1.8, leaving Risk 1 open by design per the epic's three-outcome ship policy.

---

## Per-Story Results

### E05.S1: project-wide agent word cap revision 500 → 650

| AC | Status | Evidence |
|----|--------|----------|
| AC1 verify-all.sh 500→650 | MET | `.claude/hooks/verify-all.sh:30` — `[ "$n" -gt 650 ]` |
| AC2 drift entry format | MET | Static inspection — only numeric literal swapped; format string `- $f: $n words exceeds 650 cap` unchanged in structure |
| AC3 CONTRIBUTING.md rationale | MET | `CONTRIBUTING.md:188` — rationale text byte-matches AC3 |
| AC4 CHANGELOG ### Changed entry | MET | Documents cap revision + 557/650 pre-S2 + 595–625 post-S2 projection |
| AC5 git diff scope | PARTIALLY MET | Commit `432b778` touches 5 files in `--stat`: enumerated 4 + `.roughly/plans/E05-S1-...-plan.md` (build pipeline artifact, undocumented in amended AC5) |

**Quality notes:** `CLAUDE.md` modification was user-approved scope expansion (not an agent file edit; AC5's spirit preserved). Strict gap is the plan artifact's absence from the amended file list.

### E05.S2: doc-writer multi-file failure-handling — AC amendment + completion

| AC | Status | Evidence |
|----|--------|----------|
| AC1 clause relocation + typo fix | MET | `## Failure handling` at L37 (top-level); `docs/adrs/` at L24 (typo fixed) |
| AC2 three-form anchoring | MET | MUST at L41; three code-fenced templates L43–53; post-emit self-check L57 (uses preferred `begins with <literal-prefix>` form) |
| AC3 empty-error fallback | MET | L55 — verbatim AC3 text |
| AC4 all-fail branch | MET | All-fail template at L52; branch-selection rule at L41 enumerates 0/≥1/0-succeeded outcomes |
| AC5 word cap ≤650 | MET | `wc -w` = 649 (1-word margin) |
| AC6a back-pointer notes (≥3) | MET | E04 epic L442, L448, L452 — exactly 3 `Amended in E05.S2` matches |
| AC6b CHANGELOG cross-link | MET | CHANGELOG L27 + L10; CONTRIBUTING.md L68 `Cross-epic AC amendments` |
| AC7 no Process renumber | MET | `6. **Deduplicate` at L35 (1 match) |

**Quality notes:** Implementation applied its own pitfall lesson (`begins with` self-check form). The 649/650 word count is the tightest possible pass — any future additive change breaches.

**Missing coverage:** T2 synthetic test result deferred to v0.1.8 per CHANGELOG L31; Risk 1 remains open by accepted policy.

### E05.S3: Review-plan spec-quality gates — 5 new ACs + skill-body polish

| AC | Status | Evidence |
|----|--------|----------|
| AC1 verify-vs-enumeration | MET | SKILL.md L39–40 + carve-out + canonical positive (E04.S1 AC1) + negative |
| AC2 grep -Fc co-location | MET | SKILL.md L42–43 + canonical positive (E04.S2 cycle 1) + negative |
| AC3 defensive-guard vs invariant | MET | SKILL.md L56–57 + canonical positive (E04.S5 AC8) + negative |
| AC4 behavior-divergence doc | MET | SKILL.md L59–60 + canonical positive (E04.S9 CONTRIBUTING.md L109) + negative |
| AC5 self-defeating verify | MET | SKILL.md L45–46 + carve-out + canonical positive (E04.S1 AC1/AC5) + negative |
| AC6a MUST verdict block | MET | SKILL.md L84 + L117 |
| AC6b user-invocable convention | MET | CONTRIBUTING.md L64 — distinguishes user-invocable vs subagent-dispatch-only |
| AC6c Cross-epic AC amendments | MET | CONTRIBUTING.md L68 — 5 lines, three-artifact requirement present |
| AC7a SKILL.md ≤300 lines | MET | 117 lines |
| AC7b canonical examples per AC | MET | All AC1–AC5 carry named positive + negative inline |
| AC7c 15 fixtures (5 triples) | MET | 5 PASS + 5 NEEDS-REVISION + 5 BORDERLINE-PASS; README enumerates the 15 new + 7 retained E04.S6 fixtures |

**Quality notes:** Post-merge fixes `96049fe` (AC5 PASS verify scoping) and `855cb8d` (AC3 BORDERLINE-PASS off-by-one) — both single-fixture content corrections caught at desk-check, not structural misses.

### E05.S4: Off-ramp refactor — extract ABORT HANDLING + Stage 8 to shared

| AC | Status | Evidence |
|----|--------|----------|
| AC1 two shared files + conditionals | MET | `abort-handling.md` exists; `stage-8-wrap-up.md` has inline conditionals at step 2 (L8–26) and step 6 (L32) |
| AC2 build/SKILL.md ≤270 | MET | 268 lines |
| AC3 fix/SKILL.md ≤270 | MET | 269 lines — closes 300/300 binding state with 31-line headroom |
| AC4 ADR-012 sections + forward refs | MET | Context cites E04.S3; distinguishes from ADR-003; Forward Refs to ADR-003 + E05.S5 + E05.S6 |
| AC5 drift check (a)+(b)+(c) | MET | verify-all.sh: shared/ existence L106; per-file checks L109–111; Read-directive window L116–121; content-duplication phrase greps L123–128 |
| AC6 CLAUDE.md + ADRs/README.md | MET | CLAUDE.md L17 Structure row + L18 ADR enumeration + L62 Key Design Decisions row; `docs/adrs/README.md:39` |

**Quality notes:** Read directives placed correctly under section heads (single-line, well within 3-line window). `verify-all.sh` is at 148/150 lines — 2-line headroom under the soft cap; no overage but minimal slack for further additions.

### E05.S4.5: Stage 3 `mkdir -p` audit across skill/agent `.roughly/` writes

| AC | Status | Evidence |
|----|--------|----------|
| AC1 audit across full scope | MET | Plan appendix + commit body enumerate all 6 named AC1 sites plus 2 setup sites; read-only consumers (`help/SKILL.md`) listed and excluded |
| AC2 missing instructions added in-place | MET (with documented carve-out) | Single addition at `stage-8-wrap-up.md:28`; doc-writer carve-out documented (file at 649/650 pre-edit — cap-binding; Edit-vs-Write semantics make `mkdir -p` non-applicable) |
| AC3 audit report in PR description | PARTIALLY MET | Audit table exists in plan appendix `.roughly/plans/E05.S4.5-...-plan.md` + commit body; GitHub PR #54 body contains only cubic auto-summary (no verbatim table) — strict AC3 reading requires the table in the PR body itself |
| AC4 CHANGELOG conditional | MET | CHANGELOG.md L45 under `### Changed` |
| AC5 no behavior change | MET | `git show b883677 --stat`: 3 files (`stage-8-wrap-up.md` +2/-1 inline append, CHANGELOG +2/-0, plan +233/-0 new) |

**Quality notes:** Build/fix Stage 8 convergence via ADR-012 shared file is well-handled — one addition covers both dispatch paths. doc-writer carve-out is principled (word-count blocker + tool-semantics safety argument).

### E05.S5: Stage 8 2-commit-window ABORT HANDLING entry

| AC | Status | Evidence |
|----|--------|----------|
| AC1 entry text + format byte-match | MET | `abort-handling.md:25` — recovery (a) `git rev-parse HEAD` + IMPL_SHA + commit 2; (b) 1-commit-story exception. Header matches existing `**Stage[s] X (...):**` pattern |
| AC2 position-aware + count=1 | MET | awk returned 0 (Stage 8 header and "2-commit window" phrase on same line — within ≤10 bound); `grep -Fc` = 1 |
| AC3 CHANGELOG ### Added + cross-refs | MET | CHANGELOG.md L13 references E04.S3 + epic L629 |
| AC4 self-verification via S3 check | MET | CHANGELOG L16 — review-plan PASS in 1 iteration |

**Quality notes:** awk degenerate-return-0 (entry on same line as Stage 8 header rather than ≥1 line below) is technically within bound but already captured as v0.1.8 candidate. No dogfood exercise possible per Risk 5 framing — ships as additive completeness.

### E05.S6: Reviewer-brief process improvements (3 process observations bundled)

| AC | Status | Evidence |
|----|--------|----------|
| AC1 epic-reviewer AC mutual satisfiability | MET | `agents/epic-reviewer.md:33` + canonical E04.S8 example; 443/650 words; Output section `### AC Mutual Satisfiability` at L64 |
| AC2 review-plan joint satisfiability + carve-out | MET | `skills/review-plan/SKILL.md:62`; carve-out "orthogonal surfaces (different files AND different steps AND different prose regions)" |
| AC3 Stage 6 termination (a)+(b)+(c) | MET | build/SKILL.md L205 + fix/SKILL.md L208 — byte-identical paragraph; evidence-artifact contracts for (b) and (c) |
| AC4 Stage 8 drift framing | MET | `stage-8-wrap-up.md:30` — scoped to plan-file drift, not code-quality drift |
| AC5 CHANGELOG 3 distinct improvements | MET | CHANGELOG L17–19 — three separate bullets with E04 candidate refs L597/L599/L611 |
| AC6 self-validation via S3 checks | MET | Plan reviewed by post-S3 `/roughly:review-plan` with 5 new checks active; PASS in 1 iteration (CHANGELOG L23) |
| Synthetic fixtures (4 total) | MET | 2 review-plan + 2 epic-reviewer; READMEs enumerate with expected verdicts |

**Quality notes:** AC1 word cost ~117 words vs spec's ~40–60 — over-spec'd but content load-bearing (full carve-out + canonical example explanation). Evidence-artifact contracts for cubic termination forms (b) and (c) are honor-system; flagged in CHANGELOG L21 as v0.1.8 candidate.

---

## Cross-Cutting Findings

### Consistency
- Shared-file evolution (S4 → S5 → S6 → S4.5) lands clean additions without overlap.
- Build/fix parity preserved: every dual-edit (S4 refactor, S6 Stage 6 termination) lands byte-identical or with intentional inline-conditional divergence (Stage 8 step 2 + step 6).
- `CONTRIBUTING.md` section additions across S1, S3, S4 are orthogonal (Stop hook drift rationale, skill-authoring conventions, shared-reference pattern).

### Integration
- Inter-story dependencies satisfied without re-work: S1 → S2 (cap before content); S3 → S2.AC6 (codify before apply); S4 → S5/S6 (shared file present before content additions); S3 → S6.AC6 (review-plan ACs active before S6 self-validation).
- One-word S2 margin (649/650) confirms the v0.1.7 epic's pre-implementation OQ12 resolution (650 over 600) was load-bearing — 600 would have breached at the upper projection.

### Gaps
- **T2 synthetic test for runtime LLM template-adherence** is deferred to v0.1.8 per the epic's three-outcome ship policy. Risk 1 (E05) remains OPEN by design; carried into v0.1.8 candidates.
- **Two near-cap surfaces post-E05:** `agents/doc-writer.md` (649/650 hard) and `.claude/hooks/verify-all.sh` (148/150 soft). Both will block any future additive change without explicit cap revision or trim.
- **E05.S4.5 AC3** — strict reading not met (audit table in plan appendix + commit body, not GH PR body). Semantically discoverable; behaviorally inconsequential.
- **E05.S5 AC2 awk degenerate return-0** — already on v0.1.8 candidate list.

### Regressions
- None observed. CI dogfood (S11b-2 happy-path) unchanged. Line caps for `skills/build/SKILL.md` (268/300), `skills/fix/SKILL.md` (269/300), `skills/review-plan/SKILL.md` (117/300) all comfortable.

### Risk closure (per epic Definition of Done)
| Risk | Status |
|---|---|
| Risk 1 — LLM template-adherence | **OPEN** — T2 deferred; v0.1.8 must-do per accepted policy |
| Risk 2 — shared-reference drift | **PENDING** — 30-day post-merge window in progress; assess at v0.1.8 retrospective |
| Risk 3 — review-plan false positives | **OPPORTUNISTIC CLOSE** — no false flags in S6 self-validation |
| Risk 4 — cross-epic AC amendment record | **CLOSED** — codified in S3, first-applied in S2 |
| Risk 5 — 2-commit-window abort handling | **CLOSED** — additive completeness shipped |

---

## Recommendations

Prioritized for v0.1.8 / immediate triage:

1. **HIGH — Resolve T2 synthetic test.** Run T2 against the S2-shipped doc-writer.md and document FULL PASS / PARTIAL PASS / FULL FAIL. Outcome routes Risk 1 to either close or its v0.1.8 fallback (response-validation subagent or programmatic template parser).
2. **MEDIUM — Cap-pressure on `agents/doc-writer.md` (649/650).** Any future additive change to this agent requires either a cap revision or a trim. Surface as a v0.1.8 binding constraint at plan time.
3. **MEDIUM — Cap-pressure on `.claude/hooks/verify-all.sh` (148/150 soft).** Same forcing-function constraint for the drift-check surface. Next drift-check addition either breaches or trims.
4. **LOW — Audit-table-in-PR-body convention.** Future audit stories (analogous to E05.S4.5) should paste the audit table directly into the GitHub PR description, not rely on plan-appendix + commit-body discoverability. Codify in `CONTRIBUTING.md` `## Audit conventions` if a second instance arises.
5. **LOW — E05.S5 awk return-value semantics.** Already on v0.1.8 list. The position-aware verify form should be adjusted so a same-line match returns 1 (next-line semantics) rather than 0 (same-line semantics), or the AC2 bound revised to `≥0` explicitly.
6. **LOW — E05.S1 AC5 scope amendments.** Future scope-amendment ACs that touch `.roughly/plans/*-plan.md` artifacts should enumerate the plan file explicitly to keep the diff-stat assertion clean.

---

## Notes on audit coverage

This audit verified:
- All 45 ACs by direct file inspection at HEAD + AC verify-command execution.
- File mappings derived from canonical implementation commits (`feat(E05.Sx):` + post-merge `fix(E05.Sx):` commits where present).
- Cross-cutting concerns evaluated against shared-file evolution paths and the epic's Risk register.

Not in scope of this audit:
- Real-dogfood multi-file exercise of S2's all-fail branch (Risk 5 from E04 — promotion-to-v0.1.8 assessment item).
- Verify-all.sh drift-check correctness against deliberately broken samples (S4.AC5 verification path; not re-run here).
- Plugin-version bump or v0.1.7 tag readiness (Definition of Done operator items).

---

## Post-audit follow-up: T2 synthetic test (2026-05-31)

**Run as part of audit recommendation #1 (HIGH — Resolve T2 synthetic test).** Sandboxed `roughly:doc-writer` dispatch in `/tmp/doc-writer-t2-sandbox/` with stand-in files for `.roughly/known-pitfalls.md` and `CLAUDE.md`. Writes blocked deterministically via `chflags uchg` (owner-immutable flag) — necessary because chmod 444 alone is bypassed by the Edit tool's write-temp + rename pattern (verified during fixture design).

### Scenario 1 — partial-success (1 Edit succeeds, 1 fails)

**Setup:** `pitfalls-stub.md` writable, `claude-stub.md` immutable.

**Result — FULL PASS:**

```text
doc-writer: partial success — wrote to: /tmp/doc-writer-t2-sandbox/pitfalls-stub.md; failed to write: /tmp/doc-writer-t2-sandbox/claude-stub.md: EPERM: operation not permitted, open '/tmp/doc-writer-t2-sandbox/claude-stub.md'.
```

Verbatim partial-success template at first line of response. `<path>: <reason from Edit error output>` formatting per AC3 held; AC2 three-form anchoring (MUST at L41 + code-fenced template at L48 + post-emit self-check at L57) held; no pre-template prose.

### Scenario 2 — all-fail (0 Edits succeed)

**Setup:** Both `pitfalls-stub.md` and `claude-stub.md` immutable.

**Result — FAIL (template misfire):**

```text
doc-writer: partial success — wrote to: (none); failed to write: `/tmp/doc-writer-t2-sandbox/pitfalls-stub.md`: EPERM: operation not permitted, open '/tmp/doc-writer-t2-sandbox/pitfalls-stub.md', `/tmp/doc-writer-t2-sandbox/claude-stub.md`: EPERM: operation not permitted, open '/tmp/doc-writer-t2-sandbox/claude-stub.md'.
```

Runtime LLM regressed to the partial-success template with a contrived `(none)` placeholder for the successful-paths slot instead of picking the AC4 all-fail template at `agents/doc-writer.md:52` (`doc-writer: all writes failed — <list>`). The branch-selection rule at L41 ("0 succeeded → all-fail") was not honored at the runtime LLM layer for the 0-succeeded case.

### Classification per epic L110–113

**PARTIAL PASS** — one of two scenarios emits the verbatim template. Per the epic's three-outcome ship policy: Risk 1 does NOT close; partial-success anchoring is the documented working pattern; all-fail branch surfaces as v0.1.8 candidate.

### v0.1.8 candidate update

The pre-existing v0.1.8 candidate #1 from CHANGELOG L31 ("Risk 1 T2 runtime classification — documentation task") is now **promoted from documentation to substantive work**: **AC4 all-fail-branch anchoring tightening + T2 re-run.** Candidate hypotheses for the tightening (not prescriptive — PM round decides):

1. **Lift the branch-selection rule from L41 to its own MUST-imperative + post-emit self-check pair.** Currently the branch-selection rule rides on the same MUST sentence as the partial-success template selection ("Your return summary MUST literally begin with one of the three templates below… Pick template by outcome: 0 failed → all-success; ≥1 failed and ≥1 succeeded → partial-success; 0 succeeded → all-fail."). Separating the branch selection into its own discrete MUST + self-check pair would parallel the L57 self-check structure for first-line discipline.

2. **Apply three-form reinforcement to the L52 all-fail template** currently relying on the L41 MUST shared with partial-success. Add MUST-language above the code fence specifically for the all-fail case ("Your return summary MUST literally begin with `doc-writer: all writes failed — …` when 0 writes succeeded.").

3. **Add a separate all-fail-specific post-emit self-check.** Append to L57: "If you observed 0 successful writes, confirm your first line begins with `doc-writer: all writes failed —`, NOT `doc-writer: partial success — wrote to: (none); …`."

### Test reproduction

```bash
# macOS / BSD (as run on 2026-05-31):
SANDBOX=/tmp/doc-writer-t2-sandbox
mkdir -p "$SANDBOX"
cat > "$SANDBOX/pitfalls-stub.md" << 'EOF'
# T2 Test Pitfalls
## Testing
(none yet)
EOF
cat > "$SANDBOX/claude-stub.md" << 'EOF'
# T2 Test Project
## Conventions
(none)
EOF
# Block writes deterministically — macOS/BSD form:
#   For partial-success: chflags uchg "$SANDBOX/claude-stub.md"
#   For all-fail:        chflags uchg "$SANDBOX"/*
# Dispatch roughly:doc-writer subagent with the sandbox paths overridden as targets.
# Cleanup: chflags nouchg "$SANDBOX"/* && rm -rf "$SANDBOX"
```

**Linux equivalent (ext2/3/4, btrfs, xfs):** replace `chflags uchg` with `sudo chattr +i` and `chflags nouchg` with `sudo chattr -i`. The immutability flag on Linux requires `CAP_LINUX_IMMUTABLE` (hence `sudo`) and is filesystem-specific — on filesystems without immutability support (e.g., tmpfs in some configurations, NFS, exFAT), use a writable-parent-dir approach instead: place the "fail" target inside a parent directory the user does not own / cannot write, OR `chmod 000` the parent directory of the fail target after the agent has Read it (different failure mode — affects rename, not file-content writes, so still triggers the Edit-tool write-temp + rename pattern's failure path). The audit test ran on macOS; cross-platform reproduction has not been independently validated and may surface filesystem-specific edge cases.

Test setup design choices:

- Sandbox paths (not real `.roughly/known-pitfalls.md` / `CLAUDE.md`) to avoid polluting the actual project files
- `chflags uchg` / `chattr +i` instead of `chmod 444` because the Edit tool's write-temp + rename pattern silently no-ops through chmod 444 (chmod 444 changes file-content perms; rename uses parent-directory perms which remain writable) — the immutability flag blocks both the rename and any in-place write attempt at the kernel layer
- Sandbox content cleared on disk post-cleanup; both scenarios independently verifiable
- OS constraint: the canonical run used macOS-specific `chflags`. Linux requires the equivalent `chattr` form above. Windows / WSL paths and POSIX-only environments without the immutability flag concept require the alternative parent-directory mechanism described above. Test fidelity depends on the kernel propagating the write error to the Edit tool as a discrete error code (EPERM on the systems tested); platforms that return a different errno may surface a different reason string in the runtime LLM's emitted template, but the template-selection logic under test is errno-agnostic.

---

*Audit report generated by `/roughly:audit-epic` skill; post-audit follow-up appended 2026-05-31 after running audit recommendation #1.*
