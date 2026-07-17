# ADR-014: Local-Only Gate Instrumentation (re-scopes the telemetry deferral)

**Date:** 2026-06-28
**Status:** Accepted
**Decider:** Nick Kirkes

---

## Context

Spec 1 of the differential-gate-allocation track (`docs/planning/differential-gate-allocation-specs.md`) proposes a local, append-only gate event log (`.roughly/gate-log.jsonl`) to measure `intervention_rate` and `intervention_value` per gate, so gate demotions (Spec 2b, Spec 4) are justified by recorded evidence rather than intuition.

This brushes a standing deferral. `docs/ROADMAP.md` "Deferred" section reads: "**Telemetry.** Trust + complexity cost too high at current scale." Intervention logging *is* telemetry-adjacent. The differential-gate work cannot proceed on dogfood-data discipline without resolving whether any persisted decision data is admissible.

## Decision

On 2026-06-28, Nick signed off on **local-only gate instrumentation**. Three parts, all yes:

1. **Logged intervention evidence is wanted.** Gate demotions under Spec 2b and Spec 4 are to be justified by recorded data, not intuition. (Spec 2a is excluded — it demotes the mechanical-correctness burden by construction, not by data.)
2. **The local-only trust posture is accepted.** The no-egress claim stays *absolute*: "Roughly never transmits any data off your machine" remains literally true. What is conceded is only the weaker "no logging capability exists" — because logging is off by default, written only to the user's own repo, and never transmitted.
3. **This is an explicit re-scope of the telemetry deferral, not a silent override.** Recorded here and in the roadmap.

## Re-scopes the telemetry deferral

- **Still deferred:** egress/server telemetry and usage analytics — anything that transmits off the machine or requires a server component. The original rationale ("trust + complexity cost too high at current scale") is intact for that class and remains the v0.4.0 "nothing requiring a server component" boundary.
- **Now permitted (as of this ADR):** local-only, opt-in, in-repo decision logging, bounded by the conditions below. These conditions *are* the boundary of what was admitted; anything outside them is still deferred.

## Conditions (the admitted boundary — enforced as Spec 1 blocking ACs)

1. **Off by default.** Logging is enabled only by explicit flag/config opt-in.
2. **Log artifacts gitignored by default.** `.roughly/gate-log.jsonl` and any sibling log artifact are gitignored; `/roughly:setup` adds the entry in user projects, and this repo's own `.gitignore` gains it when instrumentation lands. This closes the back-door egress: a contributor enabling logging and committing the log would otherwise leak intervention patterns into public git history.
3. **No network egress, no server component, ever.**
4. **Log-write failures fail open.** Logging never blocks a gate (the opposite of the plan-mode gate's fail-closed posture — logging is not a safety gate).

## Trust-claim language (pinned)

- **Absolute:** "Roughly never transmits any data off your machine."
- **Qualified:** "No data is collected unless you explicitly enable local logging."

Any user-facing copy making a no-data/no-telemetry claim must use these exact forms so the claim stays honest after Spec 1 ships. Repo audit at draft time found no existing absolute no-data claim to reconcile (README/CONTRIBUTING/docs clean; roughly.dev is out-of-repo and tracked separately).

## Consequences

- **Positive:** the differential-gate demotions earn dogfood evidence; the absolute no-egress trust claim survives intact; the telemetry deferral is amended transparently rather than quietly contradicted.
- **Negative:** one more thing `/roughly:setup` must install (the gitignore entry) and keep correct; a contributor can still opt in locally and inspect their own logs (intended).
- **Neutral:** if a future decision ever wants egress telemetry, that remains a separate, still-deferred decision requiring its own ADR.
