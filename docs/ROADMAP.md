# Roughly Roadmap

**Current:** v0.1.8 · **Updated:** 2026-06-10

## Thesis

Structure beats vibes. The pipeline's value is enforcement: gated stages, fresh subagents per task, mandatory plan and code review.

Primary user through v1.0: solo dev first, teams second. Team adoption is downstream of solo-dev credibility — a tech lead won't standardize on Roughly while it has known silent-failure modes. Solo trust and ergonomics through v0.2.x; team and governance after the core is airtight.

## Release map

| Release | Theme | Effort |
|---|---|---|
| v0.1.5 | Trust hardening + ergonomics + CI | 6-7 wk |
| v0.1.6 | Path consolidation + process codification | ~10 days |
| v0.1.7 | Doc-writer hardening + review-plan codification + structural off-ramp | ~6 days |
| v0.1.8 | Doc-writer all-fail anchoring + CI coverage + reviewer-brief codification | ~8 days |
| v0.1.9 | E06 codification close-out + consumer-project intake hardening | ~8-10 days |
| v0.1.10 | External issue-tracker intake (live fetch) | ~1-1.5 wk |
| v0.2.0 | Cost-aware pipeline (Haiku routing, plan format v2) | 4-5 wk |
| v0.3.0 | Monorepo support | 6-8 wk |
| v0.4.0 | Team governance | 4-6 wk |
| v0.4.x | Migration-code cleanup (opportunistic) | trivial |
| v1.0 | Stability commitment | mid-2027 |

## Sequencing notes

- **CI in v0.1.5, not v0.2.0.** Trust hardening without regression coverage is theater.
- **v0.1.5 bundles trust + ergonomics.** Original split was artificial.
- **v0.2.0 bundles cost work + plan format v2.** Both touch plan format. One migration, one ADR.
- **v0.3.0 stays at v0.3.0.** Monorepo is inferred-but-not-blocking. The worktree-by-epic workflow already handles runtime workspace inference, so v0.3.0 ships smaller than first scoped.
- **Cleanup is opportunistic.** Triggered by next unrelated touch of `upgrade/SKILL.md`, not its own release.

## Path to v1.0

1. Two consecutive minors without a silent-failure regression.
2. Self-test CI catching real regressions for ≥3 months.
3. ≥1 team adoption surviving a quarter without direct intervention.
4. ADR backbone unchanged for ≥6 months.
5. roughly.dev complete enough that a stranger gets the pipeline without reading SKILL.md.

## Docs cadence

Continuous from v0.1.5. Every release's DoD includes a docs update for user-visible changes. Floor for v0.1.5: landing page, pipeline overview, commands reference, setup walkthrough.

## Deferred investigations

Process and quality observations surfaced during execution but out of scope for the work that surfaced them are tracked in [docs/deferred-investigations.md](deferred-investigations.md). Distinct from this roadmap (which is committed work) — investigations are noticed-but-not-yet-evaluated. Pull from the catalog when scoping each release.

---

# Release scope

PM handoff: detail level sufficient for an epic-writing agent to expand into stories. Effort = wall-clock weeks part-time.

## v0.1.5 — Trust + ergonomics + CI

**Effort:** 6-7 wk · **Scope:** FROZEN. New items → v0.1.6.

### Trust hardening
1. **Plan-mode auto-detect/exit at Stage 1 of build/fix.** Without this, ADR-001 is unenforced. ✅ Done — landed in E03.S1.
2. **Finish stop-hook-v1 maturity check** integration into `/roughly:upgrade`. ✅ Done — landed in E03.S2.
3. **Retire test-verify-v1 and pitfalls-organized-v1.** ✅ Done — triggers folded into doc-writer's known-pitfalls write path (E03.S3).
4. **Pre-flight migration check in remaining 2 skills** (currently 6/9, upgrade excluded by design). ✅ Done — landed in E03.S4.
5. **Document Edit `replace_all` dual-semantic-token failure** in CONTRIBUTING.md. Prose-only. ✅ Done — landed in E03.S5.
6. **Plan-format version field.** Added now, read in v0.2.0. ✅ Done — landed in E03.S6.

### Ergonomics
7. **In-session maturity offers at Stage 1**, not just Stage 8 wrap-up. ↪ Deferred to v0.1.6 (see E03 epic v0.1.6 candidates).
8. **`/roughly:help` command.** 10th command. Structured overview of commands and pipeline state. ✅ Done — landed in E03.S8.
9. **Situation-specific abort prose** at every pipeline failure point. ✅ Done — landed in E03.S9.
10. **Retry-loop tuning.** Audit caps at Stages 5c (quality), 5c (questions), 6 (review-fix). Raise on cheap checks or replace hard escalation with prompt. ✅ Done — landed in E03.S10.

### CI
11. **Plugin self-test CI.** GitHub Actions running dogfood through scripted build/fix on push. Happy path minimum. **Architecturally novel** — plugin tests itself against the repo containing the plugin. Probably needs its own story. ✅ **Done — landed across E03.S11a (scaffolding), S11b-1 (CLI plumbing smoke test), and S11b-2 (happy-path build cycle).**

### Docs
12. ~~**roughly.dev v0.1.5.** Landing, pipeline overview, commands reference, setup walkthrough.~~ **Deferred to a separate repo/epic post-v0.1.5** (E03.S12.0 option (c), 2026-05-08). Aligns with [`docs/planning/README.md:84`](planning/README.md#L84) ("out of repo scope; tracked separately"). Long-term home: v1.0 criterion #5.

### Out of scope (→ v0.1.6 if surfaced)
- Plan format changes beyond the version field
- Setup flow changes
- New agents
- Cost optimization

---

## v0.1.6 — Path consolidation + process codification

**Effort:** ~10 days (medium release; 9 stories across 5 clusters) · **Status:** SHIPPED 2026-05-24.

Scope and per-story details: [docs/planning/epics/complete/E04-path-consolidation-and-process-codification.md](planning/epics/complete/E04-path-consolidation-and-process-codification.md). Headline outcomes — 9/9 stories merged across PRs #39–#47; post-implementation audit (PR #48) reported 71/75 ACs MET with 0 regressions; Risk 1 (plan-path migration dual-state) + Risk 6 (cubic-gate format rejection) closed; Risks 3/4/5 in their by-design open windows. Two `.roughly/known-pitfalls.md` entries added per story average; line-cap budget contract held across all 9 stories (final fix/SKILL.md at 300/300 — the off-ramp becomes binding for any v0.1.7 fix-touching story).

### Out of scope (→ v0.1.7)

- Doc-writer failure-handling cluster (5 items from E04.S8 — recommended as a single v0.1.7 story; AC3 cap-revision is the structural unblock)
- Review-plan-as-spec-quality-gate cluster (5 items from E04.S1/S2/S5/S6/S9 — recommended as a single v0.1.7 story)
- E04.S3 ABORT HANDLING gap for Stage 8's 2-commit window (requires off-ramp invocation due to fix/SKILL.md at-cap)
- Full v0.1.7 candidates list: see [E04 epic v0.1.7 candidates section](planning/epics/complete/E04-path-consolidation-and-process-codification.md#v017-candidates).

---

## v0.1.7 — Doc-writer hardening + review-plan codification + structural off-ramp

**Effort:** ~6 days (medium release; 7 stories across 4 clusters) · **Status:** SHIPPED 2026-06-01.

Scope and per-story details: [docs/planning/epics/complete/E05-doc-writer-hardening-and-spec-quality-gates.md](planning/epics/complete/E05-doc-writer-hardening-and-spec-quality-gates.md). Headline outcomes — 7/7 stories merged across PRs #50–#56; post-implementation audit (PR #57) reported 43/45 ACs MET (2 PARTIAL backfilled in audit cycle; 0 NOT MET; 0 regressions); Risks 3/4/5 closed; Risk 1 partial-close (T2 PARTIAL PASS surfaces the all-fail template misfire as v0.1.8 substantive work); Risk 2 (off-ramp shared-reference drift) in by-design 30-day dogfood window (closes ~2026-06-27 on zero false-positive accumulation). Line-cap budget contract closed the v0.1.6 binding state — fix/SKILL.md recovered from 300/300 to 269/300; doc-writer.md compliant at 649/650 post-cap-revision. ADR-012 codifies the new runtime-shared-procedural-references pattern (skills/shared/abort-handling.md + skills/shared/stage-8-wrap-up.md). CONTRIBUTING.md gains `## Cross-epic AC amendments` convention (codified in S3, first-applied in S2).

### Out of scope (→ v0.1.8)

- **Risk 1 substantive: AC4 all-fail-branch anchoring tightening + T2 re-run** (T2 ran during E05 audit; PARTIAL PASS revealed all-fail template misfire — LLM regresses to partial-success container with `(none)` placeholder for the successful-paths slot; three concrete tightening hypotheses in audit report)
- **agents/doc-writer.md cap relief** (now at 649/650 hard cap; any v0.1.8 doc-writer-touching story needs relief OR explicit carve-out)
- **.claude/hooks/verify-all.sh cap relief** (now at 148/150 soft cap; next drift check addition needs the same off-ramp pattern E05.S4 invoked for build/fix)
- **CI-coverage cluster** — negative-path CI + fix-side `--ci` (carried from E05 OQ4 resolution; unblocked now that fix/SKILL.md headroom is restored)
- **Full v0.1.8 candidates list**: see CHANGELOG `## [0.1.7]` section + [E05 epic](planning/epics/complete/E05-doc-writer-hardening-and-spec-quality-gates.md) + [E05 audit report](planning/epics/complete/E05-doc-writer-hardening-and-spec-quality-gates-audit.md).

---

## v0.1.8 — Doc-writer all-fail anchoring + CI coverage + reviewer-brief codification

**Effort:** ~8 days (medium release; 7 stories across 3 clusters) · **Status:** SHIPPED 2026-06-10.

Scope and per-story details: [docs/planning/epics/complete/E06-anchoring-closure-and-ci-coverage.md](planning/epics/complete/E06-anchoring-closure-and-ci-coverage.md). Headline outcomes — 7/7 stories merged; post-implementation audit (PR #65) reported 35/37 ACs MET (2 PARTIAL — both evidence-artifact gaps, not functional defects; 0 NOT MET; 0 regressions). Risk 1 (AC4 all-fail anchoring) CLOSED at prose-level by E06.S1 — both T2 scenarios FULL PASS against source-tree state; runtime-cache confirmation deferred to v0.1.8 retrospective. Risk 2 (cap-relief trim coverage degradation) CLOSED via 4-coverage-group preservation enumeration. Risk 4 (cross-epic re-amendment trail readability) CLOSED via preserve-hops convention extension in CONTRIBUTING.md. Risk 3 (CI fixture harness fragility) OPEN with watch list — 3-consecutive-green-runs gate restarted against post-#65 main; AC2 plan-revision determinism under per-fixture validation. New artifacts: **ADR-013** (build `--ci` runs review-plan — reverses E03.S11b-2's skip-and-synthesize; unifies build/fix `--ci`; restores ADR-001 enforcement on the CI path). CONTRIBUTING.md gains `## AC authoring conventions` section (E06.S4 — `verbatim:` / `form:` markers + marker-intent sub-carve-out) and `## Audit conventions` section (E06.S7 — audit-table-in-PR-body convention). Line-cap state preserved across all 7 stories — agents/doc-writer.md at 647/650 (net −2 via cap-relief trim); skills/build/SKILL.md 270/300; skills/fix/SKILL.md 275/300; verify-all.sh unchanged at 148/150 (off-ramp prepared, not invoked). Cumulative intra-epic AC deviation catalog: 9 instances across all 7 stories spanning 6 distinct shapes — comprehensive enough to fully scope the v0.1.9 codifier story.

### Out of scope (→ v0.1.9)

- **Intra-epic AC amendment convention codifier** (back-annotation form + 6-shape catalog from E06 — must-do for v0.1.9 per E06 audit's main systemic finding).
- **Verdict persistent-artifact convention** (E05.S5 candidate #6 raised to v0.1.9 must-do per E06 audit — three same-shape evidence gaps in E06 [S1.AC3 T2 transcripts; S7.AC3 review-plan verdict block; S5.AC5 self-attestation caveat] all rooted in attestation-vs-artifact gap).
- **ADR-013 unification follow-ups** — decide whether to port the build-side NEEDS REVISION recovery loop to fix `--ci` (full unification) or codify the asymmetry as intentional. Fix-side negative-path scenarios (Stage 5c abort + NEEDS REVISION recovery) also unblocked.
- **`--ci` "exits non-zero" aspirational-language reframing** — `claude -p` cannot set process exit code on model-level aborts; both build + fix `--ci` contracts need either marker-primary reframing or a marker→exit wrapper.
- **Risk 1 runtime-cache confirmation** — runtime-level T2 re-run against installed plugin cache (not source tree). Promoted from v0.1.7 retrospective.
- ~~**`.roughly/known-pitfalls.md` organization sweep**~~ **RESOLVED (#74):** the advisory is a whole-file `wc -l` count (domain-grouping can't reduce it) on an append-only corpus; threshold recalibrated 80→300 rather than deleting real content.
- **Install-marker producer generalization** — apply E06.S6 write-on-install + back-fill pattern to other always-installed components (formatter PostToolUse hook, settings entries beyond hook registrations).
- **Full v0.1.9 candidates list**: see CHANGELOG `## [0.1.8]` section + [E06 epic](planning/epics/complete/E06-anchoring-closure-and-ci-coverage.md) `## v0.1.9 candidates` section + [E06 audit report](planning/epics/complete/E06-anchoring-closure-and-ci-coverage-audit.md).

---

## v0.1.9 — E06 codification close-out + consumer-project intake hardening

**Effort:** ~8-10 days (medium release) · **Status:** SCOPING (draft — not yet frozen; Cluster B intake items PROPOSED pending confirmation).

Two themes. (1) Close E06's systemic findings — the codification carry-forward above. (2) Harden intake and escalation for consumer projects that manage stories in a SaaS PM tool (Linear / Jira / Shortcut) instead of local epic files — surfaced running `/roughly:setup` on a real external-PM project. Intake-item claims are grounded against build/fix/setup/agents at v0.1.8, cited inline.

### Cluster A — E06 codification carry-forward

The seven priorities in the v0.1.8 "Out of scope (→ v0.1.9)" list above. Two are must-do per the E06 audit: the **intra-epic AC amendment convention codifier** and the **verdict persistent-artifact convention**. The verdict-artifact item overlaps Cluster B's B1 (both answer "where does a deferred finding/verdict get persisted") — scope them together.

### Cluster B — Consumer-project intake hardening (new)

Prioritized by certainty × readiness, not raw impact. B1 is the cheap, high-certainty bug fix; B3 is the strategically most important ("the main gap") but is spike-first — a new capability blocked on MCP auth.

**B1 — De-dogfood and redirect the Stage 6 spec-revision-candidate escalation** *(must-do; prose fix)*. Grounded: `skills/build/SKILL.md` L205/L207 and `skills/fix/SKILL.md` L212/L214 instruct the orchestrator to append the candidate to "the active epic's v0.1.X candidates section" / "the epic file" — a target that exists in no project without local epic files. This is already broken for **every** consumer project, not just external-PM ones; the "v0.1.X candidates" vocabulary is Roughly's own dogfooding leaking into consumer runtime prose. Fix: (a) strip the epic-file / "v0.1.X candidates" language from runtime prose; (b) redirect to a **tool-neutral target** defaulting to a local `.roughly/spec-candidates.md` ledger (always works, no MCP dependency; composes with the `.roughly/` artifact pattern from ADR-014 gate-log and ADR-015 verify-rules); (c) optional "also post a comment to the source issue" when an issue-tracker is configured (see B3); (d) projects that DO use epic files (Roughly itself) point the target at their epic via config, preserving dogfood continuity. Extract the duplicated build/fix escalation prose to `skills/shared/spec-candidate-escalation.md` per ADR-012 — one fix, both pipelines, frees line budget (build 270/300, fix 275/300). Subsumes Cluster A's verdict-artifact must-do.

**B2 — Epic-vs-story granularity guard** *(should-do; low-effort)*. Grounded: build/fix process a single story's scope; no epic→story decomposition loop exists anywhere (build L25, fix L25-30). Feeding an epic ID today silently treats the whole epic as one monolithic feature. Fix: Stage 1 detects epic-shaped input (an epic ID/URL, or a file enumerating multiple child stories), warns, and asks the human to narrow to one story or confirm monolithic treatment. No decomposition loop — deferred (below). Codify the rule-of-thumb in `/roughly:help` + docs: feed story IDs, not epic IDs.

**B3 — External issue-tracker intake: spike + tool-neutral scaffolding** *(v0.1.9; live fetch → v0.1.10)*. Grounded: Stage 1 resolves local files + inline text only — no ID/URL→content path (build L25, fix L25-30); discovery/investigator agents carry only `Glob, Grep, Read, Bash`, so the fetch must happen at **orchestrator** level (Stage 1) and pass fetched content to the agents, not inside the subagents; setup has no PM-tool/MCP detection. This is "the main gap" for external-PM projects. v0.1.9 builds everything that does **not** need a live MCP, so the plumbing is functional the moment v0.1.9 ships; the live fetch follows in v0.1.10.

- **Fetch-contract survey + ADR.** Survey the fetch contract across configured issue-tracker MCPs (Shortcut, Linear, Jira); ADR the **tool-agnostic** intake-resolution decision (new ADR ≥019). Roughly ships the mechanism + config, never a specific tool (mirrors the verify-rules "ship format + engine, not opinions" decision).
- **Config surface — setup is the target step for _configuration_, not validation.** Setup runs once; MCP auth state drifts independently, so setup captures intent and the pipeline checks liveness at use. Three touch-points: **STEP 4** adds an issue-source declaration question (Linear / Jira / Shortcut / GitHub Issues / none) with best-effort MCP detection (advisory — record the declaration even if the connector isn't authorized yet; never block setup); a new **5f** writes the intake block into `.roughly/config`; **STEP 6** re-offers it to existing installs as a versioned `issue-intake-v1` maturity check (also surfaced via build/fix Stage 8, like `stop-hook-v1` / `investigator-v1`). Config lives in `.roughly/`, not CLAUDE.md — avoids the governed/clobbered-CLAUDE.md pitfall and matches gate-log / verify-rules placement. Split: **operational toggles** (intake source, B1 escalation target, ADR-014 instrumentation opt-in) unify in `.roughly/config`; **content/artifacts** (known-pitfalls.md, verify-rules.md, spec-candidates.md, gate-log.jsonl) stay separate files. Intake block fields: source name, MCP tool/server id, ID/URL match patterns, field mapping (title / description / acceptance-criteria), fallback behavior.
- **Stage-1 classifier + fallback (MCP-independent).** Intake resolution order: (a) path to an existing local file → read it (today's behavior); (b) matches the configured issue-source pattern → resolve via MCP [live fetch = v0.1.10]; (c) else → inline description (today's behavior). No config → branch (b) is skipped and behavior is exactly today's (purely additive, degrades cleanly). In v0.1.9 branch (b) recognizes the external ref and routes to the graceful inline-fallback prompt; so after v0.1.9 the classifier, config, and fallback all work — only the live fetch is pending.
- **Exit criterion:** PM-tool MCP auth resolved and a working fetch tool confirmed (non-interactive sessions cannot run OAuth). This gates v0.1.10.

### Out of scope for v0.1.9 (sequenced, not shelved)

- **Live external-issue fetch** — the actual MCP fetch call + field mapping + availability validation. Not deferred indefinitely: it lands in **v0.1.10** (below), depending on B3's scaffolding + the MCP-auth confirmation.
- **review-epic / audit-epic external-fetch wiring.** Both are strictly file-based (`$ARGUMENTS` = epic file path; audit-epic maps stories→files via `git log --grep` + `.roughly/plans/`). Accepting a Shortcut/Linear epic needs its own fetch layer — v0.1.10 stretch or later; not required for build/fix intake.
- **Real epic→story decomposition loop.** Depends on live intake + the epic-fetch wiring above.

### Reconciliation / boundaries

- **Scheduler-agnostic holds:** ID/URL→content fetch is in-session intake, not scheduling.
- **Human-gate unchanged:** B1 relocates *where a deferred finding is written*, not the human's role; B2 adds a human prompt.
- **Tool-agnostic (hard):** never hardcode Shortcut/Linear/Jira; ship the intake mechanism + a project-declared issue-source config.
- **MCP auth is a hard external dependency for B3.** Non-interactive sessions cannot run OAuth; the PM-tool MCP must be authorized (claude.ai connector settings, or `claude mcp` / `/mcp` interactively) before B3's fetch is testable.
- **`.roughly/` artifact consistency:** `.roughly/spec-candidates.md` (B1) and any B3 intake config live under `.roughly/`, consistent with gate-log (ADR-014) and verify-rules (ADR-015).
- **New ADRs:** B1 escalation-target → **ADR-019 (shipped)**; B3 intake-resolution → new ADR (spike output), next free number **≥ADR-021**. The differential-gate spec set claims **ADR-014, 016, 017, 018, 020** (Spec 2 was renumbered 015→020 after ADR-015 shipped as the #66 gate protocol; ADR-019 is escalation). Fold in the standing ADR-009 / ADR-010 stale-reference cleanup while renumbering.
- **Setup budget:** setup is at 289/300 lines. B3's STEP 4 question is one line, but the 5f write logic + `.roughly/config` schema go in `skills/setup/templates/` + a shared reference (ADR-012), not inline.

---

## v0.1.10 — External issue-tracker intake (live fetch)

**Effort:** ~1-1.5 wk (small release) · **Status:** SCOPING (PROPOSED) · **Depends on:** v0.1.9 B3 scaffolding + PM-tool MCP auth confirmed.

Lights up the live fetch on top of v0.1.9's tool-neutral scaffolding, so external-PM projects (Linear / Jira / Shortcut) get real ID/URL→story intake. **Sequencing note:** placed before v0.2.0 by explicit priority — this pushes the cost-aware release out by ~this release's duration. Justified as dogfood-driven ergonomics for existing-project adoption (Nick's own external-PM setup surfaced it), and it fits the roadmap's "solo trust + ergonomics through v0.2.x" window. Boundaries from B3 carry forward: tool-agnostic (config-driven, never hardcode a tracker), scheduler-agnostic (in-session intake), human-gate preserved (fallback keeps a human in the loop), Roughly never runs OAuth.

1. **Live MCP fetch at Stage 1.** Resolution branch (b) from B3 now calls the configured issue-source MCP, applies the field mapping (title / description / acceptance-criteria), and hands the resulting story content to discovery (build S2) / investigator (fix S2) — fetch at the orchestrator, not inside the subagents.
2. **Lazy availability validation — the contract.** Validate *only* when Stage 1 classifies the input as an external reference (local-file and inline paths never touch the MCP or pay any cost). Validate by attempting the actual fetch — one call, no separate health-check probe. Treat tool-absent / not-found / auth-error identically: fall back to the inline-description prompt with a directional message ("<tracker> MCP unavailable or unauthorized — paste the story's title/description/ACs, or authorize the connector and re-run"). Resolve once per run (Stages 2+ never re-fetch); no cross-run caching of availability (auth can lapse between runs; the check is free because it is the fetch you needed anyway).
3. **`/roughly:upgrade` handling.** Pre-v0.1.10 installs gain the intake config via the `issue-intake-v1` maturity re-offer (STEP 6 / Stage 8) or an upgrade step; strictly additive.
4. **Docs.** Intake setup walkthrough; "feed story IDs, not epic IDs" (shared with B2); supported-tracker notes and the field-mapping format.
5. **Dogfood gate.** Validate end-to-end against at least one live tracker (Nick's project) once auth resolves — no promotion of the fetch path on an unauthorized connector.

### Out of scope

- review-epic / audit-epic external-fetch wiring (unless cheap to fold in) — see v0.1.9 deferred list.
- Epic→story decomposition loop.
- Any non-issue-tracker MCP source.

---

## v0.2.0 — Cost-aware pipeline

**Effort:** 4-5 wk · **Depends on:** v0.1.5 (CI before format changes).

1. **Complexity flag in plan format.** `Task N (Complexity: simple|standard|complex)`. Plan template + plan-reviewer validation.
2. **Haiku routing for simple tasks.** Sonnet default; Opus stays exclusive to epic-reviewer (ADR-008).
3. **Plan format v2.** Activate the v0.1.5 version field. v2 = complexity flag + any small wins surfaced during v0.1.5.
4. **ADR-009.** Complexity flag, routing rules, plan format v2.
5. **Pre-compaction trim.** Audit Stages 1-4 burn (~20-40K). Target 5-10K recovery via tighter compaction lists.
6. **`/roughly:upgrade` migration step** for plan format v1 → v2.
7. **roughly.dev v0.2.0.** Cost model page; updated commands reference; ADR-009 published.

### Out of scope
- Monorepo (v0.3.0)
- Per-field CLAUDE.md merge (v0.3.0)
- Governance (v0.4.0)

---

## v0.3.0 — Monorepo support

**Effort:** 6-8 wk · **Depends on:** v0.2.0.

Targets Duff, DGF, HuntReady. Today's setup misclassifies them and generates one CLAUDE.md for everything.

1. **Detection in setup.** Trigger on (a) workspace manifest (`pnpm-workspace.yaml`, `lerna.json`, `nx.json`, `turbo.json`, `rush.json`, `Cargo.toml [workspace]`, `go.work`) or (b) ≥2 distinct stack markers at depth ≥1 (`package.json`, `Cargo.toml`, `Package.swift`, `pyproject.toml`, `setup.py`, `go.mod`, `Gemfile`, `composer.json`, `mix.exs`). Root marker becomes "root workspace" if present; doesn't count toward (b).
2. **Setup prompt on detection.** Three options: monorepo (per-workspace setup), single project (today's behavior), edit workspace list.
3. **Hierarchical CLAUDE.md.** Root for shared conventions; workspace for overrides.
4. **CLAUDE.md format restructure.** YAML frontmatter for merged fields (`build_command`, `test_command`, `type_check`, `lint`, `commit_convention`, `formatter`, `architecture`); prose for non-merged (pitfalls, architecture notes, domain). ADR-010.
5. **Field-level merge.** Workspace-defined fields fully replace root for that field; undefined fields inherit.
6. **`/roughly:upgrade` migration** for CLAUDE.md format. Auto-migrate flat → frontmatter+prose; monorepo users re-run setup to opt in.
7. **Cwd-based workspace inference at Stage 1.** Cwd inside a workspace → use that workspace. Cwd at root → ask or default to root-only. Cross-workspace features get a "specify workspaces" affordance, not deep optimization.
8. **Stop hook workspace awareness** for agent-preamble drift check.
9. **roughly.dev v0.3.0.** Monorepo guide; CLAUDE.md format reference; per-workspace setup walkthrough; ADR-010.

### Out of scope
- Per-field merge in non-monorepo enrich (v0.4.0; that's the team-shared case)
- Cross-workspace feature optimization (until real usage demands it)
- Governance (v0.4.0)

### Resolve before implementation
- **False-positive handling** for vendored libs / example apps with their own stack markers. Probably the "edit workspace list" option; exercise against real repos.
- **HuntReady's MCP server: peer or sub-component?** Match Nick's mental model.

---

## v0.4.0 — Team governance

**Effort:** 4-6 wk · **Depends on:** v0.3.0.

1. **Per-field merge in non-monorepo enrich.** Currently all-or-nothing. Reuses v0.3.0 merge machinery.
2. **Fallback context source.** `.roughly/commands.md` for teams whose CLAUDE.md is governed externally. Skills read as secondary source.
3. **Governed CLAUDE.md mode.** Setup option: "CLAUDE.md is managed externally." Roughly writes only to `.roughly/`.
4. **Upgrade-available notifications.** GitHub release check on `/roughly:setup` and `/roughly:build`. Cached, opt-out.
5. **roughly.dev v0.4.0.** Team adoption guide; governed mode walkthrough; notification config.

### Out of scope
- Telemetry / usage analytics
- Multi-user permission models
- Anything requiring a server component

---

## v0.4.x — Cleanup (opportunistic)

Triggered by next unrelated touch of `upgrade/SKILL.md`.

1. Remove pre-flight migration checks from 9 skills.
2. Drop v0.1.2 + v0.1.4 migration steps from `upgrade/SKILL.md`.
3. Prune Stop hook legacy-`.ruckus/` detection.
4. Decide: keep CHANGELOG `### Migration` convention or move to CONTRIBUTING.md.

---

## v1.0

Stability commitment. Ships when the five criteria above are met.

---

## Deferred

Surfaced during planning, consciously not on the roadmap:

- **Maturity model rework beyond file count.** Revisit if real-world misclassification surfaces post-v0.3.0.
- **Edit `replace_all` code-level defense.** Prose-only in v0.1.5; code defense waits for a second occurrence.
- **`docs/planning/**` gitignore policy.** Unresolved; default gitignored.
- **Stop hook enforcing mode (exit-1).** Breaking change for contributors. No scheduled release.
- **Telemetry — egress/server only.** Egress/server telemetry and usage analytics remain deferred — trust + complexity cost too high at current scale. **Re-scoped 2026-06-28 (ADR-014):** local-only, opt-in, in-repo decision logging is now permitted, bounded by ADR-014's conditions (off by default; log artifacts gitignored by default; no network egress; no server component; fail-open writes). The absolute claim "Roughly never transmits any data off your machine" stays literally true. See [docs/adrs/ADR-014-local-only-gate-instrumentation.md](adrs/ADR-014-local-only-gate-instrumentation.md).
