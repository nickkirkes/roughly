# ADR-011: Skill Flags as Public API, Env Vars as Debug-Only

**Date:** 2026-05
**Status:** Accepted
**Decider:** Nick Kirkes

---

## Context

S11b-2 OQ1, resolved 2026-05-08, surfaced the question of how to pass behavioral modifiers to skills — specifically whether the `/roughly:build` CI mode should be activated via environment variable, a special token in the prompt, or a flag in `$ARGUMENTS`. Three options were considered: (a) heredoc-fed stdin, (b) override-token env var, (c) flag in `$ARGUMENTS` (option (c) chosen).

The primary motivation for rejecting env vars was a silent-leak failure mode: a debug env var set during a CI session (e.g., `export ROUGHLY_CI=1` in a shell profile or CI environment) can silently carry over into local development sessions where the user did not intend CI-mode behavior. This leak is invisible — no invocation history captures it, no rerun reproduces it from the command alone.

## Decision

User-facing skill behavior changes are expressed as flags in `$ARGUMENTS`, not environment variables. Flags are part of the skill's public API: they appear in invocation history, are self-documenting when read in CI scripts or rerun logs, and are structurally harder to silently leak across contexts.

## Consequences

### Positive

- Explicit invocation surface: flags appear in the `claude` invocation history, making behavioral changes auditable after the fact.
- Self-documenting in CI scripts and rerun history — a reader can see exactly what mode was invoked without consulting shell state or CI configuration.
- Flag detection follows the standalone-token form documented in `.roughly/known-pitfalls.md`, keeping the pattern consistent across skills.

### Negative

- Flag proliferation risk on long-lived skills with many behavioral variants.
- Env-var-acceptable carve-out: environment variables remain appropriate for debug-only, contributor-facing configuration that carries no user-facing skill behavior change. As a hypothetical example of a case v0.2.0 might land: a Haiku-routing budget threshold (`ROUGHLY_HAIKU_BUDGET_USD`) for cost-sensitive teams would be env-var appropriate — it tunes an internal routing heuristic without changing the observable skill contract. By contrast, an env var that suppresses a pipeline gate (e.g., `ROUGHLY_SKIP_REVIEW=1`) would NOT qualify even if framed as "debug-only," because it changes observable skill behavior for the human operator running the pipeline — that belongs in a flag. This example is hypothetical at ADR-write time — no real v0.2.0 env-var case has surfaced. If one does, ADR-011 may need amendment or carve-out extension.

### Neutral

- Existing skill flags (e.g., `--ci`) already follow this pattern; ADR-011 codifies the precedent rather than introducing a behavior change.

## Forward References

The first downstream consumer is v0.2.0's complexity flag (`Task N (Complexity: simple|standard|complex)`), which will control model-routing behavior via a plan-format field parsed at orchestrator dispatch time. The ADR covering plan-format-v2 (currently slotted as ADR-010) should treat ADR-011 as foundational: v0.2.0's user-facing surface inherits ADR-011's principle that behavioral modifiers belong in the explicit invocation surface, not in ambient environment state. ADR-011 does not specify ADR-010's internal structure, citation form, or content placement — only the relationship by role.

## Alternatives Considered

**(a) Heredoc-fed stdin.** Rejected. Ergonomically heavier than a flag and not pattern-portable across skills. Requiring callers to construct a heredoc invocation for a behavioral toggle raises the integration cost without a corresponding benefit.

**(b) Override-token env var.** Rejected. The silent-leak failure mode — a debug env var set in one context silently persisting into another — is the core risk this ADR exists to prevent. Env vars are not captured in invocation history and cannot be reconstructed from a rerun command alone.
