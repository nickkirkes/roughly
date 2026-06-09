# hello-roughly-build-abort-control

Minimal fixture project for Roughly's CI dogfood build-abort *control* scenario (E06.S3). Not a Roughly install — the target that `/roughly:build --ci` operates on. Satisfiable test — confirms the abort trigger is the rigged test, not every build.

## Stack
Bash. No package manager, no compile step.

## Build / Test
- Build: none (shell scripts run directly)
- Type check: `bash -n src/greeter.sh` (syntax check)
- Test: `bash tests/greeter.test.sh`

## Conventions
- Source files in `src/`
- Tests in `tests/`, named `*.test.sh`
