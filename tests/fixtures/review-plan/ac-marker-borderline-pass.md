**Fixture purpose:** E06.S4 AC1 BORDERLINE-PASS — AC quotes wording containing metasyntactic notation (`<reason>` placeholder) and carries a close-but-not-identical marker (`literal:` instead of `verbatim:`) (exercises marker-intent-sub-carve-out boundary).

# Implementation Plan: Add agent failure-message format requirement

Plan-format-version: 1

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| `agents/example-agent.md` | edit | T1 |

## Notes

The marker used in T1 below (`literal:`) is close-but-not-identical to the enumerated `verbatim:` marker from E06.S4 AC1. The intent is unambiguous (the AC explicitly states "must match byte-for-byte at implementation"), so per the AC quoted-wording marker carve-out, marker intent supersedes literal-name match. This exercises the carve-out boundary of the convention.

## Tasks

### T1: Add failure-message format MUST line to agent prompt (~3 min)
**Files:** `agents/example-agent.md`
**Action:** Add a new MUST line under `## Failure handling` stating that the agent's failure return must begin with `literal: "example-agent: failed — <reason>"` — the text must match byte-for-byte at implementation, with `<reason>` substituted per failure mode.
**Details:** Insert the MUST line as a new bullet under the existing `## Failure handling` heading in `agents/example-agent.md`.
**Verify:** `grep -Fn "example-agent: failed —" agents/example-agent.md` returns ≥1 match.
**UI:** no
