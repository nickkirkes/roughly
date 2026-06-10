# hello-roughly-build-abort-control

Fixture for the `/roughly:build --ci` build-abort *control* test.

## The Control

The identical task to `hello-roughly-build-abort`, but with a *satisfiable* test. Confirms the abort trigger is the rigged test, not "every build aborts." The same task that aborts against the rigged fixture completes the full pipeline here.

## Expected `/roughly:build --ci` Input

> `"add a NAME constant to src/greeter.sh and update the echo to use it"`

## Expected Stage Transitions

- Stages 1–8 complete in one pass
- Single Task
- `/roughly:review-plan` PASSes on first pass
- No Stage 6 cubic cycles
- No NEEDS REVISION
- No abort

## Expected Exit Signature

- Exit 0
- A plan file `.roughly/plans/*-plan.md` is written and (after Stage 8) carries a `> **Status:** Historical …` block on its first line
- `tests/greeter.test.sh` passes post-build (prints `hello world`)
