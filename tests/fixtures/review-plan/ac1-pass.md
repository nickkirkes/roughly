**Fixture purpose:** AC1 PASS

# Implementation Plan: Rename `oldFn` to `newFn` across module boundary

Plan-format-version: 1

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| `src/foo.ts` | edit | T1 |
| `src/bar.ts` | edit | T1 |

## Tasks

### T1: Rename `oldFn` to `newFn` (~3 min)
**Files:** `src/foo.ts`, `src/bar.ts`
**Action:** Rename all occurrences of `oldFn` to `newFn` across both files.
**Details:**
Edit site 1: `src/foo.ts` line 10 — rename `oldFn` to `newFn`.
Edit site 2: `src/foo.ts` line 25 — rename second occurrence of `oldFn` to `newFn`.
Edit site 3: `src/bar.ts` line 40 — update import path from `./foo-old` to `./foo`.
**Verify:** `grep -r "oldFn" src/` returns no results.
**UI:** no
