# Implementation Plan: E04.S1 — Plan-path consolidation `docs/plans/` → `.roughly/plans/`

Plan-format-version: 1

## Summary

Anchor story of E04 (v0.1.6). Migrate runtime plan-path location from `docs/plans/` to `.roughly/plans/` across all skill bodies, CI assertions, README, and CONTRIBUTING; add a v0.1.6 plans-migration step to `skills/upgrade/SKILL.md`; extend the pre-flight migration check in 7 hard-abort skills + 1 soft-abort skill from one-form (`.ruckus/`) to two-form (`.ruckus/` OR `docs/plans/`) with HTML-comment delimiters; introduce `tests/fixtures/canonical-preflight-block.txt` as single-source-of-truth for the two-form block; `git mv docs/plans/ .roughly/plans/` to relocate all 29 historical plans preserving history; update CHANGELOG with the path move + new `### Migration` subsection per v0.1.4 precedent. No new ADR (matches v0.1.2 and v0.1.4 path-rename precedents).

## File Table

| File | Action | Task(s) |
|------|--------|---------|
| `tests/fixtures/canonical-preflight-block.txt` | Create | T1 |
| `skills/audit-epic/SKILL.md` | Modify | T2, T4 |
| `skills/build/SKILL.md` | Modify | T2, T4 |
| `skills/fix/SKILL.md` | Modify | T2, T4 |
| `skills/review/SKILL.md` | Modify | T2 |
| `skills/review-plan/SKILL.md` | Modify | T2, T4 |
| `skills/review-epic/SKILL.md` | Modify | T2 |
| `skills/verify-all/SKILL.md` | Modify | T2 |
| `skills/setup/SKILL.md` | Modify | T3 |
| `skills/help/SKILL.md` | Modify | T4 |
| `skills/upgrade/SKILL.md` | Modify | T5 |
| `scripts/ci-dogfood.sh` | Modify | T6 |
| `README.md` | Modify | T7 |
| `CONTRIBUTING.md` | Modify | T8 |
| `CHANGELOG.md` | Modify | T9 |
| `docs/plans/` → `.roughly/plans/` | Rename (git mv) | T10 |

## Canonical pre-flight block design (referenced by T1, T2, T3)

The existing one-line hard-abort block in 7 skills is a single bold-paragraph line. The two-form extension must:
- Detect `.ruckus/` legacy state OR `docs/plans/` legacy state
- Name both legacy states distinctly in the abort prose
- Recommend `/roughly:upgrade` (the recovery path)
- Preserve the `.ruckus/` user-extras carve-out
- Stay on a single line to avoid line-cap impact on `build` (298/300) and `fix` (299/300)
- Be delimited by `<!-- pre-flight:start -->` and `<!-- pre-flight:end -->` HTML comments on the same line as the prose

**Canonical hard-abort two-form block (verbatim — byte-identical across T1, T2):**

```
<!-- pre-flight:start --> **Pre-flight migration check:** If `.ruckus/.migration-in-progress`, `.ruckus/known-pitfalls.md`, `.ruckus/workflow-upgrades`, or `docs/plans/` exists, abort with: "Legacy state detected (`.ruckus/` from v0.1.3 install or incomplete v0.1.4 migration; `docs/plans/` from pre-v0.1.6 plan-path location). Run `/roughly:upgrade` to migrate or resume, then re-run." A `.ruckus/` directory containing only user-extras (post-`leave` state from a completed upgrade) is fine — proceed. <!-- pre-flight:end -->
```

This is **one physical line** in the file. Net line-count delta per skill: 0 (replaces existing single-line block with new single-line block).

**Setup soft-abort two-form block (verbatim — distinct from hard-abort, preserves `(proceed anyway / abort)` semantics per E03.S4 known-pitfall):**

The existing 2-line soft-abort block at `skills/setup/SKILL.md` L39–40 is replaced with a 2-line two-form block. No HTML delimiters on setup (per AC4: setup is excluded from the byte-identity check):

```
If `.ruckus/.migration-in-progress`, `.ruckus/known-pitfalls.md`, `.ruckus/workflow-upgrades`, or `docs/plans/` exists:
> "Legacy state detected (`.ruckus/` from v0.1.3 install or incomplete v0.1.4 migration; `docs/plans/` from pre-v0.1.6 plan-path location). Run `/roughly:upgrade` first to migrate, then re-run `/roughly:setup` if needed. (proceed anyway / abort)"
```

Net line-count delta on setup: 0 (2 lines → 2 lines).

## Tasks

### T1: Create canonical pre-flight fixture (~2 min)
**Files:** `tests/fixtures/canonical-preflight-block.txt`
**Action:** Create new file containing the canonical hard-abort two-form pre-flight block.
**Details:** Write the single-line block from the "Canonical pre-flight block design" section above, verbatim, byte-identical to what T2 will write into the 7 hard-abort skills. File contents are exactly one line (terminated by a single trailing newline — standard text file convention). No frontmatter, no comments, no surrounding prose. This file is the single source of truth that T2's substitutions must match byte-for-byte.
**Verify:** `cat tests/fixtures/canonical-preflight-block.txt | md5sum` produces a hash (record it for use in T2 verification). `wc -l tests/fixtures/canonical-preflight-block.txt` returns `1` (one line).
**UI:** no
**Depends on:** none

---

### T2: Replace pre-flight blocks in 7 hard-abort skills with two-form canonical block (~5 min)
**Files:** `skills/audit-epic/SKILL.md`, `skills/build/SKILL.md`, `skills/fix/SKILL.md`, `skills/review/SKILL.md`, `skills/review-plan/SKILL.md`, `skills/review-epic/SKILL.md`, `skills/verify-all/SKILL.md`
**Action:** Replace each skill's existing single-line one-form pre-flight check with the canonical two-form block delimited by HTML comments.
**Details:** In each of the 7 named skills, use `Edit` to replace the existing line beginning `**Pre-flight migration check:**` (currently containing only `.ruckus/` legacy state detection) with the canonical two-form block from the design section above. Exact lines to replace:
- `skills/audit-epic/SKILL.md` L19
- `skills/build/SKILL.md` L19
- `skills/fix/SKILL.md` L19
- `skills/review/SKILL.md` L18
- `skills/review-plan/SKILL.md` L13
- `skills/review-epic/SKILL.md` L17
- `skills/verify-all/SKILL.md` L15

The `old_string` per skill is the full existing one-line bold-paragraph block (each skill's existing L18/L19/L13/L17/L15 line — substring match anchored by `**Pre-flight migration check:** If \`.ruckus/.migration-in-progress\``). The `new_string` is the canonical two-form block (verbatim from the design section, single line, with `<!-- pre-flight:start -->` prefix and `<!-- pre-flight:end -->` suffix). Net delta per skill: 0 lines.
**Verify:** After all 7 edits:
1. `wc -l skills/{audit-epic,build,fix,review,review-plan,review-epic,verify-all}/SKILL.md` shows each skill's line count UNCHANGED from pre-edit (audit-epic 141, build 298, fix 299, review 88, review-plan 96, review-epic 64, verify-all 80).
2. AC4 byte-identity check (the canonical verification):
   ```bash
   for f in skills/audit-epic/SKILL.md skills/build/SKILL.md skills/fix/SKILL.md skills/review/SKILL.md skills/review-plan/SKILL.md skills/review-epic/SKILL.md skills/verify-all/SKILL.md; do
     awk '/<!-- pre-flight:start -->/,/<!-- pre-flight:end -->/' "$f" | md5sum
   done
   md5sum tests/fixtures/canonical-preflight-block.txt
   ```
   All 8 hashes piped through `sort -u | wc -l` must return `1`.
3. `rg -Fn "Legacy \`.ruckus/\` state detected" skills/` returns 0 matches (old prose fully replaced) — the new prose uses "Legacy state detected" without the embedded `.ruckus/` in the trigger phrase.
**UI:** no
**Depends on:** T1

---

### T3: Extend setup soft-abort to two-form (~2 min)
**Files:** `skills/setup/SKILL.md`
**Action:** Replace the existing 2-line soft-abort pre-flight prose at L39–40 with the two-form soft-abort variant.
**Details:** Use `Edit` with `old_string` matching the existing 2-line block:
```
If `.ruckus/.migration-in-progress`, `.ruckus/known-pitfalls.md`, or `.ruckus/workflow-upgrades` exists:
> "Legacy `.ruckus/` state detected (v0.1.3 install or incomplete v0.1.4 migration). Run `/roughly:upgrade` first to migrate to `.roughly/` or resume, then re-run `/roughly:setup` if needed. (proceed anyway / abort)"
```

Replace with the two-form soft-abort block from the design section above. Net delta: 0 lines. Do NOT add HTML comment delimiters — setup is explicitly excluded from AC4's byte-identity check per the E03.S4 known-pitfall (`.roughly/known-pitfalls.md` L40). Do NOT touch the `docs/claude/` line at L43 (that's the separate v0.1.2 legacy check — out of scope for this story).
**Verify:** `wc -l skills/setup/SKILL.md` returns 287 (unchanged). Read L39–40 and confirm the two-form prose is present. `rg -Fn "Legacy \`.ruckus/\` state detected" skills/setup/SKILL.md` returns 0 matches.
**UI:** no
**Depends on:** none

---

### T4: Substitute `docs/plans/` → `.roughly/plans/` in 5 skill bodies (~5 min)
**Files:** `skills/build/SKILL.md`, `skills/fix/SKILL.md`, `skills/help/SKILL.md`, `skills/audit-epic/SKILL.md`, `skills/review-plan/SKILL.md`
**Action:** Replace every `docs/plans/` reference in these 5 skill bodies with `.roughly/plans/`. Inline substitution-only — no surrounding prose changes.
**Details:** 17 substitutions total across 5 files:
- `skills/build/SKILL.md` L85, L122 (2 refs)
- `skills/fix/SKILL.md` L96, L129 (2 refs)
- `skills/help/SKILL.md` L85, L91, L102, L105, L108, L115, L118, L125, L134, L146 (10 refs)
- `skills/audit-epic/SKILL.md` L44 (1 ref)
- `skills/review-plan/SKILL.md` L36, L44 (2 refs — canonical-positive-example citations to `E03-S9-abort-prose-plan.md` and `E03-S10-retry-loop-tuning-plan.md`; per Discovery point 1, these are missed by the story spec but required for AC1's `rg -Fn` zero-match invariant)

Per-file approach (T2/T4 ordering note): T2 introduces new `docs/plans/` literals into the pre-flight blocks of 4 of the 5 files in T4's scope (build, fix, audit-epic, review-plan — review-plan also has the canonical-example citations to migrate). After T2 runs, those pre-flight `docs/plans/` literals are legitimate legacy-detection text that MUST be preserved by T4. Therefore:
- `skills/help/SKILL.md`: T4 may use `Edit` with `replace_all: true` and `old_string: "docs/plans/"`, `new_string: ".roughly/plans/"` — help has no pre-flight block, so no semantic-token collision (verified by Discovery's `rg -Fn "docs/plans" skills/` enumeration).
- `skills/build/SKILL.md`, `skills/fix/SKILL.md`, `skills/audit-epic/SKILL.md`, `skills/review-plan/SKILL.md`: T4 MUST use anchored Edits at each enumerated line. `replace_all: true` would corrupt the pre-flight block's legacy-detection text (per the `Edit replace_all` dual-semantic-token pitfall in `CONTRIBUTING.md ## Tooling Pitfalls`). Use the surrounding prose at each enumerated line as the unique `old_string` anchor.

Net line-count delta per skill: 0 (pure path substitution; the new path is 2 chars longer per ref but doesn't push any line past markdown's effective wrap).
**Verify:**
1. `rg -Fn "docs/plans" skills/` returns 0 matches (AC1's exact verify command).
2. `rg -Fn ".roughly/plans" skills/` returns 18 matches across the 5 files.
3. `wc -l skills/{build,fix,help,audit-epic,review-plan}/SKILL.md` — all line counts unchanged from pre-edit state (build 298, fix 299, help 163, audit-epic 141, review-plan 96).
**UI:** no
**Depends on:** none

---

### T5: Add v0.1.6 plans-migration step to `skills/upgrade/SKILL.md` (~5 min)
**Files:** `skills/upgrade/SKILL.md`
**Action:** Insert a new v0.1.6 plans-migration step between the existing v0.1.4 step (ends at L58 — `**Idempotency:**` paragraph) and the `**Version check:**` paragraph at L60.
**Details:** Use `Edit` to insert the v0.1.6 step. The `old_string` is the boundary between L58 (`10. **Idempotency:** ...`) and L60 (`**Version check:** ...`) — specifically the blank line at L59 (use a unique anchor like the closing prose of step 10 + blank + start of Version check). The `new_string` adds the v0.1.6 step in the same idiom as v0.1.2 (single-paragraph for read-only file migrations) but 3-pointed per the spec.

Insert exactly the following block (replaces the single blank line at L59 with: blank-line + 3-point block + blank-line):

```
**v0.1.6 migration check:** If `docs/plans/` directory exists in the project (legacy pre-v0.1.6 plan location):

1. **Detection and safety check:** If `docs/plans/` does not exist, skip this step entirely (idempotent). Otherwise check `git status --porcelain docs/plans/ 2>/dev/null` — if non-empty (uncommitted edits to historical plans), abort with: `"Uncommitted changes in docs/plans/. Commit or stash them, or pass --force-plans to override."` If `--force-plans` is in `$ARGUMENTS`, proceed despite dirty status. Detect git availability with `git rev-parse --git-dir 2>/dev/null` — silent failure means non-git; use plain `mv` otherwise use `git mv` (preserves history per E02.S2.6 precedent).

2. **Move:** Write marker at `.roughly/plans/.migration-in-progress` (create `.roughly/plans/` if absent) containing the current ISO date and plugin version, then perform `git mv docs/plans/ .roughly/plans/` inside git (or plain `mv` otherwise). If the move command returns non-zero, surface the error verbatim and abort — the marker stays in place for re-run. Do NOT fall back between `git mv` and `mv` on failure (post-failure recovery via the other tool produces confusing error output that complicates the user's mental model of which tool moved what — inherits v0.1.4's idiom).

3. **Cleanup:** Remove the marker at `.roughly/plans/.migration-in-progress` once the move completes. Idempotency: a successful migration leaves `docs/plans/` absent; re-running detects the absence at step 1 and skips entirely.
```

Net delta: ~14 added lines (164 → ~178). Upgrade has ample headroom (136 lines).
**Verify:**
1. `wc -l skills/upgrade/SKILL.md` returns approximately 178 (was 164; delta ~+14).
2. `rg -Fn "v0.1.6 migration check" skills/upgrade/SKILL.md` returns 1 match.
3. `rg -Fn "force-plans" skills/upgrade/SKILL.md` returns 1 match.
4. Read L58–L75 and confirm the block follows the v0.1.4 step and precedes `**Version check:**`.
**UI:** no
**Depends on:** none

---

### T6: Update `scripts/ci-dogfood.sh` assertion paths (~2 min)
**Files:** `scripts/ci-dogfood.sh`
**Action:** Replace `docs/plans/` with `.roughly/plans/` in the two CI assertion lines.
**Details:** Use `Edit` to substitute at L153 and L156:
- L153: `PLAN_FILE="$(ls "$WORKTREE/tests/fixtures/hello-roughly/docs/plans/"*-plan.md ...)"` → `.../tests/fixtures/hello-roughly/.roughly/plans/...`
- L156: error message `"no plan file found in $WORKTREE/tests/fixtures/hello-roughly/docs/plans/"` → `"... /tests/fixtures/hello-roughly/.roughly/plans/"`

Two `Edit` calls, OR a single `replace_all: true` with `old_string: "tests/fixtures/hello-roughly/docs/plans/"`, `new_string: "tests/fixtures/hello-roughly/.roughly/plans/"` — the substring is unique in the file and `replace_all` is safe (verified by `rg -Fn` returning exactly 2 matches).
**Verify:**
1. `rg -Fn "docs/plans" scripts/` returns 0 matches.
2. `rg -Fn "tests/fixtures/hello-roughly/.roughly/plans/" scripts/ci-dogfood.sh` returns 2 matches (L153 and L156 positionally).
3. `bash -n scripts/ci-dogfood.sh` exits 0 (syntax check passes).
**UI:** no
**Depends on:** none

---

### T7: Update `README.md` L214 prose (~1 min)
**Files:** `README.md`
**Action:** Replace `docs/plans/` with `.roughly/plans/` at L214.
**Details:** Use `Edit` with `old_string: "Written to \`docs/plans/\` automatically"`, `new_string: "Written to \`.roughly/plans/\` automatically"`. Unique substring in the file.
**Verify:** `rg -Fn "docs/plans" README.md` returns 0 matches. `rg -Fn ".roughly/plans" README.md` returns 1 match at L214.
**UI:** no
**Depends on:** none

---

### T8: Append v0.1.6 plans-migration note to `CONTRIBUTING.md` (~2 min)
**Files:** `CONTRIBUTING.md`
**Action:** Add a brief note documenting the v0.1.6 plans-path migration as a contributor-facing operational change.
**Details:** CONTRIBUTING.md currently has no `## Migration` section. Append a new short subsection between `## Tooling Pitfalls` (L64) and `## Testing` (L85). Use `Edit` to insert before the `## Testing` heading. New section content:

```
## Migration

v0.1.6 relocated `docs/plans/` to `.roughly/plans/` to consolidate all Roughly runtime state under a single root. Existing projects with historical plans run `/roughly:upgrade` to migrate; `--force-plans` overrides the dirty-tree safety check. Plan files written by the build/fix pipelines now land in `.roughly/plans/<feature>-plan.md`. The pre-flight migration check in the 7 hard-abort skills + setup soft-abort detects either `.ruckus/` or `docs/plans/` legacy state and redirects to `/roughly:upgrade`.

```

Net delta: ~5 added lines. CONTRIBUTING.md has no line cap.
**Verify:** `rg -Fn "v0.1.6 relocated" CONTRIBUTING.md` returns 1 match. `rg -Fn "^## Migration$" CONTRIBUTING.md` returns 1 match. `rg -Fn "docs/plans" CONTRIBUTING.md` returns 1 match (the legacy-state mention in the new section is the only reference; it's a deliberate documentation of the migration trigger, not a live runtime path).
**UI:** no
**Depends on:** none

---

### T9: Update `CHANGELOG.md` with v0.1.6 Migration entry (~3 min)
**Files:** `CHANGELOG.md`
**Action:** Add E04.S1 entry under existing `## [Unreleased] — v0.1.6` `### Changed`, and add a new `### Migration` subsection per v0.1.4 precedent.
**Details:** Use `Edit` twice:

(a) Add to `### Changed` block (currently at L25–29, contains E04.S4 reorg entries). Append a new bullet immediately after the existing E04.S4 organize entry (after L29's pitfall entry, before `## [0.1.5]` at L31). The bullet documents the path move:

```
- **E04.S1 — Plan-path consolidation `docs/plans/` → `.roughly/plans/`.** All 29 historical plans relocated via `git mv` (E02.S2.6 history-preserving precedent). 15 runtime references flipped across 4 skill bodies enumerated in the story spec ([skills/build/SKILL.md](skills/build/SKILL.md), [skills/fix/SKILL.md](skills/fix/SKILL.md), [skills/help/SKILL.md](skills/help/SKILL.md), [skills/audit-epic/SKILL.md](skills/audit-epic/SKILL.md)) plus 2 additional canonical-example citations in [skills/review-plan/SKILL.md](skills/review-plan/SKILL.md) surfaced during discovery. Pre-flight migration check extended from one-form (`.ruckus/`) to two-form (`.ruckus/` OR `docs/plans/`) across the 7 hard-abort skills + setup soft-abort, delimited by new `<!-- pre-flight:start -->` / `<!-- pre-flight:end -->` HTML comments for the 7 hard-abort skills. New [tests/fixtures/canonical-preflight-block.txt](tests/fixtures/canonical-preflight-block.txt) fixture as single-source-of-truth for the two-form block (consumed by E04.S5's planned drift check). New v0.1.6 migration step in [skills/upgrade/SKILL.md](skills/upgrade/SKILL.md) (3-point: detect + safety + move + cleanup; `--force-plans` opt-in for dirty `docs/plans/`). [scripts/ci-dogfood.sh](scripts/ci-dogfood.sh) L153/L156 assertion paths updated. README.md L214 prose updated. No new ADR — matches v0.1.2's `docs/claude/` → `.ruckus/` and v0.1.4's `.ruckus/` → `.roughly/` precedents.
```

(b) Add `### Migration` subsection. Since the `## [Unreleased]` block does not yet have a `### Migration` subsection, append one at the end of the v0.1.6 block immediately before `## [0.1.5]` heading at L31. Use `Edit` to insert before L31:

```
### Migration

v0.1.5 → v0.1.6 introduces one user-action step: run `/roughly:upgrade` from each project that has historical plans in `docs/plans/`. The upgrade detects the legacy directory, performs `git mv docs/plans/ .roughly/plans/` inside a git repo (preserves history per E02.S2.6) or plain `mv` otherwise, and updates no other files. If `docs/plans/` has uncommitted edits, the migration aborts; pass `--force-plans` to override (e.g., when you are intentionally migrating a dirty tree). Idempotent: re-running after a successful migration is a no-op.

The pre-flight migration check in `/roughly:build`, `/roughly:fix`, `/roughly:audit-epic`, `/roughly:review`, `/roughly:review-plan`, `/roughly:review-epic`, `/roughly:verify-all`, and `/roughly:setup` now detects either `.ruckus/` (v0.1.3 install) or `docs/plans/` (pre-v0.1.6 location) and redirects to `/roughly:upgrade`. Skills will abort with the two-form prose until both legacy directories are absent (or, for setup, you choose `proceed anyway`).

```

Net delta: ~10 added lines to CHANGELOG.md.
**Verify:**
1. `rg -Fn "E04.S1 — Plan-path consolidation" CHANGELOG.md` returns 1 match (inside v0.1.6 block).
2. `rg -Fn "^### Migration$" CHANGELOG.md` returns 2 matches (v0.1.6 new entry + v0.1.4 existing at L136).
3. The 4 historical-fact references in CHANGELOG.md (at content-match L51 the v0.1.5 entry, L106 v0.1.4 historical context, L134 v0.1.4 Notes, L270 v0.1.0 Plan naming convention) remain unchanged: `rg -Fn "docs/plans" CHANGELOG.md` returns 4 matches by content (line numbers may shift due to the additions).
**UI:** no
**Depends on:** none

---

### T10: `git mv docs/plans/ .roughly/plans/` (~3 min)
**Files:** All 29 plan files in `docs/plans/` (rename to `.roughly/plans/`)
**Action:** Relocate the entire `docs/plans/` directory to `.roughly/plans/` using `git mv` to preserve history per E02.S2.6 precedent.
**Details:**
1. Verify `.roughly/` exists (it does — contains `known-pitfalls.md` and `workflow-upgrades`).
2. Run `git mv docs/plans .roughly/plans` (note: NO trailing slash on `.roughly/plans` since the destination directory does not yet exist; `git mv` interprets this as a directory rename when the source is a directory).
3. Confirm 29 plans staged for rename: `git status --porcelain | grep -c '^R'` returns 29.

Note: this task moves THIS plan file (`docs/plans/E04-S1-plan-path-consolidation-plan.md`) to `.roughly/plans/E04-S1-plan-path-consolidation-plan.md` along with the other 28. The orchestrator must update any in-progress references after T10 completes.
**Verify:**
1. `ls docs/plans/ 2>&1` returns "No such file or directory" (or the dir is fully empty).
2. `ls .roughly/plans/*.md | wc -l` returns 29.
3. `git log --follow .roughly/plans/E03-S8-help-command-plan.md` shows the full pre-rename history (AC2's verify command — confirms history preservation).
4. `git status --porcelain` shows 29 renames (`R  docs/plans/X -> .roughly/plans/X`).
**UI:** no
**Depends on:** T1, T2, T3, T4, T5, T6, T7, T8, T9 (run last so verification commands operate on the final state — and so the plan file itself is moved by this task, simplifying orchestrator state tracking)

---

## Verification matrix (post-implementation, before Stage 6)

After all 10 tasks complete, the following must all pass:

| Check | Command | Expected |
|-------|---------|----------|
| AC1 — zero `docs/plans/` refs in skills | `rg -Fn "docs/plans" skills/` | 0 matches |
| AC1a — historical-fact carve-outs preserved | `rg -Fn "docs/plans" CHANGELOG.md` | 4 matches (line numbers may shift) |
| AC1a — historical refs in epics/prompts/archive | `rg -Fn "docs/plans" docs/planning/epics/complete/ docs/planning/prompts/ docs/planning/archive/ 2>/dev/null` | match count identical to pre-migration (capture pre-state via `wc -l`) |
| AC2 — git history preserved | `git log --follow .roughly/plans/E03-S8-help-command-plan.md \| head -5` | non-empty history |
| AC4 — canonical 7-hash byte-identity | `for f in skills/audit-epic/SKILL.md skills/build/SKILL.md skills/fix/SKILL.md skills/review/SKILL.md skills/review-plan/SKILL.md skills/review-epic/SKILL.md skills/verify-all/SKILL.md; do awk '/<!-- pre-flight:start -->/,/<!-- pre-flight:end -->/' "$f" \| md5sum; done; md5sum tests/fixtures/canonical-preflight-block.txt` piped through `sort -u \| wc -l` | `1` |
| AC5 — zero refs in active surfaces | `rg -Fn "docs/plans" scripts/ README.md` | 0 matches (CONTRIBUTING.md is acceptably 1 — its new Migration section names the legacy path as the migration trigger) |
| AC9 — no new ADR | `ls docs/adrs/ADR-012*.md 2>&1` | "No such file or directory" |
| Line caps | `wc -l skills/*/SKILL.md \| awk '$1 > 300'` | no output (no skill body exceeds 300) |

## Blast Radius

**Do NOT modify:**
- `docs/planning/epics/complete/**` (historical epics — carve-out per AC1a)
- `docs/planning/prompts/**` (PM prompts — carve-out per AC1a)
- `docs/planning/archive/**` (archived planning — carve-out per AC1a)
- Plan files' internal content (their internal references stay as documenting-the-state-at-write-time; `git mv` moves the files but does NOT rewrite their content)
- 4 historical CHANGELOG references (carve-out per AC1a)
- `docs/adrs/**` (no new ADR per AC9; existing ADR text not touched)
- `agents/**` (no agent file changes in this story)
- Any other file not listed in the File Table

**Watch for:**
- **Line-cap budget on build (298 → 298) and fix (299 → 299).** The canonical pre-flight block is single-line and net-zero per skill. If the implementer accidentally expands the block to multi-line or adds surrounding prose, fix will breach the 300-line cap and the merge fails the dogfood Stop hook. Verify `wc -l` after every edit to build and fix.
- **The 2 review-plan references** (L36, L44) are unenumerated in the spec but required for AC1's `rg -Fn` zero-match. Plan includes them in T4.
- **Setup soft-abort form** must NOT receive HTML comment delimiters (per AC4 and `.roughly/known-pitfalls.md` L40). T3 explicitly excludes delimiters from setup.
- **`git mv` semantics:** `git mv source dest` where dest does not exist treats source as a directory rename. Confirm with `git status --porcelain | grep -c '^R'` showing 29 renames (not 29 deletes + 29 adds).
- **CI dogfood line-number drift:** the spec's L153/L156 are confirmed accurate as of HEAD (Discovery point 4). Re-confirm in T6's old_string anchors.
- **Plan file self-move during T10:** this very plan file is at `docs/plans/E04-S1-plan-path-consolidation-plan.md` pre-T10 and `.roughly/plans/E04-S1-plan-path-consolidation-plan.md` post-T10. The orchestrator must track this transition when re-reading the plan file between tasks.

## Conventions

- **ADR-006** — Path strings in skills are runtime references read by Claude inside the user's project; flipping them IS a real behavior change at install time. No need to also flip "compile-time" references because there are none.
- **ADR-011** — `--force-plans` is a flag in `$ARGUMENTS`, not an env var (matches the principle codified by E04.S7 for skill flags as public API).
- **E03.S4 known-pitfall** — Setup soft-abort form is intentionally divergent from the 7 hard-abort canonical form; the byte-identity check (AC4) scopes to the 7 hard-abort skills only.
- **`Edit` `replace_all` dual-semantic-token failure** — Safe to use `replace_all: true` for the path substitutions in T4 and T6 because the literal substrings (`docs/plans/` and `tests/fixtures/hello-roughly/docs/plans/`) appear only as path references with no semantic-token collisions per the `CONTRIBUTING.md ## Tooling Pitfalls` worked example.
- **Append-only Edit pitfall** — Not directly applicable to S1 (no prepend operations on existing files; T8's CONTRIBUTING insertion is a structured insertion before a heading anchor, not an append-style edit).
- **Backport-from-template completeness gap** (`.roughly/known-pitfalls.md` L80) — Not directly applicable to S1 (S1 is the canonical source of the new pre-flight block, not a backport; future skills MUST be diffed against `tests/fixtures/canonical-preflight-block.txt` rather than per-edit-enumerated).
- **Bold-decorated markdown grep pitfall** (`.roughly/known-pitfalls.md` L84) — Applicable to T2/T3's `old_string` anchors: the canonical block starts with `**Pre-flight migration check:**` (bold). Match using literal `**Pre-flight migration check:** If \`.ruckus/.migration-in-progress\`` (a unique substring NOT straddling a bold-close marker, since `**` is at the open-bold position only).
- **Line-cap budget contract** — S1 does NOT invoke the prose-extraction off-ramp because the single-line canonical block keeps net-line-delta at 0 on the binding-constraint files (build, fix).
