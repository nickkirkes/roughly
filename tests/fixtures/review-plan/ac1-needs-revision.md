**Fixture purpose:** AC1 NEEDS REVISION

# Implementation Plan: Migrate `legacyApi` to `newApi` in widget module

Plan-format-version: 1

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| `src/widget.ts` | edit | T1 |

## Tasks

### T1: Replace `legacyApi` calls with `newApi` (~5 min)
**Files:** `src/widget.ts`
**Action:** Replace all usages of `legacyApi` with `newApi` and update the return type annotation.
**Details:**
Edit site 1: `src/widget.ts` line 30 — replace `legacyApi` call with `newApi`.
Edit site 2: `src/widget.ts` line 65 — update return type annotation from `LegacyResult` to `NewResult`.
Note: there may be an additional site near line 90 — confirm during edit.
**Verify:** `grep "legacyApi" src/widget.ts` returns no results.
**UI:** no
