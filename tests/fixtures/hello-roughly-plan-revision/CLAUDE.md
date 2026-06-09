# hello-roughly-plan-revision

Minimal fixture project for Roughly's CI dogfood plan-revision (NEEDS REVISION recovery) negative-path scenario (E06.S3). Not a Roughly install — the target that `/roughly:build --ci` operates on. The task input steers the orchestrator to author a verify command with the E05.S3 AC2 `grep -Fc` co-location anti-pattern, which review-plan flags as NEEDS REVISION on the first pass.

## Stack
Bash. No package manager, no compile step.

## Build / Test
- Build: none (shell scripts run directly)
- Type check: `bash -n src/greeter.sh` (syntax check)
- Test: `bash tests/greeter.test.sh`

## Conventions
- Source files in `src/`
- Tests in `tests/`, named `*.test.sh`
