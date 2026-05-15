# review-plan Fixtures

Synthetic plan/skill-body fixtures exercising E04.S6's new review-plan AC checks (AC1, AC2)
and the AC3 case-dispatch convention codified in CONTRIBUTING.md. Used for pre-merge
self-verification per E04.S6 AC6.

## Fixture Inventory

| File | Targets | Expected verdict | Reason |
|------|---------|------------------|--------|
| `ac1-pass.md` | AC1 (Completeness — Every edit site enumerated) | PASS | All 3 edit sites are enumerated as separate numbered entries; no "confirm during edit" footnote. |
| `ac1-needs-revision.md` | AC1 | NEEDS REVISION | Defers a third site via "confirm during edit" footnote — the surfacing-failure pattern AC1 catches. |
| `ac1-carve-out-pass.md` | AC1 (carve-out) | PASS | Consolidated enumeration is permitted because the plan body explicitly invokes "structural uniformity" and names the count (27) and pattern. |
| `ac2-pass.md` | AC2 (Assumptions — Runtime-signal source named) | PASS | Names the signal source explicitly (`git rev-parse --git-dir` and its exit code). |
| `ac2-needs-revision.md` | AC2 | NEEDS REVISION | Ungrounded conditional ("if the config file indicates debug mode is active") — no signal source named (which file? which field? which value?). |
| `ac3-pass.md` | AC3 (CONTRIBUTING.md — case-dispatch convention) | PASS (human-read) | Uses explicit "evaluate top-to-bottom" prose ahead of Cases A/B/C. |
| `ac3-needs-revision.md` | AC3 | NEEDS REVISION (human-read) | Fall-through prose invites cumulative case execution. |

## How to Verify

`skills/review-plan/SKILL.md` carries `disable-model-invocation: true` (per ADR-001) — it is not
directly user-invocable as a slash command. The Stage 4 build/fix pipelines dispatch it
programmatically as a blocking subagent. AC6 verification therefore uses one of two practical paths:

**Path A — Manual desk-check (lowest-friction):**

Read each AC1/AC2 fixture and mentally apply the new check prose from
`skills/review-plan/SKILL.md`:
- AC1: lines 36–37 — "Every edit site enumerated" + carve-out
- AC2: lines 44–45 — "Runtime-signal source named" + carve-out

For every fixture, confirm the expected verdict in the inventory table above matches what the
check prose would produce. Re-run this desk-check whenever AC1 or AC2 wording changes in
`skills/review-plan/SKILL.md`.

**Path B — Subagent dispatch (more rigorous, more setup):**

In a session with Roughly loaded, dispatch a general-purpose subagent and pass it both
`skills/review-plan/SKILL.md` and a single fixture as input. Instruct it to follow the skill's
verification process exactly and produce the structured PASS / NEEDS REVISION verdict. Repeat
per fixture. Required outcomes:

- Every `*-pass.md` and `*-carve-out-pass.md` → **PASS**
- Every `*-needs-revision.md` → **NEEDS REVISION** with the targeted AC cited by name (e.g.,
  "every edit site enumerated" for AC1, "runtime-signal source named" for AC2)

**AC3 fixtures** (`ac3-pass.md`, `ac3-needs-revision.md`) are skill-body excerpts, not plans.
AC3 lives in CONTRIBUTING.md as a contributor-facing authoring convention; the `/roughly:review-plan`
skill does NOT enforce it. These fixtures are reference artifacts for humans to read when authoring
or reviewing skills — not automated test inputs. Do not chase a missing AC3 verdict as a test gap.

## Note

Fixture content should be updated only when AC1/AC2/AC3 wording in `skills/review-plan/SKILL.md`
or `CONTRIBUTING.md` changes. Treat fixture drift as an indicator that the AC has materially
changed and warrants re-verification.
