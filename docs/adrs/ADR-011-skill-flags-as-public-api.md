# ADR-011: Skill Flags as Public API, Env Vars as Debug-Only

**Date:** 2026-05
**Status:** Accepted
**Decider:** Nick Kirkes

---

## Context

S11b-2 OQ1, resolved 2026-05-08, surfaced the question of how to pass behavioral modifiers to skills — specifically whether the `/roughly:build` CI mode should be activated via environment variable, a special token in the prompt, or a flag in `$ARGUMENTS`. Three options were considered: (a) heredoc-fed stdin, (b) override-token env var, (c) flag in `$ARGUMENTS` (option (c) chosen).

The primary motivation for rejecting env vars was a silent-leak failure mode: a debug env var set during a CI session (e.g., `export ROUGHLY_CI=1` in a shell profile or CI environment) can silently carry over into local development sessions where the user did not intend CI-mode behavior. This leak is invisible — no invocation history captures it, no rerun reproduces it from the command alone.

## Decision

A change is **user-facing** if it alters observable skill behavior for any operator running the pipeline — regardless of how the change is framed or who the intended audience is. Observable means visible in pipeline outputs, gate decisions, dispatched-model selection, or any other surface the operator can detect without inspecting shell state or CI configuration.

User-facing skill behavior changes are expressed as flags in `$ARGUMENTS`, not environment variables. Flags are part of the skill's public API: they appear in invocation history, are self-documenting when read in CI scripts or rerun logs, and are structurally harder to silently leak across contexts.

## Consequences

### Positive

- Explicit invocation surface: flags appear in the `claude` invocation history, making behavioral changes auditable after the fact.
- Self-documenting in CI scripts and rerun history — a reader can see exactly what mode was invoked without consulting shell state or CI configuration.
- Flag detection follows the standalone-token form documented in `.roughly/known-pitfalls.md`, keeping the pattern consistent across skills.

### Negative

- Flag proliferation risk on long-lived skills with many behavioral variants.
- Env-var-acceptable carve-out: environment variables remain appropriate for debug-only, contributor-facing configuration that carries no user-facing skill behavior change. The test is whether an operator who doesn't inspect shell state or CI configuration can still predict all observable pipeline outputs from the invocation command alone — if yes, the change is internal and env-var-eligible; if no, it's user-facing and belongs in a flag.
- Positive example (hypothetical, no real v0.2.0 case has surfaced): a Haiku-routing budget threshold (`ROUGHLY_HAIKU_BUDGET_USD`) for cost-sensitive teams would be env-var appropriate — it tunes an internal routing heuristic without changing the observable skill contract.
- Counterexample: an env var that suppresses a pipeline gate (e.g., `ROUGHLY_SKIP_REVIEW=1`) would NOT qualify even if framed as "debug-only," because it changes observable skill behavior for the human operator running the pipeline — that belongs in a flag.
- If a real v0.2.0 env-var case surfaces that the carve-out criterion cannot resolve, ADR-011 may need amendment or carve-out extension at v0.2.0 ADR-write time.

### Neutral

- Existing skill flags (e.g., `--ci`) already follow this pattern; ADR-011 codifies the precedent rather than introducing a behavior change.

## Forward References

The first downstream consumer is v0.2.0's complexity flag, which adjusts pipeline behavior based on declared task complexity. The ADR covering plan-format-v2 (currently slotted as ADR-010) should treat ADR-011 as foundational: v0.2.0's user-facing surface inherits ADR-011's principle that behavioral modifiers belong in the explicit invocation surface, not in ambient environment state. ADR-011 does not specify ADR-010's internal structure, citation form, syntax, or content placement — ADR-010 covers the mechanism; ADR-011 establishes only the principle that this modifier belongs in the explicit invocation surface rather than in ambient environment state.

## Alternatives Considered

**(a) Heredoc-fed stdin.** Rejected. Ergonomically heavier than a flag and not pattern-portable across skills. Requiring callers to construct a heredoc invocation for a behavioral toggle raises the integration cost without a corresponding benefit.

**(b) Override-token env var.** Rejected. The silent-leak failure mode — a debug env var set in one context silently persisting into another — is the core risk this ADR exists to prevent. Env vars are not captured in invocation history and cannot be reconstructed from a rerun command alone.
