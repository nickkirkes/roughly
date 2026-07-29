> **Status:** Historical — implemented and merged in commit d5bccf7 on 2026-07-28. This plan was an active build/fix artifact; treat as historical reference only.

# Fix Plan: #82 — codify CI assertion authoring convention (behavioral + structural)

Plan-format-version: 1

## Root Cause

The discipline that CI fixture assertions must combine **structural** signals (transcript markers, file presence, line/section counts) with at least one **behavioral** signal (run the fixture's own regression test, require its expected exit code) shipped only *inline* as E06.S2's "F6" assertion in `scripts/ci-dogfood.sh` — it was never codified in project docs. Structural-only assertions silently pass behavior-regressed implementations (a fix emitting `echo "goodbye $NAME"` satisfies the plan-structure and `$NAME`-reference greps yet produces wrong output). Without codification, future CI-scenario authors (fix-side negative-path scenarios in v0.1.9+, other pipelines) re-discover the gap from scratch. Docs-convention codification, not a code bug.

## Scope (2 tasks — enforcement verdict: CONTRIBUTING-only + known-pitfalls companion; NO review-plan check)
- **T1:** `CONTRIBUTING.md` — create a **new `## CI conventions` section** (immediately before the existing operational `## CI` section) holding the behavioral+structural fixture-assertion convention. Investigator verdict: this governs hand-authored bash assertions in `scripts/`, which `review-plan` never sees — so, unlike #81/#83/#84, there is **no** plan-review enforcement point; the paragraph closes with a pointer to the F6 canonical example + the known-pitfalls companion (mirroring how `## Audit conventions` closes), NOT an "Enforcement is at plan-review time…" sentence.
- **T2:** `.roughly/known-pitfalls.md` — new companion entry under `## Build & Deploy` (where the ci-dogfood assertion-soundness pitfalls already cluster), placed right after the topically-adjacent `### CI assertions on Roughly pipeline aborts must be marker-primary…` entry. Symptom/Cause/Fix template matching its siblings. Not a duplicate of the `grep -L` any-line entry or the `set -e` exit-capture entry.
- Cross-reference by **section name, not line number** (honor the line-number-rot pitfall). Cite the F6 example by its comment-anchor phrase ("the fixture's own regression test"), label F6 only parenthetically, to avoid label-rot if assertions renumber.

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| CONTRIBUTING.md | Modify (insert new `## CI conventions` section before `## CI`) | T1 |
| .roughly/known-pitfalls.md | Modify (append 1 `### ` entry within `## Build & Deploy`) | T2 |

## Baseline facts (captured 2026-07-28, branch `fix/81-86-contributing-convention-bundle`, 6 commits ahead of main)
- `CONTRIBUTING.md`: `## Testing` section ends at "5. Verify line/word limits: skills < 300 lines, agents < 650 words", blank line, then `## CI` whose body begins `**Triggering.** The dogfood runs real, **billed** Claude sessions…`. No `## CI conventions` section exists yet. No line cap on CONTRIBUTING.md.
- `.roughly/known-pitfalls.md` `## Build & Deploy` (heading ~L20): last two entries are `### CI assertions on Roughly pipeline aborts must be marker-primary, not exit-code-primary` (ends "…See ADR-013, `scripts/ci-dogfood.sh` build-abort scenario, and E06.S3 epic AC4 deviation note. Discovered E06.S3 (2026-06-09).") followed by `### Plugin-bundled file references must be anchored with `${CLAUDE_PLUGIN_ROOT}`…`; the section ends before `## Skill & Agent Authoring`. Entries use `### <title>` + `**Symptom:**` / `**Cause:**` / `**Fix:**`. File ~197 lines, well under the 300 organize-threshold.
- Canonical F6 example (`scripts/ci-dogfood.sh`, fix scenario): comment "Assertion F6: the fixture's own regression test now passes (behavioral proof… the grep checks above are necessary but not sufficient (e.g. `echo "goodbye $NAME"` satisfies F5a/F5b but fails this test))"; runs `bash …/greeter.test.sh` capturing exit via `OUT="$(...)" && EXIT=0 || EXIT=$?`, fails on non-zero.
- Origin (verified quote, E06 epic v0.1.9-candidates, 2026-06-08): "CI assertion authoring: behavioral + structural, not structural-only (E06.S2 PR-review observation; AC3 strengthening). E06.S2 AC3 originally specified structural/grep assertions only… F6 was added beyond AC3's description: run the fixture's regression test, require exit 0."
- Session shims `grep`/`awk` availability is fine — use `command grep`.

## Tasks

### T1: Add the `## CI conventions` section to CONTRIBUTING.md (~4 min)
**Files:** CONTRIBUTING.md
**Action:** Insert a NEW `## CI conventions` section (heading + one convention paragraph) immediately before the existing `## CI` operational section, i.e. between the `## Testing` section's last line and `## CI`. Keep exactly one blank line separating the new section's paragraph from the `## CI` heading that follows.
**Details:** Do a single exact-string Edit. Match the seam `## CI\n\n**Triggering.**` and prepend the new section before `## CI`. Insert this EXACT content so the region becomes:

```
## CI conventions

**Behavioral + structural fixture assertions.** A CI fixture assertion suite must combine **structural** signals (transcript markers, file presence, line/section counts) with at least one **behavioral** signal: run the fixture's own regression check and require its expected exit code. Structural-only assertions silently pass behavior-regressed implementations — a fix that emits `echo "goodbye $NAME"` satisfies grep markers for the plan structure and the `$NAME` reference yet produces the wrong output, so a suite without a behavioral check reports green on a broken fix. Capture the behavioral test's exit with the `OUT="$(...)" && EXIT=0 || EXIT=$?` idiom so `set -e` does not kill the script before the diagnostic fires; the structural checks remain necessary but not sufficient. Precipitating evidence: E06.S2's AC3 originally specified grep-only structural assertions; PR review flagged that they miss behavior regressions, so an assertion was added that runs the fixture's own regression test and requires exit 0 (E06.S2 PR-review observation / AC3 strengthening, 2026-06-08). See the canonical example in `scripts/ci-dogfood.sh` — the fix-scenario assertion that runs the fixture's own regression test post-fix (labeled F6) — and `.roughly/known-pitfalls.md` § "Build & Deploy".

## CI

**Triggering.**
```

Do not modify the `## Testing` section, the `## CI` operational content, or any other section.
**Verify:**
```
cd "$(git rev-parse --show-toplevel)"
command grep -qxF '## CI conventions' CONTRIBUTING.md || { echo FAIL-no-heading; exit 1; }
command grep -qF '**Behavioral + structural fixture assertions.**' CONTRIBUTING.md || { echo FAIL-no-convention; exit 1; }
# new section sits BEFORE the operational ## CI section
awk '/^## CI conventions$/{c=NR} /^## CI$/{o=NR} END{exit !(c>0 && o>0 && c<o)}' CONTRIBUTING.md || { echo FAIL-wrong-order; exit 1; }
# operational CI content untouched
command grep -qF '**Triggering.** The dogfood runs real' CONTRIBUTING.md || { echo FAIL-ci-body-lost; exit 1; }
echo "T1 PASS"
```
**UI:** no

### T2: Add the known-pitfalls companion entry under `## Build & Deploy` (~4 min)
**Files:** .roughly/known-pitfalls.md
**Action:** Append ONE `### ` entry (Symptom/Cause/Fix) to `## Build & Deploy`, placed immediately after the `### CI assertions on Roughly pipeline aborts must be marker-primary, not exit-code-primary` entry (which ends "…Discovered E06.S3 (2026-06-09).") and before the `### Plugin-bundled file references must be anchored…` entry. Keep one blank line before and after the new entry.
**Details:** Do a single exact-string Edit anchored on the marker-primary entry's ending + the next heading. Match:

`Discovered E06.S3 (2026-06-09).\n\n### Plugin-bundled file references`

and replace with the marker-primary ending, the new entry, then the `### Plugin-bundled file references` heading — i.e. insert this EXACT block between them (one blank line each side):

```
### CI fixture assertions must be behavioral + structural, not structural-only

**Symptom:** A CI fixture assertion suite passes on an implementation that is structurally plausible but behaviorally wrong. E.g. a fix emitting `echo "goodbye $NAME"` satisfies grep markers for the plan structure and the `$NAME` variable reference, so a grep-only suite reports green even though the fixture produces the wrong output.
**Cause:** Structural assertions (transcript markers, file presence, line/section counts) verify that the right *shape* was produced, not that it *behaves* correctly — on their own they cannot distinguish a correct fix from a same-shaped wrong one.
**Fix:** Pair the structural greps with at least one behavioral assertion — run the fixture's own regression test and require its expected exit code (capture the exit with the `OUT="$(...)" && EXIT=0 || EXIT=$?` idiom so `set -e` does not kill the script before the diagnostic fires). The structural checks stay necessary but not sufficient. Canonical example: `scripts/ci-dogfood.sh` fix scenario — the assertion that runs the fixture's own regression test post-fix (F6). Codified in `CONTRIBUTING.md` § "CI conventions". Origin: E06.S2 PR-review / AC3 strengthening (2026-06-08).
```

Do not modify the marker-primary entry, the `### Plugin-bundled file references` entry, or any other section.
**Verify:**
```
cd "$(git rev-parse --show-toplevel)"
command grep -qF '### CI fixture assertions must be behavioral + structural, not structural-only' .roughly/known-pitfalls.md || { echo FAIL-not-added; exit 1; }
command grep -qF 'Codified in `CONTRIBUTING.md` § "CI conventions"' .roughly/known-pitfalls.md || { echo FAIL-no-crossref; exit 1; }
# lands inside ## Build & Deploy (before ## Skill & Agent Authoring)
awk '/^## Build & Deploy/{a=1} /^## Skill & Agent Authoring/{a=0} a && /behavioral \+ structural, not structural-only/{f=1} END{exit !f}' .roughly/known-pitfalls.md || { echo FAIL-wrong-section; exit 1; }
# marker-primary sibling still intact
command grep -qF '### CI assertions on Roughly pipeline aborts must be marker-primary, not exit-code-primary' .roughly/known-pitfalls.md || { echo FAIL-sibling-lost; exit 1; }
n=$(wc -l < .roughly/known-pitfalls.md); [ "$n" -le 300 ] || { echo "FAIL-over-threshold $n"; exit 1; }
out=$(bash .claude/hooks/verify-all.sh 2>&1); [ -z "$out" ] || { echo "FAIL-verify-not-clean: $out"; exit 1; }
echo "T2 PASS ($n lines)"
```
**UI:** no

## Blast Radius
- **Do NOT modify:** the `## Testing` or operational `## CI` sections of CONTRIBUTING.md; the `## Skill authoring conventions` / `## AC authoring conventions` sections (#82 is a *different* artifact class — CI-scenario authoring, not skill-markdown or plan-AC authoring); the marker-primary or `${CLAUDE_PLUGIN_ROOT}` known-pitfalls entries adjacent to the T2 seam; `scripts/ci-dogfood.sh` (source of truth — cited, not edited); any code/agent/other file; the E06 epic (historical source).
- **Watch for:** (a) do NOT append the convention to `## Skill authoring conventions` — create the dedicated `## CI conventions` section; (b) the convention paragraph must NOT carry an "Enforcement is at plan-review time…" closer (no review-plan hook exists for this); (c) cite F6 by comment-anchor phrase, label parenthetically (avoid label-rot); (d) cross-refs by section name, never line number; (e) known-pitfalls stays under 300; (f) shimmed grep — use `command grep`; (g) all Verify greps here are POSITIVE-presence checks for literals being added — none are self-defeating negative greps.

## Conventions
- No build/test harness — inline `command grep`/`awk`/verify-all-clean Verify blocks are the validation.
- T1/T2 touch 2 distinct files → parallelizable.
