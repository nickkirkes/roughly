# ADR-015: Gate protocol (verbatim text gates) + local-commit pipeline boundary

**Date:** 2026-07-17
**Status:** Accepted
**Decider:** Nick Kirkes

---

## Context

A 2026-07-16 dogfood run of `/roughly:build` (interactive, Opus 4.8) exposed two composing guardrail gaps:

- **F1 — gate-mechanism substitution.** Every human gate was presented via the harness's `AskUserQuestion` UI tool instead of as a plain-text question in the reply. The only gate-mechanism prohibition in runtime prose (`skills/build/SKILL.md:11`, `skills/fix/SKILL.md:11`) enumerated exactly two tools — `EnterPlanMode`/`ExitPlanMode` — for plan-mode-specific reasons. `AskUserQuestion` was never named, no gate text was marked verbatim, and the model re-authored gate wording into model-authored option labels.
- **F2 — unauthorized push.** At wrap-up the orchestrator attempted `git push -u origin <branch>` (blocked only by the human rejecting the permission prompt). The "do NOT push" rule was five words, single-sited in `skills/shared/stage-8-wrap-up.md`, reachable only via a runtime `Read`, and banned only the literal verb "push" (never PR / `gh` / remote).

The two interact: F1's re-authored option ("Yes, wrap up — commit … open the PR …") imported the host project's PR convention into an option description, and the human's selection of that self-authored text was treated as authorization to override the written "do NOT push" — consent-laundering through model-authored option text.

The enumerated prohibition is an open-world failure: forbidding two named tools leaves every other structured-prompt mechanism (present or future) permitted. The push boundary was single-point and verb-narrow, with no ADR, pitfall entry, or restatement to survive a skipped `Read` or context compaction.

## Decision

**1. Gates are verbatim plain text, governed by a closed-world prohibition.** A new shared reference, `skills/shared/gate-protocol.md`, specifies: gates are plain-text questions rendered verbatim in the reply; no gate may be presented through *any* structured or interactive prompt tool (`AskUserQuestion`, `EnterPlanMode`/`ExitPlanMode`, any MCP tool, or any tool added in the future — the test is closed-world, not an enumerated list); gate options are the complete closed set and may not be re-authored or have actions folded into them; and wording the model authored is never treated as the human's authorization. Numbered stage gates additionally carry a closed-form header block (pipeline · stage N of M · what completed · consequence per answer): stage names and consequences are copied from the SKILL.md headings/gate text, and the one composed field (the completion summary) is bounded to naming only what the stage produced — never a next action — so the block delivers progress context without the re-authoring surface a UI tool creates. The pipelines reference the protocol from a `## GATE PROTOCOL` section read before the first gate; the `build:11`/`fix:11` preamble carries the closed-world rule as a recognition cue. `AskUserQuestion` was rejected as the gate mechanism: runtime placeholders (`[N]`, `[Review summary]`) make truly-verbatim options impossible, and buttons would erode the typed-friction safety gates (`override`, `discard`).

**2. The pipeline terminates at local commits.** `skills/shared/stage-8-wrap-up.md` gains an explicit terminal step: the pipeline never pushes, opens a PR, runs `gh`, or contacts a remote — full stop, under any gate answer, prior approval, or project/CLAUDE.md standing order. It does not even offer to push or ask whether to push; pushing/PR creation is a separate action the human performs themselves outside the pipeline. (The Stage 8 commit-approval step is also promoted to a proper `**Gate:**` with quoted text, so Rule 2's verbatim requirement binds at the exact site of the original incident. `CONTRIBUTING.md`'s audit-table `gh pr create` MUST is clarified as a human PR-creation action, not a pipeline step.) This boundary is restated inline in both SKILL.md `## STAGE 8` sections and added to the pre-wrap-up compaction preserve-lists, so it survives a skipped `Read` or a compaction that drops the shared-file contents. The Stage-8 plan-marker template wording is corrected from "implemented and merged" to "implemented and committed" (nothing is merged at local-commit time), removing prose that primed the merge/push mental model.

Scope is the `build` and `fix` pipelines (the surfaces the incident named). Repo-wide adoption of the gate protocol across the other prompt-bearing skills is a deliberate follow-up, not part of this decision.

## Consequences

- **Positive:** the closed-world prohibition generalizes to future harness tools without enumeration churn; the push boundary is defense-in-depth (verbatim-gate fix and local-commit fix each independently block the observed incident); text-only gates keep the typed-friction confirmations intact and gain progress context via the header block.
- **Negative:** the gate protocol is one more shared reference to keep in sync; `build:11`/`fix:11` remain an ADR-009 manual byte-identical pair, now also mirrored by the `## GATE PROTOCOL` section. verify-all's shared-reference check enforces this: it byte-compares the two CRITICAL preambles, asserts the `## GATE PROTOCOL` section + `Read` directive exist in both pipelines, asserts the inline local-commit boundary is present in both Stage 8 sections, and guards against inline duplication of `gate-protocol.md`. (What it cannot check is whether the referenced prose stays semantically strong — that remains a review responsibility; the closed-world rule and anti-laundering clause are also inlined into the always-loaded line-11 preamble so the safety-critical rules survive even if the shared `Read` is skipped or unresolved.)
- **Neutral:** extending the protocol to other skills, or adding hook-level enforcement of the tool ban, remain separate future decisions to be revisited if a second substitution incident occurs.
