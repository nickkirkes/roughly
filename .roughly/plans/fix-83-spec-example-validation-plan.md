> **Status:** Historical — implemented and committed in commit 171025dc8e6dd1897d1e4115c07c6f0a5886f7e6 on 2026-07-28. This plan was an active build/fix artifact; treat as historical reference only.

# Fix Plan: #83 — codify spec-example command validation at plan-review

Plan-format-version: 1

## Root Cause

ACs (and normative docs) can embed executable example content — shell commands, code snippets, structured-data literals — and pass plan-review + Stage 6 without the example ever being run: reviewers validate that the example *means* the right thing and that cross-references resolve, not that it *executes*. E06.S7.AC1 shipped a malformed `gh api PATCH /repos/<owner>/<repo>/pulls/<pr>` example (HTTP method passed as a positional instead of via `--method`/`-X`); it survived plan-review + Stage 6 and shipped into `CONTRIBUTING.md`, caught only by external post-merge review (2026-06-09). This is a docs-convention codification, not a code bug. It is the execution-validation twin of #81's "verified"-tag provenance rule (same E06.S7.AC1 incident, different facet).

## Scope (user-confirmed: T1+T2+T3)
- **T1 (ticket core):** `CONTRIBUTING.md` `## AC authoring conventions` — the executable-example verify-command convention. Exact wording pre-drafted at `docs/planning/epics/complete/E06-anchoring-closure-and-ci-coverage.md:575`; promote it.
- **T2 (loop-closing enforcement, user-approved):** `skills/review-plan/SKILL.md` `**Completeness:**` — a paired review-time check. The title is "…at plan-review" and the failure was the review subagent approving without executing; every prior AC-authoring convention (e.g. the quoted-wording marker) has a mirrored review-plan check (review-plan:L46), and CONTRIBUTING:L81 already names review-plan as the enforcement site — #83 without one would be the lone unpaired convention.
- **T3 (companion, user-approved):** `.roughly/known-pitfalls.md` `## Documentation Hygiene` — the execution-validation lesson, twin of #81's provenance entry (same incident).
- Cross-reference all additions by **section name, not line number** (honor the "line-number citations rot" pitfall directly above the T3 seam). Cite the incident as **E06.S7 "Post-merge correction (2026-06-09)"** — the correction (i) at `E06-…md:453` (NOT the "Second post-merge correction" at :455, which is #81's provenance facet).

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| CONTRIBUTING.md | Modify (append 1 paragraph to `## AC authoring conventions`) | T1 |
| skills/review-plan/SKILL.md | Modify (append 1 `**Completeness:**` check) | T2 |
| .roughly/known-pitfalls.md | Modify (append 1 `## Documentation Hygiene` entry) | T3 |

## Baseline facts (captured 2026-07-28, branch `fix/81-86-contributing-convention-bundle`, 2 commits ahead of main = #81)
- `CONTRIBUTING.md` `## AC authoring conventions` (L68) ends at the `Precipitating evidence:` paragraph (L81, ending "…there is no runtime check."), L82 blank, `## Cross-epic AC amendments` at L83. Insert the new peer paragraph after L81, keeping one blank before it and one blank after (before `## Cross-epic AC amendments`). No line cap on CONTRIBUTING.
- `skills/review-plan/SKILL.md` (118/300 lines) `**Completeness:**` block ends with the `- **AC quoted-wording marker.**` bullet (L46), then a blank, then `**Assumptions:**` (L49). Insert the new `- ` bullet after the quoted-wording bullet, before `**Assumptions:**`, with blank-line separation. review-plan is NO LONGER a byte-identity-checked file (its pre-flight block + Check 5 were removed in #80) — only the ≤300 cap applies (118→~123, fine).
- `.roughly/known-pitfalls.md` (194/300) `## Documentation Hygiene` last entry is #81's "A 'verified' tag…" (L124), then L125 blank, `## Planning & Scoping` at L126. Append the new bullet after L124, before the blank. Threshold 300 (194→~197, fine; verify-all stays clean).
- Canonical pre-drafted convention text (`E06-…md:575`): "ACs that include executable example content (shell commands, code snippets) must include a verify command that asserts the example executes successfully or matches the expected grammar (e.g., `command --help`, syntax-check linter, dry-run flag). For shell commands, a `--help` exit-0 check is the minimum acceptable validation."
- Session may shim grep — use `command grep`.

## Tasks

### T1: Add the executable-example convention to CONTRIBUTING.md (~4 min)
**Files:** CONTRIBUTING.md
**Action:** Append one bold-lead-in paragraph to the END of `## AC authoring conventions` (after the `Precipitating evidence:` paragraph ending "…there is no runtime check.", before the blank preceding `## Cross-epic AC amendments`). Match the section's house style (bold lead-in + rule + `Precipitating evidence:` + enforcement pointer).
**Details:** Insert this EXACT paragraph, keeping one blank line before it and one after (before `## Cross-epic AC amendments`):

`**Executable example content.** When an AC's normative text embeds executable example content — a shell command, code snippet, or structured-data literal (JSON/YAML) presented as something to run or paste — the AC must carry a verify command that asserts the example actually executes or matches the expected grammar (a \`command --help\` exit-0 check, a syntax-check linter, or a dry-run flag; for a shell command a \`--help\` exit-0 check is the minimum acceptable validation). Validating intent and cross-references is not enough — an example that reads plausibly can still be non-working. Precipitating evidence: E06.S7.AC1 shipped a malformed \`gh api PATCH /repos/<owner>/<repo>/pulls/<pr>\` example (\`gh api\` takes the HTTP method via \`--method\`/\`-X\`, not as a positional) — Stage 6 validated intent and cross-references but never executed it, so the defect shipped into this file until external review caught it (E06.S7 "Post-merge correction," 2026-06-09). Enforcement is at plan-review time via the corresponding check in [skills/review-plan/SKILL.md](skills/review-plan/SKILL.md); there is no runtime check.`

Do not modify the existing quoted-wording convention or `## Cross-epic AC amendments`.
**Verify:**
```
cd "$(git rev-parse --show-toplevel)"
command grep -qF '**Executable example content.**' CONTRIBUTING.md || { echo FAIL-not-added; exit 1; }
command grep -qF 'a `--help` exit-0 check is the minimum' CONTRIBUTING.md || { echo FAIL-no-floor; exit 1; }
awk '/^## AC authoring conventions/{a=1} /^## Cross-epic AC amendments/{a=0} a && /Executable example content/{f=1} END{exit !f}' CONTRIBUTING.md || { echo FAIL-wrong-section; exit 1; }
command grep -qF 'traced back to ambiguity over whether quoted AC example wording' CONTRIBUTING.md || { echo FAIL-existing-lost; exit 1; }
echo "T1 PASS"
```
**UI:** no

### T2: Add the paired enforcement check to review-plan (~4 min)
**Files:** skills/review-plan/SKILL.md
**Action:** Append one `- ` bullet to the END of the `**Completeness:**` block (after the `- **AC quoted-wording marker.**` bullet, before `**Assumptions:**`). Match the checklist style (bold lead-in + rule + "flagged for clarification before approving the plan" + Canonical negative citing a story).
**Details:** Insert this EXACT bullet, keeping one blank line before it and one after (before `**Assumptions:**`):

`- **AC executable-example verify command.** When an AC's normative text embeds executable example content (a shell command, code snippet, or structured-data literal presented as something to run or paste), its verify command must assert the example actually executes or matches the expected grammar — a \`command --help\` exit-0 check, a syntax-check linter, or a dry-run flag (for shell commands, a \`--help\` exit-0 check is the minimum). ACs with unvalidated executable examples are flagged for clarification before approving the plan.`
   (then a nested carve-out sub-bullet, indented two spaces to match sibling `- **Carve-out:**` lines:)
`  - **Carve-out:** illustrative or pseudocode snippets not presented as literally runnable (schematic templates, prose-with-inline-code, `<placeholder>`-heavy forms) are out of scope — the check fires only on an example an implementer would copy-paste and run. Canonical negative: E06.S7.AC1 shipped a malformed \`gh api PATCH …\` example (HTTP method as a positional instead of \`--method\`/\`-X\`) — Stage 6 validated intent and cross-references but never ran it against \`gh\`'s grammar; the defect was caught only by external post-merge review (2026-06-09).`

Do not modify the existing checks or the `**Assumptions:**`/`**Overengineering:**` blocks.
**Verify:**
```
cd "$(git rev-parse --show-toplevel)"
command grep -qF '**AC executable-example verify command.**' skills/review-plan/SKILL.md || { echo FAIL-not-added; exit 1; }
command grep -qF '**Carve-out:** illustrative or pseudocode snippets' skills/review-plan/SKILL.md || { echo FAIL-no-carveout; exit 1; }
awk '/\*\*Completeness:\*\*/{a=1} /\*\*Assumptions:\*\*/{a=0} a && /AC executable-example verify command/{f=1} END{exit !f}' skills/review-plan/SKILL.md || { echo FAIL-wrong-block; exit 1; }
command grep -qF '**AC quoted-wording marker.**' skills/review-plan/SKILL.md || { echo FAIL-existing-lost; exit 1; }
n=$(wc -l < skills/review-plan/SKILL.md); [ "$n" -le 300 ] || { echo "FAIL-cap $n"; exit 1; }
out=$(bash .claude/hooks/verify-all.sh 2>&1); [ -z "$out" ] || { echo "FAIL-verify-not-clean: $out"; exit 1; }
echo "T2 PASS ($n/300)"
```
**UI:** no

### T3: Add the companion known-pitfalls entry (~3 min)
**Files:** .roughly/known-pitfalls.md
**Action:** Append one bullet to the END of `## Documentation Hygiene` (after the #81 "A 'verified' tag…" entry, before `## Planning & Scoping`). Match the entry format (`- **bold lead-in.** … **Pattern:** …`).
**Details:** Insert this EXACT bullet, keeping one blank line before it and one after (before `## Planning & Scoping`):

`- **Normative docs and ACs can ship example commands that were never executed — reviewers validate intent, not execution.** An AC or doc that embeds a shell command / code snippet as guidance can pass plan-review and Stage 6 while the command is grammatically wrong, because reviewers check that the example *means* the right thing and that cross-references resolve — not that it *runs*. Concrete origin: E06.S7.AC1 shipped \`gh api PATCH /repos/…\` with the HTTP method as a positional (the correct form is \`gh api --method PATCH …\`); it survived plan-review + Stage 6 and shipped into \`CONTRIBUTING.md\`, caught only by external post-merge review (E06.S7 "Post-merge correction," 2026-06-09). This is the execution-validation twin of the "verified"-tag provenance entry above — same incident, different facet. **Pattern:** any AC or doc embedding an executable example must pair it with a verify command that runs or grammar-checks it (a \`--help\` exit-0 check is the floor); reviewers demand that verify, not just a plausible-looking command. Codified in \`CONTRIBUTING.md\` § "AC authoring conventions"; enforced at \`skills/review-plan/SKILL.md\` § "Completeness".`

Do not modify any other entry or `## Planning & Scoping`.
**Verify:**
```
cd "$(git rev-parse --show-toplevel)"
command grep -qF 'ship example commands that were never executed' .roughly/known-pitfalls.md || { echo FAIL-not-added; exit 1; }
awk '/^## Documentation Hygiene/{a=1} /^## Planning & Scoping/{a=0} a && /ship example commands that were never executed/{f=1} END{exit !f}' .roughly/known-pitfalls.md || { echo FAIL-wrong-section; exit 1; }
command grep -qF 'A "verified" tag on an inferred mechanism' .roughly/known-pitfalls.md || { echo FAIL-81-entry-lost; exit 1; }
n=$(wc -l < .roughly/known-pitfalls.md); [ "$n" -le 300 ] || { echo "FAIL-over-threshold $n"; exit 1; }
out=$(bash .claude/hooks/verify-all.sh 2>&1); [ -z "$out" ] || { echo "FAIL-verify-not-clean: $out"; exit 1; }
echo "T3 PASS ($n lines)"
```
**UI:** no

## Blast Radius
- **Do NOT modify:** the existing quoted-wording convention in `## AC authoring conventions`; the existing review-plan Completeness/Assumptions/Overengineering checks; any other known-pitfalls entry (esp. #81's, directly above the T3 seam — and honor its line-citation-rot rule: cross-refs use section NAMES); any code/agent/other-skill file; the E06 epic (historical — it's the source).
- **Watch for:** (a) cross-references cite `§ "section name"`, never line numbers; (b) insert at each section's END (before the next heading/`**Assumptions:**`), not mid-section; (c) review-plan must stay ≤300 (118→~123); known-pitfalls <300; (d) shared-seam with #84 in `## AC authoring conventions` — #84 (if it lands after) re-verifies the seam; (e) shimmed grep — use `command grep`.

## Conventions
- No build/test harness — inline `command grep`/`awk`/`bash -n` + verify-all-clean Verify blocks are the validation.
- T1/T2/T3 touch 3 distinct files → parallelizable; each appends to a section end.
