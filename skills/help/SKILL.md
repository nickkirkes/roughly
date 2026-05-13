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

If a remaining line is blank, starts with `#`, or does not match the `[check-id]-[added|declined] YYYY-MM-DD` shape at all (broken suffix, missing date, stray text), emit:
> "! [raw line] — unparseable entry"
Do not silently skip — surface the broken line so the user can repair the file.

If no check entries are present beyond the version line, emit:
> "No maturity checks recorded yet. Checks are offered during `/roughly:build` and `/roughly:fix` wrap-up."

---

## STEP 3: IN-PROGRESS PLAN STATE

Run `ls -lt docs/plans/*-plan.md 2>/dev/null` to list plan files sorted by modification time, newest first. Each line of `ls -lt` output contains a timestamp followed by the filename. The timestamp format depends on the system and the file's age — BSD/macOS `ls` emits `Mon DD HH:MM` for files less than ~6 months old (e.g., `May 12 14:33`) and `Mon DD YYYY` for older files (e.g., `Jan 4 2025`); GNU `ls` is similar by default. Use the timestamp string verbatim from the `ls -lt` output — do NOT reformat to a fixed shape (no canonical `YYYY-MM-DD HH:MM` pattern is portably available without `stat`-flag juggling, and reformatting risks the wrong year for old files). If the command output is empty (zero matches) or returns a non-zero exit, treat as zero matches.

**Zero matches:** emit `"No in-progress plans found in docs/plans/."` and skip the rest of Step 3.

**Exactly one match:** emit:
> "One plan found in docs/plans/:
> - `<filename>` (modified <timestamp from ls -lt, verbatim>)"

**Multiple matches:** emit:
> "Multiple plan files exist in docs/plans/. The presence of a plan file does not necessarily mean a pipeline is mid-flight — old plans may persist after their feature shipped. Which is your current in-progress plan?"

Then list every file with its modification date:
> - `<filename>` (modified <timestamp from ls -lt, verbatim>)
> - `<filename>` (modified <timestamp from ls -lt, verbatim>)
> - ...

Then ask: **"Which plan is current? (paste filename, or 'none' if no pipeline is in progress)"**

Do NOT silently pick the most-recent file. Do NOT filter or guess based on filename. Display all matches and wait for the user's answer.

Trim leading and trailing whitespace from the user's response before matching. If the trimmed response matches one of the listed filenames exactly, emit: `"Current plan: <filename>. Resume with /roughly:build or /roughly:fix as appropriate."` If the trimmed response is `none` (any capitalization), emit: `"No active pipeline. Old plans can be deleted manually when no longer useful."` If the trimmed response does not match any listed filename exactly and is not `none`, respond: `"That filename was not in the list above. Paste one of the displayed filenames exactly, or answer 'none'."` then re-display the full file list and re-ask the original question. Do NOT fuzzy-match. After three invalid responses, emit: `"Could not identify a current plan after three attempts. Continuing without selecting a plan."` and end Step 3 without picking. This bounds the loop so help never blocks the session.

**Display only.** Do not delete, rename, or modify any plan file.

---

## STEP 4: WRAP-UP

After all three sections render, emit:
> "For per-command details, run the command without arguments or read `skills/<name>/SKILL.md` in the plugin source."

End. The session continues — `/roughly:help` is informational and does not gate further work.
