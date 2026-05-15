**Fixture purpose:** AC1 carve-out PASS (negative-control)

# Implementation Plan: Update abort-prose canonical block across all pipeline skills

Plan-format-version: 1

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| `skills/build/SKILL.md` | edit | T1 |
| `skills/fix/SKILL.md` | edit | T1 |
| `skills/review-plan/SKILL.md` | edit | T1 |
| `skills/setup/SKILL.md` | edit | T1 |

## Tasks

### T1: Replace abort-prose canonical block at all 27 sites (~15 min)
**Files:** `skills/build/SKILL.md`, `skills/fix/SKILL.md`, `skills/review-plan/SKILL.md`, `skills/setup/SKILL.md`
**Action:** Sweep all 27 abort-prose sites across the four pipeline skill files and replace each block with the updated canonical form.
**Details:**
Sweep all 27 abort-prose sites across `skills/build/SKILL.md` (12 sites), `skills/fix/SKILL.md` (13 sites), `skills/review-plan/SKILL.md` (1 site), and `skills/setup/SKILL.md` (1 site). structural uniformity: each site uses the byte-identical canonical block "emit `Stage [N] [stage] aborted: [reason]. ...`". Replace each block with the updated form using `Edit` calls scoped by the unique stage identifier on each occurrence.
**Verify:** `grep -c "aborted:" skills/build/SKILL.md` returns 12; total across all four files sums to 27.
**UI:** no
