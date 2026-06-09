# hello-roughly-plan-clean

Fixture for the `/roughly:build --ci` plan-clean control test (E06.S3).

## The Control

A normal task with no anti-pattern instruction — review-plan PASSes on the first pass. Confirms the plan-revision trigger isn't "every plan triggers NEEDS REVISION."

## Expected `/roughly:build --ci` Input

Direct description form:

> `"add a NAME constant to src/greeter.sh and update the echo to use it"`

## Expected Stage Transitions

- Exactly 1 `/roughly:review-plan` dispatch
- Verdict PASS
- No NEEDS REVISION
- Stages 5–8 complete

## Expected Exit Signature

- Exit 0
- Exactly 1 `[--ci] plan review verdict: PASS` marker in the transcript
- No NEEDS REVISION marker
- A plan file is written and (after Stage 8) carries a `> **Status:** Historical …` block on its first line
