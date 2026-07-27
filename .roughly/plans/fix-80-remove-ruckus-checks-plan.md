# Fix Plan: #80 — remove obsolete `ruckus` / pre-v0.1.6 legacy machinery

Plan-format-version: 1

## Root Cause

`ruckus` was the plugin's original name (renamed to `roughly` in v0.1.4). The pre-flight migration blocks, the Stop-hook `.ruckus/` drift detector, and the v0.1.4 `.ruckus/`→`.roughly/` upgrade-migration engine were added as a safety net for consumer projects with legacy `.ruckus/` state. With no remaining users/forks/`.ruckus/` projects — and (user-confirmed) no projects on pre-v0.1.6 Roughly either — this machinery is dead weight that fires on every pipeline run. Removing it also requires coordinated doc sync so worked examples and check-enumerations don't reference deleted code. All anchors below were re-verified at current HEAD (the issue #80 body's 2026-06-10 line numbers are stale after this session's #72–#75 edits).

## Scope decisions (user-confirmed / investigator-surfaced)
- **Remove the ENTIRE pre-flight block** (both the `.ruckus/` and pre-v0.1.6 `docs/plans/*-plan.md` clauses) — user confirmed both legacy states are obsolete.
- **Behavioral tradeoff (accepted):** removing the blocks eliminates *proactive* every-run detection of un-migrated `docs/plans/*-plan.md` state; it remains detectable *reactively* only via `/roughly:upgrade` (whose v0.1.6 check stays). Documented in the CHANGELOG entry.
- **`tests/` is NOT in the AC grep scope** (the issue's AC greps `skills/ agents/ .claude/hooks/ scripts/ .github/workflows/`). The synthetic fixture `tests/fixtures/review-plan/ac5-self-defeating-pass.md` (12 incidental "ruckus" hits, unrelated to real machinery) is **left untouched**. The `tests/fixtures/canonical-preflight-block.txt` is deleted because it is the real artifact of the removed Check 5.
- **known-pitfalls L82 + L118** refactor to SYNTHETIC examples (preserve pattern, drop ruckus specifics). L24/L114/L126/L140 stay historical.
- **CONTRIBUTING "## Tooling Pitfalls"** worked example is the *same* incident as L118 — genericize it to the same synthetic scenario (no cross-file pointer).
- **Out of scope / preserve (historical):** CHANGELOG history, README migration section, ADR-004/005/006/008, all E01–E04 epics, `docs/planning/prompts/ruckus-*` + `roughly-pm-agent-v0.1.4–0.1.8.md` snapshots (incl. their `canonical-preflight-block` references), setup's L44–48 v0.1.2 `docs/claude/` clause, and the v0.1.2 migration step in `upgrade/SKILL.md` (only the **v0.1.4** step is removed).

## Shared synthetic content (T4 + T5 use these VERBATIM so the two files stay consistent)
**(A) Dual-semantic-role token** (replaces the ruckus/verify-all worked example): a config-loader script where the token `legacyDataDir` appears both as (a) user-facing comment prose to be renamed to `modernDataDir`, AND (b) a legacy-migration detector block that intentionally greps `legacyDataDir` to flag un-migrated projects. A `replace_all: true` rename flips BOTH — the detector silently starts hunting for the *current* path and can never fire. Invisible in CI (no fixture triggers the inverted grep); caught only by re-reading with fresh eyes; recovery is a surgical `Edit` restoring the detector's literal. Lesson (unchanged): before any bulk replace of a rename token, scan for sites where the OLD form is intentional (legacy detectors, migration-context strings, "renamed FROM X" prose) and use targeted per-site `Edit`s; verify with paired `rg -nw 'old'` / `rg -nw 'new'` greps whose outputs match expectations.
**(B) Byte-identity drift-check scoping** (replaces the setup-soft-abort example): a "maintenance-mode banner" convention required byte-identical across N dashboard-view files, EXCEPT one view (`admin-view`) which by design uses a softer dismissible variant. A drift check scoped to "all `*-view` files" would wrongly flag the intentional `admin-view` divergence. Lesson (unchanged) — **pattern statement (use this exact sentence verbatim in T5):** "byte-identity drift checks must be scoped to the specific subset, not the whole population." Keep an explicit exclusion list; verify the canonical set with `… | sort -u | wc -l` = 1 and verify the exempt file separately.

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| skills/{audit-epic,build,fix,review,review-epic,review-plan,verify-all}/SKILL.md | Modify (delete pre-flight block) | T1 |
| .claude/hooks/verify-all.sh | Modify (remove Check 1 + Check 5) | T1 |
| tests/fixtures/canonical-preflight-block.txt | Delete | T1 |
| skills/setup/SKILL.md | Modify | T2 |
| skills/help/SKILL.md | Modify | T2 |
| skills/upgrade/SKILL.md | Modify (remove v0.1.4 engine) | T3 |
| CONTRIBUTING.md | Modify | T4 |
| .roughly/known-pitfalls.md | Modify (2 synthetic refactors) | T5 |
| docs/ROADMAP.md | Modify | T6 |
| CHANGELOG.md | Modify (v0.1.9 entry) | T6 |

## Baseline facts (captured 2026-07-27, branch `fix/80-remove-ruckus-plugin-checks`, at parity `main`)
- Pre-flight block = ONE physical line + trailing blank, byte-identical across the 7 skills (delimited `<!-- pre-flight:start --> … <!-- pre-flight:end -->`): audit-epic:19, build:19, fix:19, review:18, review-epic:17, review-plan:13, verify-all:15. Seam per file: `<blank>` / `<block line>` / `<blank>` / `---` (or `## Input` for review-plan) — delete the block line + ONE adjacent blank.
- verify-all.sh (230 lines): Check 1 `if rg -q '\.ruckus/known-pitfalls' agents/` at 16–19; Check 5 pre-flight-byte-identity block at 40–72 (reads `tests/fixtures/canonical-preflight-block.txt`). Both self-contained `if`/`fi`; nothing else references them or the fixture. Post-removal ≈192 lines. The #75 emit_drift_json check, CRITICAL-preamble, known-pitfalls-threshold, and shared-ref-drift checks are untouched.
- upgrade/SKILL.md (174 lines): v0.1.4 block = lines 21–58 (`**v0.1.4 migration check:**` … end of its step 10), between the v0.1.2 block (ends L19) and `**v0.1.6 migration check:**` (L60). Keep v0.1.2 (16–19) and v0.1.6 (60+).
- CONTRIBUTING.md: "## Tooling Pitfalls" section ~106–119 (ruckus worked example + two false grep bullets); "## Migration" pre-flight sentence at end of L124; the check enumeration at ~201–211 ("seven structural invariants"; item 1 Path-drift L203, item 5 pre-flight L207; the "Check 8" ref at L66 is a separate unsynced track — do NOT touch).
- known-pitfalls.md L82 (setup soft-abort pitfall), L118 (dual-semantic-role pitfall) — full current text captured in investigation.
- ROADMAP.md: Cluster C entry ~165–166 (cites stale `verify-all.sh:16-18`); "## v0.4.x — Cleanup (opportunistic)" at ~269–277 (items 1 & 3 completed by this PR; item 2 partially).
- CHANGELOG.md: newest section is `## [0.1.8] — 2026-06-10`; no `[Unreleased]`/`[0.1.9]` — must add one at the top.
- `build:11 ≡ fix:11` CRITICAL invariant: line 11 in both, 8 lines above the block — unaffected. Skill line caps: all ≤289/300 pre-removal, removal only adds headroom. Session shims: use `command grep`/`command diff`/`command rg`.

## Tasks

### T1: Remove the pre-flight machinery — 7 blocks + verify-all Check 1 & Check 5 + canonical fixture (~10 min)
**Files:** skills/audit-epic/SKILL.md, skills/build/SKILL.md, skills/fix/SKILL.md, skills/review/SKILL.md, skills/review-epic/SKILL.md, skills/review-plan/SKILL.md, skills/verify-all/SKILL.md, .claude/hooks/verify-all.sh, tests/fixtures/canonical-preflight-block.txt
**Action:** Delete the pre-flight block from all 7 skills (block line + one adjacent blank), remove Check 1 and Check 5 from verify-all.sh, and delete the canonical fixture. **Do these together** — removing the blocks/fixture without removing Check 5 would make an interim verify-all run false-fire (fixture-missing + block-mismatch).
**Details:**
1. In each of the 7 skills, delete the single `<!-- pre-flight:start --> … <!-- pre-flight:end -->` line AND the blank line immediately after it (leaving the pre-existing blank line before it as the sole separator before the following `---` / `## Input`). Use `Edit` matching the block line plus its trailing blank+`---` (or `+## Input` for review-plan) to anchor the seam uniquely. After: each file has exactly one blank line between the prior content and the `---`/heading.
2. In `.claude/hooks/verify-all.sh`, remove **Check 1** — the block:
   `# Path drift: agents/ should not reference legacy .ruckus/known-pitfalls` through its `fi` (currently 16–19) plus the blank line separating it from the next check — delete lines 15–19 (the leading blank + comment + 3-line `if`/`fi`), keeping the blank before `# Skill line cap (300)`.
3. In the same file, remove **Check 5** — the entire `# Pre-flight wording byte-identity across 7 hard-abort skills` comment + code block (currently 41–72) plus its leading blank (40), keeping the blank before `# plan-mode-gate hook-pair …`. Delete lines 40–72.
4. `git rm tests/fixtures/canonical-preflight-block.txt` (or delete + `git add`).
Do NOT touch the emit_drift_json function, the #75 sync check, or any other check.
**Verify:**
```
cd /Users/nickkirkes/rowdycloud/code/roughly
command rg -nw 'ruckus' skills/audit-epic/SKILL.md skills/build/SKILL.md skills/fix/SKILL.md skills/review/SKILL.md skills/review-epic/SKILL.md skills/review-plan/SKILL.md skills/verify-all/SKILL.md .claude/hooks/verify-all.sh && { echo FAIL-ruckus-remains; exit 1; } || echo "0 ruckus in 7 skills + hook"
command rg -l 'pre-flight:start' skills/ && { echo FAIL-block-remains; exit 1; } || echo "no pre-flight blocks remain"
test ! -f tests/fixtures/canonical-preflight-block.txt || { echo FAIL-fixture-remains; exit 1; }
command grep -qF 'canonical-preflight-block' .claude/hooks/verify-all.sh && { echo FAIL-check5-remains; exit 1; } || echo "Check 5 gone"
command grep -qF '.ruckus/known-pitfalls' .claude/hooks/verify-all.sh && { echo FAIL-check1-remains; exit 1; } || echo "Check 1 gone"
bash -n .claude/hooks/verify-all.sh || { echo FAIL-syntax; exit 1; }
out=$(bash .claude/hooks/verify-all.sh 2>&1); [ -z "$out" ] || { echo "FAIL-verify-not-clean: $out"; exit 1; }
# emit_drift_json + #75 sync check intact:
command grep -qF 'emit_drift_json function-scoped sync' .claude/hooks/verify-all.sh || { echo FAIL-75check-gone; exit 1; }
echo "T1 PASS ($(wc -l < .claude/hooks/verify-all.sh) lines)"
```
**UI:** no

### T2: De-ruckus setup + help skills (~6 min)
**Files:** skills/setup/SKILL.md, skills/help/SKILL.md
**Action:** Remove the ruckus references from setup (maturity bullet + soft-abort clause, with the required `Else if`→`If` fixup) and help (STEP 0 block + error-string clause).
**Details:**
1. `skills/setup/SKILL.md` L31: the maturity-detection bullet `- Existing .claude/, .ruckus/, .roughly/, or docs/claude/ directory` — remove `.ruckus/, ` so it reads `- Existing .claude/, .roughly/, or docs/claude/ directory`.
2. `skills/setup/SKILL.md` L39–41: delete the soft-abort clause line (`If \`.ruckus/.migration-in-progress\`, … exists, OR if \`.roughly/\` exists AND any file matching \`docs/plans/*-plan.md\` exists (...):`), its blockquote line 40 (`> "Legacy state detected (\`.ruckus/\` …) … (proceed anyway / abort)"`), and the trailing blank (41). Then **change the next condition (now the first in the chain) from `Else if \`docs/claude/\` exists:` to `If \`docs/claude/\` exists:`** so the conditional chain is grammatical. Leave lines 45–48 (the generic `.roughly/`/`.claude/` existing-config clause + enriching paragraph) intact — note the `docs/claude/` clause at 42–43 is the one being reworded (`Else if`→`If`), not left as-is.
3. `skills/help/SKILL.md` L15–21: delete the entire `## STEP 0: PRE-FLIGHT NOTE (NEVER ABORTS)` heading through the blank line before the `---` at L22 (the whole STEP 0 block is ruckus-specific), leaving the `---` in place.
4. `skills/help/SKILL.md` L49: the marker-state error message — remove the trailing clause `, or \`/roughly:upgrade\` if a \`.ruckus/\` legacy file is present` so it ends `… Run \`/roughly:setup\` to initialize.`
**Verify:**
```
cd /Users/nickkirkes/rowdycloud/code/roughly
command rg -nw 'ruckus' skills/setup/SKILL.md skills/help/SKILL.md && { echo FAIL-ruckus-remains; exit 1; } || echo "0 ruckus in setup+help"
command grep -qF 'Else if `docs/claude/` exists' skills/setup/SKILL.md && { echo FAIL-orphan-elseif; exit 1; } || echo "conditional chain fixed"
command grep -qF 'STEP 0: PRE-FLIGHT NOTE' skills/help/SKILL.md && { echo FAIL-step0-remains; exit 1; } || echo "help STEP 0 removed"
echo "T2 PASS"
```
**UI:** no

### T3: Remove the v0.1.4 `.ruckus/` migration engine from upgrade (~4 min)
**Files:** skills/upgrade/SKILL.md
**Action:** Delete the v0.1.4 migration section (its 10 steps), keeping the v0.1.2 and v0.1.6 migration checks.
**Details:** Delete from the line `**v0.1.4 migration check:** If \`.ruckus/\` directory exists in the project (legacy v0.1.3 installation):` through the end of its step 10, i.e. everything up to (but not including) the `**v0.1.6 migration check:**` line — plus one of the two surrounding blank lines so exactly one blank separates the v0.1.2 `If yes:` paragraph from `**v0.1.6 migration check:**`. (Currently lines 21–58 + the blank at 59; anchor by the two `**vX migration check:**` markers, not raw line numbers.) Do NOT touch the v0.1.2 `**Migration check:**` block (16–19) or the v0.1.6 block.
**Verify:**
```
cd /Users/nickkirkes/rowdycloud/code/roughly
command rg -nw 'ruckus' skills/upgrade/SKILL.md && { echo FAIL-ruckus-remains; exit 1; } || echo "0 ruckus in upgrade"
command grep -qF 'v0.1.4 migration check' skills/upgrade/SKILL.md && { echo FAIL-v014-remains; exit 1; } || echo "v0.1.4 engine gone"
command grep -qF 'v0.1.6 migration check' skills/upgrade/SKILL.md || { echo FAIL-v016-lost; exit 1; }
command grep -qF 'Roughly renamed `docs/claude/` to `.roughly/`' skills/upgrade/SKILL.md || { echo FAIL-v012-lost; exit 1; }
n=$(wc -l < skills/upgrade/SKILL.md); [ "$n" -le 300 ] || { echo "FAIL-cap $n"; exit 1; }
echo "T3 PASS ($n lines)"
```
**UI:** no

### T4: CONTRIBUTING sync — enumeration surgery + genericize the Tooling Pitfalls worked example + drop the pre-flight sentence (~8 min)
**Files:** CONTRIBUTING.md
**Depends on:** (conceptually) T1 removed the checks this documents; no file conflict.
**Action:** (a) Remove enumeration items for the two deleted checks and renumber; (b) genericize the "## Tooling Pitfalls" ruckus worked example to synthetic scenario (A); (c) remove the now-false pre-flight sentence from "## Migration".
**Details:**
1. **Enumeration** (~201–211): delete item "**Path drift** — `agents/` files must not reference legacy `.ruckus/known-pitfalls`." and item "**Pre-flight wording byte-identity across 7 hard-abort skills** — …". Renumber the remaining five (Skill line cap→1, Agent word cap→2, HTML comment integrity→3, plan-mode-gate hook-pair→4, known-pitfalls organize threshold→5). Change the lead-in "It enforces **seven** structural invariants:" → "**five**". Rewrite the trailing provenance sentence "Checks 1–4 are pre-existing (S2-era…). Checks 5–7 land in E04.S5…" to match the new numbering (HTML-comment-integrity is the S2-era survivor at new-#3; plan-mode-gate + known-pitfalls-threshold landed in E04.S5 as new-#4/#5) — e.g. "Checks 1–3 are pre-existing (S2-era structural invariants); Checks 4–5 landed in E04.S5." Do NOT touch the separate "Check 8" reference at L66 (unsynced numbering track).
2. **Tooling Pitfalls** (~106–119): replace the ruckus-specific "Worked example: `.claude/hooks/verify-all.sh`. …" paragraph AND the two `rg -nw` verify bullets (which cite now-deleted lines 17/18/19) with synthetic scenario **(A)** from the plan header (config-loader `legacyDataDir`→`modernDataDir`). Keep the section's generic intro, at-risk-tools list, and the closing "Before any bulk replace, scan…" guidance. Rewrite the two verify bullets to the synthetic tokens (e.g. `rg -nw 'legacyDataDir' config-loader.sh` should match only the detector sites; `rg -nw 'modernDataDir' …` only the renamed prose).
3. **Migration section** (L124): delete the sentence "The pre-flight migration check in the 7 hard-abort skills + setup soft-abort detects either `.ruckus/` or `docs/plans/` legacy state and redirects to `/roughly:upgrade`." Keep the rest of the "## Migration" section (v0.1.6 `docs/plans/`→`.roughly/plans/` guidance).
**Verify:**
```
cd /Users/nickkirkes/rowdycloud/code/roughly
command rg -nw 'ruckus' CONTRIBUTING.md && { echo FAIL-ruckus-remains; exit 1; } || echo "0 ruckus in CONTRIBUTING"
command grep -qF 'five structural invariants' CONTRIBUTING.md || { echo FAIL-count; exit 1; }
command grep -qF 'Path drift' CONTRIBUTING.md && { echo FAIL-pathdrift-remains; exit 1; } || echo "Path-drift item removed"
command grep -qF 'canonical-preflight-block' CONTRIBUTING.md && { echo FAIL-preflight-item-remains; exit 1; } || echo "pre-flight item removed"
command grep -qF 'legacyDataDir' CONTRIBUTING.md || { echo FAIL-synthetic-missing; exit 1; }
command grep -qF 'Check 8' CONTRIBUTING.md || { echo FAIL-check8-ref-lost; exit 1; }
echo "T4 PASS"
```
**UI:** no

### T5: known-pitfalls — refactor L82 + L118 to synthetic examples (~8 min)
**Files:** .roughly/known-pitfalls.md
**Action:** Replace the two ruckus-anchored pitfall entries with the synthetic scenarios, preserving each reusable pattern name and the load-bearing mechanic. Leave L24/L114/L126/L140 (historical) unchanged.
**Details:**
1. The **dual-semantic-role Edit** entry (currently L118, opening `**\`Edit\`'s \`replace_all: true\` is dangerous when the same token serves dual semantic roles in the same file.**`): rewrite the body to synthetic scenario **(A)** (config-loader `legacyDataDir`→`modernDataDir`). Keep the opening bold pattern statement verbatim; replace the S02.7/verify-all.sh specifics with (A)'s narrative; keep the generalization ("any bulk-replacement tool … sed -i, IDE find/replace") and the paired-grep verify guidance (retargeted to the synthetic tokens).
2. The **setup soft-abort / byte-identity-scoping** entry (currently L82, opening about `setup/SKILL.md`'s pre-flight soft-abort): rewrite to synthetic scenario **(B)** (maintenance-mode banner across `*-view` files with an intentional `admin-view` exception). Preserve the pattern statement ("byte-identity drift checks must be scoped to the specific subset, not the whole population") and the `sort -u | wc -l = 1` + separate-exempt-file verification mechanic; drop all `.ruckus/`/`setup/SKILL.md`-pre-flight specifics (which no longer exist post-removal).
Do not renumber or reflow other entries; the file's `wc -l` stays well under the 300 organize threshold.
**Verify:**
```
cd /Users/nickkirkes/rowdycloud/code/roughly
# the two refactored entries no longer carry ruckus/pre-flight specifics:
command grep -qF 'legacyDataDir' .roughly/known-pitfalls.md || { echo FAIL-A-missing; exit 1; }
command grep -qF 'admin-view' .roughly/known-pitfalls.md || { echo FAIL-B-missing; exit 1; }
command grep -qF 'dual semantic roles' .roughly/known-pitfalls.md || { echo FAIL-pattern-A-lost; exit 1; }
command grep -qF 'scoped to the specific subset' .roughly/known-pitfalls.md || { echo FAIL-pattern-B-lost; exit 1; }
# historical entries preserved (spot-check one token each):
command grep -qF 'S2.2' .roughly/known-pitfalls.md || echo "NOTE: verify L24 historical entry intact"
# verify-all still clean (line count under threshold):
out=$(bash .claude/hooks/verify-all.sh 2>&1); [ -z "$out" ] || { echo "FAIL-verify-not-clean: $out"; exit 1; }
echo "T5 PASS"
```
**UI:** no

### T6: ROADMAP reconciliation + CHANGELOG v0.1.9 entry (~6 min)
**Files:** docs/ROADMAP.md, CHANGELOG.md
**Action:** Reconcile the ROADMAP v0.4.x cleanup section (the removed work is no longer "future"), fix the Cluster C off-by-one, and add a CHANGELOG entry.
**Details:**
1. `docs/ROADMAP.md` "## v0.4.x — Cleanup (opportunistic)" list: strike item 1 ("Remove pre-flight migration checks from 9 skills") and item 3 ("Prune Stop hook legacy-`.ruckus/` detection") as **done in v0.1.9 (#80)** — either remove them or mark `~~…~~ (done #80)`. Narrow item 2 to "Drop v0.1.2 migration step from `upgrade/SKILL.md`" (the v0.1.4 step is now removed; v0.1.2 `docs/claude/` remains). Leave item 4 (CHANGELOG `### Migration` convention decision) untouched.
2. `docs/ROADMAP.md` Cluster C entry (~166): fix the stale citation `verify-all.sh:16-18` → `verify-all.sh:16-19` (the `if`/`fi` block is 4 lines).
3. `CHANGELOG.md`: add a new top section above `## [0.1.8]`:
   ```
   ## [0.1.9] — <leave the date as the literal token TBD-RELEASE or today's ISO date>

   ### Removed
   - **Obsolete `ruckus` / pre-v0.1.6 legacy machinery (#80).** Removed the pre-flight migration blocks from the 7 hard-abort skills + setup soft-abort + help STEP 0 note; the Stop-hook `.ruckus/known-pitfalls` drift check (verify-all Check 1) and the pre-flight byte-identity check (Check 5) + its `tests/fixtures/canonical-preflight-block.txt`; and the v0.1.4 `.ruckus/`→`.roughly/` migration engine in `upgrade/SKILL.md`. Coordinated doc sync: CONTRIBUTING enumeration (7→5 invariants) + Tooling-Pitfalls worked example genericized; 2 `.roughly/known-pitfalls.md` entries refactored to synthetic examples (patterns preserved). Historical record preserved (CHANGELOG, README migration section, ADR-004/005/006/008, E01–E04 epics, `ruckus-*` planning artifacts). **Behavior change:** un-migrated pre-v0.1.6 `docs/plans/*-plan.md` state is no longer detected proactively on every pipeline run — only reactively via `/roughly:upgrade` (whose v0.1.6 migration check is unchanged). No migration path remains for v0.1.3-or-earlier `.ruckus/` installs; such users must first `/roughly:upgrade` on ≤v0.1.8 before adopting v0.1.9.
   ```
   (Use today's date if known; otherwise the literal `TBD-RELEASE` placeholder — the human sets the real date at release.)
**Verify:**
```
cd /Users/nickkirkes/rowdycloud/code/roughly
command grep -qF 'verify-all.sh:16-19' docs/ROADMAP.md || { echo FAIL-roadmap-offby1; exit 1; }
command grep -qF '## [0.1.9]' CHANGELOG.md || { echo FAIL-changelog-entry; exit 1; }
command grep -qF '#80' CHANGELOG.md || { echo FAIL-changelog-issue-ref; exit 1; }
command grep -qF 'Remove pre-flight migration checks from 9 skills' docs/ROADMAP.md && echo "NOTE: confirm v0.4.x item 1 was struck/marked-done, not left as pending"
echo "T6 PASS"
```
**UI:** no

## Blast Radius
- **Do NOT modify (historical, preserve):** `CHANGELOG.md` v0.1.0–v0.1.8 entries (only ADD the v0.1.9 section), `README.md` migration subsection, `docs/adrs/ADR-004/005/006/008`, all `docs/planning/epics/complete/E01`–`E04` files, `docs/planning/prompts/ruckus-*` + `roughly-pm-agent-v0.1.4–0.1.8.md` (incl. their `canonical-preflight-block` references), `tests/fixtures/review-plan/ac5-self-defeating-pass.md` (synthetic fixture, tests/ out of AC scope), setup L44–48 (v0.1.2 `docs/claude/` clause), the v0.1.2 + v0.1.6 migration checks in `upgrade/SKILL.md`, and known-pitfalls L24/L114/L126/L140.
- **Do NOT touch** the `emit_drift_json` function, the #75 sync check, the CRITICAL preamble (build:11≡fix:11), or the "Check 8" reference at CONTRIBUTING:66.
- **Watch for:** (a) T1 atomicity — Check 5 and the blocks/fixture must go together or interim verify-all false-fires; (b) the setup `Else if`→`If` companion edit (T2) — omitting it leaves a broken conditional chain; (c) shimmed grep/rg/diff — use `command …`; (d) do not let a bulk `ruckus`→(delete) sweep touch historical files — edit only the enumerated in-scope sites.

## Conventions
- No build/test harness — inline `command rg`/`bash -n`/live-hook-run Verify blocks are the validation.
- New pitfall (silent proactive-detection removal tradeoff) is captured in the CHANGELOG entry (T6), not as a plan task.
- The synthetic examples (A)/(B) are used identically in T4 and T5 so the two docs teach the same lesson without divergence.
