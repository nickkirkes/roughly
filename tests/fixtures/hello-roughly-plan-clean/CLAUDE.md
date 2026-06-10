# hello-roughly-plan-clean

Minimal fixture project for Roughly's CI dogfood plan-clean *control* scenario (E06.S3). Not a Roughly install — the target that `/roughly:build --ci` operates on. Clean task description — review-plan PASSes on the first pass (control for the plan-revision recovery scenario).

## Stack
Bash. No package manager, no compile step.

## Build / Test
- Build: none (shell scripts run directly)
- Type check: `bash -n src/greeter.sh` (syntax check)
- Test: `bash tests/greeter.test.sh`

## Conventions
- Source files in `src/`
- Tests in `tests/`, named `*.test.sh`
