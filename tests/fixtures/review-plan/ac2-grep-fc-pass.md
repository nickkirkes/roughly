**Fixture purpose:** AC2 PASS — grep -Fc verify counts sites on physically distinct lines (immune to co-location).

# Implementation Plan: Add T5–T8 task headings to sprint plan

Plan-format-version: 1

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| `docs/plans/sprint-12.md` | edit | T1 |

## Tasks

### T1: Append four new task headings to sprint-12 plan (~5 min)
**Files:** `docs/plans/sprint-12.md`
**Action:** Add four new task headings of the form `### T[N]: <title>` to the end of `docs/plans/sprint-12.md`. The file currently ends at T4; this task appends T5 through T8.
**Details:**
Edit site 1: `docs/plans/sprint-12.md` end-of-file — append `### T5: Migrate auth module to new provider`.
Edit site 2: `docs/plans/sprint-12.md` end-of-file — append `### T6: Add retry logic to API client`.
Edit site 3: `docs/plans/sprint-12.md` end-of-file — append `### T7: Update database connection pool config`.
Edit site 4: `docs/plans/sprint-12.md` end-of-file — append `### T8: Write integration tests for billing flow`.

Each heading is a top-level `### T[N]:` line. Markdown heading syntax requires headings to occupy their own line (a `###` prefix must appear at the start of the line with no preceding content on that line). The four new headings are therefore guaranteed to each occupy a physically distinct line — co-location with any other heading is structurally impossible.

**Verify:** `test $(grep -Fc "### T" docs/plans/sprint-12.md) -eq 8`

The verify uses `grep -Fc` (fires the AC2 trigger). The pattern `### T` matches each `### T[N]:` heading once; markdown heading syntax requires each `###` prefix to begin its own line, so every occurrence is on a physically distinct line. `grep -Fc` (which counts matching lines, not occurrences) returns the correct count because one-per-line is guaranteed by markdown structure — the carve-out applies and AC2 PASSes for the right reason.

**UI:** no
