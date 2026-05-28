**Fixture purpose:** AC1 PASS — verify command scope matches enumeration scope (no asymmetry to detect).

# Implementation Plan: Add `## Migration Notes` heading to four changelog files

Plan-format-version: 1

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| `docs/changelogs/v1.md` | edit | T1 |
| `docs/changelogs/v2.md` | edit | T1 |
| `docs/changelogs/v3.md` | edit | T1 |
| `docs/changelogs/v4.md` | edit | T1 |

## Tasks

### T1: Insert `## Migration Notes` heading into all four changelog files (~8 min)
**Files:** `docs/changelogs/v1.md`, `docs/changelogs/v2.md`, `docs/changelogs/v3.md`, `docs/changelogs/v4.md`
**Action:** Add a `## Migration Notes` heading (with a trailing placeholder line) to each of the four versioned changelog files. Insert immediately after the top-level `# Changelog: vN` heading.
**Details:**
Edit site 1: `docs/changelogs/v1.md` — insert `## Migration Notes\n\n_No breaking migrations in this release._` after line 1.
Edit site 2: `docs/changelogs/v2.md` — insert `## Migration Notes\n\n_No breaking migrations in this release._` after line 1.
Edit site 3: `docs/changelogs/v3.md` — insert `## Migration Notes\n\n_No breaking migrations in this release._` after line 1.
Edit site 4: `docs/changelogs/v4.md` — insert `## Migration Notes\n\n_No breaking migrations in this release._` after line 1.
**Verify:** `for f in docs/changelogs/v1.md docs/changelogs/v2.md docs/changelogs/v3.md docs/changelogs/v4.md; do grep -Fq "## Migration Notes" "$f" || exit 1; done && echo OK`
**UI:** no
