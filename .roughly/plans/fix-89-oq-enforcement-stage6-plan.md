> **Status:** Historical — implemented and merged in commit b471e2c on 2026-07-29. This plan was an active build/fix artifact; treat as historical reference only.

# Fix Plan: #89 — enforce epic OQ-resolution annotation at Stage 6 review

Plan-format-version: 1

## Root Cause

The epic Open Question resolution convention (#86, `CONTRIBUTING.md § "Epic Open Question resolution"`) has no automated enforcement — the E06.S7 incident (a CHANGELOG asserting an OQ resolution while the epic OQ line carried no annotation) was caught only by ad-hoc Stage 6 code-reviewer discretion. This fix makes that catch systematic by adding it as an explicit check in the `roughly:code-reviewer` agent's Process. Not a code bug — a pipeline-review-coverage gap.

## Scope (1 task — single-file agent-prompt edit; NO SKILL.md change, NO new gate)
- **T1:** `agents/code-reviewer.md` — append a new **step 8** to `## Process` (after step 7 `**Check pitfalls**`, before `## Output`): a conditional CHANGELOG-vs-epic-OQ cross-reference-consistency check that flags Critical when a CHANGELOG/commit asserts an OQ resolution the epic's `## Open questions` section doesn't reflect.
- **Why this home (investigation verdict):** both build & fix Stage 6 invoke `/roughly:review`, which dispatches the 3 review agents from ONE definition in `skills/review/SKILL.md` — so editing the single `agents/code-reviewer.md` gives BOTH pipelines the check (DRY; no SKILL.md edits, no sync risk). code-reviewer's charter is "consistency with project conventions" and it's the agent that already caught this exact class once (E06.S7).
- **Project-agnostic guard (critical):** roughly runs in consumer projects that have no epics/`## Open questions` sections — the check MUST be inert there. It is gated on a CHANGELOG OQ-resolution assertion firing first and carries an explicit "if applicable"/skip clause, mirroring the `agents/doc-writer.md` "verify X exists → if absent, skip this check entirely" precedent.
- **ADR-015 compliance:** this is a passive Process-step instruction feeding the existing `## Critical` output bucket — NOT a gate, NOT a structured/interactive prompt tool. gate-protocol.md's "gate" definition (a point where the pipeline stops for a human decision) does not apply.
- **Cross-ref:** cite `CONTRIBUTING.md § "Epic Open Question resolution"` (normative format source) in the step; do NOT re-cite the known-pitfalls entry (step 1 already ingests known-pitfalls.md).

## File Table
| File | Action | Task |
|------|--------|------|
| agents/code-reviewer.md | Modify (append step 8 to `## Process`) | T1 |

## Baseline facts (captured 2026-07-29, branch `fix/81-86-contributing-convention-bundle`, 14 commits ahead of main)
- `agents/code-reviewer.md` = 258 words (cap 650, per `.claude/hooks/verify-all.sh` `agents/*.md` word check). `## Process` is a numbered 1–7 list ending at `7. **Check pitfalls** — Does the code match any known pitfall patterns?`, then a blank line, then `## Output`. No later section references step numbers (safe to append step 8).
- `CONTRIBUTING.md § "Epic Open Question resolution"` exists (added by #86) — cross-ref target confirmed present.
- `agents/doc-writer.md` uses the self-scoping precedent: "First, verify `CLAUDE.md` exists… If absent, skip this check entirely."
- Session shims `grep` — use `command grep`.

## Tasks

### T1: Add the epic-OQ cross-reference check as step 8 of code-reviewer's Process (~4 min)
**Files:** agents/code-reviewer.md
**Action:** Insert a new numbered `8.` step at the END of the `## Process` list — immediately after `7. **Check pitfalls** — Does the code match any known pitfall patterns?` and before the blank line preceding `## Output`. Do a single exact-string Edit anchored on the step-7 line + the `## Output` heading.
**Details:** Match `7. **Check pitfalls** — Does the code match any known pitfall patterns?\n\n## Output` and insert step 8 between them, producing:

```
7. **Check pitfalls** — Does the code match any known pitfall patterns?
8. **Check epic Open Question cross-reference (if applicable)** — If the diff's CHANGELOG entry or commit message asserts that the change resolves an epic Open Question, confirm the same diff also annotates that epic's `## Open questions` section with a matching strikethrough + resolution annotation (per `CONTRIBUTING.md` § "Epic Open Question resolution"). Flag Critical if a resolution is claimed but the epic OQ section does not reflect it. If the project has no epic docs, or no OQ-resolution claim appears in the diff, this check is inert — skip it.

## Output
```

Do not modify any other step, the `## Output` template, the `## Rules`, or the frontmatter. Keep it a passive review instruction (read + flag into the existing Critical bucket) — do NOT add any gate/prompt tool.
**Verify:**
```
cd "$(git rev-parse --show-toplevel)"
command grep -qF -e '8. **Check epic Open Question cross-reference (if applicable)**' agents/code-reviewer.md || { echo FAIL-not-added; exit 1; }
# step 8 sits inside ## Process, before ## Output
awk '/^## Process/{p=1} /^## Output/{p=0} p && /Check epic Open Question cross-reference/{f=1} END{exit !f}' agents/code-reviewer.md || { echo FAIL-wrong-section; exit 1; }
# normative cross-ref present
command grep -qF -e '`CONTRIBUTING.md` § "Epic Open Question resolution"' agents/code-reviewer.md || { echo FAIL-no-crossref; exit 1; }
# project-agnostic skip guard present
command grep -qF -e 'this check is inert — skip it' agents/code-reviewer.md || { echo FAIL-no-skip-guard; exit 1; }
# step 7 still intact (not clobbered)
command grep -qF -e '7. **Check pitfalls** — Does the code match any known pitfall patterns?' agents/code-reviewer.md || { echo FAIL-step7-lost; exit 1; }
# word cap
n=$(wc -w < agents/code-reviewer.md); [ "$n" -le 650 ] || { echo "FAIL-word-cap $n"; exit 1; }
out=$(bash .claude/hooks/verify-all.sh 2>&1); [ -z "$out" ] || { echo "FAIL-verify: $out"; exit 1; }
echo "T1 PASS ($n/650 words)"
```
**UI:** no

## Blast Radius
- **Do NOT modify:** `skills/build/SKILL.md` / `skills/fix/SKILL.md` Stage 6 prose (the DRY win is that the single agent edit covers both — no SKILL.md change needed); `skills/review/SKILL.md` dispatch; the other two agents; the `## Output`/`## Rules` sections or frontmatter of code-reviewer.md; `CONTRIBUTING.md` / known-pitfalls.md (this is the enforcement follow-up to #86, not a re-edit of the convention); any code/other file.
- **Watch for:** (a) keep the check CONDITIONAL + project-agnostic (inert when no epics / no OQ-resolution claim) — it must never misfire in consumer projects; (b) it is a passive review-checklist instruction, NOT a gate or structured-prompt tool (ADR-015); (c) stay under the 650-word agent cap (258 → ~330 projected); (d) cite CONTRIBUTING § by section name, not line number; (e) shimmed grep — use `command grep`; (f) all Verify greps are positive-presence + cap/absence guards — none self-defeating.

## Conventions
- No build/test harness — inline `command grep`/`awk`/verify-all-clean Verify blocks are the validation.
- Single task, single file.
