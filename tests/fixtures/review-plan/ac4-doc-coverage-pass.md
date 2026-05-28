**Fixture purpose:** AC4 PASS — plan adds guard to brand-new code path with no prior documentation (greenfield carve-out applies).

# Implementation Plan: Add cache check to new `fetchUserProfile` function

Plan-format-version: 1

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| `src/services/userProfile.ts` | create | T1 |
| `src/services/profileCache.ts` | create | T1 |

## Tasks

### T1: Create `fetchUserProfile` with cache guard (~10 min)
**Files:** `src/services/userProfile.ts`, `src/services/profileCache.ts`
**Action:** Create a brand-new `fetchUserProfile` function in a newly-created file. The function does not exist anywhere in the codebase today. Add a `cacheCheck` guard as the first call inside the function so that warm-cache responses bypass the network fetch.
**Details:**
Edit site 1: `src/services/profileCache.ts` (new file) — implement `ProfileCache` class with `get(userId)` and `set(userId, profile)` methods.
Edit site 2: `src/services/userProfile.ts` (new file) — implement `fetchUserProfile(userId: string)` function. First line of function body: `const cached = cacheCheck(userId); if (cached) return cached;`. Remaining body: issue network request, store result in cache, return result.
Note: Greenfield addition — no prior documentation existed for the unguarded behavior because the function is new. The `fetchUserProfile` function has never shipped, so no documentation describes the behavior of calling it without a cache guard. AC4 does not fire.
**Verify:** `grep -r "fetchUserProfile" src/` returns results only in the two new files.
**UI:** no
