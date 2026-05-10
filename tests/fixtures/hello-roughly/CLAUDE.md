# hello-roughly

Minimal fixture project for Roughly's CI dogfood scenario (E03.S11b-2). Not a Roughly install — this is the *target* that `/roughly:build --ci` operates on.

## Stack
Bash. No package manager, no compile step.

## Build / Test
- Build: none (shell scripts run directly)
- Type check: `bash -n src/greeter.sh` (syntax check)
- Test: `bash tests/greeter.test.sh`

## Conventions
- Source files in `src/`
- Tests in `tests/`, named `*.test.sh`
