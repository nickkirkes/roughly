> **Status:** Historical — implemented and merged in commit bd8e37cacbcf8f45008a156e5ed2eaa391a3b5a3 on 2026-05-21. This plan was an active build/fix artifact; treat as historical reference only.

# Implementation Plan: E04.S5 Stop Hook Drift Coverage Expansion

Plan-format-version: 1

Reference: `docs/planning/epics/E04-path-consolidation-and-process-codification.md` §E04.S5 (L230–296).

## File Table

| File | Action | Task(s) |
|------|--------|---------|
| `.claude/hooks/verify-all.sh` | Modify (add 3 check blocks + 1 constant before `emit_drift_json` at L41) | T1, T2, T3 |
| `agents/doc-writer.md` | Modify (add bidirectional sync comment adjacent to `line count > 80` at L33) | T4 |
| `CONTRIBUTING.md` | Modify (insert new `## Stop hook drift checks` section before `## License` at L134) | T5 |
| — (verification only; no file writes beyond temp/revert) | Verify | T6 |

## Tasks

### T1: Add Check 1 — Pre-flight wording byte-identity across 7 hard-abort skills (~4 min)
**Files:** `.claude/hooks/verify-all.sh`
**Action:** Insert a new check block between L39 (closing `fi` of HTML comment integrity check) and L41 (`emit_drift_json() {`). New block ends with one blank line separating it from Check 2.
**Details:**
- Insertion: replace the existing blank line at L40 with the block below (a new blank line is preserved at the end so subsequent blocks insert cleanly).
- The block must:
  - Use a pipeline `{ <loop>; <fixture shasum>; } | sort -u | grep -cv '^$'` to count unique hashes across 7 skills + fixture (8 inputs total).
  - Hash the awk-extracted block per skill: `awk '/<!-- pre-flight:start -->/,/<!-- pre-flight:end -->/' "skills/${skill}/SKILL.md" | "$PREFLIGHT_SHA" | awk '{print $1}'`. The trailing `awk '{print $1}'` extracts the hash field so the fixture's filename column (`<hash>  tests/fixtures/...`) does not differ from the pipe column (`<hash>  -`) at `sort -u`.
  - List the 7 hard-abort skill names inline: `audit-epic build fix review review-plan review-epic verify-all` (setup is excluded by design — see leading comment).
  - Use `shasum` (Perl-based, default on macOS + full Linux distros) with `sha1sum` fallback (coreutils, present on BusyBox/Alpine minimal containers). Detect at script setup via `PREFLIGHT_SHA=$(command -v shasum 2>/dev/null || command -v sha1sum 2>/dev/null)`. `md5sum` is NOT portable — macOS does not ship it (only `md5`, which has different output format).
  - Guard fixture-existence at the top of the block; if fixture missing, emit a directed `- pre-flight canonical fixture missing: ... — Check 1 cannot run\n` drift entry and skip the pipeline (silent-failure mitigation: empty-input hashes collapse in `sort -u`).
  - Guard hash-tool availability; if both shasum and sha1sum absent, emit `- pre-flight check tooling unavailable: neither shasum nor sha1sum on PATH — Check 1 cannot run\n`.
  - Guard per-skill marker presence (detect empty awk extraction before hashing); if any skill is missing pre-flight markers, emit a directed `- pre-flight markers missing in skills: <list>\n` instead of running the hash comparison (diagnostic precision over generic drift).
  - Emit drift entry on `unique_preflight != 1` using AC1.2 verbatim format: `- pre-flight wording drift: ${unique_preflight} unique blocks across 7 hard-abort skills (expected 1)\n`
- Exact block to insert (replaces the existing L40 blank line; preserves a trailing blank line). **Note:** the version below reflects the as-built state after Stage 6 review (silent-failure-hunter Critical → fixture-existence + per-file marker guards + empty-block detection) and Stage 8 cubic review (P1 macOS portability → shasum with sha1sum fallback + tooling-unavailable branch):

```bash
# Pre-flight wording byte-identity across 7 hard-abort skills
# (Canonical source: tests/fixtures/canonical-preflight-block.txt.
# setup/SKILL.md uses a soft-abort form by design and is excluded — see .roughly/known-pitfalls.md.)
# Uses `shasum` (default on macOS + full Linux distros); falls back to `sha1sum`
# (default on BusyBox/Alpine and other minimal containers without Perl).
PREFLIGHT_SHA=$(command -v shasum 2>/dev/null || command -v sha1sum 2>/dev/null)
if [ ! -f tests/fixtures/canonical-preflight-block.txt ]; then
  issues="${issues}- pre-flight canonical fixture missing: tests/fixtures/canonical-preflight-block.txt — Check 1 cannot run\n"
elif [ -z "$PREFLIGHT_SHA" ]; then
  issues="${issues}- pre-flight check tooling unavailable: neither shasum nor sha1sum on PATH — Check 1 cannot run\n"
else
  preflight_missing_markers=""
  for skill in audit-epic build fix review review-plan review-epic verify-all; do
    block=$(awk '/<!-- pre-flight:start -->/,/<!-- pre-flight:end -->/' "skills/${skill}/SKILL.md" 2>/dev/null)
    [ -z "$block" ] && preflight_missing_markers="${preflight_missing_markers}${skill} "
  done
  if [ -n "$preflight_missing_markers" ]; then
    issues="${issues}- pre-flight markers missing in skills: ${preflight_missing_markers% }\n"
  else
    unique_preflight=$(
      {
        for skill in audit-epic build fix review review-plan review-epic verify-all; do
          awk '/<!-- pre-flight:start -->/,/<!-- pre-flight:end -->/' "skills/${skill}/SKILL.md" | "$PREFLIGHT_SHA" | awk '{print $1}'
        done
        "$PREFLIGHT_SHA" tests/fixtures/canonical-preflight-block.txt | awk '{print $1}'
      } | sort -u | grep -cv '^$'
    )
    if [ "$unique_preflight" -ne 1 ]; then
      issues="${issues}- pre-flight wording drift: ${unique_preflight} unique blocks across 7 hard-abort skills (expected 1)\n"
    fi
  fi
fi

```

**Verify:**
- `bash -n .claude/hooks/verify-all.sh` exits 0 (syntactically valid).
- `bash .claude/hooks/verify-all.sh; echo "exit=$?"` exits 0.
- The hook does NOT emit a `pre-flight wording drift` entry on clean main (current state has all 7 blocks byte-identical to the fixture; `unique_preflight == 1`). Capture output with: `bash .claude/hooks/verify-all.sh 2>&1 | grep -F 'pre-flight wording drift' || echo 'no preflight drift (expected)'` — must print `no preflight drift (expected)`.
- `grep -Fn 'pre-flight wording drift' .claude/hooks/verify-all.sh` returns exactly 1 match (the new drift-emit line).
- `grep -Fn 'audit-epic build fix review review-plan review-epic verify-all' .claude/hooks/verify-all.sh` returns exactly 1 match.

**UI:** no

---

### T2: Add Check 2 — plan-mode-gate hook-pair byte-identity (~3 min)
**Files:** `.claude/hooks/verify-all.sh`
**Depends on:** T1
**Action:** Append a new check block immediately after T1's block (separated by one blank line); preserve one trailing blank line before `emit_drift_json`.
**Details:**
- Block uses `diff -q` quiet mode; only exit-status matters. Both file paths must exist before `diff` runs — guard with `[ -f X ] && [ -f Y ]` so a missing template (in a future install scenario) doesn't produce a misleading drift entry from `diff` errors.
- Drift entry uses AC2.2 verbatim format including the literal backticks around `diff`: `"- plan-mode-gate hook drift: .claude/hooks/plan-mode-gate.sh and skills/setup/templates/plan-mode-gate.sh.template differ (run \`diff\` for details)\n"`. The backticks must not trigger command substitution. **Escape each backtick with a single backslash inside the double-quoted assignment: `\`diff\``.** Bash sees `\`` and emits a literal backtick — no command substitution. Verified empirically: `issues="${issues}- ... (run \`diff\` for details)\n"; printf '%b' "$issues"` produces `- ... (run \`diff\` for details)`.
- Exact block to insert (immediately after T1's block + 1 blank line):

```bash
# plan-mode-gate hook-pair byte-identity
# (verify-all-stop-hook.sh.template ↔ dogfood verify-all.sh divergence is intentional — see CONTRIBUTING.md
# "Stop hook drift checks" section citing E03.S2.)
if [ -f .claude/hooks/plan-mode-gate.sh ] && [ -f skills/setup/templates/plan-mode-gate.sh.template ]; then
  if ! diff -q .claude/hooks/plan-mode-gate.sh skills/setup/templates/plan-mode-gate.sh.template >/dev/null 2>&1; then
    issues="${issues}- plan-mode-gate hook drift: .claude/hooks/plan-mode-gate.sh and skills/setup/templates/plan-mode-gate.sh.template differ (run \`diff\` for details)\n"
  fi
fi

```

**Verify:**
- `bash -n .claude/hooks/verify-all.sh` exits 0.
- `bash .claude/hooks/verify-all.sh; echo "exit=$?"` exits 0.
- `bash .claude/hooks/verify-all.sh 2>&1 | grep -F 'plan-mode-gate hook drift' || echo 'no plan-mode-gate drift (expected)'` prints `no plan-mode-gate drift (expected)` (the two files are currently byte-identical per discovery §3).
- `grep -Fn 'plan-mode-gate hook drift' .claude/hooks/verify-all.sh` returns exactly 1 match.
- `diff .claude/hooks/plan-mode-gate.sh skills/setup/templates/plan-mode-gate.sh.template` exits 0 (byte-identical — sanity check that nothing in T1/T2 altered the pair).

**UI:** no

---

### T3: Add Check 3 + `PITFALLS_ORGANIZE_THRESHOLD` constant + script-side bidirectional sync comment (~4 min)
**Files:** `.claude/hooks/verify-all.sh`
**Depends on:** T2
**Action:** Append a new check block immediately after T2's block (separated by one blank line); preserve one trailing blank line before `emit_drift_json`.
**Details:**
- Includes the named constant `PITFALLS_ORGANIZE_THRESHOLD=80` (first named threshold constant in the script — existing checks use bare integer literals 300/500).
- Leading comment names `agents/doc-writer.md` Process step 5 ("Organize suggestion") as the matching policy parameter site (AC3.4 bidirectional sync).
- File-existence guard `[ -f .roughly/known-pitfalls.md ]` — the file may not exist in a fresh install before any pitfall is recorded.
- Uses `wc -l < <file>` (input redirect) for consistency with existing checks (no leading-space artifact).
- Drift message uses the constant via `${PITFALLS_ORGANIZE_THRESHOLD}` substitution so a future threshold change updates message in lock-step; the current substitution produces `80` exactly per AC3.2.
- Exact block to insert (immediately after T2's block + 1 blank line):

```bash
# .roughly/known-pitfalls.md organize-suggestion threshold (closes E03.S3 manual-edit coverage gap).
# Bidirectional sync: matching policy parameter in agents/doc-writer.md Process step 5
# ("Organize suggestion"). Update both if the threshold changes.
PITFALLS_ORGANIZE_THRESHOLD=80
if [ -f .roughly/known-pitfalls.md ]; then
  n=$(wc -l < .roughly/known-pitfalls.md)
  if [ "$n" -gt "$PITFALLS_ORGANIZE_THRESHOLD" ]; then
    issues="${issues}- .roughly/known-pitfalls.md is $n lines (>${PITFALLS_ORGANIZE_THRESHOLD} threshold) — consider organizing\n"
  fi
fi

```

**Verify:**
- `bash -n .claude/hooks/verify-all.sh` exits 0.
- `bash .claude/hooks/verify-all.sh; echo "exit=$?"` exits 0.
- Check 3 fires (file is at 90 lines per discovery §4): `bash .claude/hooks/verify-all.sh 2>&1 | grep -Fc '.roughly/known-pitfalls.md is 90 lines (>80 threshold) — consider organizing'` returns `1`. (The hook emits structured JSON via `emit_drift_json`; the substring appears inside the JSON `systemMessage` field. `grep -F` matches inside the JSON.)
- `grep -Fn 'PITFALLS_ORGANIZE_THRESHOLD=80' .claude/hooks/verify-all.sh` returns exactly 1 match.
- `grep -Fn 'agents/doc-writer.md Process step 5' .claude/hooks/verify-all.sh` returns exactly 1 match (the bidirectional sync comment).
- File line cap (AC6): `wc -l < .claude/hooks/verify-all.sh` returns ≤ 150 (soft cap). Expected ~85–90 post-T3 (57 + ~10 per block ×3 + comments).

**UI:** no

---

### T4: Doc-writer side of bidirectional sync (~2 min)
**Files:** `agents/doc-writer.md`
**Depends on:** T3
**Action:** Insert an inline HTML comment at the start of the "If line count > 80" conditional on L33 (within the "Organize suggestion" bullet), naming `.claude/hooks/verify-all.sh` and the `PITFALLS_ORGANIZE_THRESHOLD` constant.
**Details:**
- Anchor: locate the exact substring `If line count > 80, append a single one-line note` on L33 of `agents/doc-writer.md`.
- Insert the HTML comment **immediately before** the `If` token, on the same line, so it precedes the conditional without breaking the bullet's flow. HTML comments do not render in markdown but are visible to grep audits.
- Exact edit (replacing the existing text on L33 within the "Organize suggestion" sub-bullet):
  - **Old:** `If Read fails or returns empty, skip this check. If line count > 80, append a single one-line note`
  - **New:** `If Read fails or returns empty, skip this check. <!-- Bidirectional sync: matches PITFALLS_ORGANIZE_THRESHOLD in .claude/hooks/verify-all.sh Check 3. Update both if threshold changes. --> If line count > 80, append a single one-line note`
- Word-cap guard (AC6 hook check enforces ≤ 500 words on `agents/*.md`): the HTML comment adds ~17 words. `agents/doc-writer.md` is currently at 542 words per E04.S8 retro (epic L411 cluster) — **the file is already at +42 over cap (542/500), accepted as Path B**. This task adds words to a file already in violation. The hook's agent word cap check (existing L27–31) will continue to fire. Acceptable per AC8 ("no new invariants enforced beyond the three named") — this story does not promise to fix doc-writer.md's existing cap violation. **Confirm pre-T4 word count and report post-T4 word count in the verify step so any unexpected explosion is visible.**

**Verify:**
- `wc -w < agents/doc-writer.md` before edit and after edit; capture both (post-edit should be pre-edit + ~17).
- `grep -Fn 'Bidirectional sync: matches PITFALLS_ORGANIZE_THRESHOLD in .claude/hooks/verify-all.sh' agents/doc-writer.md` returns exactly 1 match on L33.
- `grep -Fn 'If line count > 80' agents/doc-writer.md` still returns the original conditional (edit did not break the existing prose).
- `bash .claude/hooks/verify-all.sh 2>&1 | grep -Fc 'agents/doc-writer.md:'` — the hook may emit an agent-word-cap drift entry for doc-writer.md (pre-existing violation; not regressed by this task). Capture and note.

**UI:** no

---

### T5: CONTRIBUTING.md — `## Stop hook drift checks` section (~5 min)
**Files:** `CONTRIBUTING.md`
**Depends on:** T4
**Action:** Insert a new `## Stop hook drift checks` section before the `## License` heading at L134. Section enumerates all 7 checks (4 pre-existing + 3 new) with one-line descriptions and cites E03.S2 by section heading + quoted phrase per AC7.
**Details:**
- Anchor: the line `## License` is at L134. Insert the new section + one trailing blank line above it so `## License` shifts down.
- The dogfood ↔ template divergence is documented inside Check 6's bullet via **cite-and-link** (not restate) per the epic's Files Touched note. The quoted phrase appears verbatim twice in `docs/planning/epics/complete/E03-trust-and-ergonomics.md` (L243 and L251 per discovery §5); citation by quoted phrase survives line-number shifts.
- Section structure: introductory paragraph, ordered list of 7 checks, closing line noting which are pre-existing vs new.
- Exact content to insert (the entire block below, including the trailing blank line, replaces the blank line currently at L133 above `## License`):

```markdown
## Stop hook drift checks

`.claude/hooks/verify-all.sh` runs as a non-blocking Stop hook after every Claude turn (always exits 0, informational only — see `skills/setup/templates/verify-all-stop-hook.sh.template` header). It enforces seven structural invariants:

1. **Path drift** — `agents/` files must not reference legacy `.ruckus/known-pitfalls`.
2. **Skill line cap** — every `skills/*/SKILL.md` stays ≤ 300 lines.
3. **Agent word cap** — every `agents/*.md` stays ≤ 500 words.
4. **HTML comment integrity** — `agents/agent-preamble.md` contains exactly one `<!--` opener and one `-->` closer.
5. **Pre-flight wording byte-identity across 7 hard-abort skills** — `audit-epic`, `build`, `fix`, `review`, `review-plan`, `review-epic`, `verify-all` must have byte-identical pre-flight migration check blocks (canonical source: `tests/fixtures/canonical-preflight-block.txt`). `skills/setup/SKILL.md` uses an intentionally-divergent soft-abort form and is excluded.
6. **`plan-mode-gate` hook-pair byte-identity** — `.claude/hooks/plan-mode-gate.sh` and `skills/setup/templates/plan-mode-gate.sh.template` must be byte-identical. The `verify-all-stop-hook.sh.template` ↔ dogfood `verify-all.sh` pair is **explicitly out of scope**: per `docs/planning/epics/complete/E03-trust-and-ergonomics.md` section `#### E03.S2: Stop-hook-v1 maturity check completion` under `### Trust hardening cluster`, the dogfood "stays as-is (project-specific drift checks for the plugin's own development); this story produces a separate, project-agnostic template."
7. **`.roughly/known-pitfalls.md` organize threshold** — fires when `wc -l > PITFALLS_ORGANIZE_THRESHOLD` (currently 80). The matching policy parameter lives in `agents/doc-writer.md` Process step 5 ("Organize suggestion") — bidirectional sync comments name each consumer.

Checks 1–4 are pre-existing (S2-era structural invariants). Checks 5–7 land in E04.S5 as a coverage-completion bundle.

```

**Verify:**
- `grep -Fn '## Stop hook drift checks' CONTRIBUTING.md` returns exactly 1 match.
- `grep -Fn '## License' CONTRIBUTING.md` returns exactly 1 match at a line > the previous L134 (the License section shifted down).
- AC7 quoted-phrase citation: `grep -Fc 'stays as-is (project-specific drift checks for the plugin'"'"'s own development); this story produces a separate, project-agnostic template.' CONTRIBUTING.md` returns `1`.
- Source still has the phrase: `grep -Fc 'stays as-is (project-specific drift checks for the plugin'"'"'s own development); this story produces a separate, project-agnostic template.' docs/planning/epics/complete/E03-trust-and-ergonomics.md` returns `2` (per discovery §5; the phrase appears twice in the source epic).
- Section heading citation: `grep -Fn '#### E03.S2: Stop-hook-v1 maturity check completion' CONTRIBUTING.md` returns exactly 1 match.
- All 3 new check titles present (targeted, not heuristic): `grep -Fc 'Pre-flight wording byte-identity across 7 hard-abort skills' CONTRIBUTING.md` returns `1`; `grep -Fc 'plan-mode-gate` hook-pair byte-identity' CONTRIBUTING.md` returns `1`; `grep -Fc '.roughly/known-pitfalls.md` organize threshold' CONTRIBUTING.md` returns `1`. All 4 pre-existing check titles present: `grep -Fc 'Path drift' CONTRIBUTING.md` returns `1`; `grep -Fc 'Skill line cap' CONTRIBUTING.md` returns `1`; `grep -Fc 'Agent word cap' CONTRIBUTING.md` returns `1`; `grep -Fc 'HTML comment integrity' CONTRIBUTING.md` returns `1`.
- `grep -Fn 'PITFALLS_ORGANIZE_THRESHOLD' CONTRIBUTING.md` returns exactly 1 match (Check 7's description).
- `bash .claude/hooks/verify-all.sh; echo "exit=$?"` still exits 0.

**UI:** no

---

### T6: End-to-end verification against deliberately-broken samples (~5 min)
**Files:** None (no commits). Uses temp edits + immediate revert via `git checkout -- <file>` after each test.
**Depends on:** T5
**Action:** Verify each of the 3 new checks fires correctly against a deliberately-broken sample, then reverts cleanly. Captures output for inclusion in the Stage 8 commit / PR description.

**Plan-write guidance applied:**
- **Diff result against reference (from S4 retrospective):** After T1–T3 land, diff the resulting check-block region of `verify-all.sh` against the 3-check spec from epic §E04.S5 ACs 1–3. Confirm all three blocks present, in spec-AC order (Check 1, Check 2, Check 3), each emitting the AC-specified drift entry format.
- **Grep-verify cited examples (from S6 retrospective):** Confirm each AC drift-entry format string exists verbatim in the script.

**Details (run each test exactly once; revert after each):**

**Test 6.1 — Check 1 deliberately-broken sample (AC1.3):**
0. Pre-test guard: `git diff --quiet skills/build/SKILL.md` exits 0 (no uncommitted changes). If non-zero, abort T6 — Test 6.1's sed+revert would discard those changes.
1. Capture baseline: `bash .claude/hooks/verify-all.sh > /tmp/hook-clean.txt 2>&1; echo "exit=$?"` — should exit 0; output should NOT contain `pre-flight wording drift`.
2. Break: `sed -i.bak 's|<!-- pre-flight:start -->|<!-- pre-flight:start --> |' skills/build/SKILL.md` (inserts a single trailing space inside the block — changes the hash without changing semantics).
3. Re-run hook: `bash .claude/hooks/verify-all.sh > /tmp/hook-broken-1.txt 2>&1; echo "exit=$?"` — must exit 0 AND `grep -Fc 'pre-flight wording drift: 2 unique blocks across 7 hard-abort skills (expected 1)' /tmp/hook-broken-1.txt` must return `1`.
4. Revert: `mv skills/build/SKILL.md.bak skills/build/SKILL.md` then `git diff --stat skills/build/SKILL.md` must show 0 lines changed.
5. Re-run hook: confirm `grep -Fc 'pre-flight wording drift' <(bash .claude/hooks/verify-all.sh 2>&1)` returns `0`.

**Test 6.2 — Check 2 deliberately-broken sample (AC2.3):**
0. Pre-test guard: `git diff --quiet .claude/hooks/plan-mode-gate.sh` exits 0. If non-zero, abort T6 — Test 6.2's append+revert would discard those changes.
1. Break: `printf '\n# drift sentinel\n' >> .claude/hooks/plan-mode-gate.sh` (appends a harmless comment line — changes the file, breaks byte-identity with the template).
2. Re-run hook: `bash .claude/hooks/verify-all.sh > /tmp/hook-broken-2.txt 2>&1; echo "exit=$?"` — must exit 0 AND `grep -Fc 'plan-mode-gate hook drift: .claude/hooks/plan-mode-gate.sh and skills/setup/templates/plan-mode-gate.sh.template differ (run `diff` for details)' /tmp/hook-broken-2.txt` must return `1`.
3. Revert: `git checkout -- .claude/hooks/plan-mode-gate.sh` then `diff .claude/hooks/plan-mode-gate.sh skills/setup/templates/plan-mode-gate.sh.template` must exit 0.
4. Re-run hook: confirm `grep -Fc 'plan-mode-gate hook drift' <(bash .claude/hooks/verify-all.sh 2>&1)` returns `0`.

**Test 6.3 — Check 3 deliberately-broken sample (AC3.5):**
The file is currently at 90 lines (already > 80) per discovery §4. Check 3 is **already** firing post-T3 — Test 6.3 confirms the exact drift-entry format and that count tracks the actual line count.
0. Pre-test guard: `git diff --quiet .roughly/known-pitfalls.md` exits 0. If non-zero, abort T6 — Test 6.3's append+revert would discard those changes.
1. Baseline (post-T3, no break needed): `bash .claude/hooks/verify-all.sh > /tmp/hook-check3-baseline.txt 2>&1` — `grep -Fc '.roughly/known-pitfalls.md is 90 lines (>80 threshold) — consider organizing' /tmp/hook-check3-baseline.txt` must return `1`.
2. Break (test that the count updates): `printf '\nextra line for drift test\n' >> .roughly/known-pitfalls.md` (pushes to 91 lines).
3. Re-run hook: `grep -Fc '.roughly/known-pitfalls.md is 91 lines (>80 threshold) — consider organizing' <(bash .claude/hooks/verify-all.sh 2>&1)` must return `1`.
4. Revert: `git checkout -- .roughly/known-pitfalls.md` then `wc -l < .roughly/known-pitfalls.md` must return 90.
5. Re-run hook: `grep -Fc '.roughly/known-pitfalls.md is 90 lines (>80 threshold) — consider organizing' <(bash .claude/hooks/verify-all.sh 2>&1)` must return `1` (count back to 90).

**Final end-state diff against reference (S4 retrospective):**
- Confirm all 3 new check blocks present in `.claude/hooks/verify-all.sh`:
  - `grep -Fc 'pre-flight wording drift:' .claude/hooks/verify-all.sh` returns `1`
  - `grep -Fc 'plan-mode-gate hook drift:' .claude/hooks/verify-all.sh` returns `1`
  - `grep -Fc '.roughly/known-pitfalls.md is' .claude/hooks/verify-all.sh` returns `1`
- Confirm `PITFALLS_ORGANIZE_THRESHOLD=80` exists exactly once: `grep -Fc 'PITFALLS_ORGANIZE_THRESHOLD=80' .claude/hooks/verify-all.sh` returns `1`.
- Confirm bidirectional sync comments both directions:
  - `grep -Fc 'agents/doc-writer.md Process step 5' .claude/hooks/verify-all.sh` returns `1`
  - `grep -Fc 'PITFALLS_ORGANIZE_THRESHOLD in .claude/hooks/verify-all.sh' agents/doc-writer.md` returns `1`
- Confirm `git status` after all reverts shows only T1-T5 file modifications: `.claude/hooks/verify-all.sh`, `agents/doc-writer.md`, `CONTRIBUTING.md` (and the plan file). No other files modified.
- Confirm hook line cap (AC6): `wc -l < .claude/hooks/verify-all.sh` ≤ 150 (soft cap).
- Confirm `emit_drift_json` function untouched (AC4): the function body L41–51 of the original file should be byte-identical in the new file (line numbers will have shifted forward by ~30, but content unchanged). `git diff .claude/hooks/verify-all.sh -- 2>&1 | grep -Fc 'emit_drift_json'` should match the diff context, NOT show `-` removal lines on the function body itself.
- Confirm hook still exits 0 (AC5): `bash .claude/hooks/verify-all.sh; echo "exit=$?"` returns `exit=0`.

**Verification log content** (capture for Stage 8 PR description):
- Paste the AC1.2 drift entry from Test 6.1 step 3
- Paste the AC2.2 drift entry from Test 6.2 step 2
- Paste the AC3.2 drift entries from Test 6.3 steps 1 and 3 (showing count updates from 90 → 91)
- Note the pre/post-T6 `git status` output to confirm clean tree after reverts

**Verify (task-level):**
- All `must return 1` assertions above pass.
- `git status --porcelain` after T6 completion shows only T1–T5 files (and the plan file) as modified — no leftover `.bak` files, no uncommitted edits to skill bodies or `.claude/hooks/plan-mode-gate.sh` or `.roughly/known-pitfalls.md`.

**UI:** no

---

## Blast Radius

**Files modified:**
- `.claude/hooks/verify-all.sh` (T1, T2, T3 — additions only; existing 4 checks and `emit_drift_json` untouched)
- `agents/doc-writer.md` (T4 — single-line in-place HTML comment insertion at L33)
- `CONTRIBUTING.md` (T5 — new section inserted before `## License` at L134)

**Files temporarily edited then reverted (T6 only):**
- `skills/build/SKILL.md` (Test 6.1 — sed `.bak` round-trip)
- `.claude/hooks/plan-mode-gate.sh` (Test 6.2 — sentinel line append + `git checkout --` revert)
- `.roughly/known-pitfalls.md` (Test 6.3 — one-line append + `git checkout --` revert)

**Files NOT to modify:**
- `tests/fixtures/canonical-preflight-block.txt` (already correct; canonical source)
- Any of the 7 `skills/*/SKILL.md` pre-flight blocks (already byte-identical; no story-driven change)
- `skills/setup/SKILL.md` (out of scope; soft-abort intentional divergence)
- `skills/setup/templates/plan-mode-gate.sh.template` (already byte-identical with dogfood; no change)
- `skills/setup/templates/verify-all-stop-hook.sh.template` (explicit AC2.4 out-of-scope: dogfood divergence is by design per E03.S2)
- `emit_drift_json` function body in `.claude/hooks/verify-all.sh` (AC4 — `emit_drift_json` is unmodified; new checks reuse it unchanged)
- Existing 4 check blocks at L16–39 (no modification — new blocks are append-only)
- Any ADR file (no ADR change required for this story)

**Watch for:**
- Word-cap regression on `agents/doc-writer.md` (already at 542/500 over cap; T4 adds ~17 words). The hook's agent word cap check (L27–31) will continue to emit a drift entry for this file — pre-existing, not regressed by E04.S5. Document in PR description that the doc-writer.md cap violation is inherited from E04.S8 (Path B acceptance).
- Hook line cap (AC6 soft 150): projected ~85–90 post-T3. Stays well under cap.
- `set -e` is deliberately absent from `verify-all.sh` per known-pitfall L26–28. Do NOT add `set -e`, `set -u`, or `set -o pipefail`. New blocks tolerate subcommand failures gracefully (existence guards + `2>/dev/null` on awk; hash command detected dynamically via `command -v`).
- Check 3 fires immediately on the current 90-line `.roughly/known-pitfalls.md`. This is correct behavior (it closes the manual-edit gap by design), but contributors will see drift on every Claude turn until the next organize pass. Document in PR description.
- Bash quoting in T2's drift entry: literal backticks around `diff` must be escaped to avoid command substitution. The plan specifies `\`diff\`` form (single backslash before each backtick) within the double-quoted assignment.

## Conventions

- **Reference style:** new check blocks follow the existing 4 checks' structure (leading `#` comment, body, optional drift-emit `if` block). No new helper functions; no new top-of-script setup.
- **Threshold constant naming:** `PITFALLS_ORGANIZE_THRESHOLD=80` follows the SCREAMING_SNAKE_CASE convention common in bash scripts. It is the first named constant in this script; future thresholds (e.g., for the existing 300/500 caps) are not in scope for this story.
- **Drift entry format (AC4):** every new check appends `"- <description>\n"` to `$issues` using the existing `${issues}- ...\n` concatenation pattern. `emit_drift_json` is unmodified.
- **`wc -l <`/`wc -w <` input redirect:** all `wc` invocations use input redirect (not filename argument) to avoid the leading-space artifact in `wc` output.
- **Bidirectional sync comments:** both consumers name the other. Script side names `agents/doc-writer.md Process step 5 ("Organize suggestion")`; agent side names `.claude/hooks/verify-all.sh Check 3` and `PITFALLS_ORGANIZE_THRESHOLD`.
- **Citation style for E03.S2 in CONTRIBUTING.md:** cite by section heading (`#### E03.S2: Stop-hook-v1 maturity check completion` under `### Trust hardening cluster`) AND quoted phrase (`"stays as-is (project-specific drift checks for the plugin's own development); this story produces a separate, project-agnostic template."`). Both anchors survive reformatting; the phrase appears verbatim at L243 and L251 of the source epic per discovery §5.
- **Setup skill exclusion (Check 1):** the 7-skill enumeration excludes `skills/setup/SKILL.md` by design — the soft-abort form is documented in `.roughly/known-pitfalls.md` Skill & Agent Authoring section. The leading comment on Check 1 names this exclusion.
- **`emit_drift_json` jq/python3/no-emit fallback** (AC4 out-of-scope): the function's output-encoder chain is not modified. New checks append to `$issues` only; the existing emit path consumes `$issues` unchanged.

## ADR References

- **ADR-005** (versioned maturity checks) governs the broader stop-hook framework but does not directly constrain `verify-all.sh` structure.
- **No ADR governs the stop hook's non-blocking / exit-0 contract** — it is stated in the hook template's header comment and in E03.S2 ACs. The new check blocks preserve this contract (all 3 emit to `$issues`; none affect exit code).
- **ADR-011** (skill flags as public API) is unrelated to hook drift checks; no flag is introduced by this story.
