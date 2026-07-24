# ADR-013: Build `--ci` runs review-plan (unifies with fix `--ci`)

**Date:** 2026-06-09
**Status:** Accepted
**Decider:** Nick Kirkes

---

## Context

Build's `--ci` mode previously SKIPPED review-plan and emitted a synthetic PASS (`[--ci] plan review skipped — synthetic PASS`). This behavior was introduced in E03.S11b-2 as a deliberate CI-only puncture of ADR-001's blocking-subagent enforcement: under `--ci`, the plan review subagent was bypassed and a synthetic verdict substituted so the happy-path pipeline could run unattended.

E06.S3 adds a build NEEDS-REVISION-recovery CI scenario (AC2), which requires review-plan to actually run under `--ci` — impossible while it is skipped. There is no recovery loop to exercise if the review never dispatches.

Fix's `--ci` (`skills/fix/SKILL.md`) already runs review-plan and acts on the verdict, so the two pipelines had diverged on this point.

## Decision

Build `--ci` now dispatches review-plan and acts on its verdict with a NEEDS-REVISION recovery loop: auto-apply the revision, re-dispatch, allow up to 2 verdicts then exit non-zero, and auto-progress on PASS. This unifies build with fix `--ci` and restores ADR-001 enforcement for build.

It emits structured verdict markers (`[--ci] plan review verdict: PASS` / `[--ci] plan review verdict: NEEDS REVISION (attempt <n>)`) for CI assertion.

## Consequences

- The build happy-path CI assertion changes from the synthetic-PASS marker to a plan-review-verdict marker.
- The build happy-path now incurs one real review-plan dispatch (slightly higher per-run cost/wall-time).
- ADR-010 remains reserved for v0.2.0 plan-format-v2.
- Supersedes the E03.S11b-2 skip-and-synthesize behavior.

**Correction (#73, 2026-07-24):** the "exit non-zero" phrasing in the Decision above is inaccurate — `claude -p` cannot set a process exit code, so the process exits 0 on a model-level abort; the structured marker described in the same paragraph is the actual CI signal. See `skills/build/SKILL.md`'s marker-primary `--ci` contract and `.roughly/known-pitfalls.md` § "CI assertions on Roughly pipeline aborts must be marker-primary, not exit-code-primary".
