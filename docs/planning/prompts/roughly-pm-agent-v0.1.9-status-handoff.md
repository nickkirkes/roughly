# v0.1.9 Status & Scoping Handoff — for the v0.1.9 planning agent

> **Naming:** The maintainer refers to this release as "v1.9.0"; the repo (ROADMAP, plugin.json, issue titles, ADRs) uses **`v0.1.9`**. This document uses `v0.1.9` to stay consistent with the codebase the planning agent will read. They are the same release.

> **Purpose:** Hand a fresh PM/planning agent an accurate, grounded picture of what v0.1.9 has shipped, what remains in its declared scope, what gates the release tag, and a recommendation — so it can finalize scope and write the next epic prompt. All claims below were verified against `main` (tip `43e1e48`), GitHub issues (open + closed), and the codebase on 2026‑07‑29.

---

## 1. Snapshot

- **Branch/PR state:** All work merged to `main`. No open issues. Two PRs delivered the recent bundle: **PR #90** (issues #81–#87, the CONTRIBUTING-conventions bundle) and **PR #91** (#89, Stage‑6 OQ enforcement). #80 shipped earlier via **PR #88**.
- **ROADMAP status line for v0.1.9:** *"SCOPING (draft — not yet frozen; Cluster B intake items PROPOSED pending confirmation)."* → Scope was never frozen; Cluster B (intake hardening) is an open PM decision, not committed work.
- **Declared v0.1.9 theme (ROADMAP):** "E06 codification close-out + consumer-project intake hardening + obsolete-`ruckus`-checks removal." Three clusters: **A** (E06 codification), **B** (consumer-project intake hardening), **C** (ruckus cleanup).

---

## 2. ✅ SHIPPED (merged to `main`, issues closed)

### Cluster A — E06 codification carry-forward (CONTRIBUTING micro-conventions bundle)
| # | Convention | Priority | PR |
|---|-----------|----------|----|
| #81 | `"verified"`-tag provenance discipline (observed-fact vs inferred-mechanism) | HIGH | #90 |
| #82 | CI assertion authoring — structural **+ behavioral** (E06.S2 F6 pattern) | should-do | #90 |
| #83 | Spec-example command validation at plan-review | should-do | #90 |
| #84 | Mirror-verbatim + negative-grep self-test | should-do | #90 |
| #85 | CI job-key naming (never rename in-place) | nice-to-have | #90 |
| #86 | OQ-resolution-annotation-in-epic convention | nice-to-have | #90 |

Delivered across `CONTRIBUTING.md` (new `## CI conventions` and `## Epic Open Question resolution` sections; extensions to `## AC authoring conventions`, `## Audit conventions`), `.roughly/known-pitfalls.md`, and `skills/review-plan/SKILL.md` (two new `## Completeness` checks for #83/#84).

### Cluster A — verdict-artifact / escalation must-do
- **#72** — de-dogfooded the Stage 6 spec-revision-candidate escalation target → **ADR-019** + `skills/shared/spec-candidate-escalation.md` + default `.roughly/spec-candidates.md` ledger with per-project CLAUDE.md override. The ROADMAP notes B1 **subsumes** Cluster A's "verdict persistent-artifact convention" must-do. Treat that must-do as **satisfied**.

### Cluster C — obsolete ruckus cleanup
- **#80** (PR #88) — removed pre-flight ruckus checks, drift detector, v0.1.4 migration engine; synced CONTRIBUTING worked-examples + refactored 2 known-pitfalls entries to synthetic examples.
- **#87** (PR #90) — known-pitfalls navigability reorg (rescoped: #74 already raised `PITFALLS_ORGANIZE_THRESHOLD` 80→300; #80 did the entry refactors). Delivered: moved 2 misfiled entries to correct sections + hardened 4 line-number citations into `known-pitfalls.md` to drift-proof `§ "section"` topic-form (ADR-009 ×2, CONTRIBUTING, review-plan). **Option-A** decision folded in the two already-broken live `L86` cites.

### Bonus follow-up (filed mid-cycle)
- **#89** (PR #91) — **enforcement** of #86: added `agents/code-reviewer.md` Process **step 8** (conditional, project-agnostic; flags Critical when a diff resolves an epic OQ but the epic's `## Open questions` section isn't annotated). Both build & fix inherit it via `/roughly:review` (DRY). Also broadened the code-reviewer `## Rules` bullet to accept CONTRIBUTING.md-documented conventions (was CLAUDE.md-only).

### Related hardening already merged (context; some pre-date v0.1.9)
#66 gate protocol + local-commits boundary · #67 ADR-012 shared-Read path · #68/#75 verify-all drift-report fallback + sync check · #73 `--ci` marker-primary reword · #74 known-pitfalls organize.

---

## 3. ⚠️ NOT SHIPPED — in the v0.1.9 ROADMAP scope, no ticket, absent from code

Each verified absent on `main` (2026‑07‑29). None has a GitHub issue.

### 3a. Cluster A codifier — intra-epic (build-time) AC amendment convention
- **What:** A CONTRIBUTING convention for amending/back-annotating an AC's text **within the same epic** during a build. Distinct from the shipped `## Cross-epic AC amendments` (that's *cross*-epic). Source: E06 v0.1.9 candidates **#3** ("Epic AC verbatim-text back-annotation form") + **#4** ("Intra-epic build-time AC amendment convention").
- **Why it's live:** ROADMAP Cluster A calls the "intra-epic AC amendment convention codifier" a **must-do per the E06 audit**. E06 saw **four** intra-epic AC-text post-merge handling instances (E06.S1.AC1(a), E06.S4.AC1, E06.S2.AC1, plus E06.S5 W1/W2).
- **Verified:** `CONTRIBUTING.md` contains only `## Cross-epic AC amendments` (L87); no intra-epic amendment convention.
- **Nature:** Governs **Roughly's own** epic-authoring hygiene (dogfooding-internal), not consumer-facing. Lower real urgency than the "must-do" label implies, but it *was* the parent "codifier" story the #81–#86 bundle was meant to be a sub-story of.
- **Note:** E06.S5 PM triage suggested a "codifier + 4 first applications" single-story shape (back-apply to E06.S1.AC1(a), E06.S4.AC1, and the E06.S5 W1/W2 amendments). See E06 epic candidates block "New from E06.S1 cubic-iteration epic-deviation work."

### 3b. B2 — epic-vs-story granularity guard  ← recommended cheap win
- **What:** Stage 1 detects epic-shaped input (an epic ID/URL, or a file enumerating multiple child stories), warns, and asks the human to narrow to one story or confirm monolithic treatment. Codify "feed story IDs, not epic IDs" in `/roughly:help` + docs. **No** decomposition loop (that needs live intake).
- **Why it's live:** build/fix process a single story's scope; feeding an epic ID today **silently** treats the whole epic as one feature (grounded: build L25, fix L25–30). Consumer-facing correctness gap.
- **Verified:** no epic-shaped-input guard in `skills/build/SKILL.md` / `skills/fix/SKILL.md`.
- **Priority:** should-do, **low-effort**, self-contained, no external dependency. Best v0.1.9 add.

### 3c. B3 — external issue-tracker intake: spike + tool-neutral scaffolding  ← recommend → v0.1.10
- **What (v0.1.9 portion):** the MCP-**independent** plumbing — (1) fetch-contract survey across Linear/Jira/Shortcut + a **new ADR** (tool-agnostic intake resolution); (2) setup config surface (STEP 4 issue-source question w/ best-effort MCP detection; new 5f writes an intake block to `.roughly/config`; STEP 6 re-offers as `issue-intake-v1` maturity check); (3) Stage-1 classifier + graceful inline fallback (recognizes external refs, routes to fallback; **live fetch deferred**).
- **Why it's live:** Stage 1 resolves only local files + inline text — no ID/URL→content path (build L25, fix L25–30); setup has no PM-tool detection. The ROADMAP calls this **"the main gap"** for external-PM projects.
- **Verified:** no intake config in `skills/setup/SKILL.md`; no `.roughly/config`; no ADR ≥ 021.
- **Hard dependency:** the exit criterion (working fetch tool confirmed) needs **PM-tool MCP auth**, which requires interactive OAuth — **not doable in non-interactive sessions**. Live fetch is **already scoped to v0.1.10** ("External issue-tracker intake (live fetch)").
- **Recommendation:** move B3 **wholesale to v0.1.10** so its scaffolding lands adjacent to the live fetch it enables, rather than splitting a spike across two releases.

---

## 4. 🔒 RELEASE-GATING DoD — must be assessed at v0.1.9 tag time (not new features)

Five inherited risk-windows the ROADMAP requires closing or explicitly carrying at tag. All are OBSERVATION/evidence items. The planning agent (or maintainer) must assess each and record CLOSE-vs-CARRY in the CHANGELOG at tag:

1. **E04 Risk 3** — stop-hook drift 30-day window (opened 2026‑05‑20 @ E04.S5; closed ~2026‑06‑19). Zero false positives on `main` → CLOSE; else promote mitigation to v0.1.10.
2. **E05 Risk 2** — off-ramp shared-reference (Check 8) drift 30-day window (opened 2026‑05‑28 @ E05.S4; closed ~2026‑06‑27). Zero false positives → CLOSE; else tighten Check 8 or add per-skill carve-out → v0.1.10.
3. **E05 Risk 1** — runtime-level doc-writer T2 confirmation (prose-level closed @ E06.S1; runtime-cache-layer confirmation pending a real multi-file dogfood in another project). Regression on the 0-succeeded case → promote programmatic-mechanism story to v0.1.10 must-do.
4. **E06 Risk 3** — 3-consecutive-green dogfood runs on post-#65 `main`. Counter **resets on every `main` change touching the workflow/inputs** — reset repeatedly across #66–#91. **Very likely OPEN**; assess current consecutive-green count; if ≥3 CLOSE, else carry to v0.1.10 with state documented. ⚠️ The end-to-end dogfood is **paid + label-gated** (`ci:dogfood`), so this needs deliberate runs.
5. **E04 Risk 5** — real-dogfood multi-file exercise of doc-writer. If no natural real-dogfood invocation observed → promote to v0.1.10 as a synthetic CI-test story (E06.S1 T2 synthetic re-run does **not** count).

---

## 5. 💡 Optional / deferred investigation

- **DI-001** (`docs/deferred-investigations.md`) — Stage 6 reviewers catch a minority of what post-merge cubic finds; the fix direction is surfacing `known-pitfalls.md` patterns into the three agent briefs. **#89 did this for one pitfall** (OQ annotation → code-reviewer step 8). A systematic pass (bake pitfall patterns into all three Stage-6 agent briefs) is a real **trust-depth** win and a natural v0.1.9/v0.1.10 candidate. Evaluate freshness before pulling in.

---

## 6. Recommendation (for the planning agent to confirm or override)

1. **Pull B2 into v0.1.9** — cheap, self-contained, consumer-facing correctness; no external dependency. File as a ticket.
2. **Optionally pull the Cluster A codifier (3a) into v0.1.9** — it's an audit "must-do," but dogfooding-internal; low external value. If included, use the "codifier + 4 back-applications" single-story shape.
3. **Move B3 (3c) to v0.1.10** — it's a spike gated on MCP auth that can't complete non-interactively, and its live-fetch payoff already lives in v0.1.10. File a v0.1.10 tracking issue capturing the scaffolding sub-tasks (fetch-contract survey + ADR ≥021, setup config surface, Stage-1 classifier/fallback).
4. **Run the §4 risk-window assessment before tagging** — this is required regardless of scope decisions; several will likely CARRY to v0.1.10 (esp. E06 Risk 3, which needs fresh green dogfood runs).
5. **Consider DI-001** as a trust-depth story if a slot remains.
6. If v0.1.9's remaining scope is deemed "done" after B2 (+ optional codifier), **cut the tag**: bump `plugin.json` + ROADMAP "current" marker, rename CHANGELOG `## [Unreleased] — v0.1.9` → dated, after the E06 Risk 3 green-run gate. (The DoD ties the heading rename + version bump + ROADMAP update together at tag time.)

---

## 7. Boundaries & notes the planning agent must respect

- **Tool-agnostic (hard):** never hardcode Linear/Jira/Shortcut. Ship the intake mechanism + a project-declared issue-source config. Operational toggles live in `.roughly/config`; content artifacts (known-pitfalls, verify-rules, spec-candidates, gate-log) stay separate files — avoids the governed/clobbered-CLAUDE.md pitfall.
- **ADR numbering reconciliation (from ROADMAP §Reconciliation):** ADR-019 shipped (escalation). B3's intake-resolution ADR = next free **≥ ADR-021**. The differential-gate spec set claims ADR-014, 016, 017, 018, 020 (Spec 2 renumbered 015→020 after ADR-015 shipped as the #66 gate protocol). Fold in the standing **ADR-009 / ADR-010 stale-reference cleanup** while renumbering.
- **Line-budget watch:** `skills/setup/SKILL.md` ~289/300 — B3's 5f logic + `.roughly/config` schema go in `skills/setup/templates/` + a shared reference (ADR-012), not inline. review-plan/SKILL.md is 124/300 (headroom).
- **Human-gate + push boundary unchanged:** pipeline ends at local commits; gates are verbatim plain text, never a structured-prompt tool (ADR-015). B1 relocated *where* a deferred finding is written, not the human's role; B2 *adds* a human prompt.
- **fix/89 branch:** #89 was split onto its own branch and merged via PR #91 (independent of the #81–#87 bundle PR #90). Both are now on `main`; nothing outstanding.

---

## 8. Source references (all on `main`)
- `docs/ROADMAP.md` → `## v0.1.9 — E06 codification close-out + consumer-project intake hardening` (Clusters A/B/C, Out-of-scope, Reconciliation, v0.1.8-retrospective DoD).
- `docs/planning/epics/complete/E06-anchoring-closure-and-ci-coverage.md` → `## v0.1.9 candidates` (L506+) and the "New from E06.S*" candidate blocks (L544–L606).
- `docs/planning/epics/complete/E06-…-audit.md` → cross-cutting finding #4 (verdict-artifact).
- `docs/deferred-investigations.md` → DI-001.
- GitHub issues #66–#89 (all closed); `docs/adrs/ADR-019-tool-neutral-spec-candidate-escalation.md`.
