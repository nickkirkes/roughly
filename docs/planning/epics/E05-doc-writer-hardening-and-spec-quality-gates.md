# E05: doc-writer hardening + review-plan codification + structural off-ramp

**Date:** 2026-05-26 (PM round)
**Status:** PM draft — pre-implementation review pending.
**Target version:** v0.1.7
**Target effort:** 2-3 weeks part-time (6 stories across 4 clusters; one structural refactor, one spec amendment-and-extension, one AC-additions story, three small/micro)
**Dependencies on prior epics:**

- **E04** (path consolidation + process codification) — primary input. The v0.1.7 candidates section of [E04-path-consolidation-and-process-codification.md](complete/E04-path-consolidation-and-process-codification.md) is the source for all 6 E05 stories. Patterns inherited: 2-commit Stage 8 wrap-up (E04.S3), marker-at-source migration idiom (E04.S1), bidirectional sync comments (E04.S5), ADR-011 flags-as-public-API precedent (E04.S7), the line-cap budget contract (binding post-E04.S3: `skills/fix/SKILL.md` at 300/300), and the doc-writer 500-word cap accepted-Path-B violation (557/500, +57 over) that E05 closes structurally. The off-ramp prepared but unused in E04 is invoked in E05.S4.
- **E03** (trust hardening + ergonomics + CI) — secondary. E05.S3 review-plan AC additions extend E04.S6's `## Skill authoring conventions` framing. The every-edit-site-enumerated AC from E04.S6 is a load-bearing precedent for E05.S3's additions.
- **E01–E02** — none beyond E04's inherited pattern set.

---

## Release thesis

v0.1.6 settled path consolidation and codified the first wave of skill-authoring conventions, but it surfaced two coherent gaps the pipeline can't close from within its current spec: `agents/doc-writer.md`'s failure-handling clause is structurally unreachable under its own AC2/AC4 constraints (T2 synthetic test confirmed the runtime LLM does not emit the AC5 verbatim template), and five separate v0.1.6 stories produced verify-command / scope-mismatch / additive-vs-replacement bugs that pre-implementation review didn't catch. v0.1.7 lands both as a deliberate AC-amendment + AC-additions pair, alongside the structural off-ramp (extract Stage 8 + ABORT HANDLING from build+fix to a shared procedural reference per the new ADR-012 pattern) that unblocks any future fix-touching story — `skills/fix/SKILL.md` is at 300/300 binding post-E04.S3 and the off-ramp is the only path forward. The release is debt-and-amendment work, not new feature surface; v0.2.0 (plan-format-v2, Haiku routing, cost-aware pipeline) is explicitly out of bounds.

---

## Risk register

1. **Cap-hardening unblocks but doesn't fix LLM weak-anchoring on its own.** E05.S1 (cap-hardening, project-wide 500 → 600 in `.claude/hooks/verify-all.sh`) unblocks E05.S2's word-cost additions, but the underlying issue (T2 synthetic test in E04.S8 showed the runtime LLM ignored "Emit this exact summary: `<template>`" and returned free-form prose) is independent of cap. E05.S2's AC5 anchoring-strength change is a prose-only intervention — stronger imperative wording, code-fenced template, post-emit self-check — that may or may not move runtime LLM behavior. Mitigation: re-run T2 synthetic test post-E05.S2 ship; if the runtime LLM still produces free-form prose, document as known-issue + open v0.1.8 candidate for a stronger mechanism (programmatic template parser, response-validation subagent, or downstream output-shape assertion). Risk closes on T2 synthetic test PASS; opportunistic-close otherwise per pattern established in E04.S8 Risk 5.

2. **Off-ramp introduces shared-reference indirection that future contributors may not notice.** E05.S4 extracts ABORT HANDLING + Stage 8 prose from `skills/build/SKILL.md` and `skills/fix/SKILL.md` into `skills/shared/` per the new ADR-012 pattern (distinct from ADR-003's sync-reference pattern for `agents/agent-preamble.md` — ADR-012 is runtime-loaded, not copy-and-sync). The shared-reference pattern works (agent-preamble has held since v0.1.4) but the ADR-012 variant adds a "must update both consumers + shared file" surface: a future story may edit Stage 8 prose inline in build/SKILL.md without realizing the shared reference is authoritative, producing silent drift. Mitigation: ADR-012 documents the convention; new drift check in `.claude/hooks/verify-all.sh` confirms both SKILL.md files reference the shared files at the expected positions (mirrors E04.S5 Check 1 mechanic); `CONTRIBUTING.md`'s `## Skill authoring conventions` gains an explicit "when editing build/fix Stage 8 or ABORT HANDLING prose, edit the shared file — inline copies do not exist post-E05.S4" line. Closes when 30-day post-merge dogfood shows no silent-drift entries on `main` (parallels Risk 3 from E04 — by-design opportunistic-close window).

3. **Review-plan AC additions risk false-positive flagging on legitimate-but-borderline plan structures.** E05.S3 adds 5 new review-plan check categories (AC-verify-scope-vs-enumeration, `grep -Fc` co-location, defensive-guard-vs-invariant, behavior-divergence-doc-coverage, self-defeating-verify pattern). Each check expands the surface where `/roughly:review-plan` can return NEEDS REVISION. Risk: a legitimate intent-correct verify command that names its own exclusion list (e.g., S1.AC5's `grep -v "migrat"` pattern) gets re-flagged on every iteration, producing review-fatigue and undercutting plan-reviewer's signal-to-noise. Mitigation: each AC ships with a bright-line carve-out per E04.S6 pattern; 5 paired PASS+NEEDS-REVISION fixture pairs (one per new AC) added to `tests/fixtures/review-plan/`; carve-out validation pass via desk-check or subagent dispatch before merge per E04.S6 AC6 verification pattern. Closes when E05.S3 ships with 5/5 fixture pairs validating PASS-on-PASS and NEEDS-REVISION-on-NEEDS-REVISION as specified.

4. **First-precedent AC amendment to an already-shipped story may produce inconsistent record.** E05.S2 amends E04.S8's AC2/AC4/AC5 (currently structurally contradictory with AC1's reachability requirement, per E04 epic L585 v0.1.7 candidate). This is the first time v0.1.x has formally amended an already-shipped story's contract. Risk: contributors reading the E04 epic see the original ACs; contributors reading the v0.1.7 epic see the amended ACs; the resolution trail is split across two docs with no canonical pointer. Mitigation: E05.S2 must (a) update the amended ACs in its own epic-S2 entry as the canonical source, (b) add back-pointer notes in E04's S8 entry (`**Amended in E05.S2 — see E05.S2 for the corrected contract**`), (c) CHANGELOG `### Changed` documents the contract revision, (d) codify the convention itself in CONTRIBUTING.md under a new `## Cross-epic AC amendments` subsection so future amendments inherit the pattern. Closes when E05.S2 ships with all four mitigation legs landed.

5. **Stage 8 2-commit-window ABORT HANDLING fix lands without exercise.** E05.S5 adds an ABORT HANDLING entry for the window between commit 1 (feat: implementation) and commit 2 (docs: mark plan historical) of E04.S3's 2-commit Stage 8 pattern. The gap is real (existing ABORT HANDLING covers Stages 1–7 only) but the practical impact is low (no human gate exists in that window, so abort can't realistically trigger from user action). Risk: the new entry is additive completeness without a forcing-function trigger; it may sit in the codebase indefinitely without ever being exercised, making correctness validation opportunistic-only. Mitigation: write the entry to match the existing ABORT HANDLING idiom byte-for-byte (no new prose forms); verify via E05.S3's every-abort-site-enumerated review-plan check (catches mismatches at plan-write); accept as additive completeness, not exercised-and-validated. Closes at v0.1.7 ship as additive-by-design; not a by-design opportunistic-close window like Risks 1 and 2.

---

## Line-cap budget contract

Carried forward from E04 with refreshed starting state.

**Starting state (post-v0.1.6, verified 2026-05-26):** build 299/300, fix **300/300 (AT CAP — binding)**, setup 287/300, help 163/300, upgrade 172/300, review-plan 96/300, audit-epic 141/300, review 88/300, verify-all 80/300, review-epic 64/300. `agents/doc-writer.md` 557 words / 500-word cap (+57 over — accepted Path B from E04.S8; closes structurally in E05.S1 by cap revision to 600).

**The off-ramp is binding for v0.1.7.** Any v0.1.7 story touching `skills/fix/SKILL.md` MUST be substitution-only OR must wait for E05.S4's off-ramp landing first. E05.S2 (doc-writer.md only) and E05.S3 (review-plan/SKILL.md only) are independent of fix. E05.S5 and E05.S6 hard-block on E05.S4.

**Cap-revision contract.** E05.S1 raises the project-wide agent word cap 500 → 600 to absorb E05.S2's failure-handling additions; the new cap is a maintenance parameter in `.claude/hooks/verify-all.sh`, not an ADR-level decision (per OQ3). The skill body line cap stays at 300 — no change.

This contract supersedes any per-story "No skill body exceeds 300 lines" or "agent word cap ≤500" ACs in inherited E04 framing.

---

## Stories

Stories are grouped by cluster. Sequencing — which is by dependency, not cluster order — appears in the final [Sequencing](#sequencing) section.

### Cluster C1 — Doc-writer hardening

#### E05.S1: project-wide agent word cap revision 500 → 600

**Maps to v0.1.7 candidate:** E04 epic L587 — "E04.S8 — AC3 500-word cap accepted violation (Path B at +42 at S8 ship; drifted to +57 post-E04.S5)." Recommended option (b): revise project-wide 500-word cap.

**Files touched:**
- `.claude/hooks/verify-all.sh` (single-line constant edit to the agent word cap value)
- `CONTRIBUTING.md` (one-line rationale note in `## Stop hook drift checks` section)
- `CHANGELOG.md` (under `### Changed`)

**Acceptance criteria:**

- **AC1** — `.claude/hooks/verify-all.sh` agent word cap constant updated from 500 → 600. Verify: `grep -Fn "600" .claude/hooks/verify-all.sh` returns match in the agent-word-cap check block; the corresponding `500` constant is replaced; `wc -w agents/doc-writer.md` (currently 557) is now under cap.
- **AC2** — Drift entry on cap breach still emits in the same format as before; only the threshold value changes. Verify: temporarily edit any agent to 601+ words; confirm drift entry fires with the new threshold value substituted; revert.
- **AC3** — `CONTRIBUTING.md` `## Stop hook drift checks` section updated to reflect the new 600 threshold; one-line rationale appended: `"agent word cap raised 500 → 600 in E05.S1 to accommodate failure-handling clauses with verbatim summary templates."`
- **AC4** — `CHANGELOG.md` `### Changed` entry documents the cap revision and the E04.S8 post-revision compliance status (`agents/doc-writer.md` now compliant at 557/600 pre-E05.S2; will move to ~595–600 post-E05.S2).
- **AC5** — No agent file edits. Verify: `git diff --stat` shows only `.claude/hooks/verify-all.sh`, `CONTRIBUTING.md`, `CHANGELOG.md`.

**Verification:**

- **Dogfood:** trigger Stop hook by completing a Claude turn in this repo's worktree post-edit; confirm agent word cap drift entry no longer fires for `agents/doc-writer.md` (557 ≤ 600).
- **No CI scenario change** — this story doesn't touch CI surface; `--max-budget-usd 1.50` unchanged.

**Dependencies on other E05 stories:** None — anchor for E05.S2.

**Out of scope:**
- Any edits to `agents/doc-writer.md` content (E05.S2 territory)
- Per-agent caps (E04.S8 v0.1.7 candidate option c — deferred without forcing function)
- ADR amendment — cap is a maintenance parameter in a hook constant, not an ADR-level decision
- Adjusting the `PITFALLS_ORGANIZE_THRESHOLD=80` constant or any other Stop hook threshold

---

#### E05.S2: doc-writer multi-file failure-handling — AC amendment + completion

**Maps to v0.1.7 candidates** (E04 epic L585–L593, 4 of the 5 doc-writer-cluster items — AC3 cap-hardening ships separately as E05.S1):
- "E04.S8 — AC2/AC4 vs AC1-reachability spec contradiction"
- "E04.S8 — AC5 strict-format LLM-anchoring"
- "E04.S8 — Empty `Edit` error-output fallback"
- "E04.S8 — All-fail branch missing from AC5 template"

Plus folded-in (per OQ10):
- "Pre-existing typo `docs/adr/` (singular) at `agents/doc-writer.md:24`"

**Files touched:**

- `agents/doc-writer.md` — multi-edit: clause relocation outside step 5; AC5 anchoring strength (MUST + code-fenced template + post-emit self-check); empty-error fallback; all-fail branch addition; redundant gate-override prefix removed post-relocation; `docs/adr/` typo fix at L24
- `docs/planning/epics/complete/E04-path-consolidation-and-process-codification.md` — back-pointer notes appended to AC2, AC4, AC5 entries in the E04.S8 section per Risk 4 mitigation
- `CONTRIBUTING.md` — new `## Cross-epic AC amendments` subsection codifying the amendment convention (3–5 lines)
- `CHANGELOG.md` — `### Changed` documenting the contract revision

**Acceptance criteria:**

- **AC1 — AC2/AC4 amendment via clause relocation outside step 5.** Resolves the AC1-reachability contradiction documented at E04 epic L585. Implementation per recommended option (a): relocate the multi-file failure-handling clause from `agents/doc-writer.md` Process step 5 (currently L35) to an explicit unconditional position — either as a new Process step 6 or as a dedicated `## Failure handling` section. The relocation must preserve all (a)–(f) semantic coverage from original E04.S8 AC1. Verify: `grep -Fn "multi-file failure handling" agents/doc-writer.md` returns a match outside any gated step; clause no longer inherits step 5's success-conditional outer gate. Inline gate-override prefix `(always — overrides step 5's outer gate)` (added in E04.S8 commit `ecf7147`) is removed since relocation makes it redundant. The original `docs/adr/` typo at L24 is also corrected during this pass.

- **AC2 — AC5 anchoring strength.** Replaces the current "Emit this exact summary: `<template>`" form (which T2 synthetic test in E04.S8 showed the runtime LLM ignored — returned free-form prose with correct content but wrong format) with three concurrent reinforcements per `.roughly/known-pitfalls.md` L72: (a) MUST-language imperative ("Your return summary MUST literally begin with the text…"), (b) code-fenced template on its own line with strong preamble ("Format your return summary EXACTLY as this string, substituting only the placeholders:"), (c) post-emit self-check ("Before returning, confirm your summary's first line is `doc-writer: partial success — …` or `doc-writer: all writes failed — …`."). All three required. Verify: `grep -Fn "MUST literally" agents/doc-writer.md` returns match; code-fenced template present on own line; self-check line present. **T2 synthetic test re-run PASS is the runtime validation** (see Verification below); Risk 1 mitigation closes on PASS.

- **AC3 — Empty `Edit` error-output fallback.** Closes the silent-failure-hunter Stage 6 finding from E04.S8 (epic L591). The partial-success template slot `<reason from Edit error output>` previously had no fallback for empty/missing Edit error text — LLM would hallucinate a reason, emit the literal placeholder, or omit the path. Add explicit fallback prose immediately following the template: `"If Edit's error output is empty for a failed path, write '(no error output)' as the reason for that path."` Verify: `grep -Fn "(no error output)" agents/doc-writer.md` returns match.

- **AC4 — All-fail branch.** Closes the silent-failure-hunter Stage 6 finding from E04.S8 (epic L593). The current AC5 template (`partial success — wrote to: …; failed to write: …`) is internally contradictory when every write in a multi-file dispatch fails — `wrote to:` list is empty; "partial success" is false. Add explicit all-fail branch with alternate phrasing template: `"doc-writer: all writes failed — <comma-separated list of failed paths with one-line failure reason each, format '<path>: <reason from Edit error output>'>."` Branch selection rule prose: "Emit the partial-success template when ≥1 write succeeded; emit the all-fail template when 0 writes succeeded." Verify: `grep -Fn "all writes failed" agents/doc-writer.md` returns match; branch-selection rule present.

- **AC5 — Word cap held under E05.S1's new 600 threshold.** `wc -w agents/doc-writer.md` post-edit ≤600. Estimated word delta: AC2 anchoring ≈ +15 net (replaces existing ~15-word "Emit this exact summary" form with ~30-word MUST + preamble + self-check); AC3 empty-error fallback ≈ +10; AC4 all-fail branch ≈ +20–25; AC1 relocation ≈ net-zero (prose moves, doesn't grow); **compensating savings:** AC1 relocation removes the redundant `(always — overrides step 5's outer gate)` prefix (E04.S8 commit `ecf7147`, −7 words). Projected total: 557 + 38–43 = **595–600 words** — at or just under cap. If actual count breaches 600 by 1–5 words, trim existing clause prose without altering (a)–(f) semantic coverage. If breach is larger, surface as Stage 6 question gate — Path B precedent from E04.S8 is available but not preferred since v0.1.7 explicitly closes the v0.1.6 cap-violation; a second violation in the same surface would set a normalization precedent.

- **AC6 — Risk 4 mitigation (cross-epic amendment record).** Three artifacts updated to make the amendment trail discoverable: (a) E04.S8 entry in `docs/planning/epics/complete/E04-path-consolidation-and-process-codification.md` gains back-pointer notes at AC2, AC4, AC5 locations: `**Amended in E05.S2 — see E05.S2 for the corrected contract.**`; (b) new `## Cross-epic AC amendments` subsection in `CONTRIBUTING.md` (3–5 lines) documents the convention: when amending an already-shipped story's AC, update the new epic entry as the canonical source + add back-pointer note in the original epic entry + CHANGELOG `### Changed` entry; (c) `CHANGELOG.md` `### Changed` entry documents the contract revision with explicit reference to E04.S8 ACs being amended. Verify: `grep -Fn "Amended in E05.S2" docs/planning/epics/complete/E04-path-consolidation-and-process-codification.md` returns ≥3 matches.

- **AC7 — Strictly additive to existing Process steps 1–4 and 6+.** AC1's relocation does NOT modify Process steps 1–4 or the existing Process step 6+ (organize-suggestion + test-integration suggestion sub-bullets at L33–34 retain their original conditional shape; both remain inside step 5). The relocated multi-file failure-handling clause becomes either a new Process step 6 (renumbering existing steps 6+ to 7+) OR a new `## Failure handling` section after Process steps. **Bright-line carve-out** preserving the spirit of E04.S8 original AC2: only the clause being relocated changes step-numbering or section-structure; existing failure-handling intent for missing CLAUDE.md and Read-failure (Process steps 3, 4 conditionals) is byte-identical pre/post. Verify: `git diff agents/doc-writer.md` inspection — no content removed or modified outside the relocated clause's source/destination sites + the `docs/adr/` typo correction.

**Verification:**

- **Synthetic test (mirrors E04.S8 T2, expanded for all-fail branch):** dispatch doc-writer with both `.roughly/known-pitfalls.md` and `CLAUDE.md` writes; intentionally permission-deny one. Required outcome: runtime LLM emits the verbatim AC5 partial-success summary template (NOT free-form prose). Then dispatch with both files permission-denied; required outcome: runtime LLM emits the verbatim all-fail template (per AC4 branch-selection rule). Both PASS conditions are required for Risk 1 close.
- **Dogfood:** Stop hook runs against this repo's worktree post-edit; confirms `agents/doc-writer.md` word count ≤600 (per E05.S1 cap-revision + this story's AC5).
- **CI dogfood:** S11b-2 happy-path unchanged — no fixture or assertion change required by this story.
- **Cross-epic amendment record:** verify each AC6 artifact landed by inspection (back-pointer notes present, CONTRIBUTING.md convention written, CHANGELOG entry filed).

**Dependencies on other E05 stories:** **E05.S1 must ship first.** S2's word additions (~38–43 net) breach the current 500 cap; cap-revision to 600 is the structural unblock.

**Out of scope:**

- Programmatic template parser / response-validation subagent (Risk 1 deferred mitigation; v0.1.8 candidate if T2 still fails despite the three-form anchoring in AC2)
- Audit of other agents (investigator, discovery, code-reviewer, silent-failure-hunter, static-analysis, epic-reviewer) for similar multi-file failure-handling gaps (E04 v0.1.7 candidate "Other-agents multi-file failure-handling audit" — explicitly deferred without surface justifying)
- Per-agent word caps (E04.S8 option c — deferred without forcing function)
- Modifying doc-writer's organize-suggestion or test-integration suggestion trigger logic (Risk 5 from E04 specifically protects against this)
- Lifting any of doc-writer's failure-handling clauses into `agents/agent-preamble.md` (agent-preamble is shared-context, not failure-handling)
- Retroactively amending E04.S8 ACs in place rather than adding back-pointer notes (the back-pointer pattern preserves historical record — amendment-in-place would corrupt it)

---

### Cluster C2 — Review-plan codification

#### E05.S3: Review-plan spec-quality gates — 5 new ACs + skill-body polish

**Maps to v0.1.7 candidates** (5-item review-plan-as-spec-quality-gate cluster, plus folded-in items per OQ10):

- "E04.S1 — AC verify-command scope must match spec's enumerated-file-list" (epic L607)
- "E04.S1 — Pre-flight `rg -Fn` verify-command self-defeat pattern" (epic L609; reinforced by audit's S1.AC5 finding)
- "E04.S2 — `grep -Fc` / `grep -Fn` same-line co-location verify-command hazard" (epic L621)
- "E04.S5 — AC8 'no new invariants' boundary erosion under iterative defensive review" → defensive-guard-vs-invariant distinction (epic L617)
- "E04.S9 — Additive-vs-replacement misclassification at plan-write" → behavior-divergence-doc-coverage check (epic L625)

Plus folded-in (per OQ10):

- "Stronger output-mandatory wording in `skills/review-plan/SKILL.md`" (epic L583)
- "README/doc invocation examples must align with skill frontmatter" (epic L581) — landed as a CONTRIBUTING.md `## Skill authoring conventions` convention rather than a review-plan AC

**Files touched:**

- `skills/review-plan/SKILL.md` — 5 new check entries added to existing dimensions (Completeness / Assumptions / Risks per E04.S6 framing); stronger output-mandatory wording added to skill body's verdict-emission instructions. Current 96/300 lines; projected ≈130–145 — well under cap.
- `CONTRIBUTING.md` — `## Skill authoring conventions` section (created E04.S6) extended with 5 paired one-line summaries (rule + canonical positive/negative pointer per E04.S6 pattern); separate one-line addition for the invocation-example/frontmatter convention.
- `tests/fixtures/review-plan/` — 5 new paired PASS + NEEDS REVISION fixtures (one per AC1–AC5); README enumeration extended per E04.S6 fixtures README convention post-`9d61030`.
- `CHANGELOG.md` — `### Added` entry documenting the 5 new checks + 1 new convention.

**Acceptance criteria:**

- **AC1 — AC-verify-command-scope vs spec-enumeration check.** `skills/review-plan/SKILL.md` gains a check entry: "When an AC's verify command searches a broader scope than the spec's enumerated file list (e.g., AC says 'verify against `skills/`' but spec enumerates only `build/SKILL.md` and `fix/SKILL.md`), flag the asymmetry. The asymmetry is either an under-enumeration bug (spec missed files the verify will catch at execution) or an intentional broader-than-enumeration safety net (in which case the plan must explicitly acknowledge the asymmetry)." **Bright-line carve-out:** explicit acknowledgment in the plan body using the phrase "intentionally broader than enumeration" (or equivalent named asymmetry rationale) is the PASS form; silent asymmetry is the NEEDS REVISION form. Canonical positive example: E04.S1 AC1's `rg -Fn "docs/plans" skills/` verify — broader-than-enumeration discovered `skills/review-plan/SKILL.md` unenumerated, caught at Stage 2; the asymmetry pattern is correct, the plan-time acknowledgment is what was missing. Canonical negative example: an AC enumerating 4 files and verifying with `rg ... <only those 4 files>` (verify scope = enumeration scope; no asymmetry detection mechanism — but no asymmetry to detect, so PASS).

- **AC2 — `grep -Fc` / `grep -Fn` same-line co-location check.** `skills/review-plan/SKILL.md` gains a check entry: "When a verify command uses `grep -Fc <pattern> <file>` or `grep -Fn <pattern> <file>` to count occurrences, and the plan enumerates N edited sites that might land on the same physical line (paragraph-dense skill markdown is common), flag the verify-command form. `grep -Fc` counts matching LINES, not occurrences; use `grep -Fo <pattern> <file> | wc -l` for occurrence counts." **Bright-line carve-out:** verify commands that count N sites known to be on physically distinct lines (function definitions, separately-bulleted entries, line-by-line config keys) pass; the check fires only when same-line co-location is plausible (multiple sites within a single paragraph, parenthetical alternatives, or HTML-comment-internal annotations). Canonical positive example: E04.S2 cycle 1 caught two abort-suffix sites landing on the same L44 — the AC3 verify expected `count=3` but got `count=2`. Canonical negative example: a verify counting `^### T[0-9]+` task headings in a plan file — one per line by markdown structure, immune to co-location.

- **AC3 — Defensive-guard vs new-invariant distinction check.** `skills/review-plan/SKILL.md` gains a check entry: "When an AC bounds the scope of new invariants using language like 'no new X beyond the named Y,' the bound is on *structural rules*, not on *behavior at the named site*. Defensive precondition guards for the named Y are explicitly in-scope and do not require AC amendment. Plans that add guards for the named-Y invariants pass; plans that add a new invariant beyond the named set need AC amendment." **Bright-line carve-out:** AC bounding language should be written as "no new structural rules" rather than "no new behavior at the named site" to enable guard additions; review-plan flags AC text using the latter form and suggests the former. Canonical positive example: E04.S5 AC8 + the Stage 6 fixture-existence guard + per-skill marker pre-check + tooling-unavailable branch — all defensive guards for the three named invariants, AC8 preserved in spirit per E04 epic L617 boundary observation. Canonical negative example: a plan that adds a fourth byte-identity check while AC8 forbids new invariants — that requires AC amendment, not a guard.

- **AC4 — Behavior-divergence doc-coverage check.** `skills/review-plan/SKILL.md` gains a check entry: "When a guard, early-exit, or new branch is added before previously-reachable code, any documentation describing the previously-reachable behavior via that input path must be examined for accuracy. It cannot be classified as 'additive prose untouched.' If the doc describes the now-unreachable behavior, it must be revised or removed in the same PR." **Bright-line carve-out:** guards added at boundaries where no prior documentation existed (greenfield addition) pass; only guards layered onto previously-reachable code paths trigger the check. Canonical positive example: E04.S9 CONTRIBUTING.md L109 — the `ANTHROPIC_API_KEY` empty-guard made the previously-reachable `claude --bare` auth-failure path unreachable for the unset-key case; CONTRIBUTING.md L109 documented the unreachable behavior; cubic round 2 caught the contradiction post-PR. Canonical negative example: a new function that adds caching as its first call (no prior doc could describe the uncached path because the function is new).

- **AC5 — Self-defeating-verify-pattern check.** `skills/review-plan/SKILL.md` gains a check entry: "When an AC's verify command searches for a literal that is intentionally present in the new detection prose or in newly-added historical/explanatory docs (legacy-state detection blocks, migration step prose, retro-mark sweep documentation), the literal-form verify is self-defeating. Use `grep -v` exclusions for documented self-reference sites, OR restructure to a count-based or hash-based check, OR scope the verify to active-runtime surfaces only with named exclusions." **Bright-line carve-out:** verify commands operating on a scope known to be free of the literal (e.g., production runtime files after a complete migration with no documented retention) pass; the check fires only when the new detection prose, migration step, or historical doc contains the literal being searched. Canonical positive example: E04.S1 AC1 (`rg -Fn "docs/plans" skills/` → 14 matches post-impl, all legitimate pre-flight / setup / upgrade self-references) and AC5 (`rg -Fn "docs/plans" scripts/ README.md CONTRIBUTING.md` → 2 matches post-impl, both intentional historical/explanatory references). Both required `grep -v` exclusions post-shipping (audit S1.AC5 finding). Canonical negative example: a verify command using `rg -Fn` against a scope explicitly carved out of self-reference (e.g., `skills/ --exclude-dir=setup` when only setup contains the literal).

- **AC6 — Skill-body polish (stronger output-mandatory wording + invocation-example/frontmatter convention).** Two-part fold-in per OQ10:
   - (a) `skills/review-plan/SKILL.md` body gains stronger output-mandatory wording in the verdict-emission section: "Every dispatch MUST produce a verdict block (PASS or NEEDS REVISION). No early termination, no mid-investigation 'let me check' interruptions; produce the verdict block as the final output." Surfaced 2026-05-15 during E04.S6 Stage 4 dispatch where the agent stopped mid-investigation and required explicit "produce the verdict block, no exceptions" re-dispatch to recover (epic L583). Verify: `grep -Fn "MUST produce a verdict block" skills/review-plan/SKILL.md` returns match.
   - (b) `CONTRIBUTING.md` `## Skill authoring conventions` section gains a one-line addition: "Any README or doc that documents `/roughly:<skill>` as a user-invocable command must cross-check the skill's `disable-model-invocation` frontmatter field; skills with `disable-model-invocation: true` are subagent-dispatch-only and cannot be invoked via the `claude /roughly:<skill>` slash-command form. Examples: setup, upgrade, help, build, fix are user-invocable; review-plan, review, review-epic, audit-epic, verify-all are subagent-dispatch-only." Canonical reference: E04.S6 fixtures README post-`9d61030`. Verify: section contains the named convention; example list distinguishes the two categories accurately against current frontmatter.

- **AC7 — Cross-cutting requirements (mirrors E04.S6 AC4–AC6 pattern):**
   - (a) `skills/review-plan/SKILL.md` post-merge ≤300 lines (current 96; projected 130–145 with the 5 new checks + AC6 polish — comfortable headroom).
   - (b) Each new AC1–AC5 entry has at least one named canonical positive example AND one named negative example, sourced from v0.1.6 E04 retrospective material (already specified per-AC above; verify presence by inspection).
   - (c) Self-verification: 5 paired synthetic fixtures (PASS + NEEDS REVISION) under `tests/fixtures/review-plan/` — one pair per AC1–AC5 — plus the existing 7 E04.S6 fixtures retained unchanged. Each new pair tests both the PASS form (carve-out applies or no asymmetry) and the NEEDS REVISION form (the AC fires with the AC-number cited by name in the verdict). Verification via manual desk-check OR subagent dispatch per the E04.S6 fixtures README convention. Required outcome: 5 PASS plans return PASS; 5 NEEDS REVISION plans return NEEDS REVISION with AC1 / AC2 / AC3 / AC4 / AC5 cited respectively. Fixtures README enumerates the 5 new pairs alongside the existing 7.

**Verification:**

- **Synthetic fixture verification (pre-merge):** AC7c above. All 10 new fixtures (5 pairs) exercised; verdicts confirmed as specified.
- **Regression check against E04.S6 ACs:** existing 7 E04.S6 fixtures still PASS/NEEDS REVISION as originally specified — no behavior change to AC1 (every-edit-site enumerated), AC2 (runtime-signal-source named), AC3 (case-dispatch convention) from E04.S6.
- **Negative-control:** craft a plan that has the carve-out language for each new AC (e.g., "AC verify intentionally broader than enumeration to catch missed edit sites" for AC1; "all sites on physically distinct lines per N=1 per `### T<n>` heading" for AC2). Run `/roughly:review-plan`; required outcome PASS (carve-out applies, not false-positive flag — closes Risk 3 from this epic).
- **CI dogfood:** S11b-2 happy-path unchanged — this story doesn't touch CI surface.
- **Self-validation via E05.S2:** E05.S2's draft plan is itself reviewed by the post-E05.S3 `/roughly:review-plan` checks. Required outcome: E05.S2's cross-epic amendment ACs and word-budget projection do not silently flag any of the new 5 checks (or, if they do, the plan acknowledges the carve-out explicitly per the bright-line carve-out pattern).

**Dependencies on other E05 stories:** None — independent. `skills/review-plan/SKILL.md` has substantial headroom (96/300); no shared-surface conflict with C1 or C3. Can land in parallel with any other story.

**Out of scope:**

- Single-source `PITFALLS_ORGANIZE_THRESHOLD` mechanism (E04 v0.1.7 candidate; not in review-plan's surface)
- Verify-all.sh drift check for README invocation examples (option b from epic L581 candidate; this story uses option a — CONTRIBUTING.md convention only, per OQ10)
- Stage 6 prose changes to build/fix (E05.S6 territory)
- Modifying existing E04.S6 ACs beyond the 5 additions and the AC6 skill-body polish
- Enforcing the new conventions via `verify-all.sh` Stop hook or pipeline-skill runtime checks — conventions are pre-implementation review (review-plan only)
- Bundling the AC mutual-satisfiability check from E05.S6 here — that check operates on the epic level (across ACs), not the plan level (within an AC); different review-stage surface (epic-reviewer vs plan-reviewer)
- Plan-implementation drift framing (E05.S6 territory; Stage 8 prose, not review-plan AC)

---

### Cluster C3 — Structural off-ramp

#### E05.S4: Off-ramp refactor — extract ABORT HANDLING + Stage 8 prose to shared procedural reference

**Maps to v0.1.7 candidates:**

- E03 carry-forward, E04 epic L566: "Refactor build/fix preamble + Stage 1 + Stage 8 prose into a shared reference" — scoped to ABORT HANDLING + Stage 8 only per OQ11
- E04.S3 ABORT HANDLING gap (epic L629) — structural prerequisite for E05.S5

Plus fold-in (per OQ10):

- "E04.S1 — Stage 3 `mkdir -p` audit across skills writing to `.roughly/` subpaths" (epic L613)

**Current state (verified 2026-05-26):** ABORT HANDLING at `skills/build/SKILL.md` L277–299 (~23 lines) and `skills/fix/SKILL.md` L278–300 (~23 lines); Stage 8 WRAP-UP at build L223–276 (~54 lines) and fix L226–277 (~52 lines). Per-file extraction potential: ~75–77 lines.

**Files touched:**

- New: `skills/shared/abort-handling.md` (extracted authoritative ABORT HANDLING prose)
- New: `skills/shared/stage-8-wrap-up.md` (extracted authoritative Stage 8 prose; merges build + fix variants via highest-fidelity union with conditional prose where they diverge)
- `skills/build/SKILL.md` — Stage 8 + ABORT HANDLING sections replaced with shared-reference directives; current 299 → projected ≤240 (~60 line recovery)
- `skills/fix/SKILL.md` — same; current 300 → projected ≤240 (~60 line recovery; closes the 300/300 binding state)
- New: `docs/adrs/ADR-012-runtime-shared-procedural-references.md`
- `.claude/hooks/verify-all.sh` — new drift check confirming both SKILL.md files reference the shared files and the shared files exist
- `CONTRIBUTING.md` — `## Skill authoring conventions` extended with shared-reference pattern guidance (when to extract vs inline)
- `CLAUDE.md` — Structure table adds `skills/shared/<name>.md` row; ADR enumeration updated to include ADR-012; Key Design Decisions table adds ADR-012 row
- `docs/adrs/README.md` — ADR-012 entry added
- `CHANGELOG.md` — `### Changed`

**Acceptance criteria:**

- **AC1 — Shared procedural reference files created.** Two new files: `skills/shared/abort-handling.md` (extracted from build L277–299 + fix L278–300; merged via highest-fidelity union — where build and fix diverge, the union preserves both variants under conditional prose like "If invoked from /roughly:build: X. If invoked from /roughly:fix: Y."); `skills/shared/stage-8-wrap-up.md` (extracted from build L223–276 + fix L226–277; same union mechanic). Both files are documentation-class (no `disable-model-invocation` frontmatter required since they're not skills; implementer chooses whether to add YAML frontmatter for tooling consistency). Each file is authoritative; build/fix SKILL.md references derive from these.

- **AC2 — `skills/build/SKILL.md` post-merge ≤240 lines.** Current 299. Stage 8 (L223–276) and ABORT HANDLING (L277–299) sections replaced with shared-reference invocation directives at the section heads (e.g., `## STAGE 8: WRAP-UP\n\nRead `skills/shared/stage-8-wrap-up.md` and apply the procedure documented there. Build-specific sub-steps (if any) are tagged in the shared file.`). Each replaced section becomes ~3 lines (heading + directive + per-skill conditional pointer). Net: ~75 inline lines → ~6 directive lines, recovering ~70 lines. Projected: 299 - 70 + minor adjustments = ≤240.

- **AC3 — `skills/fix/SKILL.md` post-merge ≤240 lines.** Current 300 (AT CAP). Same mechanic as AC2 applied to fix L226–277 + L278–300. Projected: 300 - 70 = ≤240. **Closes the binding state at 300/300** that constrained any v0.1.6+ fix-touching work.

- **AC4 — ADR-012 created.** `docs/adrs/ADR-012-runtime-shared-procedural-references.md` follows existing ADR format (ADR-008/ADR-009/ADR-011 precedent). Sections: `## Context` (cites E04.S3 line-cap binding at fix=300/300 + E05.S2 cap pressure on doc-writer + the off-ramp candidate at E04 epic L566); `## Decision` (procedural prose duplicated across build and fix is extracted to `skills/shared/` and referenced via runtime Read directive — distinct from ADR-003's sync-reference pattern which covers static context inlined verbatim in agents); `## Consequences` (Positive: line-cap headroom recovered; single source of truth for procedural prose; new content lands in one place. Negative: "must update both consumers + shared file" if directive paths change, mitigated by AC5's drift check; runtime Read adds one tool call per section entry); `## Alternatives Considered` (sync-reference per ADR-003 pattern — rejected since it doesn't recover lines; per-stage extraction — rejected as over-fragmenting; bigger cap-bump — rejected since the duplication itself was technical debt). `## Forward References` to ADR-003 (related pattern, different use case) and E05.S5 (first downstream story landing new content in the shared file).

- **AC5 — `.claude/hooks/verify-all.sh` drift check added.** New check fires when (a) either shared file is missing from `skills/shared/`, OR (b) `skills/build/SKILL.md` does not contain a Read directive pointing at `skills/shared/abort-handling.md` AND `skills/shared/stage-8-wrap-up.md`, OR (c) same for `skills/fix/SKILL.md`. Drift entry format: `"- shared procedural reference drift: <skill>/SKILL.md missing Read directive for <shared-file>"` or `"- shared procedural reference drift: skills/shared/<file>.md missing"`. Soft cap on verify-all.sh stays at 150 lines (current 114; +~10 for new check = ~124 — comfortable). Defensive precondition guard per E04.S5 boundary observation: if `skills/shared/` directory itself is missing, emit a directed `"shared/ directory missing"` diagnostic rather than collapsing to per-file checks.

- **AC6 — CLAUDE.md + docs/adrs/README.md updated.** Structure table in CLAUDE.md gains a `skills/shared/<name>.md` row describing runtime-shared procedural references with ADR-012 pointer. ADR enumeration updated from `(ADR-001 through ADR-009, ADR-011; ADR-010 reserved for v0.2.0 plan-format-v2)` to `(ADR-001 through ADR-009, ADR-011, ADR-012; ADR-010 reserved for v0.2.0 plan-format-v2)`. Key Design Decisions table gains ADR-012 row. `docs/adrs/README.md` Current ADRs list adds ADR-012 with one-line summary.

- **AC7 — Stage 3 `mkdir -p` audit per OQ10 fold-in.** Audit all skill/agent files that perform `Write` to under-`.roughly/` paths; confirm explicit `mkdir -p <parent>` instruction or "create parent if absent" hint immediately precedes each Write site. Audit scope: `skills/build/SKILL.md` Stage 3 (existing, verified post-E04.S1), `skills/fix/SKILL.md` Stage 3 (existing), `skills/build/SKILL.md` Stage 8 plan-historical write (added in E04.S3 — verify `.roughly/plans/` parent guaranteed since plan was already written at Stage 3), `skills/fix/SKILL.md` Stage 8 plan-historical write (same), `agents/doc-writer.md` `.roughly/known-pitfalls.md` write paths, `skills/upgrade/SKILL.md` migration-related writes. Read-only consumers (e.g., `skills/help/SKILL.md`) excluded. Audit report appended to E05.S4 PR description; missing mkdir-p instructions added in the same PR. Verify: post-audit, no Write-to-under-`.roughly/` site lacks a paired mkdir-p instruction or a documented "parent guaranteed because [reason]" rationale.

**Verification:**

- **Dogfood (local):** run build pipeline end-to-end against a synthetic happy-path fixture (`tests/fixtures/hello-roughly/` or equivalent); confirm orchestrator successfully Reads shared files at Stage 8 entry and at any abort-trigger point; abort-handling procedure executes as before (no behavior regression). Confirm post-build line counts: build/SKILL.md ≤240, fix/SKILL.md ≤240.
- **CI dogfood:** S11b-2 happy-path passes against the refactored build skill. The shared-file Read introduces 1–2 extra tool calls but token cost held within `--max-budget-usd 1.50`.
- **Drift detection:** deliberately-broken samples — temporarily delete `skills/shared/abort-handling.md` (confirm Stop hook fires with AC5 entry format); temporarily edit a Read directive's path to a nonexistent file (confirm same); revert each.
- **Audit:** confirm AC7 audit report attached to PR description; all named sites pass mkdir-p check or have documented parent-guaranteed rationale.

**Dependencies on other E05 stories:** None — anchor for E05.S5 and the Stage 6 / Stage 8 components of E05.S6.

**Out of scope:**

- Extract preamble or Stage 1 (per OQ11 — confirmed off-ramp scope is ABORT HANDLING + Stage 8 only; preamble + Stage 1 extraction deferred until next forcing function)
- Convert `agents/agent-preamble.md` to ADR-012 pattern (different concern; agent-preamble is static context, not procedure; ADR-003 stays authoritative for that case)
- Behavior change to ABORT HANDLING or Stage 8 procedures (this story is mechanical refactor only; E05.S5 + E05.S6 add behavior in the shared files post-extraction)
- New stages, gates, or commits in the wrap-up sequence
- Modifying maturity-check or stop-hook installation prose (separate concern, not in scope)
- Renumbering ADR-010 to make room — ADR-010 stays reserved for v0.2.0 plan-format-v2

---

#### E05.S5: Stage 8 2-commit-window ABORT HANDLING entry

**Maps to v0.1.7 candidate:** E04 epic L629 — "E04.S3 — ABORT HANDLING extension for Stage 8's 2-commit window. S3 introduced the 2-commit Stage 8 pattern (commit 1 = implementation; commit 2 = Status block prepend referencing commit 1's SHA). The existing ABORT HANDLING block in `skills/build/SKILL.md` + `skills/fix/SKILL.md` covers Stages 1–7 explicitly but has no entry for 'after step 3 commit, before step 4 commit.'"

**Files touched:**

- `skills/shared/abort-handling.md` (modified — adds new entry for the 2-commit window; post-E05.S4 this is the authoritative source)
- `CHANGELOG.md` — `### Added`

**Acceptance criteria:**

- **AC1 — New ABORT HANDLING entry for Stage 8 2-commit window.** `skills/shared/abort-handling.md` gains an entry covering the window between commit 1 (feat: implementation) and commit 2 (docs: mark `<feature>` plan historical). Entry text: "**After Stage 8 step 3 commit, before step 4 commit (rare — no human gate exists in this window):** Commit 1 already landed; do not revert. Recovery options: (a) manually run `git rev-parse HEAD` to capture `IMPL_SHA`, prepend the Status block per Stage 8 step 4 template, commit 2 (`docs: mark <feature> plan historical`); OR (b) accept the implementation-only commit and skip plan-historical marking — the plan stays as a Stage-3 snapshot per E05.S6's plan-implementation-drift framing. Recovery path (a) preserves the canonical 2-commit pattern; (b) accepts a 1-commit story as a documented exception." Format matches existing ABORT HANDLING entries byte-for-byte — no new prose forms per Risk 5 mitigation.

- **AC2 — Entry placement matches the file's organizational principle.** If `skills/shared/abort-handling.md` is organized by stage (Stage 1 → 2 → 3 → ... → 8 → general), the new entry goes immediately after the existing Stage 8 entry (which currently covers Stage 8 step 1–3 only). Verify by inspection: `grep -B1 -A1 "2-commit window" skills/shared/abort-handling.md` returns the new entry placed adjacent to Stage 8 prose.

- **AC3 — CHANGELOG `### Added` entry** documents the new 2-commit-window entry with reference to E04.S3's surfacing of the gap and E04 epic L629 candidate.

- **AC4 — Self-verification via E05.S3's `every-abort-site-enumerated` review-plan check** (if E05.S3 shipped first; otherwise manual desk-check). The plan for E05.S5 itself should pass the E05.S3 AC5 check (self-defeating verify pattern) since the verify command operates on `skills/shared/abort-handling.md` — not a file with self-referential prose.

**Verification:**

- **Static inspection:** `grep -Fn "2-commit window" skills/shared/abort-handling.md` returns 1 match in the entry; surrounding format matches existing entries.
- **No dogfood/CI exercise possible** — per Risk 5, no human gate exists in the 2-commit window, so abort cannot realistically trigger; this story ships as additive completeness, not exercised-and-validated. Documented as such in the PR description.

**Dependencies on other E05 stories:** **E05.S4 must ship first** (provides `skills/shared/abort-handling.md` as the authoritative source for the new entry).

**Out of scope:**

- Modifying the underlying 2-commit Stage 8 pattern (E04.S3 locked)
- Adding a human gate between commit 1 and commit 2 (intentionally absent; auto-progresses per E04.S3 spec)
- Backporting the new entry into `skills/build/SKILL.md` or `skills/fix/SKILL.md` inline (post-E05.S4 the shared file is authoritative; inline backport would be a regression)
- Other ABORT HANDLING additions (no other identified gaps; out-of-scope creep would defeat the AC1 "match existing format byte-for-byte" guarantee)

---

### Cluster C4 — Reviewer-brief process improvements

#### E05.S6: Reviewer-brief process improvements (3 process observations bundled)

**Maps to v0.1.7 candidates** (3 items per OQ7 Option A — prose-only):

- "Epic-reviewer / plan-reviewer 'AC mutual satisfiability' check pass" (epic L597)
- "Plan-implementation drift at Stage 8 wrap-up" (epic L599) — recommended option (b): plans explicitly marked as Stage-3 snapshots not maintained post-implementation
- "E04.S1 — Cubic-iteration termination criteria" (epic L611) — covers OQ9 absorption

**Note:** "Cubic-readable known-issues mechanism" (epic L601) deferred to v0.1.8 per OQ7 Option A (mechanism design, separate from prose-only process work).

**Files touched:**

- `agents/epic-reviewer.md` (~+5 lines for AC mutual satisfiability check; current 72 lines / well under 500-word cap)
- `skills/review-plan/SKILL.md` (~+5–8 lines for plan-level AC mutual satisfiability; current ~96 + projected ~130–145 from E05.S3 + this ~5–8 = ~135–153; comfortably under 300 cap)
- `skills/build/SKILL.md` Stage 6 (cubic-iteration termination criteria; ~+5 lines)
- `skills/fix/SKILL.md` Stage 6 (cubic-iteration termination criteria; ~+5 lines)
- `skills/shared/stage-8-wrap-up.md` (plan-implementation drift framing; ~+3 lines added to the Status block prepend instruction; post-E05.S4 file)
- `CHANGELOG.md` — `### Added`

**Acceptance criteria:**

- **AC1 — Epic-level AC mutual satisfiability check in `agents/epic-reviewer.md`.** Add a new evaluation step to the epic-reviewer's brief: "For each pair of ACs that reference overlapping surfaces (same file path, same step number, same prose region, same fixture, or same constraint), verify joint satisfiability. If two ACs jointly create a structural impossibility — e.g., AC2 forbids modification outside step X AND AC1 requires the modification to fire when step X's gate is closed — flag as a blocker requiring AC amendment before the epic is approved." Canonical positive example named in the brief: E04.S8's AC2/AC4-vs-AC1-reachability contradiction (would have been caught at epic-review iteration 2 instead of surfacing across multiple post-merge cubic iterations). Word cost ≈ 40–60 words; epic-reviewer.md stays under 500-word cap. Verify: `grep -Fn "AC mutual satisfiability" agents/epic-reviewer.md` returns match.

- **AC2 — Plan-level AC mutual satisfiability check in `skills/review-plan/SKILL.md`.** Mirror of AC1 at the plan-review level. Add a new check entry: "For each pair of ACs in the plan that reference overlapping surfaces (same file, same step, same prose region), verify joint satisfiability. If two ACs create a structural impossibility within the plan's implementation scope, flag for clarification before approving the plan." **Bright-line carve-out:** ACs that reference orthogonal surfaces (different files, different steps, different prose regions) skip this check. Canonical positive example: same E04.S8 example as AC1. Add to the existing review-plan check list at the location matching E04.S6 + E05.S3 patterns (under Assumptions or Risks dimension — implementer chooses based on existing organization). Verify: `grep -Fn "joint satisfiability" skills/review-plan/SKILL.md` returns match.

- **AC3 — Cubic-iteration termination criteria in Stage 6 prose.** Document a stopping rule for post-merge cubic iterations in both `skills/build/SKILL.md` Stage 6 and `skills/fix/SKILL.md` Stage 6: "Cubic iterations terminate when: (a) cubic returns `{\"issues\": []}` (clean), OR (b) 5 iterations have completed with progressively narrower findings (diminishing-returns observable: each iteration surfaces fewer or lower-severity issues than the prior), OR (c) the remaining finding can only be addressed by spec amendment — escalate as a candidate via the active epic's v0.1.X candidates section, then accept the current state as documented-deferral." Prose lands at the cubic-iteration step in Stage 6 (currently absent from formal spec per epic L611). Word cost ≈ 5 lines per file. **Depends on E05.S4** for fix/SKILL.md headroom (fix is at 300/300 pre-E05.S4; +5 lines impossible without the off-ramp recovering ~60 lines).

- **AC4 — Plan-implementation drift framing in Stage 8 prose.** Add prose to the Status block prepend instruction in `skills/shared/stage-8-wrap-up.md` (post-E05.S4): "The Status block frames the plan as a Stage-3 snapshot. Implementation actuals may differ from the plan — e.g., post-merge cubic-fix iterations that modify the shipped code without re-editing the plan — and that drift is expected, not a defect. Downstream review tools (cubic and similar) should treat the plan as historical context, not authoritative spec — the Status block + first-line marker signals this intent." Word cost ≈ 3 lines added to the shared file. **Depends on E05.S4** for the shared file to exist; otherwise edit would go to build/fix SKILL.md (latter at cap).

- **AC5 — CHANGELOG `### Added` entry** documents the three process improvements with cross-references to surfacing E04 candidates (L597, L599, L611). Verify: entry mentions epic-reviewer AC mutual satisfiability, plan-implementation drift framing, cubic-iteration termination criteria — three distinct improvements, not bundled into one bullet.

- **AC6 — Self-validation via E05.S3 review-plan checks (post-S3 ship).** The plan for E05.S6 itself is reviewed by the post-E05.S3 `/roughly:review-plan` checks (including the new AC1–AC5 from E05.S3). Required outcome: PASS or NEEDS REVISION with documented carve-outs. This is the first "review-plan reviews its own AC additions" exercise — surfaces any false-positive cases from E05.S3's new checks (closes Risk 3 from this epic).

**Verification:**

- **Synthetic plan exercising the AC mutual satisfiability check (AC1 + AC2):** craft a plan with two ACs that overlap on the same step — one PASS variant (no mutual unsatisfiability), one NEEDS REVISION variant (mutual unsatisfiability per E04.S8 pattern). Dispatch `/roughly:review-plan` for the plan-level check; dispatch a synthetic epic-review for the epic-level check. Required outcomes per AC1/AC2.
- **Stage 6 cubic-termination prose (AC3):** inspect build + fix SKILL.md for the rule presence; no runtime exercise possible without a post-merge cubic-iteration scenario. Documented as such.
- **Stage 8 framing prose (AC4):** inspect `skills/shared/stage-8-wrap-up.md` for the new Status-block-framing instruction.
- **CHANGELOG entry inspection (AC5).**
- **CI dogfood:** S11b-2 happy-path unchanged.

**Dependencies on other E05 stories:** **E05.S4 must ship first** (Stage 6 + Stage 8 edits per AC3 + AC4 require the off-ramp to recover fix/SKILL.md headroom). **E05.S3 should ship before or in parallel** (provides the AC mutual satisfiability framework at the review-plan level; E05.S6's AC2 extends it; AC6 verification gate is degraded without S3).

**Out of scope:**

- Cubic-readable known-issues mechanism (per OQ7 Option A — deferred to v0.1.8 as mechanism design, not prose-only)
- Modifying the underlying 2-commit Stage 8 pattern (E04.S3 locked)
- Adding new agents or skills
- Modifying epic-reviewer's other evaluation dimensions beyond AC mutual satisfiability addition
- Lifting AC mutual satisfiability into a runtime check via verify-all.sh (review-only convention; runtime enforcement is out of scope and would expand surface significantly)
- Plan-implementation drift mechanism (option a from epic L599 — "build pipeline Stage 8 includes an explicit 'update plan artifact to reflect post-merge state' step" was the alternative; this story uses option (b) drift-tolerant-by-design per E04 epic recommendation)

---

## Open questions

PM-phase open questions and resolutions. Pre-locked decisions inherited from v0.1.6 (ADR-011 flags-as-public-API; S7 in-session maturity offers deferred; DI-001 deferred; 2-commit Stage 8 pattern; marker-at-source migration idiom; `*-plan.md` filename pre-flight signal) are not re-litigated.

1. **Release shape (small / medium / larger).** **Resolved: medium, 6 stories.** Both priority clusters (doc-writer hardening + review-plan codification) + off-ramp + ABORT HANDLING + reviewer-brief process bundle. CI-coverage cluster (negative-path + fix-side `--ci`), dogfood-self template-sync, and `/roughly:help` install-marker schema fix all deferred to v0.1.8 to keep scope focused on debt closure.

2. **Off-ramp placement (standalone vs bundled).** **Resolved: standalone refactor-only story (E05.S4).** Unblocks E05.S5 + E05.S6 Stage 6/Stage 8 ACs cleanly; couples better with the new ADR-012 pattern that needs its own context.

3. **AC3 cap-hardening placement (standalone vs cluster-bundled).** **Resolved: standalone micro-story (E05.S1).** One-line constant edit doesn't bundle cleanly with multi-edit clause refactor; clean blame trail.

4. **Negative-path CI + fix-side `--ci` (CI-coverage cluster).** **Resolved: defer both to v0.1.8.** v0.1.7 already runs to medium with the two priority clusters + off-ramp + process bundle; both candidates benefit from waiting until the off-ramp lands (fix-side `--ci` will need to touch fix/SKILL.md, which is binding until E05.S4 ships). Cleaner as a coherent v0.1.8 CI-coverage cluster.

5. **Dogfood-self template-sync mechanism.** **Resolved: defer to v0.1.8.** Immediate gap was patched manually 2026-05-14; systemic fix (recommended option (b) sync script) doesn't fit cleanly with v0.1.7 theme.

6. **`/roughly:help` install-marker schema fix.** **Resolved: defer to v0.1.8.** Output is cosmetically misleading but functionally correct; schema decision (option a / b / c per epic L577) more interesting once additional install markers accumulate.

7. **Process-observations bundle from E04.S8 + E04.S1.** **Resolved: Option A — bundle (a) AC mutual satisfiability + (b) plan-implementation drift framing + (d) cubic-iteration termination criteria as E05.S6 (three prose-only items); defer (c) cubic-readable known-issues mechanism to v0.1.8** (mechanism design, separate from prose-only process work).

8. **DI-001 (Stage 6 review depth investigation).** **Resolved: stays deferred.** No hypothesis surfaced signal during v0.1.6 execution. Default per the "investigations don't promote without signal" rule.

9. **Stage 6 review-fix cycles cap conversion-to-prompt** (E03.S10 deferral, evidence-gated). **Resolved: absorbed into E05.S6 AC3 (cubic-iteration termination criteria).** v0.1.6 dogfood data (S1's 6 cubic-fix iterations with diminishing returns) is the signal that prompted the more concrete "termination criteria" framing.

10. **C6 small-misc bundling.** **Resolved: fold into adjacent stories where they belong topically.** `docs/adr/` typo → E05.S2 (touches doc-writer.md); README invocation alignment → E05.S3 (CONTRIBUTING.md skill-authoring conventions); mkdir-p audit → E05.S4 (off-ramp touches Stage 3-adjacent prose); stronger output-mandatory wording → E05.S3 (review-plan skill body).

11. **Off-ramp scope (what to extract).** **Resolved: ABORT HANDLING + Stage 8 only.** Preamble + Stage 1 are extraction-eligible but stable (low churn); pulling them in inflates the off-ramp PR for marginal future-headroom gain. Defer those extractions until the next forcing-function story.

12. **Cap-hardening number (550 vs 600).** **Resolved: 600.** Going to 550 doesn't even cover current 557 state without trim; 600 gives ~5–43 word headroom for E05.S2's four word-cost additions to land at 595–600 projected.

**Carried for implementer discretion (not PM-blocking):**

- **OQ-extraction-pattern (E05.S4):** read-at-runtime vs copy-and-sync mechanism for the shared file. ADR-012 codifies the pattern chosen. AC2/AC3 require the line-count outcome regardless of mechanism — implementer picks.
- **OQ-AC5-trim-vs-second-bump (E05.S2):** if word count breaches 600 by >5 words after compensating savings, trim or bump-to-650? Lean: trim. Surface at S2 plan-review time.
- **OQ-S4-AC1-frontmatter (E05.S4):** shared files under `skills/shared/` — with or without YAML frontmatter. Either works; the AC requires the outcome, not the form.

---

## v0.1.8 candidates

Items deliberately out of v0.1.7 scope. Carry-forward from E04 epic still applies; additional items surfaced in v0.1.7 PM listed below. The list is unprioritized; pull from it when scoping v0.1.8.

**Carried forward from E04 (still applicable):**

- All E04 v0.1.7-candidate items not landed in v0.1.7 — see [E04 epic v0.1.7 candidates section](complete/E04-path-consolidation-and-process-codification.md#v017-candidates) for the canonical list.
- **CI-coverage cluster** (negative-path CI scenarios + fix-side `--ci` flag) — per OQ4 resolution; coherent v0.1.8 bundle.
- **Dogfood-self template-sync mechanism** (recommended option (b) sync script) — per OQ5 resolution.
- **`/roughly:help` install-marker schema fix** (recommended option (a)) — per OQ6 resolution.
- **Cubic-readable known-issues mechanism** for accepted-violations — per OQ7 resolution; mechanism design, not prose-only.
- **Other-agents multi-file failure-handling audit** — E04 v0.1.7 candidate, deferred without forcing function surfacing.
- **Single-source `PITFALLS_ORGANIZE_THRESHOLD` mechanism** — E04 v0.1.7 candidate, bidirectional sync comments holding for now.
- **`set -uo pipefail` audit of `.claude/hooks/verify-all.sh`** — no forcing function.
- **Preamble + Stage 1 extraction** to `skills/shared/` (additional off-ramp work per OQ11) — wait for next forcing function.

**New from v0.1.7 PM work:**

- **Risk 1 promotion: programmatic mechanism for runtime LLM template adherence.** If E05.S2 T2 synthetic test still fails despite the three-form anchoring in AC2 (MUST + code-fenced + self-check), v0.1.8 work: response-validation subagent that asserts output-shape post-emission, or programmatic template parser that re-formats free-form output to the locked template. Surface decision at v0.1.7 retrospective on T2 test result.
- **Risk 5 (E04) promotion: synthetic CI-test for doc-writer multi-file path.** If v0.1.7 also passes without real-dogfood multi-file invocations exercising the guard (no `.roughly/known-pitfalls.md` + `CLAUDE.md` simultaneous write), promote to synthetic CI-test story in v0.1.8 per the original E04 risk register opportunistic-close-or-promote rule. T2 synthetic re-run in E05.S2 does NOT count as real-dogfood exercise.
- **Risk 2 (E05) follow-through: shared-reference drift 30-day window assessment.** If E05.S4's drift check (AC5) accumulates false positives during v0.1.7 dogfood, v0.1.8 work: tighten the check's mechanic or add a per-skill carve-out.

---

## Sequencing

Order is by dependency, not cluster number. Stories #1–3 are mutually independent and can land in parallel as the early-window. Stories #4–6 depend on the early-window stories landing first.

| # | Story | Cluster | Depends on | Why this position |
|---|---|---|---|---|
| 1 | **E05.S1** — project-wide agent word cap revision 500 → 600 | C1 | None | Smallest blast radius (1-line constant edit + 3 small docs); anchor for S2. Land first to unblock S2 without coupling its review to a structural change. |
| 2 | **E05.S3** — Review-plan spec-quality gates (5 new ACs + skill-body polish) | C2 | None | Independent. Lands early so subsequent stories' `/roughly:review-plan` cycles inherit the 5 new checks at plan-review time — closes the gap where E04.S1/S2/S5/S6/S9's review-plan didn't catch the surfacing bugs. Also self-validates against E05.S2's plan + E05.S4's plan + E05.S6's plan (AC6). |
| 3 | **E05.S4** — Off-ramp refactor (ABORT HANDLING + Stage 8 extraction to `skills/shared/`) | C3 | None | Independent. Anchor for S5 + S6's Stage 6/Stage 8 ACs. Recovers ~60 lines in both build and fix SKILL.md, closing the 300/300 binding state. Lands in the early-window to unblock the post-window stories. |
| 4 | **E05.S2** — doc-writer multi-file failure-handling (AC amendment + 4-item completion) | C1 | S1 | S1 ships 500→600 cap; S2's word additions (~38–43 net) would breach the 500 cap. Can land in parallel with S3/S4 once S1 ships. T2 synthetic test PASS closes Risk 1. First-precedent cross-epic AC amendment per Risk 4 mitigation. |
| 5 | **E05.S5** — Stage 8 2-commit-window ABORT HANDLING entry | C3 | S4 | Trivial additive completeness; lands in the shared file created by S4. No CI/dogfood exercise possible (no human gate in the window); ships as documented completeness per Risk 5. |
| 6 | **E05.S6** — Reviewer-brief process improvements (epic AC mutual satisfiability + plan-implementation drift framing + cubic-termination criteria) | C4 | S4 (hard), S3 (soft) | Stage 6 + Stage 8 prose edits require S4's off-ramp to recover fix/SKILL.md headroom. AC mutual satisfiability extension benefits from S3's review-plan AC additions landing first (AC6 self-validation gate). Lands last as the closing codification pass. |

**Critical path:** S4 → S5 → S6. S4 unconditionally unblocks any fix-touching work. S1 → S2 is the parallel critical path on the doc-writer thread. **~3-4 sequential PRs minimum** if S1/S3/S4 are parallelized into the early window; **6 PRs sequential** if not.

**Parallelism notes (if multi-stream development is feasible):**

- Stories #1–3 (S1, S3, S4) are mutually independent. Can land in any order or in parallel.
- Story #4 (S2) only depends on S1; can land in parallel with S3 + S4 once S1 ships.
- Stories #5 (S5) and #6 (S6) only depend on S4 and can land in parallel post-S4. S6 also benefits from S3 shipping but doesn't hard-block on it.

---

## Definition of done

- [ ] **All 6 stories merged** (E05.S1 through E05.S6)
- [ ] **v0.1.7 tag pushed:** `git tag v0.1.7 && git push origin v0.1.7` (operator step — destructive write to remote tag namespace; explicit authorization required)
- [ ] **CHANGELOG entries** cover Added / Changed / Migration for each story under `## [0.1.7] — YYYY-MM-DD`
- [ ] **ROADMAP.md updated:** `**Current:**` v0.1.6 → v0.1.7; `**Updated:**` → release date; new v0.1.7 row added to release map between v0.1.6 and v0.2.0; new v0.1.7 detail section with epic pointer + v0.1.8 carry-forward summary
- [ ] **CI dogfood passing on `main`** post-refactor — S4 changes the build path; verify S11b-2 happy-path still completes within `--max-budget-usd 1.50`
- [ ] **ADR-012 merged** (S4); `CLAUDE.md` ADR enumeration updated; `docs/adrs/README.md` index updated
- [ ] **After every merge,** `wc -l skills/build/SKILL.md skills/fix/SKILL.md` recorded in PR description; final post-S4 values targeted at ≤240/240
- [ ] **`wc -w agents/doc-writer.md`** post-S2 recorded; targeted ≤600
- [ ] **Risk 1 (E05) assessment:** T2 synthetic test re-run post-E05.S2; PASS closes Risk 1, FAIL surfaces as v0.1.8 candidate (programmatic mechanism for runtime LLM template adherence)
- [ ] **Risk 2 (E05) assessment:** shared-reference drift check (S4 AC5) running clean on `main` for 30 days post-S4 merge; opportunistic close at v0.1.8 retrospective on zero false-positive evidence
- [ ] **Risk 3 (E04) assessment** — Stop hook drift false-positive 30-day window closes ~2026-06-19 (within v0.1.7 timeline); review false-positive log at v0.1.7 retrospective; zero false-positive accumulation closes Risk 3 (E04)
- [ ] **Risk 5 (E04) assessment** — if v0.1.7 also passes without real-dogfood multi-file invocations exercising the doc-writer guard, promote to synthetic CI-test story in v0.1.8 per the original E04 risk register opportunistic-close-or-promote rule; E05.S2 T2 synthetic re-run does NOT count as real-dogfood exercise
- [ ] **v0.1.8 candidates list reviewed** and prep next epic PM prompt
- [ ] **Plugin version bump:** `.claude-plugin/plugin.json` `version` field → `0.1.7`
- [ ] **CHANGELOG heading rename:** `## [Unreleased] — v0.1.7` → `## [0.1.7] — YYYY-MM-DD` at tag time
- [ ] **Audit `.roughly/workflow-upgrades` for retired-check markers before tag** (per E04 DoD precedent; check for any stale markers accumulated during v0.1.7 cycle)
