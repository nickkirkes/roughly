# ADR-012: Runtime-shared procedural references

**Date:** 2026-05
**Status:** Accepted
**Decider:** Nick Kirkes

---

## Context

E04.S3 landed `skills/fix/SKILL.md` at 300/300 — the binding state where any subsequent fix-touching story had to either operate substitution-only or invoke an off-ramp. E05.S2 was projected to add ~38–63 net words to `agents/doc-writer.md`, which the E05.S1 cap raise (500 → 650) absorbed for the agent surface but did not address the symmetric pressure on the skill surface. The off-ramp candidate was recorded at E04 epic L566: "Refactor build/fix preamble + Stage 1 + Stage 8 prose into a shared reference."

`skills/build/SKILL.md` and `skills/fix/SKILL.md` both inline two near-identical procedural blocks: ABORT HANDLING (byte-identical between the two consumers as of 2026-05-26) and Stage 8 WRAP-UP (identical at steps 1, 3, 4, 5; diverges at step 2 commit-message stanza and step 6 wording). Per-file extraction surface: ~39 prose lines (Stage 8 + ABORT HANDLING only); ~33 lines net recovery after replacing inline prose with shared-reference directives.

The forcing function for this ADR was the binding 300/300 state on `skills/fix/SKILL.md` — any v0.1.6+ fix-touching work was structurally blocked.

## Decision

Procedural prose duplicated across `skills/build/SKILL.md` and `skills/fix/SKILL.md` is extracted to authoritative files under `skills/shared/<name>.md` and referenced at the consumer section head via a single-line directive of the form `` Read `skills/shared/<file>.md` `` placed within 3 lines of the section heading. The orchestrator reads the shared file when reaching the section and applies the procedure documented there.

Pipeline-specific divergence inside a shared file uses inline conditional prose: "When invoked from /roughly:build: X. When invoked from /roughly:fix: Y." The runtime LLM applies the branch matching its dispatch context. No template engine; no placeholder substitution; no marker comments.

This is **distinct from ADR-003's sync-reference pattern.** ADR-003 covers *static context* (e.g., `agents/agent-preamble.md`) inlined verbatim in agents and manually kept in sync across consumers. ADR-012 is *runtime-loaded* procedural reference: the consumer never inlines the prose; the orchestrator reads the shared file at runtime and applies the procedure.

The drift surface for ADR-012 is documented in CONTRIBUTING.md `## Skill authoring conventions` and enforced by a new check in `.claude/hooks/verify-all.sh` (path-presence + content-duplication phrase scan).

## Consequences

### Positive

- Recovers ~33 lines per consumer (build/fix SKILL.md). Closes the 300/300 binding state on `skills/fix/SKILL.md` and provides ~30-line headroom for downstream Stage-6/Stage-8 edits (E05.S5, E05.S6 AC3/AC4).
- Single source of truth for procedural prose. New content (e.g., E05.S5's 2-commit-window ABORT HANDLING entry, E05.S6's cubic-iteration termination criteria) lands in one place.
- Pipeline-conditional divergence is readable inline. No template engine, no out-of-band substitution; a contributor reading the shared file sees both branches in context.

### Negative

- Adds a "must update both consumers + shared file" drift surface. A future contributor may edit Stage 8 prose inline in `skills/build/SKILL.md` without realizing the shared reference is authoritative, producing silent drift. Mitigated by Check 8 in `.claude/hooks/verify-all.sh` (path-presence + content-duplication phrase scan); load-bearing phrases bidirectionally synced between the shared files and the drift check.
- Runtime `Read` of the shared file adds one extra tool call per section entry.

### Neutral

- Shared files are documentation-class — no `disable-model-invocation` frontmatter required since they are not skills. Implementer chooses whether to add YAML frontmatter. E05.S4's initial implementation uses no frontmatter, since the files contain pure procedural prose and are read by the orchestrator, not invoked by the model.

## Alternatives Considered

- **Sync-reference per ADR-003 pattern.** Rejected — inlines the prose verbatim in both consumers; does not recover any lines and re-creates the cap pressure that triggered the off-ramp.
- **Per-stage extraction (extract every stage, not just Stage 8 + ABORT HANDLING).** Rejected — over-fragments the consumer skill file; preamble + Stage 1 extraction explicitly deferred per OQ11 until the next forcing function.
- **Bigger cap-bump (raise the 300-line SKILL.md cap).** Rejected — the duplication itself was technical debt; raising the cap masks the underlying problem and leaves drift risk in place.

## Forward References

- ADR-003 — related shared-reference pattern (copy-and-sync for static context inlined verbatim in agents). Read alongside this ADR to understand which pattern applies in which case: ADR-003 for static context that must be visible in the agent's loaded prompt; ADR-012 for procedural prose that the orchestrator reads at runtime when reaching the section.
- E05.S5 — first downstream story landing new content (2-commit-window ABORT HANDLING entry) in `skills/shared/abort-handling.md` post-extraction.
- E05.S6 AC3 (cubic-iteration termination criteria in Stage 6) and AC4 (plan-implementation drift framing in Stage 8) — both land in the shared file after E05.S4 ships.
