# hello-roughly-build-abort

Fixture for the `/roughly:build --ci` build-abort negative-path test.

## The Trigger

`tests/greeter.test.sh` is structurally unsatisfiable: it asserts the greeter output equals two distinct strings (`hello world` and `goodbye world`) at once. No possible `src/greeter.sh` can satisfy this contradiction, so every implementation fails the Verify command.

## Expected `/roughly:build --ci` Input

A normal task; the rigged test is what aborts:

> `"add a NAME constant to src/greeter.sh and update the echo to use it"`

## Expected Stage Transitions

- Stages 1–4 complete
- At Stage 5c the Verify (`bash tests/greeter.test.sh`) fails every attempt
- Auto-fix cap reached after 2 attempts (test-type failure)
- The abort-and-escalate path fires
- Build does NOT reach Stage 8

## Expected Exit Signature

- The Stage 5c escalation marker `cannot proceed: auto-fix cap reached on` is present in the transcript
- NO `> **Status:** Historical` plan-historical marking (build never reaches Stage 8)
- Process exit code to be confirmed empirically (the build pipeline's own validation step calibrates whether the abort yields exit 0-with-marker or non-zero)
