**Fixture purpose:** AC1 BORDERLINE-PASS — verify scope broader than enumeration WITH acknowledgment using close-but-not-identical phrasing (exercises carve-out boundary).

# Implementation Plan: Rename `abort-prose` to `abort-block` in build and fix skills

Plan-format-version: 1

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| `skills/build/SKILL.md` | edit | T1 |
| `skills/fix/SKILL.md` | edit | T1 |

## Notes

The verify command for T1 searches the entire `skills/` directory rather than only the two enumerated files. This is done because the term `abort-prose` may appear in adjacent skill files (e.g., `skills/review-plan/SKILL.md`, `skills/setup/SKILL.md`) as cross-references or comments. The verify intentionally exceeds the enumeration scope to catch any newly-introduced edit sites in adjacent skill files — if any such occurrences surface during the search, the implementer must evaluate whether they also require renaming before the task can be considered complete.

## Tasks

### T1: Rename all occurrences of `abort-prose` to `abort-block` in build and fix skills (~10 min)
**Files:** `skills/build/SKILL.md`, `skills/fix/SKILL.md`
**Action:** Replace every occurrence of the term `abort-prose` with `abort-block` across both pipeline skill files.
**Details:**
Edit site 1: `skills/build/SKILL.md` — use a global find-and-replace for the string `abort-prose`; expect approximately 14 occurrences across Stage headers, inline prose, and the canonical block definition.
Edit site 2: `skills/fix/SKILL.md` — use a global find-and-replace for the string `abort-prose`; expect approximately 13 occurrences across the same structural positions.
**Verify:** `rg -Fn "abort-prose" skills/`
**UI:** no
