# Differential Gate Allocation — Build-Ready Specs

**Status:** PROPOSED · **Drafted against:** v0.1.8 (shipped 2026-06-10) · **Date:** 2026-06-27
**Author handoff:** spec set for the five-deliverable enhancement track. Every claim below was reconciled against the repo at draft time; divergences from the originating prompt are flagged inline and in each spec's Reconciliation Notes.

This document corrects the frame where the repo contradicts it, then specs each deliverable. Read the two framing sections first — three of the five specs change shape once the corrections land.

---

## Framing corrections (read before the specs)

Five places where the originating prompt's frame diverges from repo reality. These are not nitpicks; each one moves a design.

**1. "Stop-gated verification hooks" — there is no such gate.** The repo has exactly two hook points: a `UserPromptSubmit` hook (`.claude/hooks/plan-mode-gate.sh`, *blocking*, fail-closed) and a `Stop` hook (`.claude/hooks/verify-all.sh` in this repo / the `verify-all-stop-hook.sh.template` installed per-project, *non-blocking, informational only*). The Stop hook emits a `systemMessage` on drift and always `exit 0`s — it gates nothing. The roadmap's "Deferred" section confirms an enforcing Stop hook (`exit-1`) was consciously not scheduled ("Breaking change for contributors. No scheduled release."). So Deliverable 2's premise — that verification is held back by a stop-gate the human must watch — is half-true: the watching is real, but it comes from Stage 7's interactive gate and the *non*-enforcing hook, not a blocking one.

**2. There is no "verification subagent," and verification is not a subagent today.** `/roughly:verify-all` is an orchestrator-run skill that shells type/test/build inline (max 3 fix attempts, then escalate). Deliverable 2 asks to push mechanical-correctness checks "into a verification subagent" — that subagent does not exist and is a real architectural addition, not a hardening of something present. This is the right move (ADR-001's logic — blocking subagent dispatch prevents skipping — applies), but the spec must build it, not extend it.

**3. "Story-plan approval" maps to Stage 4, which is per-build-run, not a separate story gate.** The pipeline has no distinct "story plan approval" stage. `/roughly:build <story>` produces one plan (Stage 3) and gates it once at Stage 4 (the mandatory blocking `review-plan` subagent + a human gate, ADR-001). An epic decomposes into N stories, each its own build run with its own Stage 4. So Deliverable 4 = make Stage 4's *human* gate conditional (keep the `review-plan` subagent; relocate the human seat to batched async for non-divergent plans). The `review-plan` subagent is a PRE-FILTER already; the constraint that it must feed, not replace, the human is already the repo's posture (ADR-001 + the override protocol).

**4. Gate instrumentation (Deliverable 1) collides with a conscious telemetry deferral.** The roadmap's "Deferred" section: "Telemetry. Trust + complexity cost too high at current scale." `intervention_rate`/`intervention_value` *are* telemetry. They are reconcilable — but only if scoped as **local-only, in-repo, opt-in** decision logging written to `.roughly/`, with no network egress and no server component (the v0.4.0 boundary "Anything requiring a server component" stays intact). The spec below takes that scope. **Signed off by Nick 2026-06-28 and recorded as an explicit re-scope in ADR-014 + the roadmap "Deferred" section** — egress/server telemetry stays deferred; the admitted boundary is Spec 1's four blocking ACs.

**5. The highest-blast-radius gate (epic) is outside the build/fix per-run pipeline entirely.** Epic review is a separate manual command (`/roughly:review-epic` → `epic-reviewer` agent, Opus, ADR-008), run once before an epic's stories are built; `/roughly:audit-epic` is its post-implementation twin. "Uniform gating tax on every stage" is accurate *within* a build/fix run (eight inline `yes/adjust/abort` gates), but the epic gate is already differentiated — it's not one of the eight. Deliverable 5 strengthens a gate that already sits where the frame wants judgment concentrated. Good — but it means Deliverable 5 touches `review-epic`/`epic-reviewer`, not the build/fix stage gates.

**Net:** the design axis the prompt states — *where judgment lives, and how human attention is allocated across gates* — holds. The corrections sharpen it: instrument the eight per-run gates (Spec 1), automate the lowest-judgment one (Spec 2, verify), make the plan gate conditional (Spec 4), and concentrate adversarial pre-analysis at the already-separate epic gate (Spec 5). Spec 3 is the one genuinely new surface.

---

## Cross-cutting reconciliation

**Scope-freeze / target release.** None of the five land in an existing frozen release. Current shipped state is v0.1.8; v0.1.5–v0.1.8 are FROZEN and SHIPPED; v0.2.0 (cost-aware), v0.3.0 (monorepo), v0.4.0 (team governance) are scoped. Recommended sequencing, decisive:

- **Spec 1 (instrumentation)** → pull into a **v0.2.x point release** as local-only logging groundwork. It is non-breaking, has no multi-agent dependency, and unblocks evidence for the data-gated work. Telemetry-deferral re-scope signed off 2026-06-28 (ADR-014); the four blocking ACs in Spec 1 are the admitted boundary.
- **Spec 2a (verify-rules engine + verify subagent)** → **v0.2.x / v0.3.x, pulled forward alongside or just after Spec 1.** This is the boring, high-certainty autonomy win tied to the motivating pain. It is **independent of Spec 1**: the human never wanted to see "rewrite the wrong CLI," so the verify subagent demotes that gate *by construction*, not by data. Composes with v0.2.0's complexity flag; frees build/fix line budget.
- **Spec 2b (Stage-7 residual human-seat demotion) + Spec 4 (story-plan async)** → a dedicated post-v0.2.0 release, proposed **v0.5.0 "Differential gate allocation."** Both consume Spec 1's intervention data to justify demotion. (Note: the ≥20-run window accrues slowly for a solo dev — an additional reason 2a must not be chained to it.)
- **Specs 3 + 5 (multi-lens cell, epic adversarial cell)** → opt-in behind a capability flag, **sequenced after Spec 2a — never before it.** They are speculative (experimental, CC-agent-teams-dependent, flag-gated) and must not precede the high-certainty verification win that addresses the actual pain. Team-governance-adjacent; target at/after v0.4.0 but with the explicit ordering constraint that 2a lands first.

Do not inject any of this into v0.2.0's frozen cost-aware scope. v0.2.0 ships the complexity flag and Haiku routing; these specs *consume* that work, they don't extend its scope.

**Sequencing inversion fixed (vs prior draft).** The earlier ladder let Specs 3+5 (flag-gated cells) land at v0.4.0, ahead of a monolithic Spec 2 at v0.5.0 — sequencing speculative work before the boring verification win. Split Spec 2 and the inversion resolves: 2a (certain, low-risk) leads; the cells follow.

**Verify-rules population — decided (PROPOSED).** `.roughly/verify-rules.md` is a **separate file** from `known-pitfalls.md` (deterministic machine-checkable assertions vs prose a reviewer pattern-matches — the distinction Spec 2 already draws), but it **shares known-pitfalls' write-path and owner**: `/roughly:setup` scaffolds it *empty* (mirroring how Step 5b scaffolds known-pitfalls), and `doc-writer` appends rules **reactively at wrap-up** — one machine-checkable `forbid`/`require` pair the first time a mechanical failure is caught and corrected. No rule ships as a framework default. Setup stack-detection is **not** used to enumerate command rules; detection is shallow (file-count tier + framework/formatter/CI sniff + free-text stack) and hardening it is out of scope for this track.

**Per-role model selection must compose with v0.2.0, not fight it.** v0.2.0 establishes Sonnet-default + Haiku-for-simple + Opus-exclusive-to-epic-reviewer (ADR-008). Specs 3 and 5 add review/adversarial lenses; each lens picks a model from that same ladder (e.g. test-coverage and perf lenses → Haiku/Sonnet; devil's-advocate and synthesis-lead → Sonnet; epic adversarial lenses → at most Opus for the cross-cutting lens, Sonnet for the bounded ones). No lens gets Opus "for better results" without the ADR-008 cross-document-reasoning justification.

**ADR numbering — the roadmap is stale here.** Roadmap v0.2.0 item 4 says "ADR-009. Complexity flag, routing rules" but **ADR-009 is already accepted** as plan-mode detection. ADR-010 is reserved for v0.2.0 plan-format-v2 (per CLAUDE.md + ADR-013). These five specs were originally proposed to claim **ADR-014 through ADR-018**, but the block was partly consumed since: **ADR-014** shipped as this set's Spec 1 (gate instrumentation) ✓, while **ADR-015** was taken by the unrelated #66 gate protocol and **ADR-019** by tool-neutral spec-candidate escalation. So Spec 2 (verify-autonomy) is **renumbered from 015 to ADR-020**; Specs 3/4/5 keep ADR-016/017/018. Current claim: **ADR-014, 016, 017, 018, 020**. Flag the roadmap's "ADR-009" reference for correction when v0.2.0 is scoped.

| Spec | Proposed ADR | Proposed release |
|------|--------------|------------------|
| 1 Gate instrumentation | ADR-014 | v0.2.x (point) |
| 2a Verify-rules engine + verify subagent | ADR-020 | v0.2.x / v0.3.x (pull forward) |
| 2b Stage-7 residual human-seat demotion | ADR-020 | v0.5.0 (data-gated) |
| 4 Story-plan async escalation | ADR-017 | v0.5.0 |
| 3 Multi-lens review cell | ADR-016 | after 2a; flag-gated |
| 5 Epic-review adversarial cell | ADR-018 | after 2a; flag-gated |

*Rows ordered by build sequence, not ADR number.*

**Hard-constraint compliance baked into every spec below:** lead/pre-filter approval is always a pre-filter feeding the human gate (never removal); multi-agent features ship opt-in behind a capability flag and are never load-bearing; scheduler-agnostic boundary holds (in-session coordination only, no external scheduler); no implementation-stage parallelism (deferred to post-v0.3.0 file-boundary work); bounded, auditable cells only — provenance (which lenses, which findings, which synthesis) is the persisted product.

**Line/word caps are a build constraint, not a footnote.** `agents/doc-writer.md` is at 647/650 words; `skills/build/SKILL.md` 270/300 lines; `skills/fix/SKILL.md` 275/300; `verify-all.sh` 148/150. Any spec adding prose to these files needs the ADR-012 shared-reference off-ramp (`skills/shared/`) or an explicit cap-relief carve-out. Specs below state where they spend budget.

---

## Spec 1 — Gate instrumentation (ADR-014, v0.2.x)

Do this first. It is the cheapest, has no multi-agent dependency, and produces the evidence that justifies the **data-gated** demotions — Spec 2b and Spec 4. Without it, Spec 2b and Spec 4 are speculation, which violates dogfood-data discipline. (Spec 2a is explicitly excluded: it demotes the mechanical-correctness burden *by construction* — auto-fix — not by data, so it does not wait on this evidence.)

### Current repo state

- **Gates that exist.** Build and fix each run eight inline human gates (Stage 1 intake, 2 discover/investigate, 4 plan-review, 5d implement-complete, 6 review, 7 verify, plus the Stage 5c per-task escalations and Stage 8 wrap-up). Each is a conversational `yes / adjust / abort` prompt in the SKILL.md body. Plus two out-of-run gates: `/roughly:review-epic` and `/roughly:audit-epic`.
- **No instrumentation of any kind.** Nothing records whether a human said yes, adjusted, aborted, or overrode. The only persisted runtime artifacts are plan files (`.roughly/plans/*-plan.md`), `.roughly/known-pitfalls.md`, and `.roughly/workflow-upgrades`. There is no event log, no gate-outcome record, no notion of "the human flipped the subagent's verdict."
- **The one signal that already encodes a flip.** Stage 4's override protocol: a human proceeding past a non-PASS `review-plan` verdict must literally say "override," and the orchestrator must print "Proceeding without plan review PASS." That is a high-value, human-flipped, expensive-outcome event that is currently spoken and then lost.
- **Telemetry is a standing deferral** (see framing correction 4). Instrumentation must be local-only to be admissible.

### Proposed design

A local, append-only, opt-in **gate event log** at `.roughly/gate-log.jsonl`, written by the orchestrator at each gate as a single structured line. No network, no server, no aggregation service — reconciling with the v0.4.0 "nothing requiring a server component" boundary and the telemetry deferral. Off by default; enabled by a `--instrument` flag on build/fix (ADR-011: flags, not env vars) or a `.roughly/config` opt-in key.

**Two metrics per gate, computed offline from the log — not at runtime.**

- `intervention_rate(gate)` = (# runs where the human's response ≠ the gate's default/recommended action) ÷ (# runs reaching that gate). The default action is `yes`/proceed for stage gates and `PASS→proceed` for Stage 4. "Intervention" = `adjust`, `abort`, `override`, or any human edit before proceeding.
- `intervention_value(gate)` = blast radius of human-flipped outcomes, scored per intervention, **not** a frequency. Captured fields that let it be computed: `flip` (did the human reverse the machine verdict — e.g. override past NEEDS REVISION, or abort a PASS), `files_touched_downstream` (count from the plan file table / `git diff --name-only`), `stage` (later-stage flips are costlier — a Stage 6 flip means Stages 1–5 built on a wrong premise), and `defect_class` if the human annotates one. `intervention_value` is the **cost-asymmetry** measure: a rare flip at Stage 4 that prevents an N-file misimplementation scores high; a frequent `adjust` that retitles a task scores ~zero.

**Log line schema (per gate, one JSONL line):**

```json
{
  "ts": "2026-06-27T14:03:11Z",
  "run_id": "build-user-dashboard-1719500000",
  "pipeline": "build",
  "stage": 4,
  "gate": "review-plan",
  "machine_verdict": "NEEDS REVISION",
  "human_response": "override",
  "flip": true,
  "files_in_scope": 7,
  "blast_radius_hint": "7 files, 3 new",
  "note": "optional human annotation"
}
```

**Where it hooks into the existing pipeline — mapped to real points, not assumed ones.**

1. **Orchestrator-emitted, at each gate.** The build/fix SKILL.md gate prose gains one instruction at each `## STAGE N` gate: *"If instrumentation is enabled, append a gate-log line per `skills/shared/gate-log.md` before acting on the response."* The schema and the append procedure live in a new `skills/shared/gate-log.md` (ADR-012 shared-reference pattern) so build/fix spend ~1 line of budget each, not 15. This is the only viable hook for the *human-response* gates — there is no Claude Code hook event that fires "a human answered an inline conversational prompt," so it must be orchestrator-written.
2. **Stop hook augmentation for verify drift (passive signal).** The existing `Stop` → `verify-all.sh` hook already detects post-turn drift. Add an optional branch: when instrumentation is on and drift is detected, append a `gate:"stop-verify"` line. This is the one place a *real Claude Code hook* contributes, and it is non-blocking (preserves the informational contract).
3. **Stage 4 override is the flagship event.** The override protocol already forces a verbatim human utterance and an orchestrator confirmation string. Wire the log write into that exact path — it is the highest-signal `flip:true` event in the pipeline and is free to capture.

**Demotion / promotion rules (the point of the metrics):**

- **Demote to async or automate** when `intervention_rate` is near-zero *and* `intervention_value` is near-zero over a meaningful window (propose: ≥20 runs, dogfooded on Duff/HuntReady/DGF). Near-zero on both means the gate is a pure attention tax. On Stage 7 specifically, separate the two phases: Spec **2a** removes the mechanical-correctness burden *by construction* (auto-fix — no metric needed); Spec **2b** is the *data-gated* demotion of the *residual* `ESCALATE`-only seat, and that is the demotion this metric justifies. Other candidate for data-gated demotion: the Stage 5d implement-complete gate.
- **Keep the synchronous human seat** when `intervention_rate` is low but `intervention_value` is high — rare but expensive catches. Stage 4 (plan-review) and the epic gate are the expected members. Low frequency is *not* grounds to demote these; cost-asymmetry is the criterion.
- **Investigate / re-author** when `intervention_rate` is high but `intervention_value` is low — the gate fires constantly on cheap adjustments, suggesting the upstream stage produces consistently-wrong-but-trivially-fixable output. Fix the upstream stage, don't demote the gate.
- **Promotion** (add or harden a gate) when a stage with no synchronous gate accumulates high-value flips downstream — e.g. if Stage 5c escalations correlate with Stage 6 critical findings, the per-task review earns more weight.

The rule engine is a **human-run offline analysis** (`/roughly:gate-report` reading `.roughly/gate-log.jsonl`), not a runtime auto-demoter. Auto-demotion would itself be an unaudited judgment relocation — exactly what the project's human-gate thesis forbids. The report *recommends*; Nick decides per release.

### Blocking acceptance criteria (ADR-014 conditions — a build violating any is incomplete)

These are not soft contract notes. They are what keeps the absolute no-egress trust claim true; Spec 1 is not done until all four hold.

- **AC1 — Off by default.** Instrumentation is enabled only by explicit `--instrument` flag or `.roughly/config` opt-in. A default-on build fails this AC.
- **AC2 — Log artifacts gitignored by default.** `.roughly/gate-log.jsonl` and any sibling log artifact must be gitignored without user action: `/roughly:setup` adds the ignore entry in user projects, and this repo's own `.gitignore` gains it when instrumentation lands. (Scope the ignore to the log file(s), **not** `.roughly/` wholesale — `.roughly/plans/`, `known-pitfalls.md`, and `workflow-upgrades` are committed.) This closes the back-door egress where a committed log leaks intervention patterns into public git history. **New in this revision — not in the original Spec 1.**
- **AC3 — No network egress, no server component, ever.** (Framing correction 4, promoted from scoping aside to hard AC.)
- **AC4 — Log writes fail open.** A log-write failure never blocks a gate (opposite of the plan-mode gate's fail-closed posture — logging is not a safety gate).

**Pinned trust-claim language (ADR-014):** absolute — "Roughly never transmits any data off your machine"; qualified — "No data is collected unless you explicitly enable local logging." Any user-facing copy must use these exact forms.

### Reconciliation Notes

- **RESOLVED (was "needs sign-off"):** local-only gate logging is admissible despite the telemetry deferral. Nick signed off 2026-06-28; recorded as an explicit re-scope in **ADR-014** and the roadmap "Deferred" section. The admitted boundary is the four blocking ACs above; egress/server telemetry stays deferred.
- **VERIFY:** there is no Claude Code hook that fires on an inline conversational human answer. Confirmed by absence in the repo's hook usage (only `UserPromptSubmit` + `Stop`), but re-verify against current CC hook docs before committing to orchestrator-written logging as the only path.
- **DIVERGENCE FROM FRAME:** the prompt implies metrics "hook into" the pipeline at hook points. Reality: only one of the three capture points is a real hook (Stop); the gate-outcome captures are orchestrator-written prose. The frame's "map to current hook points" is satisfiable only partially.
- **DOGFOOD:** validate the metric definitions against real runs on Duff, HuntReady, DGF before promoting any demotion rule to a product decision (dogfood-data discipline). Name those three projects in the ADR.
- **BUDGET:** schema + append procedure go in `skills/shared/gate-log.md`; build/fix each spend ≤2 lines referencing it. `verify-all.sh` Stop-hook branch is ~6 lines — it is at 148/150, so this needs the off-ramp or a cap-relief carve-out (flag in the story).
- **CONTRACT:** instrumentation defaults OFF; an enabled run must never block on a log-write failure (fail-open for logging is correct here — the opposite of the plan-mode gate's fail-closed posture, because logging is not a safety gate).

---

## Spec 2 — Verification autonomy hardening (ADR-020)

Goal: make verification trustworthy enough to run unattended. The blocker is that mechanical-correctness errors — wrong CLI, wrong invocation, environment mismatch — currently have no home; they either slip through or surface to the human at Stage 7.

**Split into two phases with different release gates and different justifications:**

- **Spec 2a — verify-rules engine + verify subagent (pull forward, v0.2.x / v0.3.x).** The mechanical-correctness oracle that auto-fixes deterministic violations and only escalates genuine ambiguity. **Independent of Spec 1**: the human never wanted to see "rewrite the wrong CLI," so this demotes that gate *by construction*, not by data.
- **Spec 2b — formal demotion of the residual ESCALATE-only Stage 7 human seat (data-gated, v0.5.0).** Once 2a means the human only ever sees genuine ambiguity, the *remaining* synchronous Stage 7 gate can be demoted to async — but that step needs Spec 1's ≥20-run evidence to justify, and that window accrues slowly for a solo dev. Do not chain 2a to it.

### Current repo state

- **`/roughly:verify-all` is an inline orchestrator skill, not a subagent.** It reads commands from CLAUDE.md (`{{TYPE_CHECK_COMMAND}}`, `{{TEST_COMMAND}}`, `{{BUILD_COMMAND}}`), runs them in sequence, attempts fixes (max 3/check), then escalates to the human. It ends Stage 7 with a `yes / additional checks / abort` gate.
- **The Stop hook is the only always-on verification**, and it runs *only* the fast type-check (template comment: slow checks deliberately excluded). Non-blocking, informational.
- **`static-analysis` agent** (Sonnet, part of the Stage 6 review trio) also runs type/lint/build and checks "convention violations per CLAUDE.md" — but it only flags violations of rules *written in CLAUDE.md*. There is no per-project rule layer for "this project uses `supabase db`, never `psql`" unless someone wrote that sentence into CLAUDE.md or `known-pitfalls.md` as prose.
- **Mechanical-correctness checks have no structured home.** The "wrong CLI: `psql` instead of `supabase`" class is exactly the gap: it is not a type error (type-check passes), not a logic bug (review agents look at diffs, not command choice), and known-pitfalls is unstructured prose a reviewer may or may not pattern-match against. Nothing deterministically catches it.
- **What forces the human to watch today:** (a) Stage 7's interactive gate; (b) the non-enforcing Stop hook surfaces drift but cannot act on it; (c) no machine has authority to say "this command invocation is wrong for this project" — so a human is the only correctness oracle for mechanical choices.

### Proposed design

Two parts: a structured **per-project verification rules file** and a **blocking verification subagent** that owns mechanical-correctness so it never reaches the human.

**Part A — `.roughly/verify-rules.md` (per-project, structured, reactively populated).** Roughly ships the rule *format* and the *engine* — **never opinions about specific commands.** A `forbid: psql` default would be actively wrong on a raw-Postgres project where `psql` is correct. The file is a **separate file** from `known-pitfalls.md` (deterministic machine-checkable assertions vs prose), but shares its write-path and owner.

- **Setup scaffolds it empty** (mirroring `known-pitfalls.md`, setup Step 5b). No rules at install time.
- **Rules accrete reactively.** `doc-writer` appends one machine-checkable `forbid`/`require` (or `require-before-commit`) pair the first time a mechanical failure is caught and corrected — the same wrap-up write-path that maintains `known-pitfalls.md`. Setup stack-detection is **not** used to enumerate command rules (detection is shallow — file-count tier + framework/formatter/CI sniff + free-text stack — and hardening it is out of scope for this track).

The rule *format* (illustrative — these are placeholders for content a project generates at setup, **not shipped defaults**):

```markdown
## Command correctness rules
- forbid: <project-disallowed-command>   require: <project-required-command>   scope: <where>   reason: <why this project disallows it>
- require-before-commit: <project-command> exits 0
```

These are **deterministic grep/AST/exit-code assertions**, not LLM judgment, and not framework opinions. The wrong-CLI class becomes a `forbid`/`require` pair checked against the diff and the proposed command set, *once a project has accreted such a rule*.

**Dogfood test fixture (not a framework rule).** A `psql` → `supabase db` violation on Duff/HuntReady is the **fixture for validating the engine** — "does the mechanism catch a project-specific violation and auto-correct it" — not a rule Roughly knows about. Name the project the fixture ran against in the ADR; the thing being promoted is the *engine*, never the example rule.

**Part B — `verify` subagent (new `agents/verify.md`, Sonnet).** Verification becomes a blocking subagent dispatch (ADR-001's anti-skip logic), replacing the inline Stage 7 skill body's human-facing portion. The subagent:

1. Reads CLAUDE.md commands + `.roughly/verify-rules.md`.
2. Runs type/test/build (the existing sequence).
3. Runs the mechanical-correctness rule set against the diff and command choices — the layer that did not exist.
4. Returns a structured `CLEAN / FIX-APPLIED / ESCALATE` verdict with a per-rule table.

Mechanical failures that the rules can auto-correct (wrong CLI → rewrite to the required form, re-run) are fixed by the subagent and reported as `FIX-APPLIED` — **these never reach the human**. Only genuine ambiguity (a failing test with no rule, an environmental error) escalates. **That is 2a's by-construction demotion**: the Stage 7 *human* gate fires only on `ESCALATE`, not on every clean verify — achieved without any Spec 1 data. **2b** is the separate, data-gated step that demotes the residual `ESCALATE`-only seat to async once Spec 1 confirms it.

**Composition with the Stop hook.** The same `verify-rules.md` feeds an optional enforcing tier of the Stop hook — but keep the non-blocking default (the enforcing `exit-1` Stop hook is a deferred breaking change; do not pull it forward here). Instead, the Stop hook gains a passive `verify-rules` drift check that *surfaces* a forbidden command if one lands, consistent with its informational contract.

**Composition with v0.2.0 cost-aware.** The `verify` subagent is Sonnet by default; simple-complexity tasks (v0.2.0 flag) route its mechanical-rule pass to Haiku — the checks are deterministic, so the model only formats the verdict.

### Reconciliation Notes

- **DIVERGENCE FROM FRAME:** "stop-gated verification hooks" — corrected. The Stop hook gates nothing; verification's human-attention cost is Stage 7's interactive gate plus the absence of a mechanical-correctness oracle. Spec retargeted accordingly.
- **DIVERGENCE FROM FRAME:** there is no verification subagent to "harden" — Part B builds one. ADR-020 should record the inline-skill→subagent transition and cite ADR-001 for the anti-skip rationale and ADR-007's note that *if* a stage moves from inline to subagent the cost calculus changes.
- **ASSUMPTION:** auto-rewriting a wrong CLI invocation is safe to do without human sight. True only for deterministic `forbid`/`require` pairs with an unambiguous rewrite; anything requiring judgment must `ESCALATE`. The rule format must forbid ambiguous auto-rewrites.
- **DECISION (PROPOSED):** `verify-rules.md` is a **separate file** from `known-pitfalls.md` (deterministic assertions vs prose) but **shares its write-path and owner** — setup scaffolds it empty (Step 5b pattern), `doc-writer` accretes rules reactively at wrap-up. No rule is a shipped framework default; Roughly ships only format + engine. Setup stack-detection is not used to enumerate rules (out of scope; detection is shallow).
- **SEQUENCING (split):** 2a (engine + verify subagent) is independent of Spec 1 — it demotes the wrong-CLI gate by construction and is pulled forward to v0.2.x / v0.3.x. 2b (residual ESCALATE-seat demotion) is data-gated to v0.5.0. Flag-gated Specs 3+5 must land *after* 2a, never before.
- **VERIFY:** whether making Stage 7 a blocking subagent interacts with the `--ci` path (build/fix `--ci` auto-proceeds gates). The subagent's `ESCALATE` under `--ci` must halt on a structured failure marker like other `--ci` cap conditions — confirm against the ADR-011/ADR-013 `--ci` contract.
- **BUDGET / OFF-RAMP:** moving Stage 7 logic into a subagent *frees* lines in build/fix (the inline Stage 7 prose shrinks to a dispatch), which helps the 270–275/300 budgets. `verify-all.sh` rule-check branch needs the off-ramp (148/150). The reactive-accretion procedure (how `doc-writer` appends a `forbid`/`require` pair at wrap-up) goes in the ADR-012 shared-reference off-ramp (`skills/shared/`), **not** inline in `agents/doc-writer.md` — that file is at 647/650 words (3 words of headroom) and cannot absorb new logic.
- **VERIFY — confirmed at draft time:** `doc-writer` is the owner/writer of `known-pitfalls.md` (its frontmatter lists `.roughly/known-pitfalls.md` among files it may update; build/fix Stage 8 wrap-up step 6 dispatches it for new pitfalls). The "shares known-pitfalls' write-path and owner" claim therefore names the correct owner. Re-confirm if the wrap-up dispatch owner changes.
- **DOGFOOD:** the engine is validated by running a project-specific violation (the `psql`→`supabase db` fixture on Duff/HuntReady) and confirming auto-correction — the *mechanism* earns promotion, never the example rule. No promotion on the prompt's hypothetical alone.

---

## Spec 3 — Post-implementation multi-lens review cell (ADR-016, ≥v0.4.0, flag-gated)

Bounded cell: domain-specialized reviewers (correctness, security, perf, test-coverage) → synthesizing lead → human spot-checks the synthesis.

### Current repo state

- **A 3-lens parallel review cell already exists.** `/roughly:review` dispatches `code-reviewer`, `static-analysis`, and `silent-failure-hunter` in parallel (single message, multiple tool calls), then the orchestrator synthesizes a severity-grouped, deduplicated report. This is already a bounded, auditable cell — just narrower than the proposed one and with the synthesis done inline by the orchestrator rather than a dedicated lead.
- **All three lenses are Sonnet subagents** with `Glob, Grep, Read, Bash` tools. They read CLAUDE.md + known-pitfalls for context (via file Read, not via `skills`/`mcpServers` frontmatter).
- **Stage 6 already has a disposition protocol** for findings: `fix` / `defer` / `spec-revision-candidate`. The human seat is the Stage 6 gate after synthesis. So "human spot-checks the synthesis" is the present design.
- **Missing lenses:** security is folded into `code-reviewer` (OWASP mention), not a dedicated lens; there is no perf lens and no test-coverage lens.

### Proposed design — subagents, not teams (decisive)

**Extend the existing `/roughly:review` cell to the four named lenses, keep it on subagents, and add a dedicated synthesis-lead pass.** Do **not** make CC agent teams the default. Rationale, grounded in the hard constraints and the verified CC facts (appendix):

- **Provenance is the product.** Subagent dispatches return clean, isolated artifacts the orchestrator concatenates and the human audits — exactly the "which lenses, which findings, which synthesis" record the constraints require. Agent-teams' peer-to-peer messaging and shared context make the provenance trail muddier, not cleaner.
- **Frontmatter non-propagation breaks per-lens config.** Verified: a subagent's `skills`/`mcpServers` frontmatter does **not** carry to teammates (only `tools`/`model` do; teammates reload skills/MCP from project/user settings). The per-role model selection these lenses need (Spec's compose-with-v0.2.0 requirement) would have to be re-plumbed; for a security/perf lens that may need a specific MCP, teams add a configuration failure mode subagents don't have.
- **Structural limits collide with the pipeline.** One-team-per-session and no-nested-teams mean a review cell implemented as a team would consume the session's single team allotment and block any other team use (e.g. Spec 5's epic cell) in the same session. Subagents have no such cap.
- **The experimental flag cannot be load-bearing.** `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` gates a fast-moving feature; the core review path must work without it.

**Design (subagent cell):**

1. **Four lens subagents**, new `agents/`: `code-reviewer` (correctness, exists), `security-reviewer` (new), `perf-reviewer` (new), `test-coverage-reviewer` (new). `static-analysis` and `silent-failure-hunter` remain and fold under correctness/coverage as appropriate. Models per ADR-008 ladder: correctness + security → Sonnet; perf + test-coverage → Sonnet, with Haiku routing for simple-complexity tasks (v0.2.0). No Opus — none does cross-document reasoning.
2. **Spin-up within Stage 6, tear-down, proceed.** The cell is dispatched in parallel, returns, and is torn down within the stage — no persistent team. This is in-session coordination only (scheduler-agnostic boundary holds).
3. **Synthesizing lead.** Promote synthesis from inline-orchestrator to a dedicated `review-synthesis-lead` pass (Sonnet) that ingests the four lens reports, dedupes, resolves severity conflicts, and produces *one* ranked report with per-finding lens attribution. The lead's output is a **pre-filter**: it ranks and groups; it does not decide dispositions.
4. **Human spot-checks the synthesis.** The Stage 6 gate stays. The human sees the synthesized report + attribution and applies the existing `fix`/`defer`/`spec-revision-candidate` disposition. Lead synthesis never auto-closes a finding — pre-filter feeding the human gate, never replacement.
5. **Capability flag.** The four-lens cell ships behind a `--deep-review` flag (ADR-011). Default `/roughly:review` stays the proven 3-agent path until dogfood evidence (Spec 1 metrics on Stage 6 `intervention_value`) justifies promotion.

**Optional teams variant (documented, not default).** If a user enables `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`, an experimental `--deep-review=team` mode may run the lenses as teammates to exploit peer cross-challenge. Ship this as a clearly-labeled experiment with the appendix caveats; it is never the load-bearing path.

### Reconciliation Notes

- **DECISION:** subagents are the default; teams are an opt-in experiment. This is the decisive recommendation; the constraints (provenance, no-nesting, non-load-bearing flag) point one way.
- **VERIFY (fast-moving):** every CC agent-teams fact in the appendix — flag name, frontmatter non-propagation, `TeammateIdle`/`TaskCompleted` hooks, one-team/no-nesting limits, TeamCreate/TeamDelete removal — came from a docs-research subagent at draft time, not from Nick reading live docs. Re-verify against code.claude.com before building even the experimental variant. Confidence was high but not 100% on frontmatter-propagation specifics.
- **DIVERGENCE FROM FRAME:** the cell is not new — a 3-lens version ships today. The work is +2 lenses, a dedicated synthesis lead, and the flag; not a greenfield cell.
- **CONSTRAINT CHECK:** bounded/auditable ✓ (subagent artifacts), no swarm ✓, no impl-stage parallelism ✓ (review stage only), pre-filter-not-replacement ✓ (lead ranks, human dispositions).
- **BUDGET:** three new agent files (≤650 words each); `review/SKILL.md` gains the flag branch and the lead dispatch — currently small, has headroom.

---

## Spec 4 — Story-plan async escalation (ADR-017, v0.5.0)

Replace synchronous Stage-4 human approval of every story plan with: AI pre-screens each story plan against the epic, flags only divergent/risky plans for synchronous human review, and lets the rest proceed and queue for batched async review.

### Current repo state

- **Stage 4 is the gate in question, and it is already two-part.** Part 1: the `review-plan` blocking subagent (Sonnet, ADR-001) verifies the plan against the codebase and returns PASS / NEEDS REVISION — this is *already* an AI pre-filter and must stay. Part 2: after PASS, a *synchronous human gate* ("Ready to implement? yes / revise plan / abort") plus the override protocol. Part 2 is the per-run synchronous tax this spec targets.
- **`review-plan` checks the plan against the codebase, not against the epic.** Its dimensions are completeness / assumptions / overengineering — internal plan soundness. It does **not** check "does this plan diverge from the epic's intent for this story." That epic-alignment check does not exist anywhere in the per-story path; `review-epic` checks the epic *before* decomposition, not each story plan against it.
- **No batching or async queue exists.** Each `/roughly:build <story>` is a synchronous run with its own Stage 4 human gate. Nothing accumulates plans for later review.
- **`--ci` already auto-acts on Stage 4** without a human (ADR-013/ADR-011) — proof the human gate is mechanically relocatable; the missing piece is a *selective* relocation in interactive mode, plus an epic-alignment signal to drive the selection.

### Proposed design

**Add an epic-alignment pre-screen to Stage 4, and make the human gate conditional on its verdict.** Keep `review-plan` (codebase soundness) exactly as is; add a second, cheap pre-filter and a routing decision.

1. **Epic-alignment pre-screen (new, cheap).** When `/roughly:build <story>` runs with an epic reference in scope (Stage 1 already reads referenced epic/story files), after `review-plan` PASS the orchestrator runs an `epic-alignment` check: does the plan's task set, file table, and blast radius stay within the story's slice of the epic, or does it diverge (touches files outside the story's stated scope, introduces an approach the epic didn't anticipate, or crosses into another story's surface)? Returns `ALIGNED` or `DIVERGENT` with cited reasons. Model: Sonnet (or Haiku for simple-complexity stories, v0.2.0).
2. **Conditional human seat.**
   - `ALIGNED` + `review-plan: PASS` → **proceed without a synchronous gate**, and **append the plan to a batched async review queue** (`.roughly/plan-review-queue/`). The human's judgment is relocated, not removed.
   - `DIVERGENT` *or* `review-plan: NEEDS REVISION`/override → **synchronous human gate fires** as today. Divergence and unresolved codebase concerns are exactly the high-`intervention_value` cases that keep their human seat (Spec 1's promotion rule).
3. **Batched async review.** A new `/roughly:review-queue` command presents all queued ALIGNED plans (and, post-hoc, their implementations) for one human pass — the relocated gate. This is asynchronous *within the human's own session cadence*; it is **not** scheduled (scheduler-agnostic boundary — Roughly never triggers it; the human runs it). The queue persists in `.roughly/` so it survives across sessions.
4. **Pre-filter, never replacement.** The `epic-alignment` lead verdict gates *routing* (sync now vs async later), not *approval*. Every plan still reaches a human — the question is only whether before or after implementation, chosen by blast-radius proxy (divergence). An ALIGNED plan that the async pass later rejects rolls back via the existing ABORT HANDLING.

**Tunable risk floor — start aggressive, loosen with evidence.** A `.roughly/config` key sets what may route to async; everything else stays synchronous. **Default starts tight, not loose:** only a plan that is `ALIGNED` *and* small-footprint *and* low-risk by every available proxy (e.g. ≤2 files, no new files, no migration, no new public surface) is eligible for async; everything else — including any subtly-divergent-in-approach plan — keeps its synchronous seat. The failure mode of the opposite default (a small-footprint, subtly-divergent plan auto-routed to async, implemented, and caught only post-hoc where rollback costs far more than a plan-time catch) is exactly what the aggressive start prevents. Loosen the floor (raise the file threshold, drop the no-new-files condition) only once Spec 1 proves small-footprint divergences are cheap to reverse. This is the cost-asymmetry dial from Spec 1, made operational — and it opens narrow, not wide. **Day-one expectation:** because the floor starts this tight, Spec 4 changes little at first ship — async routing rarely fires until evidence lets the floor loosen. That is correct behavior, not a broken feature; the throughput benefit is unlocked progressively, not on day one.

### Reconciliation Notes

- **DIVERGENCE FROM FRAME:** "story-plan approval" is Stage 4, which is per-build-run, and its AI pre-filter (`review-plan`) already exists. This spec adds the *epic-alignment* dimension `review-plan` lacks and a routing/queue layer — it does not introduce the first AI screen.
- **CONSTRAINT CHECK:** the async queue is human-pulled, never Roughly-triggered (scheduler-agnostic ✓). Human judgment relocated sync→async for low-risk plans, preserved sync for divergent ones (gate relocation, not removal ✓).
- **ASSUMPTION:** an epic reference is reliably in scope at Stage 1. True only when the story was invoked with its epic/story file; freehand `/roughly:build "<text>"` has no epic to align against — in that case the pre-screen is skipped and the synchronous gate stays (safe default). State this branch explicitly in the spec.
- **DEPENDENCY:** this spec's demotion (skip sync gate for ALIGNED) should not ship until Spec 1 shows Stage 4's `intervention_value` is genuinely concentrated in the DIVERGENT/override cases. Otherwise the routing threshold is guesswork. Sequence Spec 1 → Spec 4.
- **DEFAULT DIRECTION (changed vs prior draft):** the risk floor now starts **aggressive** (route most to sync; async only the small-footprint-and-aligned), and loosens with evidence — inverting the earlier throughput-first default that optimized before the data justifying it existed.
- **VERIFY:** interaction with `--ci`. Under `--ci` the human gate already auto-proceeds; the queue should still record ALIGNED plans for an audit trail but not block. Confirm against ADR-013.
- **BUDGET:** Stage 4 prose grows in build/fix (both at 270–275/300). The epic-alignment dispatch + routing table likely needs the ADR-012 off-ramp into `skills/shared/stage-4-routing.md`.

---

## Spec 5 — Epic-review adversarial cell (ADR-018, ≥v0.4.0, flag-gated)

Highest-blast-radius gate. Front the human epic decision with an adversarial multi-agent pre-analysis — architecture, scope, dependency, and a dedicated devil's-advocate lens that tries to break the decomposition before the human sees it.

### Current repo state

- **`/roughly:review-epic` dispatches a single `epic-reviewer` agent (Opus, ADR-008)** — the only Opus agent in the system, justified by cross-story reasoning. It reviews along six declared dimensions (technical accuracy, best practices, risks, overengineering, AC quality, dependencies) plus an **AC mutual-satisfiability** dimension that already does adversarial pairwise reasoning ("do these two ACs create a structural impossibility"). Returns `Ready / Needs Revision / Major Concerns`, saved beside the epic as `<epic>-review.md`.
- **It is a single reviewer, not a cell.** One Opus pass covers all dimensions. There is no separate scope lens, dependency lens, or dedicated devil's-advocate — the adversarial reasoning is one dimension among seven inside one agent.
- **The human seat is `/roughly:review-epic`'s Step 4 gate** ("Address findings before implementation, or proceed as-is?"). This *is* the concentrated, high-blast-radius gate the whole frame wants to front. It is already outside the per-run build/fix tax.
- **`epic-reviewer` already validates against the codebase** (tools: Glob/Grep/Read/Bash) and cites story IDs — so an adversarial cell has a real codebase to attack, not just the epic prose.

### Proposed design

**Decompose the single Opus reviewer into a bounded adversarial cell of specialized lenses + a synthesizing lead, fronting the existing human gate.** This is the one place per-role models and an explicit devil's-advocate earn their cost, because the gate's blast radius is an entire epic.

1. **Four adversarial lenses** (subagents, spin-up within `review-epic`, tear-down, proceed):
   - **Architecture lens** — Opus. The one lens that needs cross-story, cross-document reasoning (the ADR-008 justification); inherits today's `epic-reviewer` technical-accuracy/best-practices/overengineering dimensions.
   - **Scope lens** — Sonnet. Is each story's scope coherent, non-overlapping, correctly sliced? Does the epic over- or under-reach vs the stated goal?
   - **Dependency lens** — Sonnet. Cross-story ordering, shared-surface conflicts, the existing AC mutual-satisfiability check, integration risk.
   - **Devil's-advocate lens** — Sonnet, **adversarial brief**: its job is to *break the decomposition* — find the story that will surface a blocker mid-epic, the AC pair that's jointly unsatisfiable, the "story 5 contradicts story 2" trap, the optimistic estimate. It argues for `Major Concerns` and must produce its strongest case even when the epic looks clean. This is the lens the current single-reviewer design lacks.
2. **Synthesizing lead** (Sonnet) ingests the four lens reports, reconciles conflicts (architecture says Ready, devil's-advocate says Major Concerns → lead surfaces the tension explicitly rather than averaging it away), and produces one verdict with full per-lens attribution. The lead is a **pre-filter**: it organizes the adversarial case; it does not decide.
3. **Human spot-checks the synthesis** at the existing Step 4 gate, now fronted by a sharper, adversarially-stress-tested brief. Verdict and all four lens artifacts persist beside the epic (`<epic>-review.md` + per-lens sections) — provenance is the product.
4. **Capability flag.** Ships behind `--adversarial` (ADR-011). Default `review-epic` stays the proven single-Opus path until dogfood evidence (epics reviewed both ways on Duff/HuntReady/DGF) shows the cell catches decomposition failures the single reviewer missed.

**Subagents vs teams:** same decision as Spec 3 — **subagents by default** (provenance, no one-team-per-session contention with Spec 3's cell, non-load-bearing flag). A teams variant could let the devil's-advocate *cross-examine* the architecture lens via peer messaging, which is genuinely attractive for adversarial review; offer it only as a labeled `--adversarial=team` experiment gated on `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`, with appendix caveats.

**Model-cost composition.** Only the architecture lens is Opus (preserves ADR-008's "Opus for cross-story reasoning only" — now scoped to the one lens that does it, rather than the whole reviewer). Three lenses + lead on Sonnet means the cell is *not* 4× an Opus pass; it is roughly one Opus + four Sonnet, comparable cost for materially deeper coverage. This composes with, rather than fights, v0.2.0's cost direction.

### Reconciliation Notes

- **DIVERGENCE FROM FRAME:** the epic gate is already the concentrated, differentiated, high-blast-radius gate (outside the per-run tax) and already does *some* adversarial reasoning (AC mutual-satisfiability). The work is decomposing one Opus reviewer into a cell with an explicit devil's-advocate — not adding adversarial review where none existed.
- **ADR-008 INTERACTION:** this spec re-scopes "Opus only for epic-reviewer" to "Opus only for the architecture lens within the epic cell." That is an amendment to ADR-008's consequence, and ADR-018 must state it explicitly so the next reader doesn't see Opus creep. Net Opus token spend per epic review is roughly unchanged (one lens instead of one monolithic agent).
- **CONSTRAINT CHECK:** bounded/auditable cell ✓, no swarm ✓, lead is pre-filter not replacement ✓, in-session coordination (no scheduler) ✓, opt-in flag / not load-bearing ✓.
- **VERIFY (fast-moving):** CC agent-teams facts per appendix before building the `=team` variant; and confirm the one-team-per-session limit means Spec 3's review cell and Spec 5's epic cell can't both be teams in one session (they can't) — which is itself a reason to keep both on subagents by default.
- **DOGFOOD:** run real epics (E04/E05/E06 are available as historical fixtures, plus live Duff/HuntReady/DGF epics) through both the single-reviewer and the cell; promote the cell only if it catches a decomposition failure the single reviewer missed. No promotion on speculation.
- **BUDGET:** new `agents/` files for scope/dependency/devil's-advocate lenses + a synthesis lead (≤650 words each); `review-epic/SKILL.md` gains the flag branch and parallel dispatch — small file, has headroom.

---

## Appendix — Verified Claude Code agent-teams facts (for Specs 3 & 5)

Gathered by a docs-research pass against code.claude.com at draft time. **Re-verify before building any teams variant — the feature is experimental and fast-moving; confidence noted per item.**

| Fact | Finding | Confidence |
|------|---------|-----------|
| Enable flag | `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` (env or settings.json) | High |
| Frontmatter propagation | `skills` and `mcpServers` do **NOT** propagate to teammates; `tools` and `model` do. Teammates reload skills/MCP from project/user settings | High (re-verify — load-bearing for the subagents-vs-teams decision) |
| Lifecycle hooks | `TeammateIdle` (exit 2 keeps teammate working) and `TaskCompleted` (exit 2 blocks completion + sends feedback) | High |
| Structural limits | One team per session; no nested teams (teammate cannot spawn its own team); no hard teammate cap (3–5 practical) | High |
| Spin-up / tear-down | Teammates spawned via the `Agent` tool by name; auto-cleanup on session exit (TeamCreate/TeamDelete tools reportedly removed in a recent version) | Medium (re-verify the tool-removal claim) |
| Subagent contrast | Subagents run isolated, report only to parent, lower token cost — the stable mechanism Roughly already uses throughout | High |

**Sources:** code.claude.com/docs/en/agent-teams; code.claude.com/docs/en/hooks; code.claude.com/docs/en/agents; code.claude.com/docs/en/changelog. The one-team-per-session + no-nesting limits are the decisive constraints: with two proposed cells (Spec 3 review, Spec 5 epic), teams cannot serve both in one session, which on its own justifies subagents as the default for both.

---

## Build sequencing summary

1. **Spec 1** (v0.2.x, ADR-014) — gate instrumentation, local-only. Telemetry-deferral re-scope signed off 2026-06-28 (ADR-014); ship behind the four blocking ACs. Unblocks the data-gated work.
2. **Spec 2a** (v0.2.x / v0.3.x, ADR-020) — verify-rules engine + verify subagent. **Independent of Spec 1; runs alongside or just after it.** The boring, high-certainty autonomy win tied to the motivating pain — it leads. Frees build/fix line budget; composes with v0.2.0's complexity flag.
3. **Spec 2b + Spec 4** (v0.5.0, ADR-020/017) — residual Stage-7 demotion + story-plan async. Both consume Spec 1 evidence. Spec 4's risk floor starts aggressive and loosens with data.
4. **Specs 3 + 5** (after 2a; flag-gated, ADR-016/018) — multi-lens + adversarial cells, subagent-default, never load-bearing. **Must not precede Spec 2a.** Re-verify CC agent-teams facts before any `=team` variant.

Reconcile the roadmap's stale "ADR-009" reference (v0.2.0 item 4 — already accepted as plan-mode detection; cost-aware work needs ≥ADR-014) and confirm none of this enters v0.2.0's frozen scope before scoping the v0.5.0 epic. This housekeeping stands independent of whether any spec here ships.

