**Fixture purpose:** E06.S4 AC1 PASS — AC quotes wording containing metasyntactic notation (`<reason>` placeholder) AND carries the appropriate `form:` marker, satisfying the marker convention.

# Implementation Plan: Add agent failure-message format requirement

Plan-format-version: 1

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| `agents/example-agent.md` | edit | T1 |

## Tasks

### T1: Add failure-message format MUST line to agent prompt (~3 min)
**Files:** `agents/example-agent.md`
**Action:** Add a new MUST line under `## Failure handling` stating that the agent's failure return must begin with the form `form: "example-agent: failed — <reason> (<path>)" (adapt for clarity)`. The `<reason>` and `<path>` are structural placeholders; the implementer chooses concrete content per failure mode. The `form:` marker signals that the bracketed placeholders are illustrative of the structural form, not literal text.
**Details:** Insert the MUST line as a new bullet under the existing `## Failure handling` heading in `agents/example-agent.md`.
**Verify:** `grep -Fn "example-agent: failed —" agents/example-agent.md` returns ≥1 match.
**UI:** no
