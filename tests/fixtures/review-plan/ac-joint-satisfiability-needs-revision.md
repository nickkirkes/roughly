**Fixture purpose:** AC joint satisfiability NEEDS REVISION — two ACs touch the same file, same step, same prose region with a structural impossibility (AC1 requires net-add; AC2 forbids any net change to line count).

# Implementation Plan (FX02): Add deprecation warning to config-loader.sh

Plan-format-version: 1

## Acceptance Criteria (from epic)

**AC1:** `scripts/config-loader.sh` must emit a deprecation warning line (`echo "WARNING: legacy config format" >&2`) inserted immediately above the existing `parse_config` call at line 42 of `scripts/config-loader.sh`.

**AC2:** `scripts/config-loader.sh` must preserve its current line count exactly (no net additions, no net deletions) so that downstream tooling that hard-codes line offsets into `scripts/config-loader.sh` continues to function unchanged.

## File Table

| File | Action | Task(s) |
|------|--------|---------|
| `scripts/config-loader.sh` | edit | T1 |

## Tasks

### T1: Insert deprecation warning above parse_config (~3 min)
**Files:** `scripts/config-loader.sh`
**Action:** Insert `echo "WARNING: legacy config format" >&2` immediately above line 42 (the `parse_config` call) in `scripts/config-loader.sh`.
**Verify:** `grep -Fc 'WARNING: legacy config format' scripts/config-loader.sh` returns `1`.
**UI:** no

### T2: (none — single-task plan)

Expected verdict: NEEDS REVISION citing "joint satisfiability" — AC1 and AC2 both target `scripts/config-loader.sh` within T1 (same file, same step, same prose region). AC1 mandates one net-added line; AC2 forbids any net change to line count. The two ACs are not jointly satisfiable within the plan's implementation scope.
