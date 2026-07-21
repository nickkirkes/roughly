# ADR-019: Tool-neutral spec-candidate escalation

**Date:** 2026-07-20
**Status:** Accepted
**Decider:** Nick Kirkes

---

## Context

Stage 6's `spec-revision-candidate` disposition and cubic-termination option (c) instructed the orchestrator to escalate findings to "the active epic's v0.1.X candidates section" / "the epic file" — targets that exist only in Roughly's own repo. In any consumer project the escalation pointed at nothing, so real spec-gap findings were silently dropped (issue #72; same class as #67's plugin-internal-assumption leak).

## Decision

Escalation is a tool-neutral procedure, single-sourced in `skills/shared/spec-candidate-escalation.md` and referenced via a `${CLAUDE_PLUGIN_ROOT}`-anchored Read (ADR-012 + #67). Default target: `.roughly/spec-candidates.md` (append-only, zero-setup, composes with the `.roughly/` artifact pattern). A project may override the target via a documented line in its own CLAUDE.md (ADR-006 runtime-CLAUDE.md mechanism — no new config-file parser; the full `.roughly/config` system remains deferred to the B3 track). Roughly's own repo overrides to its epic files, preserving dogfood continuity. This subsumes the E06 "verdict persistent-artifact" carry-forward (ROADMAP.md:147/153).

## Consequences

Consumers get a working escalation target; drift is guarded by verify-all Check 8 + a de-dogfood revert tripwire. The `.roughly/spec-candidates.md` ledger is a **durable, tracked** project record of deferred spec findings (like `.roughly/known-pitfalls.md`) — committed, not gitignored. Note: ADR numbering starts at 019 per ROADMAP.md:177 (014–018 reserved for the differential-gate spec set); the differential-gate reservation table's ADR-015 slot is already stale (ADR-015 shipped as gate-protocol) — a separate housekeeping item, not resolved here.
