**Fixture purpose:** AC4 BORDERLINE-PASS — plan adds guard before previously-reachable code WITH explicit greenfield-equivalent rationale citing documentation audit (exercises carve-out boundary).

# Implementation Plan: Add API key validation guard to `runApiCall` with documentation audit

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
This guard makes the `runApiCall` body unreachable when `$API_KEY` is empty. Previously, any caller with no `$API_KEY` set could reach the full function body.
**Verify:** `bash -c 'source scripts/api_runner.sh; API_KEY="" runApiCall'` exits with status 1 and prints the warning.
**UI:** no

## Documentation audit

Greenfield-equivalent: ran `grep -rn 'API_KEY missing' docs/ CONTRIBUTING.md README.md` and confirmed no prior documentation describes the now-unreachable behavior. No documentation revision required.

The audit covered all prose files that could describe `runApiCall` behavior for the empty-key case:
- `docs/` — no matches
- `CONTRIBUTING.md` — no matches
- `README.md` — no matches

Because no existing documentation describes the behavior of `runApiCall` when `$API_KEY` is unset, there is no prior documentation to contradict, revise, or remove. The greenfield-equivalent carve-out applies: AC4 does not fire.

## Notes
- The guard is a safety improvement preventing unnecessary upstream auth-failure round-trips.
- Documentation audit was performed before finalizing the plan; results are recorded above for reviewer verification.
