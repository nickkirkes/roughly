**Fixture purpose:** AC joint satisfiability PASS — two ACs reference orthogonal surfaces (different files, different steps, different prose regions); carve-out applies.

# Implementation Plan (FX01): Add unrelated guards to two independent subsystems

Plan-format-version: 1

## Acceptance Criteria (from epic)

**AC1:** `scripts/log-rotate.sh` must refuse to rotate when the target log file is currently open by another process (detected via `lsof`). Implementation lives entirely in `scripts/log-rotate.sh`.

**AC2:** `docs/onboarding.md` must include a `## Prerequisites` section listing three required CLI tools (`jq`, `lsof`, `awk`). Implementation lives entirely in `docs/onboarding.md`.

## File Table

| File | Action | Task(s) |
|------|--------|---------|
| `scripts/log-rotate.sh` | edit | T1 |
| `docs/onboarding.md` | edit | T2 |

## Tasks

### T1: Add open-file guard to log-rotate.sh (~6 min)
**Files:** `scripts/log-rotate.sh`
**Action:** Before the rotation block, insert `lsof "$LOG_FILE" >/dev/null && { echo "log in use"; exit 1; }`.
**Verify:** `bash -n scripts/log-rotate.sh` exits 0.
**UI:** no

### T2: Add Prerequisites section to onboarding.md (~4 min)
**Files:** `docs/onboarding.md`
**Action:** Append a new `## Prerequisites` section listing `jq`, `lsof`, `awk`. **Verify:** `grep -Fq "## Prerequisites" docs/onboarding.md`. **UI:** no
