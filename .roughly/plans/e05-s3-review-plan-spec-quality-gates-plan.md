> **Status:** Historical — implemented and merged in commit 6b377638c583164aedd1e326dfb0f6eaf4a12da2 on 2026-05-27. This plan was an active build/fix artifact; treat as historical reference only.

# Implementation Plan: E05.S3 — Review-plan spec-quality gates (5 new ACs + skill-body polish)

Plan-format-version: 1

Source spec: `docs/planning/epics/E05-doc-writer-hardening-and-spec-quality-gates.md` lines 145–211 (E05.S3).

## File Table

| File | Action | Task(s) |
|------|--------|---------|
| `skills/review-plan/SKILL.md` | Modify (add 5 check entries + AC6a polish) | T1, T2 |
| `CONTRIBUTING.md` | Modify (extend skill-authoring conventions + new subsection) | T3, T4 |
| `tests/fixtures/review-plan/ac1-broader-scope-pass.md` | Create | T5 |
| `tests/fixtures/review-plan/ac1-broader-scope-needs-revision.md` | Create | T5 |
| `tests/fixtures/review-plan/ac1-broader-scope-borderline-pass.md` | Create | T5 |
| `tests/fixtures/review-plan/ac2-grep-fc-pass.md` | Create | T6 |
| `tests/fixtures/review-plan/ac2-grep-fc-needs-revision.md` | Create | T6 |
| `tests/fixtures/review-plan/ac2-grep-fc-borderline-pass.md` | Create | T6 |
| `tests/fixtures/review-plan/ac3-defensive-guard-pass.md` | Create | T7 |
| `tests/fixtures/review-plan/ac3-defensive-guard-needs-revision.md` | Create | T7 |
| `tests/fixtures/review-plan/ac3-defensive-guard-borderline-pass.md` | Create | T7 |
| `tests/fixtures/review-plan/ac4-doc-coverage-pass.md` | Create | T8 |
| `tests/fixtures/review-plan/ac4-doc-coverage-needs-revision.md` | Create | T8 |
| `tests/fixtures/review-plan/ac4-doc-coverage-borderline-pass.md` | Create | T8 |
| `tests/fixtures/review-plan/ac5-self-defeating-pass.md` | Create | T9 |
| `tests/fixtures/review-plan/ac5-self-defeating-needs-revision.md` | Create | T9 |
| `tests/fixtures/review-plan/ac5-self-defeating-borderline-pass.md` | Create | T9 |
| `tests/fixtures/review-plan/README.md` | Modify (header + table + Path A line refs) | T10 |
| `CHANGELOG.md` | Modify (new `### Added` under `[Unreleased]`) | T11 |

**Note:** Existing 7 fixtures (`ac1-pass.md`, `ac1-needs-revision.md`, `ac1-carve-out-pass.md`, `ac2-pass.md`, `ac2-needs-revision.md`, `ac3-pass.md`, `ac3-needs-revision.md`) are **NOT modified** — per spec "existing 7 E04.S6 fixtures retained unchanged." The new fixtures use descriptive infixes (`-broader-scope-`, `-grep-fc-`, etc.) to disambiguate from the E04.S6 set without name collision.

## Pre-implementation design decisions

These resolve ambiguities surfaced in discovery:

### Dimension placement (resolves Risk #1 from discovery)

The spec at epic L164 says "Completeness / Assumptions / Risks per E04.S6 framing" but actual `skills/review-plan/SKILL.md` L47 uses **Overengineering** as the third dimension. Placement per AC:

- **AC1 (verify scope vs enumeration)** → **Completeness** (verify-command correctness against spec scope)
- **AC2 (`grep -Fc` co-location)** → **Completeness** (verify-command correctness against fact-of-co-location)
- **AC3 (defensive-guard vs invariant)** → **Assumptions** (the plan assumes a defensive guard is not a new invariant; that assumption needs validation)
- **AC4 (behavior-divergence doc-coverage)** → **Assumptions** (the plan assumes existing docs remain accurate after a guard is added; that assumption needs validation)
- **AC5 (self-defeating verify)** → **Completeness** (verify-command correctness against the literal-presence reality of new prose)

This places 3 checks under Completeness, 2 under Assumptions, none under Overengineering. The existing E04.S6 checks (every-edit-site-enumerated under Completeness, runtime-signal-source-named under Assumptions) extend cleanly — no new dimension introduced.

### BORDERLINE-PASS naming convention (resolves Risk #2 from discovery)

New fixture form: `ac<N>-<infix>-borderline-pass.md`. The descriptive infix differentiates new E05.S3 fixtures from the E04.S6 existing `ac1`/`ac2`/`ac3` names. Forms per AC:
- PASS: clean PASS — no violation present, or carve-out unambiguously applies
- NEEDS REVISION: clear violation with AC-number cited by name in the verdict
- BORDERLINE-PASS: legitimate-but-unusual plan that exercises the carve-out boundary

### AC6b convention text nuancing (resolves Risk #4 from discovery)

The spec at epic L183 frames `build`, `fix` as "user-invocable" but they have `disable-model-invocation: true` (per CLAUDE.md "Pipeline skills (build, fix) must have `disable-model-invocation: true`"). The nuance: `disable-model-invocation: true` prevents conversational invocation, but slash-command invocation is unaffected. Convention text must distinguish:

- **User-invocable via slash command:** `setup`, `upgrade`, `help`, `build`, `fix` (regardless of `disable-model-invocation` value — these have README/doc examples like `claude /roughly:build`)
- **Subagent-dispatch-only (no slash-command form):** `review-plan`, `review`, `review-epic`, `audit-epic`, `verify-all` (all have `disable-model-invocation: true` AND are dispatched programmatically, not invoked by the user)

The convention check is: a README documenting `/roughly:<skill>` as a user-invocable command must cross-check the skill's actual invocation pattern (whether it's dispatched programmatically only, or also has a slash-command surface). This is a stronger framing than the binary `disable-model-invocation` field alone.

### AC6c placement (resolves discovery item)

`## Cross-epic AC amendments` goes between `## Skill authoring conventions` (currently L50–62) and `## Tooling Pitfalls` (currently L64) in CONTRIBUTING.md. New `##`-level heading, not a subsection of `## Skill authoring conventions`.

### AC6a placement

Per discovery, verdict-emission stop-logic lives at L60–62 and the `## Output Format` section starts at L64. The strongest output-mandatory wording placement: add to `## Rules` section (current L90–96) as a new bullet — Rules is the imperative-form section already. Plus add a one-line statement at the top of `## Output Format` (L64) for visibility at the section the reader skips to.

## Tasks

### T1: Add 5 new check entries to `skills/review-plan/SKILL.md` (~6 min)
**Files:** `skills/review-plan/SKILL.md`
**Action:** Add 5 new check entries (AC1, AC2, AC5 under Completeness; AC3, AC4 under Assumptions) following the E04.S6 template.

**Details:**
Insertion points (current line numbers; will shift as edits are made):

- **Under `## Verification Process` → `**Completeness:**`** (current L31–37): append AFTER the existing "Every edit site enumerated" check entry at L36–37. Add three new entries in this order: AC1 (verify-scope-vs-enumeration), AC2 (grep-Fc co-location), AC5 (self-defeating verify pattern).

- **Under `## Verification Process` → `**Assumptions:**`** (current L39–45): append AFTER the existing "Runtime-signal source named" check entry at L44–45. Add two new entries in this order: AC3 (defensive-guard vs invariant), AC4 (behavior-divergence doc-coverage).

Template to mirror (from L36–37):
```markdown
- **Every edit site enumerated.** When a task description enumerates edit sites...
  - **Carve-out:** consolidated enumeration is allowed ONLY when...
```

Each new entry: bold check name + trigger condition prose + sub-bulleted bright-line carve-out + canonical positive AND negative example named inline citing file paths or commit hashes.

**AC1 — AC-verify-command-scope vs spec-enumeration check.** Use spec text from epic L171 verbatim where possible. Trigger: "When an AC's verify command searches a broader scope than the spec's enumerated file list...". Carve-out: "Explicit acknowledgment in the plan body using the phrase 'intentionally broader than enumeration' (or equivalent named asymmetry rationale) is the PASS form; silent asymmetry is the NEEDS REVISION form." Canonical positive: "E04.S1 AC1's `rg -Fn \"docs/plans\" skills/` verify — broader-than-enumeration discovered `skills/review-plan/SKILL.md` unenumerated, caught at Stage 2; asymmetry is correct, the plan-time acknowledgment is what was missing." Canonical negative: "AC enumerating 4 files and verifying with `rg ... <only those 4 files>` (no asymmetry to detect)."

**AC2 — `grep -Fc` / `grep -Fn` same-line co-location check.** Use spec text from epic L173. Trigger: "When a verify command uses `grep -Fc <pattern> <file>` or `grep -Fn <pattern> <file>` to count occurrences, and the plan enumerates N edited sites that might land on the same physical line (paragraph-dense skill markdown is common)...". Carve-out: "verify commands that count N sites known to be on physically distinct lines (function definitions, separately-bulleted entries, line-by-line config keys) pass; the check fires only when same-line co-location is plausible (multiple sites within a single paragraph, parenthetical alternatives, or HTML-comment-internal annotations)." Canonical positive: "E04.S2 cycle 1 caught two abort-suffix sites landing on the same L44 — the AC3 verify expected `count=3` but got `count=2`." Canonical negative: "a verify counting `^### T[0-9]+` task headings — one per line by markdown structure, immune to co-location."

**AC5 — Self-defeating-verify-pattern check.** Use spec text from epic L179. Trigger: "When an AC's verify command searches for a literal that is intentionally present in the new detection prose or in newly-added historical/explanatory docs...". Carve-out: "verify commands operating on a scope known to be free of the literal pass; the check fires only when the new detection prose, migration step, or historical doc contains the literal being searched." Canonical positive: "E04.S1 AC1 (`rg -Fn \"docs/plans\" skills/` → 14 matches post-impl, all legitimate pre-flight / setup / upgrade self-references) — required `grep -v` exclusions post-shipping (audit S1.AC5 finding)." Canonical negative: "a verify command using `rg -Fn` against a scope explicitly carved out of self-reference (e.g., `skills/ --exclude-dir=setup` when only setup contains the literal)."

**AC3 — Defensive-guard vs new-invariant distinction check.** Use spec text from epic L175. Trigger: "When an AC bounds the scope of new invariants using language like 'no new X beyond the named Y,' the bound is on *structural rules*, not on *behavior at the named site*. Defensive precondition guards for the named Y are explicitly in-scope and do not require AC amendment." Carve-out: "AC bounding language should be written as 'no new structural rules' rather than 'no new behavior at the named site' to enable guard additions; review-plan flags AC text using the latter form and suggests the former." Canonical positive: "E04.S5 AC8 + the Stage 6 fixture-existence guard + per-skill marker pre-check + tooling-unavailable branch — all defensive guards for three named invariants, AC8 preserved in spirit per E04 epic L617." Canonical negative: "a plan that adds a fourth byte-identity check while AC8 forbids new invariants — that requires AC amendment, not a guard."

**AC4 — Behavior-divergence doc-coverage check.** Use spec text from epic L177. Trigger: "When a guard, early-exit, or new branch is added before previously-reachable code, any documentation describing the previously-reachable behavior via that input path must be examined for accuracy. It cannot be classified as 'additive prose untouched.'" Carve-out: "guards added at boundaries where no prior documentation existed (greenfield addition) pass; only guards layered onto previously-reachable code paths trigger the check." Canonical positive: "E04.S9 CONTRIBUTING.md L109 — the `ANTHROPIC_API_KEY` empty-guard made the previously-reachable `claude --bare` auth-failure path unreachable for the unset-key case; cubic round 2 caught the contradiction post-PR." Canonical negative: "a new function that adds caching as its first call (no prior doc could describe the uncached path because the function is new)."

**Verify:**
```
test $(grep -c "^- \*\*" skills/review-plan/SKILL.md) -ge 7 && \
grep -Fq "intentionally broader than enumeration" skills/review-plan/SKILL.md && \
grep -Fq "grep -Fo <pattern> <file> | wc -l" skills/review-plan/SKILL.md && \
grep -Fq "no new structural rules" skills/review-plan/SKILL.md && \
grep -Fq "previously-reachable behavior" skills/review-plan/SKILL.md && \
grep -Fq "self-defeating" skills/review-plan/SKILL.md && \
test $(wc -l < skills/review-plan/SKILL.md) -le 300 && \
echo OK
```

**UI:** no

---

### T2: Add AC6a stronger output-mandatory wording to `skills/review-plan/SKILL.md` (~3 min)
**Files:** `skills/review-plan/SKILL.md`
**Depends on:** T1
**Action:** Add the literal phrase "MUST produce a verdict block" with surrounding context to both `## Output Format` section opening AND a new bullet in `## Rules`.

**Details:**
- **At top of `## Output Format` section** (current L64, will shift after T1): immediately after the heading and before the fenced code block, add a one-line statement: `Every dispatch MUST produce a verdict block (PASS or NEEDS REVISION) as the final output. No early termination, no mid-investigation "let me check" interruptions.`

- **In `## Rules` section** (current L90–96, will shift after T1): add a new bullet at the end: `- **Verdict is mandatory.** Every dispatch MUST produce a verdict block. If you reach the iteration cap (3) without resolution, emit the verdict block with the unresolved findings classified as ❌ Blocker and NEEDS REVISION.`

The literal phrase "MUST produce a verdict block" must appear at least twice (once in each location).

**Verify:**
```
test $(grep -Fc "MUST produce a verdict block" skills/review-plan/SKILL.md) -ge 2 && echo OK
```

**UI:** no

---

### T3: Add AC6b skill-authoring convention to `CONTRIBUTING.md` (~3 min)
**Files:** `CONTRIBUTING.md`
**Action:** Add a new convention block to the `## Skill authoring conventions` section covering README/doc invocation-example/frontmatter cross-check.

**Details:**
Insertion point: at the end of `## Skill authoring conventions` section, before `## Tooling Pitfalls`. After the existing ADR-011 cross-reference line.

**Note on epic L165 "5 paired one-line summaries":** Epic L165 says CONTRIBUTING.md gains "5 paired one-line summaries (rule + canonical positive/negative pointer per E04.S6 pattern)." This language describes the format of the 5 new check entries being added to `skills/review-plan/SKILL.md` (which DO follow the bold-name + trigger + carve-out + named-examples pattern from E04.S6), NOT 5 additional CONTRIBUTING.md bullets. No AC (AC1–AC7) requires CONTRIBUTING.md summaries for AC1–AC5; adding them to `## Skill authoring conventions` would be a category mismatch (that section covers skill-authoring rules for contributors, not review-plan check descriptions). The only CONTRIBUTING.md additions in this story are AC6b (this task, T3) and AC6c (T4).

Convention text (use the nuanced framing from pre-implementation design decisions above — NOT the binary spec text verbatim):

```markdown
**README/doc invocation examples align with skill invocation surface.** Any README, CONTRIBUTING.md, or skill doc that documents `/roughly:<skill>` as a user-invocable slash command must cross-check that the skill is actually invocable from a slash-command form. Pipeline coordinator skills (`build`, `fix`) have `disable-model-invocation: true` but ARE user-invocable via slash command — the field prevents conversational invocation, not slash-command dispatch. Pure subagent-dispatch-only skills (`review-plan`, `review`, `review-epic`, `audit-epic`, `verify-all`) also have `disable-model-invocation: true` AND are dispatched programmatically only — they have no slash-command surface and must NOT be documented as `claude /roughly:<skill>`. User-invocable skills with slash-command surfaces: `setup`, `upgrade`, `help`, `build`, `fix`. Canonical reference: `tests/fixtures/review-plan/README.md` post-`9d61030` enumerates the invocation surface explicitly per fixture.
```

**Verify:**
```
grep -Fq "README/doc invocation examples align with skill invocation surface" CONTRIBUTING.md && \
grep -Fq "Pure subagent-dispatch-only skills" CONTRIBUTING.md && echo OK
```

**UI:** no

---

### T4: Add new `## Cross-epic AC amendments` subsection to `CONTRIBUTING.md` (~3 min)
**Files:** `CONTRIBUTING.md`
**Depends on:** T3
**Action:** Add a new `##`-level heading and subsection codifying the cross-epic AC amendment convention (per Risk 4 mitigation).

**Details:**
Insertion point: between `## Skill authoring conventions` section (after T3's addition) and `## Tooling Pitfalls`. Add as a new top-level `##` heading.

Convention text (from epic L184):

```markdown
## Cross-epic AC amendments

When amending an already-shipped story's AC from a later epic, three artifacts must land together:

1. **The amending epic entry is the canonical source** of the corrected AC text. Write the new AC contract in full inside the amending story's entry.
2. **The original epic entry gains a back-pointer note** at each amended AC location, in the form `**Amended in <new-story-id> — see <new-story-id> for the corrected contract.**`. The original AC text is NOT edited in-place — the back-pointer preserves the historical record while making the amendment trail discoverable.
3. **The `CHANGELOG.md` `### Changed` entry** documents the contract revision and cross-references both the original AC location (epic + story ID) and the amending location (epic + story ID).

Canonical first instance: E05.S2 amends E04.S8 AC2/AC4/AC5 (corrected contract in E05.S2 entry of `docs/planning/epics/E05-doc-writer-hardening-and-spec-quality-gates.md`; back-pointers in `docs/planning/epics/complete/E04-path-consolidation-and-process-codification.md` E04.S8 entry; CHANGELOG `### Changed` entry references both).
```

**Verify:**
```
grep -Fq "## Cross-epic AC amendments" CONTRIBUTING.md && \
grep -Fq "back-pointer note" CONTRIBUTING.md && \
grep -Fq "Amended in <new-story-id>" CONTRIBUTING.md && echo OK
```

**UI:** no

---

### T5: Create AC1 fixture triple — `ac1-broader-scope-{pass,needs-revision,borderline-pass}.md` (~5 min)
**Files:**
- `tests/fixtures/review-plan/ac1-broader-scope-pass.md`
- `tests/fixtures/review-plan/ac1-broader-scope-needs-revision.md`
- `tests/fixtures/review-plan/ac1-broader-scope-borderline-pass.md`

**Action:** Create three new fixtures exercising AC1 (verify-command scope vs spec enumeration).

**Details:** Follow existing fixture structure verbatim (see `tests/fixtures/review-plan/ac1-pass.md` and `ac1-carve-out-pass.md` as templates).

**File 1: `ac1-broader-scope-pass.md`** — `**Fixture purpose:** AC1 PASS — verify command scope matches enumeration scope.` Plan body: a synthetic plan where the AC enumerates 4 files and the verify command targets exactly those 4 files (no asymmetry).

**File 2: `ac1-broader-scope-needs-revision.md`** — `**Fixture purpose:** AC1 NEEDS REVISION — verify scope broader than enumeration with NO acknowledgment.` Plan body: a synthetic plan where the AC enumerates 2 files but the verify command searches an entire directory `skills/` with no acknowledgment of the asymmetry. Expected verdict cites AC1 by name.

**File 3: `ac1-broader-scope-borderline-pass.md`** — `**Fixture purpose:** AC1 BORDERLINE-PASS — verify scope broader than enumeration WITH acknowledgment using close-but-not-identical phrasing.` Plan body: a synthetic plan where the AC enumerates 2 files but verify searches `skills/`, AND the plan body explicitly acknowledges the asymmetry using phrasing like "verify intentionally exceeds the enumeration scope to catch any newly-introduced edit sites" — the carve-out boundary requires the reviewer to recognize that the rationale-substance matches even though the exact phrase "intentionally broader than enumeration" is not used.

Header convention (line 1): `**Fixture purpose:** AC1 <FORM> — <brief description>`

**Verify:**
```
test -f tests/fixtures/review-plan/ac1-broader-scope-pass.md && \
test -f tests/fixtures/review-plan/ac1-broader-scope-needs-revision.md && \
test -f tests/fixtures/review-plan/ac1-broader-scope-borderline-pass.md && \
head -1 tests/fixtures/review-plan/ac1-broader-scope-borderline-pass.md | grep -Fq "BORDERLINE-PASS" && echo OK
```

**UI:** no

---

### T6: Create AC2 fixture triple — `ac2-grep-fc-{pass,needs-revision,borderline-pass}.md` (~5 min)
**Files:**
- `tests/fixtures/review-plan/ac2-grep-fc-pass.md`
- `tests/fixtures/review-plan/ac2-grep-fc-needs-revision.md`
- `tests/fixtures/review-plan/ac2-grep-fc-borderline-pass.md`

**Action:** Create three new fixtures exercising AC2 (`grep -Fc` / `grep -Fn` same-line co-location).

**Details:**
- **PASS:** plan enumerates 4 task headings to add (`^### T[0-9]+`) and uses `grep -c "^### T[0-9]+"` to verify count — immune to co-location by markdown line structure.
- **NEEDS REVISION:** plan enumerates 3 sites in a single paragraph (e.g., 3 abort-suffix additions in build/SKILL.md Stage 8 prose) and uses `grep -Fc "Recovery:"` to verify count=3 — same-line co-location plausible. Expected verdict cites AC2 by name.
- **BORDERLINE-PASS:** plan enumerates 3 sites and uses `grep -Fc <pattern>`, AND the plan body explicitly names per-line distinctness with rationale (e.g., "each addition lands at the head of a distinct numbered list item, guaranteed one-per-line by markdown structure") — carve-out applies, but the reviewer must recognize the distinctness rationale.

**Verify:**
```
test -f tests/fixtures/review-plan/ac2-grep-fc-pass.md && \
test -f tests/fixtures/review-plan/ac2-grep-fc-needs-revision.md && \
test -f tests/fixtures/review-plan/ac2-grep-fc-borderline-pass.md && \
head -1 tests/fixtures/review-plan/ac2-grep-fc-borderline-pass.md | grep -Fq "BORDERLINE-PASS" && echo OK
```

**UI:** no

---

### T7: Create AC3 fixture triple — `ac3-defensive-guard-{pass,needs-revision,borderline-pass}.md` (~5 min)
**Files:**
- `tests/fixtures/review-plan/ac3-defensive-guard-pass.md`
- `tests/fixtures/review-plan/ac3-defensive-guard-needs-revision.md`
- `tests/fixtures/review-plan/ac3-defensive-guard-borderline-pass.md`

**Action:** Create three new fixtures exercising AC3 (defensive-guard vs new-invariant distinction).

**Details:**
- **PASS:** plan adds a precondition guard (`if [ ! -f <file> ]; then warn; abort; fi`) at the start of an existing function. The AC bounds invariants by structural rule and the guard does not introduce a new invariant — just protects an existing one. Plan body uses framing: "defensive guard for named invariant, no new invariant added."
- **NEEDS REVISION:** plan adds a fourth byte-identity check while the AC says "no new invariants beyond the three named." The plan classifies this as a "minor defensive addition" but it's actually a new invariant. Expected verdict cites AC3 by name.
- **BORDERLINE-PASS:** plan adds what looks like a new check, but its semantics are protective-not-additive — e.g., a count check that aborts if more than N entries exist (where N is determined by a previously-named invariant), AND the plan body explicitly invokes the carve-out language "defensive guard for named invariant, no new invariant added" with a paragraph-level explanation of why the check is structurally-bounded by an existing rule.

**Verify:**
```
test -f tests/fixtures/review-plan/ac3-defensive-guard-pass.md && \
test -f tests/fixtures/review-plan/ac3-defensive-guard-needs-revision.md && \
test -f tests/fixtures/review-plan/ac3-defensive-guard-borderline-pass.md && \
head -1 tests/fixtures/review-plan/ac3-defensive-guard-borderline-pass.md | grep -Fq "BORDERLINE-PASS" && echo OK
```

**UI:** no

---

### T8: Create AC4 fixture triple — `ac4-doc-coverage-{pass,needs-revision,borderline-pass}.md` (~5 min)
**Files:**
- `tests/fixtures/review-plan/ac4-doc-coverage-pass.md`
- `tests/fixtures/review-plan/ac4-doc-coverage-needs-revision.md`
- `tests/fixtures/review-plan/ac4-doc-coverage-borderline-pass.md`

**Action:** Create three new fixtures exercising AC4 (behavior-divergence doc-coverage).

**Details:**
- **PASS:** plan adds a guard to a brand-new code path that has no prior documentation describing the unguarded behavior (greenfield carve-out applies).
- **NEEDS REVISION:** plan adds a guard before previously-reachable code path X, and the existing CONTRIBUTING.md documents X's previously-reachable behavior. Plan classifies docs as "additive prose untouched" but they are actually contradicted by the new guard. Expected verdict cites AC4 by name.
- **BORDERLINE-PASS:** plan adds a guard before a previously-reachable code path, AND the plan body explicitly invokes the greenfield carve-out language "no prior documentation existed for the now-unreachable behavior" with a one-line rationale citing the grep'd doc tree — the boundary requires the reviewer to accept the rationale as a credible documentation audit.

**Verify:**
```
test -f tests/fixtures/review-plan/ac4-doc-coverage-pass.md && \
test -f tests/fixtures/review-plan/ac4-doc-coverage-needs-revision.md && \
test -f tests/fixtures/review-plan/ac4-doc-coverage-borderline-pass.md && \
head -1 tests/fixtures/review-plan/ac4-doc-coverage-borderline-pass.md | grep -Fq "BORDERLINE-PASS" && echo OK
```

**UI:** no

---

### T9: Create AC5 fixture triple — `ac5-self-defeating-{pass,needs-revision,borderline-pass}.md` (~5 min)
**Files:**
- `tests/fixtures/review-plan/ac5-self-defeating-pass.md`
- `tests/fixtures/review-plan/ac5-self-defeating-needs-revision.md`
- `tests/fixtures/review-plan/ac5-self-defeating-borderline-pass.md`

**Action:** Create three new fixtures exercising AC5 (self-defeating verify pattern).

**Details:**
- **PASS:** plan adds a verify command `rg -Fn "foo" scripts/ --exclude-dir=setup` where only setup contains the literal as historical reference — the verify scope is explicitly carved out of the literal's self-reference sites.
- **NEEDS REVISION:** plan adds a new pre-flight detection block to `skills/build/SKILL.md` that contains the phrase "legacy-state detected" and the AC verify is `grep -Fc "legacy-state detected" skills/build/SKILL.md` expecting count=N — but the new detection prose itself contributes to the count, making the verify self-defeating. Expected verdict cites AC5 by name.
- **BORDERLINE-PASS:** plan adds a verify using `grep -v "<documented-exclusion-pattern>"` to filter the literal-presence sites, AND the plan body explicitly documents what each excluded site is for — the boundary is whether the reviewer accepts the `grep -v` exclusion as exhaustive (no future self-reference sites missed) or asks for a structural-position verify (awk-based) instead.

**Verify:**
```
test -f tests/fixtures/review-plan/ac5-self-defeating-pass.md && \
test -f tests/fixtures/review-plan/ac5-self-defeating-needs-revision.md && \
test -f tests/fixtures/review-plan/ac5-self-defeating-borderline-pass.md && \
head -1 tests/fixtures/review-plan/ac5-self-defeating-borderline-pass.md | grep -Fq "BORDERLINE-PASS" && echo OK
```

**UI:** no

---

### T10: Update `tests/fixtures/review-plan/README.md` (~4 min)
**Files:** `tests/fixtures/review-plan/README.md`
**Depends on:** T1, T2, T5, T6, T7, T8, T9
**Action:** Update README header, fixture inventory table, and Path A line-number references after SKILL.md edits.

**Details:**
- **Header:** Update from "exercising E04.S6's new review-plan AC checks (AC1, AC2) and the AC3 case-dispatch convention" to also mention E05.S3's 5 new ACs and the new BORDERLINE-PASS form.

- **Fixture inventory table:** Add 15 new rows (3 per AC × 5 ACs) to the existing table. Each row: `File | Targets | Expected verdict | Reason`. Categorize by AC and by form (PASS / NEEDS REVISION / BORDERLINE-PASS) per AC7c.

- **Path A line-number references:** Look up current SKILL.md line numbers for the existing E04.S6 checks (AC1 "every-edit-site-enumerated" and AC2 "runtime-signal-source-named") AND for the new E05.S3 check entries. Update Path A desk-check section to reference the new post-merge line numbers for all 7 checks (2 existing + 5 new). Use `grep -n "^- \*\*" skills/review-plan/SKILL.md` to find the exact post-T1 line numbers.

- **Path B (subagent dispatch):** no changes required — references the skill, not specific lines.

- Add a one-line note at the README top: "Fixture forms: PASS (clean), NEEDS REVISION (clear violation with AC cited by name), BORDERLINE-PASS (legitimate plan structure exercising the AC's carve-out boundary). The BORDERLINE-PASS form was introduced in E05.S3 to protect against false-positive review-fatigue (epic Risk 3)."

**Verify:**
```
grep -Fq "E05.S3" tests/fixtures/review-plan/README.md && \
grep -Fq "BORDERLINE-PASS" tests/fixtures/review-plan/README.md && \
test $(grep -c "ac[1-5]-.*-borderline-pass.md" tests/fixtures/review-plan/README.md) -ge 5 && echo OK
```

**UI:** no

---

### T11: Add CHANGELOG `### Added` entry under `[Unreleased]` (~3 min)
**Files:** `CHANGELOG.md`
**Depends on:** T1, T2, T3, T4, T5, T6, T7, T8, T9, T10
**Action:** Add a new `### Added` subsection under `## [Unreleased]` (currently only `### Changed` exists per E05.S1).

**Details:**
Insert `### Added` subsection BEFORE the existing `### Changed` subsection (Keep a Changelog ordering convention). Entry text covers:

- 5 new review-plan check entries (AC1: verify-scope-vs-enumeration; AC2: `grep -Fc` co-location hazard; AC3: defensive-guard vs new-invariant distinction; AC4: behavior-divergence doc-coverage; AC5: self-defeating-verify pattern) added to `skills/review-plan/SKILL.md`. Closes v0.1.7 candidates from E04 epic L607, L609, L617, L621, L625.
- Stronger output-mandatory wording in `skills/review-plan/SKILL.md` ("MUST produce a verdict block") closing E04 epic L583 candidate.
- New CONTRIBUTING.md convention: README/doc invocation examples must align with skill invocation surface (E04 epic L581 candidate, landed as CONTRIBUTING.md convention per OQ10).
- New CONTRIBUTING.md `## Cross-epic AC amendments` subsection codifying the 3-artifact amendment convention (E05 epic Risk 4 mitigation; convention codified here, first applied in E05.S2).
- 15 new test fixtures (5 triples — PASS + NEEDS REVISION + BORDERLINE-PASS) under `tests/fixtures/review-plan/`. BORDERLINE-PASS is a new fixture form introduced in this story.

Reference the E05.S3 story ID and the epic file path.

**Verify:**
```
grep -Fq "### Added" CHANGELOG.md && \
grep -Fq "E05.S3" CHANGELOG.md && \
grep -Fq "BORDERLINE-PASS" CHANGELOG.md && \
grep -Fq "Cross-epic AC amendments" CHANGELOG.md && echo OK
```

**UI:** no

---

## Blast Radius

**Do NOT modify:**
- `skills/review-plan/SKILL.md` lines 1–13 (frontmatter + pre-flight block; byte-identity enforced by `.claude/hooks/verify-all.sh` Check 5 against `tests/fixtures/canonical-preflight-block.txt`)
- Existing 7 fixtures (`ac1-pass.md`, `ac1-needs-revision.md`, `ac1-carve-out-pass.md`, `ac2-pass.md`, `ac2-needs-revision.md`, `ac3-pass.md`, `ac3-needs-revision.md`) — spec says retained unchanged
- Existing `## Skill authoring conventions` prose in CONTRIBUTING.md (the two long convention blocks + ADR-011 one-liner) — new entries append, don't replace existing
- Any agent files (`agents/*.md`) — agent word cap revision was E05.S1, separate story
- Any skill file other than `skills/review-plan/SKILL.md`
- Any pipeline coordinator skill body (`skills/build/SKILL.md`, `skills/fix/SKILL.md`) — out of scope per epic L205

**Watch for:**
- After T1, the `## Output Format` and `## Rules` section line numbers shift — T2 must reference relative-to-section, not absolute line numbers
- After T1, the README's Path A line-number references at `tests/fixtures/review-plan/README.md` will become stale — T10 closes this
- `.claude/hooks/verify-all.sh` Check 2 enforces `skills/review-plan/SKILL.md` ≤300 lines — projection ~140 lines is comfortable
- `.claude/hooks/verify-all.sh` Check 5 enforces pre-flight block byte-identity — DO NOT edit lines 1–13 of SKILL.md
- The agent word cap from E05.S1 (650 words) does NOT apply to skill bodies (which have a separate 300-line cap); only agent files. T1's additions to a skill body are line-count-bounded, not word-count-bounded.

## Conventions

- **E04.S6 check-entry template** at `skills/review-plan/SKILL.md` L36–37 and L44–45 — mirror verbatim for AC1–AC5 entries (bold name + trigger + sub-bulleted carve-out + named positive + named negative example)
- **E04.S6 fixture structure** at `tests/fixtures/review-plan/ac1-pass.md` etc. — mirror verbatim (purpose-header + full synthetic plan body)
- **E04.S6 CONTRIBUTING.md convention pattern** at `CONTRIBUTING.md` L52–62 — mirror block structure (rule prose + canonical positive/negative pointers) for T3's AC6b addition
- **Keep a Changelog conventions** for CHANGELOG.md — `### Added` before `### Changed` under `[Unreleased]`
- **ADR references:** ADR-001 (review-plan dispatched as blocking subagent) and ADR-007 (two-stage review) are relevant context but no new ADR required for this story (per epic L162 files-touched list; no ADR entry)
- **Known pitfall:** `grep -Fn "Status: Accepted"` fails against `**Status:** Accepted` (bold-markdown straddles `**` markers) — verify commands in this plan grep around bold-decorated content carefully (T3 and T4 use phrases that don't straddle bold)
- **Per CLAUDE.md "User context, not plugin context":** file paths in SKILL.md and CONTRIBUTING.md prose refer to the user's project, not the plugin source — but for THIS story, both ARE the plugin source (Roughly is the project), so paths resolve directly
