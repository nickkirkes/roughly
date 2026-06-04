> **Status:** Historical — implemented and merged in commit 97f6d8f2add3006eae80265af562c5fe6c61c9c9 on 2026-06-04. This plan was an active build/fix artifact; treat as historical reference only.

# Implementation Plan: E06.S4 — AC quoted-wording marker convention (`verbatim:` vs `form:` markers)

Plan-format-version: 1

Story spec: [docs/planning/epics/E06-anchoring-closure-and-ci-coverage.md](../../docs/planning/epics/E06-anchoring-closure-and-ci-coverage.md) L289–L332.

## Scope

Add a new review-plan check that flags ACs quoting example wording with metasyntactic notation (`<placeholder>`, `…`, `XXX`) unless they explicitly mark the wording as `verbatim:` or `form:`. Codify the convention in `CONTRIBUTING.md` as a new `## AC authoring conventions` subsection (resolves OQ-S4-convention-location per discovery rationale: AC text authoring is a distinct domain from skill-body authoring; new subsection cleanly clusters with adjacent `## Cross-epic AC amendments`). Author a fixture triple (PASS / NEEDS REVISION / BORDERLINE-PASS) per E05.S3 + E05.S7c discipline. Update fixtures README inventory + Path A desk-check line-number references. Write CHANGELOG `### Added` entry.

## File Table

| File | Action | Task(s) |
|------|--------|---------|
| `skills/review-plan/SKILL.md` | Edit | T1 |
| `CONTRIBUTING.md` | Edit | T2 |
| `tests/fixtures/review-plan/ac-marker-pass.md` | Create | T3 |
| `tests/fixtures/review-plan/ac-marker-needs-revision.md` | Create | T3 |
| `tests/fixtures/review-plan/ac-marker-borderline-pass.md` | Create | T3 |
| `tests/fixtures/review-plan/README.md` | Edit | T4 |
| `CHANGELOG.md` | Edit | T5 |

## Tasks

### T1: Add AC quoted-wording marker check entry to `skills/review-plan/SKILL.md` (~4 min)

**Files:** `skills/review-plan/SKILL.md`

**Action:** Insert one new check entry in the Completeness block, immediately after the self-defeating-verify carve-out (current L46) and immediately before the blank line preceding `**Assumptions:**` (current L48). Mirror the format of L39–L46 exactly: bold-name trigger sentence + indented `- **Carve-out:** ... Canonical positive: ... Canonical negative: ...`.

**Details:**

Use `Edit` with `old_string` anchored on the unique end of the L45–L46 self-defeating-verify entry (the canonical negative for L46 mentions `--exclude-dir=setup`, which is unique within the file). Insert the new check entry between the existing entry's blank line and `**Assumptions:**`.

Concrete entry text to insert (3 lines: bullet + carve-out bullet + trailing blank line — matches the 3-line-per-check pattern of L39–L41, L42–L44, L45–L47):

```
- **AC quoted-wording marker.** When an AC quotes example wording that contains metasyntactic notation (angle-bracketed placeholders like `<placeholder>`, ellipses `…`, or sample-text tokens like `XXX` / `<list>`), the AC must explicitly mark whether the wording is `verbatim: <text>` (text must match literally byte-for-byte at implementation) or `form: <text> (adapt for clarity)` (text is illustrative of structure; implementer chooses concrete wording within the structural form). ACs that quote metasyntactic-containing example wording WITHOUT a marker are flagged for clarification before approving the plan.
  - **Carve-out:** ACs whose quoted wording contains NO metasyntactic notation (plain literal text only — fixed strings used in `grep -Fn` patterns, exact section headings, etc.) pass without requiring a marker. Canonical positive: an AC quoting `` "confirm your summary's first line is `prefix — …`" `` (the trailing `…` is metasyntactic per `.roughly/known-pitfalls.md` L86 LLM self-check anchor pattern) — required `form:` marker (would have prevented the E05.S2.AC2(c) anchoring-wording deferral). Canonical negative: an AC saying `` grep -Fn "Cross-epic AC amendments" CONTRIBUTING.md `` returns ≥1 match — quoted text is verbatim search literal with no metasyntactic notation; no marker required (passes).
```

**Verify:**

```bash
# (a) The new check entry is present
grep -Fn "AC quoted-wording marker" skills/review-plan/SKILL.md
# Expected: exactly 1 match in the Completeness block

# (b) Line cap held (per AC4: ≤300; epic projection ~123, plan target ≤123)
wc -l skills/review-plan/SKILL.md
# Expected: ≤123

# (c) Insertion ordering — new check is between self-defeating verify and Assumptions block
awk '/Self-defeating verify pattern/,/^\*\*Assumptions:\*\*/' skills/review-plan/SKILL.md | grep -Fc "AC quoted-wording marker"
# Expected: 1
```

**UI:** no

### T2: Add `## AC authoring conventions` subsection to `CONTRIBUTING.md` (~4 min)

**Files:** `CONTRIBUTING.md`

**Action:** Insert a new top-level `## AC authoring conventions` subsection between the current `## Skill authoring conventions` section (ends at L66) and the current `## Cross-epic AC amendments` section (begins at L68). Resolves OQ-S4-convention-location: new subsection (Option B per epic L474), chosen because AC text authoring is a distinct domain from skill-body authoring and clusters cleanly with the adjacent `## Cross-epic AC amendments` AC-related convention.

**Details:**

Use `Edit` with `old_string` anchored on the transition between the runtime-shared-procedural-references convention at L66 and the `## Cross-epic AC amendments` heading at L68. The blank line at L67 is the unique insertion point.

Concrete subsection text to insert (placed immediately before `## Cross-epic AC amendments`):

```
## AC authoring conventions

**Quoted-wording markers (`verbatim:` vs `form:`).** When an AC quotes example wording that contains metasyntactic notation — angle-bracketed placeholders like `<placeholder>`, ellipses `…`, or sample-text tokens like `XXX` or `<list>` — explicitly mark whether the wording is verbatim-required or illustrative-only. Recognized markers:

- `verbatim: <text>` — the text must match literally byte-for-byte at implementation (used when the literal string is load-bearing for a `grep -Fn` verify, a regex anchor, or a user-visible contract).
- `form: <text> (adapt for clarity)` — the text is illustrative of the structural form; the implementer chooses concrete wording that satisfies the form.

**Bright-line carve-out:** ACs whose quoted wording contains NO metasyntactic notation (plain literal text only — fixed strings used in `grep -Fn` patterns, exact section headings, etc.) need no marker; verbatim-equality is implicit.

**Examples.** Positive — an AC quoting `` "confirm your summary's first line is `prefix — …`" `` contains the metasyntactic `…` and must carry a `form:` marker (or be rewritten without the ellipsis). Negative — an AC saying `` grep -Fn "Cross-epic AC amendments" CONTRIBUTING.md `` returns ≥1 match quotes only a verbatim search literal; no marker required.

Precipitating evidence: both v0.1.7 E05.S2 deferrals (AC2(c) anchoring wording + AC4 binary-vs-three-way rule) traced back to ambiguity over whether quoted AC example wording was verbatim-required or illustrative. See [.roughly/known-pitfalls.md](.roughly/known-pitfalls.md) L86 (LLM self-check anchor pattern: prefer "begins with" over "is" + ellipsis) for the underlying spec-time anti-pattern this convention forecloses. Enforcement is at plan-review time via the corresponding check in [skills/review-plan/SKILL.md](skills/review-plan/SKILL.md); there is no runtime check.

```

**Verify:**

```bash
# (a) Subsection heading present
grep -Fn "## AC authoring conventions" CONTRIBUTING.md
# Expected: exactly 1 match

# (b) Both marker names present in the new subsection
awk '/## AC authoring conventions/,/## Cross-epic AC amendments/' CONTRIBUTING.md | grep -Fc "verbatim:"
# Expected: ≥1
awk '/## AC authoring conventions/,/## Cross-epic AC amendments/' CONTRIBUTING.md | grep -Fc "form:"
# Expected: ≥1

# (c) Bright-line carve-out language present
awk '/## AC authoring conventions/,/## Cross-epic AC amendments/' CONTRIBUTING.md | grep -Fc "no metasyntactic notation"
# Note: the verify quotes the literal phrase "no metasyntactic notation" used in the new subsection (the `## AC authoring conventions` carve-out paragraph's "contains NO metasyntactic notation" sentence will match — both the SKILL.md check at L47ish and the new convention prose use this exact phrase).
# Expected: ≥1

# (d) Adjacency — new subsection sits between existing skill-authoring and cross-epic sections
awk '/## Skill authoring conventions/,/## Tooling Pitfalls/' CONTRIBUTING.md | grep -Fc "## AC authoring conventions"
# Expected: 1
```

**UI:** no

### T3: Create fixture triple under `tests/fixtures/review-plan/` (~5 min)

**Files (all new):**
- `tests/fixtures/review-plan/ac-marker-pass.md`
- `tests/fixtures/review-plan/ac-marker-needs-revision.md`
- `tests/fixtures/review-plan/ac-marker-borderline-pass.md`

**Action:** Create three new fixture files following the existing `Fixture purpose:` header + minimal synthetic `# Implementation Plan` skeleton pattern (see [tests/fixtures/review-plan/ac1-broader-scope-pass.md](../../tests/fixtures/review-plan/ac1-broader-scope-pass.md), `ac1-broader-scope-needs-revision.md`, `ac1-broader-scope-borderline-pass.md` for the canonical format).

**Details:**

Each fixture must contain a synthetic plan body whose `## Tasks` section includes one or more ACs (typically expressed as task `**Action:**` or `**Details:**` text that quotes example wording the implementer will need to match). All three fixtures MUST exercise the trigger condition — metasyntactic notation present in quoted example wording — per `.roughly/known-pitfalls.md` L142 ("PASS fixtures must exercise the trigger condition, not merely trigger-absence"). The BORDERLINE-PASS must carry exactly one rationale acknowledgment per L148.

**Fixture 1 — `ac-marker-pass.md`:** Synthetic plan where an AC's quoted wording contains metasyntactic notation (e.g., a `<reason>` placeholder in an emit template) AND carries an explicit `form:` or `verbatim:` marker — verify command should accept the plan.

Suggested skeleton (adapt as needed; keep ≤30 lines):

```
**Fixture purpose:** AC quoted-wording marker PASS — AC quotes wording containing metasyntactic notation AND carries the appropriate marker.

# Implementation Plan: Add agent failure-message format requirement

Plan-format-version: 1

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| `agents/example-agent.md` | edit | T1 |

## Tasks

### T1: Add failure-message format MUST line to agent prompt (~3 min)
**Files:** `agents/example-agent.md`
**Action:** Add a new MUST line under `## Failure handling` stating that the agent's failure return must begin with the form `form: "example-agent: failed — <reason> (<path>)" (adapt for clarity)`. The `<reason>` and `<path>` are structural placeholders; the implementer chooses concrete content per failure.
**Details:** Insert the MUST line as a new bullet under the existing `## Failure handling` heading. The marker `form:` signals that the bracketed placeholders are illustrative of the structural form, not literal text to be reproduced.
**Verify:** `grep -Fn "example-agent: failed —" agents/example-agent.md` returns ≥1 match.
**UI:** no
```

**Fixture 2 — `ac-marker-needs-revision.md`:** Synthetic plan where an AC quotes wording containing metasyntactic notation but carries NO marker — verify should return NEEDS REVISION citing this AC by name (the check is "AC quoted-wording marker").

Suggested skeleton:

```
**Fixture purpose:** AC quoted-wording marker NEEDS REVISION — AC quotes wording containing metasyntactic notation but carries NO marker.

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
**Details:** Insert the MUST line as a new bullet under the existing `## Failure handling` heading.
**Verify:** `grep -Fn "example-agent: failed —" agents/example-agent.md` returns ≥1 match.
**UI:** no
```

**Fixture 3 — `ac-marker-borderline-pass.md`:** Synthetic plan where an AC quotes wording containing metasyntactic notation AND carries a marker with close-but-not-identical name (e.g., `literal:` or `template: ... (illustrative)`) — per the carve-out, marker intent supersedes literal-name match when intent is unambiguous. Verify should return PASS with one rationale acknowledgment in a `## Notes` section.

Suggested skeleton:

```
**Fixture purpose:** AC quoted-wording marker BORDERLINE-PASS — AC quotes wording containing metasyntactic notation and carries a close-but-not-identical marker (`literal:` instead of `verbatim:`); intent is unambiguous (exercises carve-out boundary).

# Implementation Plan: Add agent failure-message format requirement

Plan-format-version: 1

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| `agents/example-agent.md` | edit | T1 |

## Notes

The marker used below (`literal:`) is close-but-not-identical to the enumerated `verbatim:` marker. The intent is unambiguous (the AC explicitly states "must match byte-for-byte"), so per the AC quoted-wording marker carve-out, marker intent supersedes literal-name match. This exercises the boundary of the convention.

## Tasks

### T1: Add failure-message format MUST line to agent prompt (~3 min)
**Files:** `agents/example-agent.md`
**Action:** Add a new MUST line under `## Failure handling` stating that the agent's failure return must begin with `literal: "example-agent: failed — <reason>"` — the text must match byte-for-byte at implementation, with `<reason>` substituted per failure.
**Details:** Insert the MUST line as a new bullet under the existing `## Failure handling` heading.
**Verify:** `grep -Fn "example-agent: failed —" agents/example-agent.md` returns ≥1 match.
**UI:** no
```

**Verify:**

```bash
# (a) All three fixture files exist
for f in ac-marker-pass.md ac-marker-needs-revision.md ac-marker-borderline-pass.md; do
  test -f "tests/fixtures/review-plan/$f" || { echo "MISSING: $f"; exit 1; }
done && echo "all 3 fixtures present"
# Expected: "all 3 fixtures present"

# (b) Each fixture opens with the canonical `**Fixture purpose:**` header (line 1)
for f in ac-marker-pass.md ac-marker-needs-revision.md ac-marker-borderline-pass.md; do
  head -1 "tests/fixtures/review-plan/$f" | grep -Fq "**Fixture purpose:**" || { echo "BAD HEADER: $f"; exit 1; }
done && echo "headers OK"
# Expected: "headers OK"

# (c) BORDERLINE-PASS has exactly one `## Notes` rationale block (per L148 discipline)
grep -Fc "## Notes" tests/fixtures/review-plan/ac-marker-borderline-pass.md
# Expected: 1

# (d) Each fixture contains metasyntactic notation in the quoted-wording region (PASS-fires-trigger discipline per L142)
# Substantively: each fixture exercises the trigger condition — the angle-bracketed `<reason>` placeholder
# is the metasyntactic notation in all three fixtures' quoted example wording. Grepping for the
# literal `<reason>` is the load-bearing verify (counting `<` or `…` would over-match because
# the metasyntax tokens this AC targets are specifically angle-bracketed placeholders, ellipses,
# and `XXX`-style tokens; `<reason>` is the chosen exemplar across all three fixtures).
for f in ac-marker-pass.md ac-marker-needs-revision.md ac-marker-borderline-pass.md; do
  grep -Fq "<reason>" "tests/fixtures/review-plan/$f" || { echo "MISSING TRIGGER: $f"; exit 1; }
done && echo "trigger present in all 3"
# Expected: "trigger present in all 3"
```

**UI:** no

### T4: Update `tests/fixtures/review-plan/README.md` (~4 min)

**Files:** `tests/fixtures/review-plan/README.md`

**Action:** Two edits to the README:

**Edit site 1** — Append three new rows to the Fixture Inventory table (after the existing last data row `ac-joint-satisfiability-needs-revision.md` at L37):

```
| `ac-marker-pass.md` | E06.S4 AC1 (AC quoted-wording marker) | PASS | AC quotes wording containing metasyntactic notation AND carries appropriate `verbatim:` or `form:` marker. |
| `ac-marker-needs-revision.md` | E06.S4 AC1 | NEEDS REVISION | AC quotes wording containing metasyntactic notation (`<reason>` placeholder, trailing `…`) but carries NO marker. |
| `ac-marker-borderline-pass.md` | E06.S4 AC1 | PASS | Close-but-not-identical marker (`literal:` instead of `verbatim:`) with unambiguous intent + single `## Notes` rationale; exercises carve-out boundary. |
```

**Edit site 2** — Update Path A desk-check line-number references (L49–L56). T1 inserts ~3 lines at L47, shifting all Assumptions-block check line numbers by +3. Replace the existing 8-line check list with the updated line numbers. The new E06.S4 check is the one being added at the old L47 region.

Use `Edit` per edit site. Verify after each.

**Details:**

For Edit site 2, capture the actual post-T1 line numbers by running `grep -Fn` queries against the post-T1 `skills/review-plan/SKILL.md`. Substitute the captured numbers into the README Path A list. Add a new bullet for E06.S4 AC1 at its captured line number.

Pre-edit Path A list (current L49–L56):
```
- E04.S6 AC1 (Every edit site enumerated): line 36 — "Every edit site enumerated" + carve-out
- E04.S6 AC2 (Runtime-signal source named): line 53 — "Runtime-signal source named" + carve-out
- E05.S3 AC1 (verify-command scope matches spec enumeration): line 39 — asymmetry + carve-out
- E05.S3 AC2 (`grep -Fc` / `grep -Fn` same-line co-location hazard): line 42 — co-location + carve-out
- E05.S3 AC3 (defensive guard vs new invariant): line 56 — guard vs invariant + carve-out
- E05.S3 AC4 (behavior-divergence doc coverage): line 59 — doc coverage + carve-out
- E05.S3 AC5 (self-defeating verify pattern): line 45 — self-defeating + carve-out
- E05.S6 AC2 (AC joint satisfiability): line 62 — joint satisfiability + carve-out
```

Post-T1 expected updates (lines that shift by +3 because the new entry inserts 3 lines at L47):
- E04.S6 AC1 (L36) — UNCHANGED (above insertion point)
- E04.S6 AC2 (L53) — shifts to L56
- E05.S3 AC1 (L39) — UNCHANGED (above insertion point)
- E05.S3 AC2 (L42) — UNCHANGED (above insertion point)
- E05.S3 AC3 (L56) — shifts to L59
- E05.S3 AC4 (L59) — shifts to L62
- E05.S3 AC5 (L45) — UNCHANGED (above insertion point)
- E05.S6 AC2 (L62) — shifts to L65
- **NEW** E06.S4 AC1 (AC quoted-wording marker): L47

The implementer MUST run `grep -Fn` queries against the post-T1 `skills/review-plan/SKILL.md` to **observe** the actual line numbers rather than relying on the projected +3 arithmetic (the actual insertion size may differ slightly from the projection due to wrapping or trailing-blank-line decisions). Inserting the projected list into the README WITHOUT the post-T1 verify step is a stale-line-number bug.

**Verify:**

```bash
# (a) All three new inventory rows present
grep -Fc "ac-marker-pass.md" tests/fixtures/review-plan/README.md
# Expected: ≥1
grep -Fc "ac-marker-needs-revision.md" tests/fixtures/review-plan/README.md
# Expected: ≥1
grep -Fc "ac-marker-borderline-pass.md" tests/fixtures/review-plan/README.md
# Expected: ≥1

# (b) E06.S4 cited in inventory table
grep -Fc "E06.S4 AC1" tests/fixtures/review-plan/README.md
# Expected: ≥3 (one per new fixture row)

# (c) Path A line numbers match actual post-T1 SKILL.md positions
# For each (check-name, line-number) pair in the README Path A section,
# verify the named check actually appears at the cited line in skills/review-plan/SKILL.md.
# Spot-check at least the two shifted entries (E04.S6 AC2 and E05.S6 AC2):
EAC2_LINE=$(sed -n "$(grep -Fn 'E04.S6 AC2' tests/fixtures/review-plan/README.md | head -1 | awk -F: '{print $1}')p" tests/fixtures/review-plan/README.md | grep -Eo 'line [0-9]+' | awk '{print $2}')
sed -n "${EAC2_LINE}p" skills/review-plan/SKILL.md | grep -Fq "Runtime-signal source named" || echo "MISMATCH: E04.S6 AC2 line number stale"
# Expected: no MISMATCH output

# (d) New E06.S4 AC1 entry added to Path A list
grep -Fc "E06.S4 AC1" tests/fixtures/review-plan/README.md
# Expected: ≥4 (3 inventory rows + 1 Path A bullet)
```

**Depends on:** T1 (line-number observations require T1 to have landed).

**UI:** no

### T5: Add `### Added` section to `CHANGELOG.md` `[0.1.8]` block (~3 min)

**Files:** `CHANGELOG.md`

**Action:** Insert a new `### Added` section into the existing `[0.1.8]` block, placed BEFORE the existing `### Changed` section. Per CHANGELOG `[0.1.7]` pattern (L30), `### Added` precedes `### Changed`.

**Details:**

Use `Edit` with `old_string` targeting the boundary between the `[0.1.8]` blockquote (L5) and `### Changed` (L7). The `old_string` must include enough context to anchor uniquely (the blockquote line is unique; `### Changed` alone appears in multiple version blocks).

Concrete `### Added` entry text (single multi-line bullet documenting the convention, per CHANGELOG entry-format precedent):

```
### Added

- **AC quoted-wording marker convention — review-plan check + CONTRIBUTING.md codification (E06.S4).** New spec-authoring convention preventing ambiguity over whether AC-quoted example wording is verbatim-required or illustrative. Two recognized markers: `verbatim: <text>` (text must match literally byte-for-byte at implementation) and `form: <text> (adapt for clarity)` (text is illustrative of structural form; implementer chooses concrete wording). Bright-line carve-out: ACs whose quoted wording contains no metasyntactic notation (plain literal text only) need no marker. Convention codified in [CONTRIBUTING.md](CONTRIBUTING.md) `## AC authoring conventions` (new top-level subsection between `## Skill authoring conventions` and `## Cross-epic AC amendments`, resolving OQ-S4-convention-location toward the new-subsection option per the AC-text-authoring-distinct-from-skill-body-authoring rationale). Enforced at plan-review time via the corresponding check entry in [skills/review-plan/SKILL.md](skills/review-plan/SKILL.md) Completeness block. Three new fixtures landed in `tests/fixtures/review-plan/` (`ac-marker-pass.md`, `ac-marker-needs-revision.md`, `ac-marker-borderline-pass.md`) per E05.S3 + E05.S7c triple discipline. Cross-references:
  - **Maps to v0.1.8 candidate:** E05.S2 candidate #5 (CHANGELOG L33 of the `[0.1.7]` block — "AC quoted-wording marker convention" entry in the "Six v0.1.8 candidates" bullet).
  - **Prevented deferral cases:** E05.S2.AC2(c) anchoring-wording deferral + E05.S2.AC4 binary-vs-three-way rule deferral — both traced to ambiguity over verbatim-vs-illustrative quoted AC wording. Convention would have surfaced both at plan-review time.
  - **Underlying spec-time anti-pattern:** [.roughly/known-pitfalls.md](.roughly/known-pitfalls.md) L86 (LLM self-check anchor pattern: prefer "begins with" over "is" + ellipsis) — the spec-time form the convention forecloses by requiring an explicit marker on any quoted wording carrying `…`. (Note: epic L302 and L315 reference the pitfall as L80; actual current line is L86 — the discrepancy is a known stale-line-reference in the epic text, captured here for cubic-readability.)
  - **Fixture-design discipline anchors:** [.roughly/known-pitfalls.md](.roughly/known-pitfalls.md) L142 (PASS fixtures must exercise the trigger condition) + L148 (BORDERLINE-PASS single rationale acknowledgment).

```

**Verify:**

```bash
# (a) `### Added` section present in [0.1.8] block
awk '/## \[0.1.8\]/,/## \[0.1.7\]/' CHANGELOG.md | grep -Fc "### Added"
# Expected: 1

# (b) Section ordering — `### Added` precedes `### Changed` within [0.1.8]
awk '/## \[0.1.8\]/,/## \[0.1.7\]/' CHANGELOG.md | grep -nE "^### (Added|Changed)$" | head -2
# Expected first line: "### Added"; second line: "### Changed"

# (c) Required cross-references present in the new entry
awk '/## \[0.1.8\]/,/## \[0.1.7\]/' CHANGELOG.md | grep -Fc "AC quoted-wording marker convention"
# Expected: ≥1
awk '/## \[0.1.8\]/,/## \[0.1.7\]/' CHANGELOG.md | grep -Fc "E05.S2 candidate #5"
# Expected: ≥1
awk '/## \[0.1.8\]/,/## \[0.1.7\]/' CHANGELOG.md | grep -Fc "E05.S2.AC2(c)"
# Expected: ≥1
awk '/## \[0.1.8\]/,/## \[0.1.7\]/' CHANGELOG.md | grep -Fc "binary-vs-three-way"
# Expected: ≥1
awk '/## \[0.1.8\]/,/## \[0.1.7\]/' CHANGELOG.md | grep -Fc "known-pitfalls.md"
# Expected: ≥1

# (d) Confirm prior E06.S1 `### Changed` content untouched (regression guard against bad insertion overwriting existing prose)
grep -Fc "doc-writer all-fail-branch anchoring tightened (E06.S1.AC1)" CHANGELOG.md
# Expected: 1 (unchanged from pre-edit count)
```

**Depends on:** T2 (the `### Added` entry references `## AC authoring conventions` in CONTRIBUTING.md, which T2 creates).

**UI:** no

## Blast Radius

**Modify:**
- `skills/review-plan/SKILL.md` (T1 — Completeness block, single new check entry)
- `CONTRIBUTING.md` (T2 — single new top-level subsection between existing sections)
- `tests/fixtures/review-plan/README.md` (T4 — inventory table append + Path A line-number updates)
- `CHANGELOG.md` (T5 — single new `### Added` section in `[0.1.8]` block)

**Create:**
- `tests/fixtures/review-plan/ac-marker-pass.md`
- `tests/fixtures/review-plan/ac-marker-needs-revision.md`
- `tests/fixtures/review-plan/ac-marker-borderline-pass.md`

**Do NOT modify:**
- `.roughly/known-pitfalls.md` — AC5 references but does not amend. Stale epic line refs (L80→L86, L138→L142, L143→L148) are captured in CHANGELOG entry for cubic-readability; epic text itself is shipped contract and not retroactively edited per E05.S3 `## Cross-epic AC amendments` convention.
- Existing fixture files in `tests/fixtures/review-plan/` — immutable per README L79–L82.
- `.claude/hooks/verify-all.sh` — no new runtime check; AC5 explicitly notes "no runtime enforcement."
- Existing CHANGELOG entries (E06.S1 `### Changed` content in `[0.1.8]`).
- Epic file `docs/planning/epics/E06-anchoring-closure-and-ci-coverage.md` — out of scope; epic L302/L315 stale line refs are captured-as-known in T5's CHANGELOG entry rather than retroactively patched.

**Watch for:**
- **Path A line-number cascade.** T4 must observe actual post-T1 line numbers via `grep -Fn`, not arithmetic projection. The "Doc claims that cite specific line numbers" pitfall (CONTRIBUTING.md L110, `## Tooling Pitfalls`) applies — citing stale line numbers in README Path A is a discoverable bug.
- **CHANGELOG `### Added` insertion ordering.** Naive `Edit` append into the `[0.1.8]` block would produce `### Changed` followed by `### Added`, violating CHANGELOG convention. Insertion must target the boundary between the L5 blockquote and the L7 `### Changed` heading.
- **BORDERLINE-PASS single-rationale discipline.** AC3's BORDERLINE-PASS fixture must carry exactly one `## Notes` rationale block. Zero acknowledgments degrades to NEEDS REVISION semantically (per L148); multiple acknowledgments dilute the single-rationale test signal.
- **PASS-fires-trigger discipline.** All three fixtures must contain the trigger condition (metasyntactic notation in quoted AC wording). A PASS-by-trigger-absence is invalid per L142.

## Conventions

- New check entry format mirrors `skills/review-plan/SKILL.md` L39–L46 (E05.S3 entries): bold-name trigger sentence + indented `- **Carve-out:** ... Canonical positive: ... Canonical negative: ...` (per E04.S6 + E05.S3 organizational precedent referenced by epic L295).
- New CONTRIBUTING.md subsection format mirrors the adjacent `## Cross-epic AC amendments` at L68–L78 (top-level `##` subsection, prose convention with named recognized forms + bright-line carve-out + canonical examples + precipitating evidence cross-reference).
- Fixture format mirrors `tests/fixtures/review-plan/ac1-broader-scope-*.md` triple: `**Fixture purpose:**` header line 1, then `# Implementation Plan: ...` with `Plan-format-version: 1` + `## File Table` + (optional `## Notes` for BORDERLINE-PASS) + `## Tasks`.
- Fixture inventory rows match the existing table format: `` | `<file>` | <Targets> | <Expected verdict> | <Reason> | ``.
- CHANGELOG entry format mirrors `[0.1.7]` `### Added` entries (L32–L48): bold-name + story ID in parentheses, prose body, indented sub-bullets for cross-references using `[file](file)` inline-link form.
- ADRs binding: ADR-001 (review-plan is subagent-dispatch-only — confirmed already documented in fixtures README L41–L43). No new ADR required.

## Self-validation context for /roughly:review-plan dispatch in Stage 4

Per AC5: this plan's body should be reviewed by `/roughly:review-plan` with the post-E05.S3 checks active (E05.S3.AC1–AC5 + E05.S6.AC2 + E04.S6.AC1–AC2). The post-E06.S4 marker check is NOT yet shipped, so the plan body itself need not satisfy that check (it will be active for downstream stories per epic L321). The plan's quoted ACs intentionally avoid bare metasyntactic notation in AC1's `Concrete entry text to insert` blocks — the blocks ARE the verbatim convention text being installed and are inside fenced code blocks (verbatim by markdown convention), so no marker is needed at this plan layer. Any AC quoted wording in the plan body that does carry metasyntactic notation (e.g., the `<text>` and `<reason>` placeholders in the convention text) is enclosed in code fences and used as illustrative-only structural form — the implicit `form:` semantics apply by the fenced-code-block convention. Plan body should PASS without explicit marker annotation under the bright-line carve-out for fenced-code-block-quoted illustrative content.
