---
name: help
description: "In-CLI overview of Roughly commands, maturity-check state, and any in-progress plan. Read-only and interactive — never aborts, never modifies files."
disable-model-invocation: false
---

# Roughly Help

In-CLI overview: commands by cluster, current maturity-check state, and any in-progress plan.

**Read-only.** This skill never modifies files, never aborts the session, and never blocks other work. It is itself a recovery path — like `/roughly:upgrade` — so it surfaces legacy state without halting.

---

## STEP 0: PRE-FLIGHT NOTE (NEVER ABORTS)

If `.ruckus/` directory exists at the project root, emit a single note line before Step 1's output:
> "Legacy `.ruckus/` directory present. If migration is still pending, run `/roughly:upgrade`. If this directory contains only user-extras you kept after a completed migration, it can be removed manually."

Do NOT abort. Continue to Step 1. If no `.ruckus/` directory exists, emit nothing and proceed silently.

---

## STEP 1: COMMANDS BY CLUSTER

Emit three labeled groups. For each command, give one short line of purpose. Use this exact grouping:

**Pipeline** (orchestrators with gated stages):
- `/roughly:build` — feature pipeline with discovery, plan review, subagent-per-task implementation, review, verify, commit
- `/roughly:fix` — bug pipeline with investigation instead of discovery; same gate structure

**Coordinator** (dispatch agents or other skills):
- `/roughly:review` — parallel 3-agent review of recent changes (code-reviewer, static-analysis, silent-failure-hunter)
- `/roughly:review-plan` — verify an implementation plan against the codebase (auto-dispatched by build/fix; also usable standalone)
- `/roughly:review-epic` — pre-implementation epic review (Opus); flags spec issues before any code is written
- `/roughly:audit-epic` — post-implementation epic audit; verifies acceptance criteria across all stories
- `/roughly:verify-all` — type check + test + build verification loop

**Utility** (interactive, non-gate):
- `/roughly:setup` — first-time project bootstrap with maturity detection
- `/roughly:upgrade` — diff installed files against latest plugin templates; apply structural updates
- `/roughly:help` — this command

---

## STEP 2: MATURITY-CHECK STATE

Read `.roughly/workflow-upgrades`. If the file does not exist, emit:
> "No `.roughly/workflow-upgrades` file found. Run `/roughly:setup` to initialize, or `/roughly:upgrade` if a `.ruckus/` legacy file is present."
Skip the rest of Step 2.

If the file exists, parse it:
- **Line 1** is the version line: `roughly-version X.Y.Z YYYY-MM-DD`. Display as: `Plugin version: X.Y.Z (recorded YYYY-MM-DD)`. If line 1 does not match this format, display: `Plugin version: unrecorded (file may predate v0.1.2)`.
- **Remaining lines** match the pattern `[check-id]-[added|declined] YYYY-MM-DD`. For each, classify by suffix:

Active check IDs (display under their natural label):
- `investigator-v1` — bug-diagnosis subagent for `/roughly:fix`
- `stop-hook-v1` — verify-all enforcement via Claude Code Stop hook

Retired check IDs (display under "Retired — no longer offered"):
- `pitfalls-organized-v1`
- `test-verify-v1`

For each ID found in the file, emit one line:
> "✓ [id] — added YYYY-MM-DD" (for `-added` entries)
> "✗ [id] — declined YYYY-MM-DD" (for `-declined` entries)

If a check ID in the file does not match any known active or retired ID, emit:
> "? [id] — unknown check (YYYY-MM-DD)"
Do not crash or filter; display the unknown entry so the user can investigate.

Skip blank lines silently (trailing newlines and visual spacing are benign and present in normal installs).

If a non-blank line does not match the `[check-id]-[added|declined] YYYY-MM-DD` shape (broken suffix, missing date, `#`-prefixed comment, stray text), emit:
> "! [raw line] — unparseable entry"
Do not silently skip non-blank malformed lines — surface them so the user can repair the file.

If no check entries are present beyond the version line, emit:
> "No maturity checks recorded yet. Checks are offered during `/roughly:build` and `/roughly:fix` wrap-up."

---

## STEP 3: PLAN STATE

Run `ls -lt docs/plans/*-plan.md 2>/dev/null` to list plan files sorted by modification time, newest first. Each line of `ls -lt` output contains a timestamp followed by the filename. The timestamp format depends on the system and the file's age — BSD/macOS `ls` emits `Mon DD HH:MM` for files less than ~6 months old (e.g., `May 12 14:33`) and `Mon DD YYYY` for older files (e.g., `Jan 4 2025`); GNU `ls` is similar by default. Use the timestamp string verbatim from the `ls -lt` output — do NOT reformat to a fixed shape (no canonical `YYYY-MM-DD HH:MM` pattern is portably available without `stat`-flag juggling, and reformatting risks the wrong year for old files). If the command output is empty (zero matches) or returns a non-zero exit, treat as zero matches.

Run `git rev-parse --abbrev-ref HEAD 2>/dev/null` to detect the current branch. If the command fails (not a git repo, git not installed), set the branch to `unknown`.

**Detect in-progress plans by branch association.** Plan files persist in `docs/plans/` after their feature ships, so file presence alone is not a reliable in-progress signal. The current git branch is the strongest positive signal: build/fix pipelines run on feature branches whose names typically encode the same story ID as the plan filename (e.g., branch `feat/E03.S8-help-command` ↔ `docs/plans/E03-S8-help-command-plan.md`). To match:
- **Normalize the branch name:** strip leading conventional prefixes (`feat/`, `fix/`, `chore/`, `docs/`, `bug/`, `wip/`); replace `.` with `-`; lowercase.
- **Normalize each plan filename:** strip the trailing `-plan.md`; lowercase.
- A plan file is "associated with the current branch" if the normalized branch name contains the normalized filename as a substring, OR the normalized filename contains the normalized branch name as a substring.

This is a heuristic, not a guarantee — paused features on other branches won't be flagged as in-progress here, but their existence is surfaced in the count line so the user can find them.

**Zero plan files in docs/plans/:** emit `"No plan files in docs/plans/."` and end Step 3.

**Branch is a main-line branch** (`main`, `master`, `trunk`, `develop`) **or `unknown`:** no in-progress pipeline is likely on this branch. Emit:
> "<N> plan files in docs/plans/. Current branch is <branch> — no in-progress pipeline detected. Most recent plan: `<filename>` (modified <timestamp from ls -lt, verbatim>)."

End Step 3 with no prompt. (If the user is mid-pipeline, they can switch back to the feature branch and re-run `/roughly:help`.)

**Feature/fix branch with zero plan files matching the branch:** No in-progress plan was confidently identified. Emit:
> "<N> plan files in docs/plans/. Current branch (<branch>) does not match any plan filename — no in-progress pipeline confidently detected. Most recent plan: `<filename>` (modified <timestamp from ls -lt, verbatim>)."

End Step 3 with no prompt. (If the user is mid-pipeline on a non-conventional branch, they already know the plan filename and don't need help to surface it.)

**Feature/fix branch with exactly one plan file matching:** emit:
> "In-progress plan for current branch <branch>:
> - `<filename>` (modified <timestamp from ls -lt, verbatim>)"

If `N > 1` (other plan files exist beyond the matched one), append:
> "(<M> other plans in docs/plans/ are unrelated to this branch.)" — where `M = N - 1`.

End Step 3 with no prompt — single match is unambiguous.

**Feature/fix branch with multiple plan files matching:** This is the case where the spec requires asking. Emit:
> "Multiple plan files match the current branch <branch>. Which is your current in-progress plan?"

Then list every matching file, sorted newest first by mtime:
> - `<filename>` (modified <timestamp from ls -lt, verbatim>)
> - ...

If unmatched plan files also exist, append (with `M` = unmatched count):
> "(<M> other plans in docs/plans/ are unrelated to this branch.)"

Then ask: **"Which plan is current? (paste filename, or 'none' if no pipeline is in progress)"**

Do NOT silently pick the most-recent file. Do NOT filter or guess based on filename within the matched set. Display all matched entries and wait for the user's answer.

Trim leading and trailing whitespace from the user's response before matching. If the trimmed response matches one of the listed filenames exactly, emit: `"Current plan: <filename>. Resume with /roughly:build or /roughly:fix as appropriate."` If the trimmed response is `none` (any capitalization), emit: `"No active pipeline. Old plans can be deleted manually when no longer useful."` If the trimmed response does not match any listed filename exactly and is not `none`, respond: `"That filename was not in the list above. Paste one of the displayed filenames exactly, or answer 'none'."` then re-display the matched list and re-ask the original question. Do NOT fuzzy-match. After three invalid responses, emit: `"Could not identify a current plan after three attempts. Continuing without selecting a plan."` and end Step 3 without picking. This bounds the loop so help never blocks the session.

**Display only.** Do not delete, rename, or modify any plan file.

---

## STEP 4: WRAP-UP

After all three sections render, emit:
> "For per-command details, run the command without arguments or read `skills/<name>/SKILL.md` in the plugin source."

End. The session continues — `/roughly:help` is informational and does not gate further work.
