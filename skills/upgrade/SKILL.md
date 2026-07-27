---
name: upgrade
description: "Update installed Roughly files from latest plugin templates. Diffs installed vs source, classifies changes, applies structural updates while preserving project customizations. Never overwrites without asking."
---

# Roughly Upgrade

Compare installed Roughly files against the latest plugin templates. Apply structural updates while preserving project-specific customizations.

**Never overwrites without asking.**

---

## STEP 1: INVENTORY

**Migration check:** If `docs/claude/` directory exists in the project:
> "Roughly renamed `docs/claude/` to `.roughly/`. Migrate existing files? (yes / abort)"
If abort: stop the upgrade. Display: "Migration is required before upgrading — all v0.1.2+ paths use `.roughly/`. Re-run `/roughly:upgrade` when ready to migrate."
If yes: create `.roughly/` directory if it doesn't exist. Move (preserving content) `docs/claude/known-pitfalls.md` to `.roughly/known-pitfalls.md`, move `docs/claude/.workflow-upgrades` to `.roughly/workflow-upgrades`. If `docs/claude/CLAUDE.md` exists but root `CLAUDE.md` does not, move it to root `CLAUDE.md`. If both exist and differ, show the diff and ask the user which to keep. If both exist and are identical, or only root exists, delete `docs/claude/CLAUDE.md`. Remove `docs/claude/` only if empty after moves. If any source file doesn't exist, skip that move and note it in the migration summary. Then update root `CLAUDE.md`: replace any remaining `docs/claude/known-pitfalls.md` with `.roughly/known-pitfalls.md` and `docs/claude/.workflow-upgrades` with `.roughly/workflow-upgrades`.

**v0.1.6 migration check:** If `docs/plans/` directory exists in the project (legacy pre-v0.1.6 plan location):

1. **Detection and safety check:** If `docs/plans/` does not exist, skip this step entirely (idempotent). If `docs/plans/.migration-in-progress` exists (resume from a prior failed attempt), read the first line of the marker and extract the ISO date (the first whitespace-separated token; the second token is the plugin version, per step 2's marker format). Emit: `"Resuming v0.1.6 migration from step 2 of 3 (marker dated YYYY-MM-DD; step 1 already ran)."` (substitute the extracted date for `YYYY-MM-DD`); set `mode = resume` (step 2's marker write becomes a no-op because the marker is already present — overwriting would lose the original migration date). Continue with the safety checks below. Then check `git status --porcelain docs/plans/ 2>/dev/null` — if non-empty (uncommitted edits to historical plans), abort with: `"Uncommitted changes in docs/plans/. Commit or stash them, or pass --force-plans to override."` If `--force-plans` appears as a standalone token in `$ARGUMENTS` (preceded by whitespace or string start, followed by whitespace or string end — not as a substring of `--force-plans-dry-run` or similar), proceed despite dirty status. Also handle the destination directory: if `.roughly/plans/` exists with any content other than a `.migration-in-progress` marker, abort with: `"Both docs/plans/ and .roughly/plans/ exist with content. Resolve manually (review both, choose one location, remove the other) before re-running."` If `.roughly/plans/` exists and is empty OR contains only a leftover `.migration-in-progress` marker from a prior failed attempt, `rm -rf .roughly/plans/` to clear it before the move — `git mv` into an existing destination directory NESTS the source under it (producing `.roughly/plans/plans/`) instead of renaming, so the destination MUST not exist at move time; the active resume marker is the source one at `docs/plans/.migration-in-progress` (written fresh in step 2), not the leftover destination one. Detect git availability with `git rev-parse --git-dir 2>/dev/null` — silent failure means non-git; use plain `mv` otherwise use `git mv` (preserves history per E02.S2.6 precedent).

2. **Move:** Skip the marker write if `mode = resume` (existing marker is preserved; overwriting would lose the original migration date — matches v0.1.4 step 3's idiom). Otherwise write marker at `docs/plans/.migration-in-progress` (the SOURCE dir — writing into the destination would create `.roughly/plans/` and make `git mv` nest `docs/plans/` INSIDE the destination rather than renaming) containing the current ISO date and plugin version. If the marker write fails (read-only filesystem, restrictive permissions, disk full): abort immediately with `"Cannot write marker to docs/plans/.migration-in-progress — check directory permissions or filesystem state."` No move has been attempted at this point, so no partial state is created; the user can fix permissions and re-run `/roughly:upgrade`. (Matches v0.1.4 step 3's marker-write-failure idiom.) Step 1 guarantees `.roughly/plans/` does not exist as a directory at this point. Ensure the destination's PARENT exists with `mkdir -p .roughly/` (idempotent; no-op when `.roughly/` already exists — matches v0.1.4's defensive parent-directory creation pattern). Then perform `git mv docs/plans/ .roughly/plans/` inside git (or plain `mv` otherwise) — the rename is an atomic directory move because the destination is absent; the marker is carried along to `.roughly/plans/.migration-in-progress` as part of the move (matches v0.1.4's marker-at-source idiom). If the move command returns non-zero, surface the error verbatim and abort — the marker stays at `docs/plans/.migration-in-progress` for re-run. Emit: `"Marker preserved at docs/plans/.migration-in-progress for resume on next /roughly:upgrade."` Do NOT fall back between `git mv` and `mv` on failure (post-failure recovery via the other tool produces confusing error output that complicates the user's mental model of which tool moved what — inherits v0.1.4's idiom).

3. **Cleanup:** Remove the marker — usually at `.roughly/plans/.migration-in-progress` (carried by a successful move) but also remove `docs/plans/.migration-in-progress` if it still exists (resume case where a prior attempt failed before the rename completed). Both removals are silent if the file is absent. Idempotency: a successful migration leaves `docs/plans/` absent; re-running detects the absence at step 1 and skips entirely.

**Version check:** Read `.roughly/workflow-upgrades` and extract the `roughly-version` line. Read `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` for the current plugin version. If they differ:
> "Plugin version changed: [installed] → [current]. Structural diffs below may include changes from the version bump, not just your edits."

If `.roughly/workflow-upgrades` is missing or has no version line, warn:
> "No installed version recorded. Run `/roughly:setup` to initialize, or proceeding will compare against current plugin templates."

After displaying the version status, enumerate all template files in the plugin's `${CLAUDE_PLUGIN_ROOT}/skills/setup/templates/` directory dynamically. For each template, determine its installed counterpart:

**Known mappings:**
| Template | Installs to |
|----------|-------------|
| `CLAUDE.md.template` | `CLAUDE.md` |
| `known-pitfalls.md.template` | `.roughly/known-pitfalls.md` |
| `claudeignore.template` | `.claudeignore` |
| `settings.json.template` | `.claude/settings.json` |

For any new templates not in this table, infer the install path from the filename (strip `.template` suffix, place in `.roughly/` or `.claude/` as appropriate).

**Agent files are plugin-shipped** — they are loaded via `subagent_type` (e.g., `roughly:code-reviewer`) directly from the plugin cache. Do NOT inventory plugin `agents/` for installation to `.claude/agents/` — never classify agent files as "New" in STEP 2 and never offer to create them in STEP 5.

**Preamble drift check:** For each installed agent in `.claude/agents/`, verify its context-loading step references both `CLAUDE.md` and `.roughly/known-pitfalls.md` consistent with `agents/agent-preamble.md`. Flag any agent where either file reference is missing or uses a stale path (excluding exceptions: static-analysis, doc-writer). Note: inlined copies in `build/SKILL.md` and `fix/SKILL.md` Stage 5b are not checked here — verify those manually when updating the preamble.

---

## STEP 2: CLASSIFY CHANGES

For each file, classify as:

- **New** — exists in plugin source but not installed. Offer to create.
- **Changed** — plugin source has structural updates not in installed version. Show diff.
- **Unchanged** — installed matches plugin structure (customizations preserved).
- **Local-only** — exists in project but not in plugin source. Leave alone.

Display the classification table.

---

## STEP 3: REVIEW CHANGES

For each file classified as **Changed**, show:
1. What the plugin update adds/modifies (structural changes)
2. What project customizations exist (will be preserved)
3. The proposed merged result

**Structural changes** (apply automatically):
- New sections added to templates
- Updated ignore patterns in .claudeignore
- New hook configurations
- Updated agent prompts (structural, not project-specific)

**Project customizations** (always preserved):
- Filled `{{PLACEHOLDER}}` values
- Added conventions, pitfalls, architecture notes
- Custom ignore patterns added by the user
- Project-specific hook configurations

---

## STEP 4: APPLY UPDATES

For each changed file, ask:
> "[file]: Plugin has structural updates. Apply? (yes / show diff / skip)"

Apply approved updates. For each applied update:
1. Create a backup: `[file].backup-[date]`
2. Merge structural changes with preserved customizations
3. Verify the merged file is valid

**For settings.json:** Preserve all existing user-added hook entries — they may be from other plugins or custom workflows. Only add or update hooks defined in the plugin template. If a previously-installed plugin hook is no longer in the current template, flag it to the user rather than silently removing or preserving it.

---

## STEP 5: NEW FILES

For files classified as **New**:
> "New plugin file available: [file]. Purpose: [description]. Install? (yes / skip)"

---

## STEP 6: UPDATE VERSION

Update the `roughly-version` line in `.roughly/workflow-upgrades` to match the current plugin version. Do this regardless of whether the user accepted or declined changes — the version tracks "last reviewed," not "last applied." File-content comparison in STEP 2 will still surface any unmerged diffs on future runs.
```
roughly-version [current version from plugin.json] [today's date]
```

If the file doesn't exist, create it with the version line.

**plan-mode-gate install-marker back-fill.** Back-fill the marker only when the hook is actually **active**, not merely present on disk (`setup` copies the hook file unconditionally but may leave it unregistered on a Branch 3 warning path). Active means: `.claude/hooks/plan-mode-gate.sh` exists AND `.claude/settings.json` registers it under `.hooks.UserPromptSubmit` with an entry whose `command` is `.claude/hooks/plan-mode-gate.sh`. Confirm registration with `jq` (e.g., `jq -e '[.hooks.UserPromptSubmit[]?.hooks[]? | select(.command == ".claude/hooks/plan-mode-gate.sh")] | length > 0' .claude/settings.json`, run only after `jq empty .claude/settings.json` parses cleanly). If `jq` is unavailable or the file does not parse, **skip the back-fill silently** — do not infer registration from a plain-text scan (a non-structural match risks a false marker); the marker can be written by the next `setup` run or a `jq`-equipped `upgrade`. If the hook is active AND `.roughly/workflow-upgrades` contains no `plan-mode-gate-v1-added` entry, append `plan-mode-gate-v1-added [today's date]`. This back-fills projects that installed the hook before `setup` recorded the marker, deriving it from the actual active-hook state (file present + registered) — a copied-but-unregistered hook is NOT back-filled, so the marker never overclaims. Silent; no prompt. (The marker drives `/roughly:help`'s "Installed components" section.)

---

## STEP 7: SUMMARY

```
# Upgrade Summary

| File | Status | Action Taken |
|------|--------|--------------|
| [file] | Updated | Merged structural changes |
| [file] | Skipped | User declined |
| [file] | New | Installed |
| [file] | Unchanged | No action needed |

**Plugin version:** [previous] → [current] (or "unchanged")
**Backups created:** [list or "none"]
```
