**Fixture purpose:** AC4 NEEDS REVISION — plan adds guard before previously-reachable code path; plan classifies all documentation as "additive prose untouched" without auditing whether existing docs describe the now-unreachable behavior.

# Implementation Plan: Add API key validation guard to `runApiCall`

Plan-format-version: 1

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| `scripts/api_runner.sh` | edit | T1 |

## Tasks

### T1: Guard `runApiCall` against missing `$API_KEY` (~5 min)
**Files:** `scripts/api_runner.sh`
**Action:** Insert an early-exit guard at the entry of the existing `runApiCall` function. If `$API_KEY` is unset or empty, emit a warning and return without calling the API. This prevents credential-less requests from reaching the upstream service.
**Details:**
Edit site 1: `scripts/api_runner.sh` line 18 — insert guard block immediately after the function opening brace:
```
if [ -z "$API_KEY" ]; then
  warn 'API_KEY missing, skipping runApiCall'
  return 1
fi
```
This guard makes the `runApiCall` body unreachable when `$API_KEY` is empty. Previously, any caller (including those with no `$API_KEY` set) could reach the full function body; the function would proceed to call the API endpoint and surface the upstream auth failure.
Note: CONTRIBUTING.md is additive prose untouched — no changes required to documentation files.
**Verify:** `bash -c 'source scripts/api_runner.sh; API_KEY="" runApiCall'` exits with status 1 and prints the warning.
**UI:** no

## Notes
- The guard is a safety improvement; callers that previously passed an empty `$API_KEY` will now receive an early exit instead of an auth-failure response from the upstream API.
- CONTRIBUTING.md documents general contribution guidelines only; no documentation changes are needed for this patch.
