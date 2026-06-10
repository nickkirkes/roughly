# hello-roughly-build-abort

Minimal fixture project for Roughly's CI dogfood build-abort negative-path scenario (E06.S3). Not a Roughly install — the target that `/roughly:build --ci` operates on. The test is intentionally unsatisfiable to exercise the Stage 5c auto-fix-cap abort.

## Stack
Bash. No package manager, no compile step.

## Build / Test
- Build: none (shell scripts run directly)
- Type check: `bash -n src/greeter.sh` (syntax check)
- Test: `bash tests/greeter.test.sh`

## Conventions
- Source files in `src/`
- Tests in `tests/`, named `*.test.sh`
