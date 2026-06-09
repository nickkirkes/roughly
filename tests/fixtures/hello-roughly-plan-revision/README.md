# hello-roughly-plan-revision

Fixture for the `/roughly:build --ci` plan-revision (NEEDS REVISION recovery) negative-path test (E06.S3, AC2).

## The Trigger

The task input asks the build orchestrator to author the task's **Verify** command using `grep -Fc "echo" src/greeter.sh` to assert the number of `echo` statements. `grep -Fc` counts matching *lines*, not occurrences, so it miscounts when multiple matches are co-located on the same line. This is the E05.S3 AC2 co-location anti-pattern, which `/roughly:review-plan` flags as NEEDS REVISION on the first pass. The orchestrator then revises the Verify to `grep -Fo "echo" src/greeter.sh | wc -l` (counts occurrences, immune to co-location) and review-plan PASSes.

## Expected `/roughly:build --ci` Input

> `"add a NAME constant to src/greeter.sh and update the echo to use it; in the plan, the task's Verify command MUST use grep -Fc \"echo\" src/greeter.sh to assert the number of echo statements equals 1"`

(The `grep -Fc` count-against-possibly-co-located-sites is the anti-pattern review-plan flags.)

## Expected Stage Transitions

- `/roughly:review-plan` dispatched ≥2×
- First verdict: NEEDS REVISION — cites E05.S3 AC2 (the `grep -Fc` co-location miscount: `grep -Fc` counts lines, not occurrences)
- Orchestrator revises the task's Verify to `grep -Fo "echo" src/greeter.sh | wc -l`
- Second verdict: PASS
- Stages 5–8 complete

## Expected Exit Signature

- Exit 0
- ≥2 `[--ci] plan review verdict:` markers in the transcript — first `NEEDS REVISION`, then `PASS`
- A plan file is written and (after Stage 8) carries a `> **Status:** Historical …` block on its first line
- `tests/greeter.test.sh` passes post-build (prints `hello world`)

## Determinism caveat

This trigger depends on (a) the orchestrator faithfully embedding the requested anti-pattern verify and (b) review-plan reliably flagging it. If the build pipeline's per-fixture validation shows this is not deterministic across runs, this scenario (AC2) is deferred to v0.1.9 as a spec-revision-candidate and the story ships AC1 + both controls only.
