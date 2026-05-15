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
| `ac2-needs-revision.md` | AC2 | NEEDS REVISION | Ungrounded conditional ("if the user is in CI") — no signal source named. |
| `ac3-pass.md` | AC3 (CONTRIBUTING.md — case-dispatch convention) | PASS (human-read) | Uses explicit "evaluate top-to-bottom" prose ahead of Cases A/B/C. |
| `ac3-needs-revision.md` | AC3 | NEEDS REVISION (human-read) | Fall-through prose invites cumulative case execution. |

## How to Verify

**AC1 and AC2 fixtures** are enforced by the `/roughly:review-plan` skill. Run it against each
fixture file:

```
claude /roughly:review-plan tests/fixtures/review-plan/ac1-pass.md
claude /roughly:review-plan tests/fixtures/review-plan/ac1-needs-revision.md
# ... repeat for ac1-carve-out-pass.md, ac2-pass.md, ac2-needs-revision.md
```

Required outcomes:
- Every `*-pass.md` and `*-carve-out-pass.md` → skill returns **PASS**
- Every `*-needs-revision.md` → skill returns **NEEDS REVISION** with the targeted AC cited by
  name (e.g., "every edit site enumerated" for AC1, "runtime-signal source named" for AC2)

**AC3 fixtures** (`ac3-pass.md`, `ac3-needs-revision.md`) are skill-body excerpts, not plans.
AC3 lives in CONTRIBUTING.md as a contributor-facing authoring convention; the `/roughly:review-plan`
skill does NOT enforce it. These fixtures are reference artifacts for humans to read when authoring
or reviewing skills — not automated test inputs. Do not chase a missing AC3 verdict as a test gap.

## Note

Fixture content should be updated only when AC1/AC2/AC3 wording in `skills/review-plan/SKILL.md`
or `CONTRIBUTING.md` changes. Treat fixture drift as an indicator that the AC has materially
changed and warrants re-verification.
