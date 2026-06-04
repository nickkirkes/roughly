**Fixture purpose:** E06.S4 AC1 NEEDS REVISION — AC quotes wording containing metasyntactic notation (`<reason>` placeholder and trailing `…`) but carries NO marker.

# Implementation Plan: Add agent failure-message format requirement

Plan-format-version: 1

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| `agents/example-agent.md` | edit | T1 |

## Tasks

### T1: Add failure-message format MUST line to agent prompt (~3 min)
**Files:** `agents/example-agent.md`
**Action:** Add a new MUST line under `## Failure handling` stating that the agent's failure return must begin with `"example-agent: failed — <reason> …"`. The implementer should figure out what to do with the bracketed `<reason>` and trailing `…`.
**Details:** Insert the MUST line as a new bullet under the existing `## Failure handling` heading in `agents/example-agent.md`.
**Verify:** `grep -Fn "example-agent: failed —" agents/example-agent.md` returns ≥1 match.
**UI:** no
