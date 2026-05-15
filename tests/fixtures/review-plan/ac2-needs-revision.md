**Fixture purpose:** AC2 NEEDS REVISION — runtime detection with no named signal source

# Implementation Plan: Enable verbose logging when debug mode is active

Plan-format-version: 1

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| `scripts/runner.sh` | edit | T1 |

## Tasks

### T1: Conditionally enable verbose logging (~4 min)
**Files:** `scripts/runner.sh`
**Action:** Add a conditional that enables verbose logging when debug mode is active and keeps the default minimal-output mode otherwise.
**Details:**
Edit site 1: `scripts/runner.sh` line 18 — insert debug-mode check before the main run loop.
If the config file indicates debug mode is active, enable verbose logging. Otherwise, keep the default minimal-output behavior.
Edit site 2: `scripts/runner.sh` line 35 — add the verbose-output branch under the conditional.
**Verify:** Toggle the debug-mode setting that the Edit site 1 conditional reads; run the script in both states. Confirm `grep -c '^\[DEBUG\]' runner.log` ≥ 1 in the debug-active state and `grep -c '^\[DEBUG\]' runner.log` == 0 otherwise. (This verify step depends on the conditional's signal source — making the AC2 violation block verification as well as implementation.)
**UI:** no
