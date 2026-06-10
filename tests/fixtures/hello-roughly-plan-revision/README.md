# hello-roughly-plan-revision

Fixture for the `/roughly:build --ci` plan-revision (NEEDS REVISION recovery) negative-path test (E06.S3, AC2).

## The Trigger

The task input asks the build orchestrator to put **two occurrences of the word `world` on a single `echo` line** and to author the task's **Verify** command as `grep -Fc world src/greeter.sh` asserting the count `= 2`. `grep -Fc` counts matching *lines*, not occurrences, so the two co-located matches return `1`, not `2`. This is the E05.S3 AC2 same-line co-location anti-pattern, which `/roughly:review-plan` flags as NEEDS REVISION on the first pass.

The two occurrences must be **co-located on one line** for the trigger to fire: a single occurrence on its own line (or N occurrences each on a distinct line) falls under the review-plan AC2 carve-out and PASSes on the first pass — never exercising the recovery loop. The orchestrator revises the Verify to `grep -Fo world src/greeter.sh | wc -l` (counts occurrences, immune to co-location) and review-plan PASSes.

## Expected `/roughly:build --ci` Input

> `"update src/greeter.sh so its single echo statement prints the greeting word \"world\" twice on the same line (for example: echo \"hello world, goodbye world\"); in the plan, the task's Verify command MUST use grep -Fc world src/greeter.sh to assert the number of \"world\" occurrences equals 2"`

(Two `world` occurrences co-located on one line, counted with `grep -Fc` — the same-line co-location anti-pattern review-plan flags.)

## Expected Stage Transitions

- `/roughly:review-plan` dispatched ≥2×
- First verdict: NEEDS REVISION — cites E05.S3 AC2 (the `grep -Fc` same-line co-location miscount: two `world` occurrences on one line, `grep -Fc` counts lines not occurrences → returns 1, not the asserted 2)
- Orchestrator revises the task's Verify to `grep -Fo world src/greeter.sh | wc -l`
- Second verdict: PASS
- Stages 5–8 complete

## Expected Exit Signature

- Exit 0
- ≥2 `[--ci] plan review verdict:` markers in the transcript — first `NEEDS REVISION`, then `PASS`
- A plan file is written and (after Stage 8) carries a `> **Status:** Historical …` block on its first line
- `tests/greeter.test.sh` passes post-build (the echo prints `world` twice, e.g. `hello world, goodbye world`)

## Determinism caveat

This trigger depends on (a) the orchestrator faithfully embedding the requested co-located anti-pattern verify and (b) review-plan reliably flagging it. If the build pipeline's per-fixture validation shows this is not deterministic across runs, this scenario (AC2) is deferred to v0.1.9 as a spec-revision-candidate and the story ships AC1 + both controls only.
