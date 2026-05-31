# review-plan Fixtures

Synthetic plan/skill-body fixtures exercising E04.S6's AC checks (AC1, AC2), E05.S3's 5 new
AC checks (AC1–AC5), and E05.S6's AC2 plan-level joint-satisfiability check, plus the AC3
case-dispatch convention codified in CONTRIBUTING.md. Used for pre-merge self-verification per
E04.S6 AC6 and E05.S3 BORDERLINE-PASS coverage.

**Fixture forms:** PASS (clean — no violation present, or carve-out unambiguously applies), NEEDS REVISION (clear violation with the AC cited by name in the verdict), BORDERLINE-PASS (legitimate plan structure exercising the AC's carve-out boundary — requires the reviewer to recognize substantive rationale, not just literal phrase matching). The BORDERLINE-PASS form was introduced in E05.S3 to protect against false-positive review-fatigue (epic Risk 3).

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
| `ac1-broader-scope-pass.md` | E05.S3 AC1 (verify-scope-vs-enumeration) | PASS | Verify scope matches enumeration scope (no asymmetry). |
| `ac1-broader-scope-needs-revision.md` | E05.S3 AC1 | NEEDS REVISION | Verify scope broader than enumeration with NO acknowledgment. |
| `ac1-broader-scope-borderline-pass.md` | E05.S3 AC1 | PASS | Asymmetry acknowledged with rationale-equivalent phrasing (close-but-not-identical to "intentionally broader than enumeration"); exercises carve-out boundary. |
| `ac2-grep-fc-pass.md` | E05.S3 AC2 (`grep -Fc` co-location) | PASS | Enumerated sites on physically distinct lines (markdown line-anchored headings, immune to co-location). |
| `ac2-grep-fc-needs-revision.md` | E05.S3 AC2 | NEEDS REVISION | `grep -Fc` verify against multi-site paragraph-dense prose; same-line co-location plausible. |
| `ac2-grep-fc-borderline-pass.md` | E05.S3 AC2 | PASS | `grep -Fc` against co-locatable region WITH explicit per-line distinctness rationale; exercises carve-out boundary. |
| `ac3-defensive-guard-pass.md` | E05.S3 AC3 (defensive-guard vs invariant) | PASS | Precondition guard for named invariant; no new invariant introduced. |
| `ac3-defensive-guard-needs-revision.md` | E05.S3 AC3 | NEEDS REVISION | New fourth invariant misclassified as "minor defensive addition" while AC forbids new invariants. |
| `ac3-defensive-guard-borderline-pass.md` | E05.S3 AC3 | PASS | Count-bounded check structurally derived from existing invariant; rationale invokes carve-out language; exercises boundary. |
| `ac4-doc-coverage-pass.md` | E05.S3 AC4 (behavior-divergence doc-coverage) | PASS | Greenfield carve-out (guard on brand-new code path; no prior documentation). |
| `ac4-doc-coverage-needs-revision.md` | E05.S3 AC4 | NEEDS REVISION | Guard makes previously-reachable behavior unreachable; existing CONTRIBUTING.md documents now-contradicted behavior; plan misclassifies as "additive prose untouched." |
| `ac4-doc-coverage-borderline-pass.md` | E05.S3 AC4 | PASS | Greenfield-equivalent carve-out with explicit documentation audit (grep-rn against docs/CONTRIBUTING.md/README.md); exercises boundary. |
| `ac5-self-defeating-pass.md` | E05.S3 AC5 (self-defeating verify) | PASS | Verify scope explicitly excludes the new-detection-prose location; literal absent from runtime files. |
| `ac5-self-defeating-needs-revision.md` | E05.S3 AC5 | NEEDS REVISION | Literal-form `grep -Fc` verify against same file containing new detection prose; new prose contributes to count, self-defeating. |
| `ac5-self-defeating-borderline-pass.md` | E05.S3 AC5 | PASS | `grep -v` exclusion with line-number-keyed sites; exhaustiveness debatable (could prefer structural-position verify); exercises boundary. |
| `ac-joint-satisfiability-pass.md` | E05.S6 AC2 (AC joint satisfiability) | PASS | Two ACs reference orthogonal surfaces (different files, different tasks, different prose regions); carve-out applies and the check skips. |
| `ac-joint-satisfiability-needs-revision.md` | E05.S6 AC2 | NEEDS REVISION | Two ACs target the same file + same step + same prose region; AC1 mandates one net-added line while AC2 forbids any net change to line count — structural impossibility. |

## How to Verify

`skills/review-plan/SKILL.md` carries `disable-model-invocation: true` (per ADR-001) — it is not
directly user-invocable as a slash command. The Stage 4 build/fix pipelines dispatch it
programmatically as a blocking subagent. AC6 verification therefore uses one of two practical paths:

**Path A — Manual desk-check (lowest-friction):**

Read each fixture and mentally apply the relevant check prose from `skills/review-plan/SKILL.md`:

- E04.S6 AC1 (Every edit site enumerated): line 36 — "Every edit site enumerated" + carve-out
- E04.S6 AC2 (Runtime-signal source named): line 53 — "Runtime-signal source named" + carve-out
- E05.S3 AC1 (verify-command scope matches spec enumeration): line 39 — asymmetry + carve-out
- E05.S3 AC2 (`grep -Fc` / `grep -Fn` same-line co-location hazard): line 42 — co-location + carve-out
- E05.S3 AC3 (defensive guard vs new invariant): line 56 — guard vs invariant + carve-out
- E05.S3 AC4 (behavior-divergence doc coverage): line 59 — doc coverage + carve-out
- E05.S3 AC5 (self-defeating verify pattern): line 45 — self-defeating + carve-out
- E05.S6 AC2 (AC joint satisfiability): line 62 — joint satisfiability + carve-out

For every fixture, confirm the expected verdict in the inventory table above matches what the
check prose would produce. For BORDERLINE-PASS fixtures, confirm the reviewer would recognize the
substantive rationale and return PASS rather than a false-positive NEEDS REVISION. Re-run this
desk-check whenever any AC wording changes in `skills/review-plan/SKILL.md`.

**Path B — Subagent dispatch (more rigorous, more setup):**

In a session with Roughly loaded, dispatch a general-purpose subagent and pass it both
`skills/review-plan/SKILL.md` and a single fixture as input. Instruct it to follow the skill's
verification process exactly and produce the structured PASS / NEEDS REVISION verdict. Repeat
per fixture. Required outcomes:

- Every `*-pass.md`, `*-carve-out-pass.md`, and `*-borderline-pass.md` → **PASS**
- Every `*-needs-revision.md` → **NEEDS REVISION** with the targeted AC cited by name (e.g.,
  "every edit site enumerated" for E04.S6 AC1, "runtime-signal source named" for E04.S6 AC2)

**AC3 fixtures** (`ac3-pass.md`, `ac3-needs-revision.md`) are skill-body excerpts, not plans.
AC3 lives in CONTRIBUTING.md as a contributor-facing authoring convention; the `/roughly:review-plan`
skill does NOT enforce it. These fixtures are reference artifacts for humans to read when authoring
or reviewing skills — not automated test inputs. Do not chase a missing AC3 verdict as a test gap.

## Note

Fixture content should be updated only when AC wording in `skills/review-plan/SKILL.md`
or `CONTRIBUTING.md` changes. Treat fixture drift as an indicator that the AC has materially
changed and warrants re-verification.
