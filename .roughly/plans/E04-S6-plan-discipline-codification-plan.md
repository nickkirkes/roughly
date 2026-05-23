> **Status:** Historical — implemented and merged in commit 9a18161f8087240a436a5d56d7cf592f95dd0936 on 2026-05-15. This plan was an active build/fix artifact; treat as historical reference only.

# Implementation Plan: E04.S6 — Plan-discipline codification

Plan-format-version: 1

## File Table

| File | Action | Task(s) |
|------|--------|---------|
| skills/review-plan/SKILL.md | Modify | T1, T2 |
| CONTRIBUTING.md | Modify | T3 |
| tests/fixtures/review-plan/ac1-pass.md | Create | T4 |
| tests/fixtures/review-plan/ac1-needs-revision.md | Create | T4 |
| tests/fixtures/review-plan/ac1-carve-out-pass.md | Create | T4 |
| tests/fixtures/review-plan/ac2-pass.md | Create | T5 |
| tests/fixtures/review-plan/ac2-needs-revision.md | Create | T5 |
| tests/fixtures/review-plan/ac3-pass.md | Create | T6 |
| tests/fixtures/review-plan/ac3-needs-revision.md | Create | T6 |
| tests/fixtures/review-plan/README.md | Create | T7 |

## Tasks

### T1: Add AC1 (edit-site enumeration) check to review-plan/SKILL.md (~5 min)
**Files:** skills/review-plan/SKILL.md
**Action:** Add a new check bullet to the **Completeness** dimension block (currently lines 31–35) covering edit-site enumeration and the structural-uniformity carve-out.
**Details:** Insert a new bullet at the end of the Completeness block (after line 35, before the blank line preceding Assumptions). The bullet must:
- Use the existing `- **Bold lead phrase.**` pattern (compare lines 86–92 Rules section)
- Lead phrase: `**Every edit site enumerated.**`
- State the rule: when a task description enumerates edit sites (line numbers, file ranges, named blocks), every site must appear as a separately numbered entry. Reject "confirm during edit" footnotes — they are surfacing-failure traps.
- Include the bright-line carve-out: consolidated enumeration is allowed only when the plan body explicitly contains the phrase "structural uniformity" (or an equivalent explicit phrase) AND names the count and pattern (e.g., "27 abort-prose sites, byte-identical canonical block"). Outside that exact form, per-site enumeration is required.
- Cite the canonical positive example: E03.S9 implementation plan (`docs/plans/E03-S9-abort-prose-plan.md`) — 27-site enumeration.
- Cite the canonical negative example: E03.S9 cycle-1 stranded summary at build L185 / fix L192 (recorded in `.roughly/known-pitfalls.md` and commit `015bb4d`).
- Keep the bullet under 8 lines (markdown source) to maintain readability alongside the existing 4-line Completeness bullets — break across multiple sub-bullets if needed, but keep the same indent depth as siblings.
**Verify:** `grep -c "Every edit site enumerated" skills/review-plan/SKILL.md` returns 1; `wc -l skills/review-plan/SKILL.md` shows file is still ≤300 lines; visual diff shows the bullet sits inside the Completeness block, not Assumptions.
**UI:** no

### T2: Add AC2 (runtime-signal source) check to review-plan/SKILL.md (~5 min)
**Files:** skills/review-plan/SKILL.md
**Depends on:** T1
**Action:** Add a new check bullet to the **Assumptions** dimension block (currently lines 37–41, post-T1 line numbers will shift) covering runtime-signal source naming.
**Details:** Insert a new bullet at the end of the Assumptions block (after the existing last bullet about "APIs, utilities, or patterns that don't exist"). The bullet must:
- Use the existing `- **Bold lead phrase.**` pattern
- Lead phrase: `**Runtime-signal source named.**`
- State the rule: any task that performs runtime detection (mtime, branch name, file content, JSON field, command output) MUST name the observable signal source — the specific command, file path, or field whose output the conditional reads. A conditional that does not name its data source is unverifiable.
- Clarify the scope distinction (this is a correctness check, not a maintenance check): signal source = WHERE data comes from; policy parameters (thresholds, comparators, target values) are explicitly NOT covered by this check. Duplicated policy values like a literal `80` threshold are out of scope.
- Cite the canonical positive example: E03.S10's "if the failure output indicates a test failure — assertion errors or test-runner output" prose (currently in `skills/build/SKILL.md` line 180 and `skills/fix/SKILL.md` line 187).
- Cite the canonical negative example: E03.S10 first-draft "if Stage 5c was hit by changes to test files" (no detection mechanism for "test files" exists — preserved in `docs/plans/E03-S10-retry-loop-tuning-plan.md` lines 8–11 and commit `3c46687`).
- Keep the bullet to a similar size as T1's addition (≤8 lines of markdown).
**Verify:** `grep -c "Runtime-signal source named" skills/review-plan/SKILL.md` returns 1; `wc -l skills/review-plan/SKILL.md` ≤300; visual diff shows the bullet sits inside the Assumptions block, not Completeness or Overengineering.
**UI:** no

### T3: Add `## Skill authoring conventions` section to CONTRIBUTING.md (~4 min)
**Files:** CONTRIBUTING.md
**Action:** Insert a new `## Skill authoring conventions` section between `## Code Standards` (currently ends line 48) and `## Tooling Pitfalls` (currently starts line 50). Document the multi-branch case-dispatch language convention with the named carve-out for genuinely-sequential structures.
**Details:** The new section must:
- Use the `##` heading level (matches sibling sections)
- Lead with the multi-branch case-dispatch rule: when a skill body partitions behavior across multiple mutually-exclusive cases (Case A / Case B / Case C / etc.), the dispatch instruction must explicitly state *"evaluate top-to-bottom; execute only the first matching case."* Reject fall-through prose ("then do X if not, otherwise do Y") — it invites cumulative execution.
- State the bright-line carve-out for genuinely-sequential structures: ordered enumeration (Step A → Step B → Step C → Step D) WITH explicit "after Step N completes, proceed to Step N+1" transition prose. Both conditions are required for the carve-out to apply.
- Cite the canonical case-dispatch positive example: `skills/help/SKILL.md` Step 3 (Cases A–E, post-E03.S8 form) — explicit "evaluate top-to-bottom; execute ONLY the first matching case" language.
- Cite the canonical sequential-structure carve-out example: `skills/setup/SKILL.md` Step 5d Branch 4 transactional commit (Steps A → B → C → D with explicit transition prose).
- Tone and depth: match the medium-depth Tooling Pitfalls section (worked examples encouraged but keep total ~12–18 lines).
- Section should appear before Tooling Pitfalls so that the lighter-weight authoring rule is read first.
**Verify:** `grep -n "^## Skill authoring conventions" CONTRIBUTING.md` returns line in the 40–60 range and BEFORE the `## Tooling Pitfalls` line; `grep -c "evaluate top-to-bottom" CONTRIBUTING.md` returns ≥1.
**UI:** no

### T4: Create AC1 synthetic fixtures (~5 min)
**Files:** tests/fixtures/review-plan/ac1-pass.md, tests/fixtures/review-plan/ac1-needs-revision.md, tests/fixtures/review-plan/ac1-carve-out-pass.md
**Action:** Create three small synthetic plan fixtures exercising AC1's PASS, NEEDS REVISION, and carve-out PASS (negative-control) paths.
**Details:** First create the directory: `tests/fixtures/review-plan/`. Each fixture is a minimal `Plan-format-version: 1` markdown plan with a `## Tasks` section containing one or two tasks. Each fixture is a stand-alone testable artifact:
- `ac1-pass.md`: Contains a task that enumerates 3 edit sites as separately numbered entries (e.g., "1. Site A at L10", "2. Site B at L25", "3. Site C at L40"). No "confirm during edit" footnote anywhere.
- `ac1-needs-revision.md`: Contains a task that enumerates 2 edit sites explicitly but defers a third site with a "confirm during edit" footnote (e.g., "Note: an additional site at L80 — confirm during edit"). This is the surfacing-failure pattern AC1 is designed to catch.
- `ac1-carve-out-pass.md`: Contains a task with consolidated enumeration that explicitly invokes the carve-out — the plan body contains the literal phrase "structural uniformity" AND names the count and pattern (e.g., "27 abort-prose sites, byte-identical canonical block"). This must PASS review-plan because the carve-out applies.
Each fixture should be 15–35 lines, include the `Plan-format-version: 1` line, and a header comment at the top noting `**Fixture purpose:** [AC1 PASS | AC1 NEEDS REVISION | AC1 carve-out PASS (negative-control)]` — a 1-line note so future readers know why the file exists. Do not invent real codepaths; use fictional but plausible file paths.
**Verify:** `ls tests/fixtures/review-plan/ac1-*.md | wc -l` returns 3; each file contains a `## Tasks` section (`grep -l "## Tasks" tests/fixtures/review-plan/ac1-*.md | wc -l` returns 3); `grep -l "confirm during edit" tests/fixtures/review-plan/ac1-needs-revision.md` returns the file; `grep -l "structural uniformity" tests/fixtures/review-plan/ac1-carve-out-pass.md` returns the file.
**UI:** no

### T5: Create AC2 synthetic fixtures (~3 min)
**Files:** tests/fixtures/review-plan/ac2-pass.md, tests/fixtures/review-plan/ac2-needs-revision.md
**Action:** Create two small synthetic plan fixtures exercising AC2's PASS and NEEDS REVISION paths.
**Details:**
- `ac2-pass.md`: Contains a task that performs runtime detection AND names the observable signal source. Example: a task with a conditional like "if `git rev-parse --git-dir 2>/dev/null` exits 0, the repo has a `.git/` directory" — names the command and the expected output.
- `ac2-needs-revision.md`: Contains a task that performs runtime detection WITHOUT naming the signal source. Example: a conditional phrased as "if the user is in a CI environment, skip the prompt" — no signal source named (which env var? which command output? which file presence?).
Each fixture should be 15–30 lines, include `Plan-format-version: 1`, and a 1-line header note (`**Fixture purpose:** AC2 PASS` or `AC2 NEEDS REVISION`). Use plausible-but-fictional codepaths.
**Verify:** `ls tests/fixtures/review-plan/ac2-*.md | wc -l` returns 2; `grep -l "## Tasks" tests/fixtures/review-plan/ac2-*.md | wc -l` returns 2.
**UI:** no

### T6: Create AC3 synthetic fixtures (~3 min)
**Files:** tests/fixtures/review-plan/ac3-pass.md, tests/fixtures/review-plan/ac3-needs-revision.md
**Action:** Create two small synthetic skill-body draft fixtures exercising AC3's PASS and NEEDS REVISION paths. (AC3 is about skill-authoring convention, not plan structure — so these fixtures are short skill-body draft excerpts, not Plan-format-version plans.)
**Details:**
- `ac3-pass.md`: Contains a 10–15-line skill-body excerpt that uses proper case-dispatch language: explicit "evaluate top-to-bottom; execute only the first matching case" prose ahead of Cases A/B/C definitions.
- `ac3-needs-revision.md`: Contains a similar 10–15-line skill-body excerpt that uses fall-through prose ("if not Case A, then Case B; otherwise Case C") with no top-to-bottom evaluation declaration. The structure invites cumulative execution.
Each fixture should be 15–25 lines, lead with a 1-line header note (`**Fixture purpose:** AC3 PASS` or `AC3 NEEDS REVISION`), and depict a plausible-but-fictional decision split. Do NOT include `Plan-format-version: 1` — these are skill-body excerpts being reviewed for AC3 convention compliance, not plans being reviewed by `/roughly:review-plan` per se.
**Verify:** `ls tests/fixtures/review-plan/ac3-*.md | wc -l` returns 2.
**UI:** no

### T7: Create tests/fixtures/review-plan/README.md (~3 min)
**Files:** tests/fixtures/review-plan/README.md
**Depends on:** T4, T5, T6
**Action:** Create a README documenting the fixture directory's purpose, the file inventory, and the expected verdict for each fixture when used in AC6 self-verification.
**Details:** The README should contain:
- A short intro: "Synthetic plan fixtures exercising E04.S6's new review-plan AC checks (AC1, AC2, AC3). Used for pre-merge self-verification per E04.S6 AC6."
- A table of fixtures with columns: `File`, `Targets`, `Expected verdict`, `Reason`. Rows for all 7 fixtures (3 AC1 + 2 AC2 + 2 AC3).
- A short "How to verify" subsection: "Dispatch `/roughly:review-plan` against each fixture. Required outcome: all `*-pass.md` and `*-carve-out-pass.md` return PASS; all `*-needs-revision.md` return NEEDS REVISION with the targeted AC cited by name."
- A note that AC3 fixtures are skill-body excerpts (not plans) and may need different framing if `/roughly:review-plan` proves AC3 review is contributor-facing (CONTRIBUTING.md), not LLM-enforced — in which case AC3 fixtures are read by humans, not by `/roughly:review-plan`. Capture this honestly so future maintainers do not chase a false test gap.
- Target length: 30–50 lines.
**Verify:** `test -f tests/fixtures/review-plan/README.md`; `grep -c "Expected verdict" tests/fixtures/review-plan/README.md` returns ≥1; `wc -l tests/fixtures/review-plan/README.md` is 25–60.
**UI:** no

## AC6 Self-Verification (post-implementation, pre-commit)

After T1–T7 complete and Stage 6/7 pass:
1. Orchestrator (this build pipeline) dispatches `/roughly:review-plan` against `tests/fixtures/review-plan/ac1-pass.md`. Required: PASS.
2. Repeat for `ac1-needs-revision.md`. Required: NEEDS REVISION citing AC1's "every edit site enumerated" rule.
3. Repeat for `ac1-carve-out-pass.md`. Required: PASS (carve-out applies).
4. Repeat for `ac2-pass.md`. Required: PASS.
5. Repeat for `ac2-needs-revision.md`. Required: NEEDS REVISION citing AC2's "runtime-signal source" rule.
6. AC3 fixtures: per the AC3-is-CONTRIBUTING-only framing, AC3 fixtures are human-read; if `/roughly:review-plan` is not the verifier (because AC3 lives in CONTRIBUTING.md, not review-plan/SKILL.md), document that openly in the README and do not dispatch — read them for correctness instead.

The AC6 verification step is NOT a task — it is an orchestrator-level check performed at Stage 5d completion or Stage 7 verify. Capture results in the README's verdict table or in a Stage 8 commit-message verification summary.

## Blast Radius

- Do NOT modify: any agents, hooks, templates, scripts, fixtures (other than the new ones), or skills (other than `review-plan/SKILL.md`).
- Do NOT modify: `skills/build/SKILL.md`, `skills/fix/SKILL.md`, `skills/setup/SKILL.md`, `skills/help/SKILL.md`, `.claude/hooks/`, `agents/`, or `docs/adrs/` — those files are *cited* by the new content, not modified.
- Do NOT alter existing AC checks in `review-plan/SKILL.md` — only add new bullets.
- Do NOT alter existing CONTRIBUTING.md sections — only insert a new `##` section.
- Watch for: line-count drift on `review-plan/SKILL.md` (AC4 requires ≤300; current 92, projected ~107–112).
- Watch for: regex metachar pitfall when greping for citation phrases — use `grep -F` for literal strings.

## Conventions

- Skill body format: dash bullets with bold lead phrases (see review-plan/SKILL.md lines 86–92).
- CONTRIBUTING.md section format: `##` headings, prose paragraphs, worked examples when illustrative (see Tooling Pitfalls section).
- Synthetic fixtures: `Plan-format-version: 1` for plan-shaped fixtures (AC1, AC2); plain markdown excerpts for skill-body fixtures (AC3).
- Citations: file path + line number where stable; commit SHA + filename where historical; `.roughly/known-pitfalls.md` line ref where the pitfall is permanently recorded.
- ADR-001 (review-plan dispatched as blocking subagent): AC6 verification respects this by dispatching `/roughly:review-plan` per fixture, not by inlining the review logic.
- Per the discovery report, the count "27 abort-prose sites" reflects the final post-cycle-2 count in `.roughly/known-pitfalls.md`; cite that number, not the mid-run T6 count (25) from the S9 plan body.
