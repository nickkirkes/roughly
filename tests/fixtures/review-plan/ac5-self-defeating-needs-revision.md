**Fixture purpose:** AC5 NEEDS REVISION — verify command greps for a literal that is intentionally present in the new detection prose; self-defeating.

# Implementation Plan: Add legacy-state detection block to build pipeline

Plan-format-version: 1

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| `skills/build/SKILL.md` | edit | T1 |

## Tasks

### T1: Add legacy-state detection prose to build SKILL.md (~6 min)
**Files:** `skills/build/SKILL.md`
**Action:** Insert a new Stage 2a pre-flight block that outputs a "legacy-state detected" message when a deprecated config key is present, and document the expected trigger count so a count-based verify can catch regressions.
**Details:**
Edit site 1: `skills/build/SKILL.md` Stage 2, after the "Read project CLAUDE.md" step — insert:

```
**Stage 2a — Deprecated config pre-flight**
Read `.roughly/config.json`. If the key `legacyMode` is present and truthy, halt and output:
  "legacy-state detected: remove `legacyMode` from .roughly/config.json before proceeding"
If the key `deprecatedRegistry` is present, halt and output:
  "legacy-state detected: replace `deprecatedRegistry` with `registry` in .roughly/config.json"
```

The phrase "legacy-state detected" now appears twice in the new detection block (once per error branch). It also appears once in the existing Stage 5 rollback note ("legacy-state detected during rollback...") added in a prior sprint. Total occurrences in `skills/build/SKILL.md` after this edit: 3.

**Verify:** `test $(grep -Fc "legacy-state detected" skills/build/SKILL.md) -eq 3`

Note: the plan author intends this count-based verify to confirm exactly 3 occurrences are present (2 new + 1 pre-existing). However, the 2 new occurrences are inside the detection prose itself — they are instructional/error-message text, not runtime trigger points. If a future edit adds or removes a detection branch, the count will drift and the verify will fail spuriously. More critically, the verify conflates the detection-prose occurrences (self-reference sites in `skills/build/SKILL.md`) with any actual runtime trigger wiring — there is no separate runtime file being checked.
**UI:** no
