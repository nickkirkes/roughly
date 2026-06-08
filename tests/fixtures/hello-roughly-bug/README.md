# hello-roughly-bug

Fixture for the `/roughly:fix --ci` happy-path test.

## The Bug

`src/greeter.sh` references `$NMAE` (typo) instead of `$NAME`, so it prints `hello ` instead of `hello world`.

## Expected `/roughly:fix --ci` Input

Direct description form:

> `"src/greeter.sh prints 'hello ' instead of 'hello world' — variable reference typo in the echo"`

## Expected Stage Transitions

- Stages 1–8 complete in one pass
- Single Task
- `/roughly:review-plan` PASSes on first pass
- No Stage 6 cubic cycles
- No NEEDS REVISION

## Expected Exit Signature

- Exit 0
- A plan file `.roughly/plans/fix-*-plan.md` is written and (after Stage 8) carries a `> **Status:** Historical …` block on its first line
- `tests/greeter.test.sh` passes post-fix (prints `hello world`)
