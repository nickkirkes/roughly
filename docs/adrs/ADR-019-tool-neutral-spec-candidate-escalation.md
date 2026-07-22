# ADR-019: Tool-neutral spec-candidate escalation

**Date:** 2026-07-20
**Status:** Accepted
**Decider:** Nick Kirkes

---

## Context

Stage 6's `spec-revision-candidate` disposition and cubic-termination option (c) instructed the orchestrator to escalate findings to "the active epic's v0.1.X candidates section" / "the epic file" — targets that exist only in Roughly's own repo. In any consumer project the escalation pointed at nothing, so real spec-gap findings were silently dropped (issue #72; same class as #67's plugin-internal-assumption leak).

## Decision

Escalation is a tool-neutral procedure, single-sourced in `skills/shared/spec-candidate-escalation.md` and referenced via a `${CLAUDE_PLUGIN_ROOT}`-anchored Read (ADR-012 + #67). Default target: `.roughly/spec-candidates.md` (append-only, zero-setup, composes with the `.roughly/` artifact pattern). A project may override the target via a documented line in its own CLAUDE.md (ADR-006 runtime-CLAUDE.md mechanism — no new config-file parser; the full `.roughly/config` system remains deferred to the B3 track). The override target must be a file this procedure can write to; a documented non-file target (e.g. an external issue tracker) is not silently honored — escalation falls back to the durable default ledger and flags it for manual posting. Roughly's own repo overrides to its active root-level epic file **when exactly one exists** at the `docs/planning/epics/` root, preserving dogfood continuity; on zero such epics (dormant, between releases) or more than one (genuinely ambiguous), the override does not apply and escalation uses the default ledger — see this repo's CLAUDE.md for the resolved root-state rule. This subsumes the E06 "verdict persistent-artifact" carry-forward (ROADMAP.md:147/153).

## Consequences

Consumers get a working escalation target; drift is guarded by verify-all Check 8 + a de-dogfood revert tripwire. The `.roughly/spec-candidates.md` ledger is a **durable, tracked** project record of deferred spec findings (like `.roughly/known-pitfalls.md`) — committed, not gitignored. Note: ADR-014 (local-only gate instrumentation) and ADR-015 (gate protocol, #66) are both accepted, so 019 was the next free number when this ADR landed. The differential-gate spec set originally reserved ADR-014–018, but ADR-015 shipped as the #66 gate protocol, so that set's verify-autonomy spec (Spec 2) has been renumbered 015→ADR-020; the set now claims ADR-014/016/017/018/020 (reconciled in `docs/planning/differential-gate-allocation-specs.md` and ROADMAP.md:177). ADR-016–018 and ADR-020 remain unwritten reservations.
