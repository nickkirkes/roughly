# ADR-019: Tool-neutral spec-candidate escalation

**Date:** 2026-07-20
**Status:** Accepted
**Decider:** Nick Kirkes

---

## Context

Stage 6's `spec-revision-candidate` disposition and cubic-termination option (c) instructed the orchestrator to escalate findings to "the active epic's v0.1.X candidates section" / "the epic file" — targets that exist only in Roughly's own repo. In any consumer project the escalation pointed at nothing, so real spec-gap findings were silently dropped (issue #72; same class as #67's plugin-internal-assumption leak).

## Decision

Escalation is a tool-neutral procedure, single-sourced in `skills/shared/spec-candidate-escalation.md` and referenced via a `${CLAUDE_PLUGIN_ROOT}`-anchored Read (ADR-012 + #67). Default target: `.roughly/spec-candidates.md` (append-only, zero-setup, composes with the `.roughly/` artifact pattern). A project may override the target via a documented line in its own CLAUDE.md (ADR-006 runtime-CLAUDE.md mechanism — no new config-file parser; the full `.roughly/config` system remains deferred to the B3 track). The override target must be a file this procedure can write to; a documented non-file target (e.g. an external issue tracker) is not silently honored — escalation falls back to the durable default ledger and flags it for manual posting. Roughly's own repo overrides to its **active root-level** epic file *when one exists*, preserving dogfood continuity; between releases, when no active epic sits at the `docs/planning/epics/` root, the override is dormant and escalation uses the default ledger (see this repo's CLAUDE.md for the resolved root-state rule). This subsumes the E06 "verdict persistent-artifact" carry-forward (ROADMAP.md:147/153).

## Consequences

Consumers get a working escalation target; drift is guarded by verify-all Check 8 + a de-dogfood revert tripwire. The `.roughly/spec-candidates.md` ledger is a **durable, tracked** project record of deferred spec findings (like `.roughly/known-pitfalls.md`) — committed, not gitignored. Note: ADR-014 (local-only gate instrumentation) and ADR-015 (gate protocol) are accepted; only ADR-016–018 remain reserved for the differential-gate spec set (per ROADMAP.md), so 019 is the next free number. The differential-gate reservation table that still lists 014/015 as reserved is itself stale — a separate housekeeping item, not resolved here.
