> **Status:** Historical — implemented and merged in commit b58f4bd4e6d495c748e3301be048a7770d9aac01 on 2026-05-07. This plan was an active build/fix artifact; treat as historical reference only.

# Implementation Plan: E03.S5 — Tooling Pitfalls section in CONTRIBUTING.md

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| CONTRIBUTING.md | Modify | T1 |

## Tasks

### T1: Add `## Tooling Pitfalls` section to CONTRIBUTING.md (~5 min)
**Files:** CONTRIBUTING.md
**Action:** Insert a new top-level `## Tooling Pitfalls` section between the existing `## Code Standards` section (ending at L48) and the existing `## Testing` section (starting at L50). The section must document the dual-semantic-token failure mode for `Edit replace_all`/sed/IDE find-replace, drawn from the recorded `verify-all.sh` incident.

**Details:**

Insert the new section so that current L50 (`## Testing`) is pushed downward. The blank-line spacing must match the rest of the file: a blank line between the end of `## Code Standards` content and the new `## Tooling Pitfalls` heading, and a blank line between the end of the new section and the `## Testing` heading.

Section requirements (driven by acceptance criteria E03.S5):

1. **Heading:** `## Tooling Pitfalls` (matching the file's `##` top-level style; no `###` subsections used elsewhere — keep this section flat too).

2. **Failure-mode statement (1–3 lines):** Name the failure mode explicitly: bulk replacement of a token (`Edit` with `replace_all: true`, `sed`, or IDE find-replace) silently corrupts code when the same token serves dual semantic roles in one file — e.g., user-facing prose AND a legacy detector that intentionally references the old name.

3. **At-risk tools:** Name `Edit` (with `replace_all: true`), `sed`, and IDE find-replace explicitly.

4. **Worked example from the recorded incident:** Reference the real file `.claude/hooks/verify-all.sh`. Describe what happened: an edit intended to migrate user-facing prose from `ruckus` → `roughly` on lines 2 and 11 also rewrote the legacy drift detector at lines 17–19, which deliberately greps for `.ruckus/known-pitfalls` to catch stale references. The result: a no-op detector that would never fire. Use real numbers — do not invent.

5. **Verification commands:** Document running BOTH `rg -nw 'old-token' <file>` and `rg -nw 'new-token' <file>` after a bulk replacement, to inspect every match site by hand. Show the exact commands a reader can run against the live file:
   - `rg -nw 'ruckus' .claude/hooks/verify-all.sh` — expected: 3 matches at lines 17, 18, 19 (the legacy detector lines that MUST retain `ruckus`)
   - `rg -nw 'roughly' .claude/hooks/verify-all.sh` — expected: 2 matches at lines 2 and 11 (the user-facing prose lines that were legitimately renamed)

6. **Length:** The full section (heading line through the last content line, exclusive of the trailing blank line) must be 15–30 lines. Aim for ~22–25 lines for headroom on both ends. Use prose, not extensive lists, to keep the line count reasonable while staying load-bearing.

7. **Tone:** Direct, contributor-facing, second person ("when you do a bulk replacement…"). No emojis. No code-block decoration beyond what the existing CONTRIBUTING.md uses (this file uses inline backticks for commands and file paths — match that style).

Reference content already in the file for style: lines 41–48 (`## Code Standards`) and lines 50–58 (`## Testing`). Both use simple paragraph + numbered list or bullet list. The new section should likewise be readable cold in under 60 seconds.

The existing pitfall record at `.roughly/known-pitfalls.md` (around line 38) is the source incident — refer to it inline as the runtime catalog so contributors know where the build pipeline writes new pitfalls. Do not duplicate the full incident — the worked example in CONTRIBUTING.md is the cold-read introduction; `.roughly/known-pitfalls.md` is the canonical record.

**Verify:**
1. `wc -l` over just the new section (heading line through last content line) returns a number in [15, 30].
2. `rg -nw 'ruckus' .claude/hooks/verify-all.sh` returns exactly 3 matches at lines 17, 18, 19. If the doc claims different counts, fix the doc, not the file.
3. `rg -nw 'roughly' .claude/hooks/verify-all.sh` returns exactly 2 matches at lines 2 and 11. Same rule.
4. The new section appears between `## Code Standards` and `## Testing`, with one blank line on each side.
5. Section names: failure mode, at-risk tools (Edit, sed, IDE find-replace), worked example file path, the two verification commands.

**UI:** no

## Blast Radius
- Do NOT modify: `.claude/hooks/verify-all.sh` — the worked example depends on its current state. Leave it untouched.
- Do NOT modify: `.roughly/known-pitfalls.md` — referenced as the runtime catalog but not edited here.
- Do NOT modify any skills, agents, hooks, or other docs. Prose-only per acceptance criterion #6.
- Do NOT change other CONTRIBUTING.md sections — only insert the new section in the slot specified.
- Watch for: trailing whitespace, mismatched blank-line spacing (the existing file uses single blank lines between sections — match exactly).

## Conventions
- File uses `##` for top-level sections, no `###` subsections; new section must follow that.
- Inline backticks for commands and file paths (see `## Testing` for the pattern).
- No emojis anywhere in CONTRIBUTING.md — keep that.
- Section length budget is the binding constraint (15–30 lines). If the section reads cleanly at 22 lines, leave it at 22 — do not pad to fill the budget.
- Acceptance criterion #4 ("self-verification") means the doc's example must reproduce on the live repo today. The numbers in the discovery report (3 matches for `ruckus`, 2 matches for `roughly`) ARE today's numbers — use them.
