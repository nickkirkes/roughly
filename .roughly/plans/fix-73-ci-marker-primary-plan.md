# Fix Plan: #73 — `--ci` marker-primary reword (drop the unenforceable "exits non-zero" claim)

Plan-format-version: 1

## Root Cause

The `--ci` failure-signalling contract in `skills/build/SKILL.md` and `skills/fix/SKILL.md` was drafted assuming the orchestrator could set the process exit code on a model-level abort. It cannot: `claude -p` returns the CLI's own exit code on normal turn completion, so an aborted/cap-escalated run emits its structured marker and the process still exits **0**. A CI harness keying on exit status therefore reads an aborted pipeline as success. This was already discovered during E06.S3 (2026-06-09) and recorded in `.roughly/known-pitfalls.md` plus flagged as a v0.1.9 candidate, and the CI harness (`scripts/ci-dogfood.sh`) was made marker-primary — but the live skill prose was never corrected. #73 closes that gap by making the prose marker-primary and self-consistent.

## Design decision (applies to T1/T2)

State the full marker-primary contract **once per file**, at the canonical Stage-1 `--ci` definition site (build:31 / fix:40), and at the three downstream sites use a short "halts on the structured marker" phrasing that points back to it. This avoids repeating the explanation four times (line-cap pressure: build 283/300, fix 288/300) while keeping each site accurate.

**Canonical contract sentence** (to appear once in each of build and fix — insert ONLY the sentence text below; it becomes part of the running `--ci` paragraph, NOT a blockquote, so do not carry any leading `>` into the file):

**The marker on stdout is the authoritative CI failure signal — not the process exit code:** `claude -p` may exit 0 even on a model-level abort (the orchestrator cannot set a process exit code), so a CI harness must key on the marker, wrapping it to derive an exit status if it needs one. See `.roughly/known-pitfalls.md` § "CI assertions on Roughly pipeline aborts must be marker-primary, not exit-code-primary".

Cross-references cite the known-pitfalls entry **by heading text, not line number** (per that file's own "line-number citations rot silently" pitfall).

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| skills/build/SKILL.md | Modify | T1 |
| skills/fix/SKILL.md | Modify | T2 |
| .roughly/known-pitfalls.md | Modify | T3 |
| docs/adrs/ADR-013-build-ci-runs-review-plan.md | Modify | T4 |
| docs/planning/differential-gate-allocation-specs.md | Modify | T4 |

## Baseline facts (captured 2026-07-24, branch `fix/73-fix-ci-abort-non-zero-claims`, at parity with `main`)
- Exactly 6 defect sites, verified by exhaustive grep: build 31/106/112, fix 40/121/123. No others in build/fix.
- Line counts: `skills/build/SKILL.md` 283/300 (17 slack); `skills/fix/SKILL.md` 288/300 (12 slack).
- `build:11 ≡ fix:11` CRITICAL byte-identity invariant is **unaffected** — no target site is line 11.
- `.claude/hooks/verify-all.sh` has **no** tripwire grepping this prose (grep for `exit non-zero`/`CI_MODE`/`non-zero`/`--ci` returned zero matches) — rewording trips nothing.
- Build/fix wording need **not** be byte-identical here; their `--ci` NEEDS-REVISION handling is an intentional asymmetry (ADR-013).
- `scripts/ci-dogfood.sh:393-398` is already marker-primary and already documents this exact fact — the harness is correct; only the prose is wrong.
- Session shell note: `grep`/`diff` are shimmed — implementers must use `command grep` / `command diff` and prefer `-F` for literal matches.

## Tasks

### T1: Reword build/SKILL.md `--ci` prose to marker-primary (~5 min)
**Files:** skills/build/SKILL.md
**Action:** Replace the three "exit(s) non-zero" claims with marker-primary wording; add the canonical contract sentence once at line 31.
**Details:**
1. **Line 31** (Stage 1 `--ci` contract — canonical site). Current clause reads "…each abort/cap-escalation condition (e.g. Stage 5c auto-fix cap, Stage 6 review-fix cap) emits its structured log message and **exits non-zero** instead of prompting…". Replace `emits its structured log message and exits non-zero instead of prompting` with `emits its structured failure marker and halts instead of prompting`, then append the **canonical contract sentence** (verbatim from the "Design decision" section above) to that same paragraph.
2. **Line 106.** Current: "…then emit `Stage 4 plan-review cannot proceed: 2 NEEDS REVISION verdicts. Plan at [path] needs human revision.` and **exit non-zero** (do not present to a human)." Replace `and exit non-zero (do not present to a human)` with `and halt — that marker is the CI signal (do not present to a human)`.
3. **Line 112.** Current: "(Under `CI_MODE=true`, the `--ci` rule above governs the cap instead: it **exits non-zero** rather than presenting findings to a human.)" Replace `it exits non-zero rather than` with `it halts on the structured marker rather than`.
Do not alter the surrounding stage logic, the CRITICAL preamble, or any other line.
**Verify:**
```
command grep -nE 'exits? non-zero' skills/build/SKILL.md ; test $(command grep -cE 'exits? non-zero' skills/build/SKILL.md) -eq 0 || { echo FAIL-residual; exit 1; }
command grep -qF 'authoritative CI failure signal' skills/build/SKILL.md || { echo FAIL-no-contract; exit 1; }
command grep -qF 'marker-primary, not exit-code-primary' skills/build/SKILL.md || { echo FAIL-no-xref; exit 1; }
n=$(wc -l < skills/build/SKILL.md); [ "$n" -le 300 ] || { echo "FAIL-cap $n"; exit 1; }; echo "T1 PASS ($n/300)"
```
**UI:** no

### T2: Reword fix/SKILL.md `--ci` prose to marker-primary (~5 min)
**Files:** skills/fix/SKILL.md
**Action:** Same three-site treatment as T1, adapted to fix's wording; canonical contract sentence once at line 40.
**Details:**
1. **Line 40** (Stage 1 `--ci` contract — canonical site). Current clause: "…each abort/cap-escalation condition (e.g. Stage 5c) emits its structured log message and **exits non-zero** instead of prompting…". Replace `emits its structured log message and exits non-zero instead of prompting` with `emits its structured failure marker and halts instead of prompting`, then append the **canonical contract sentence** (verbatim, same text as T1) to that paragraph.
2. **Line 121.** Current: "…on NEEDS REVISION, emit structured `FAIL — plan-review NEEDS REVISION: <verdict block>` and **exit non-zero** (no revision loop, no human gate)." Replace `and exit non-zero (no revision loop, no human gate)` with `and halt — that marker is the CI signal (no revision loop, no human gate)`.
3. **Line 123.** Current: "**If NEEDS REVISION (interactive mode only — the `CI_MODE=true` path **exits non-zero** above without entering this loop):**" Replace `the CI_MODE=true path exits non-zero above` with `the CI_MODE=true path halts on the marker above`.
Preserve the intentional build/fix asymmetry — do NOT add a revision loop to fix. Do not touch the CRITICAL preamble (line 11).
**Verify:**
```
command grep -nE 'exits? non-zero' skills/fix/SKILL.md ; test $(command grep -cE 'exits? non-zero' skills/fix/SKILL.md) -eq 0 || { echo FAIL-residual; exit 1; }
command grep -qF 'authoritative CI failure signal' skills/fix/SKILL.md || { echo FAIL-no-contract; exit 1; }
command grep -qF 'marker-primary, not exit-code-primary' skills/fix/SKILL.md || { echo FAIL-no-xref; exit 1; }
n=$(wc -l < skills/fix/SKILL.md); [ "$n" -le 300 ] || { echo "FAIL-cap $n"; exit 1; }
command diff <(sed -n '11p' skills/build/SKILL.md) <(sed -n '11p' skills/fix/SKILL.md) >/dev/null && echo "T2 PASS ($n/300, build:11==fix:11)" || { echo FAIL-preamble-drift; exit 1; }
```
**UI:** no

### T3: De-stale the known-pitfalls entry (~3 min)
**Files:** .roughly/known-pitfalls.md
**Depends on:** T1, T2
**Action:** Update the trailing Note in the **Cause** line so it no longer describes the skill prose as claiming "exit non-zero".
**Details:** In `.roughly/known-pitfalls.md`, under `### CI assertions on Roughly pipeline aborts must be marker-primary, not exit-code-primary`, the **Cause** paragraph (currently line 63) ends with: `Note: the build/fix `--ci` skill prose says "exit non-zero" — that is aspirational intent, not an enforceable process contract under `claude -p` (tracked as a v0.1.9 spec-revision-candidate in the E06 epic).` Once T1/T2 land, that sentence is factually wrong and self-contradictory. Replace **only that trailing Note sentence** with: `Note: the build/fix `--ci` prose was made marker-primary in #73 — it no longer claims "exit non-zero"; the structured marker is the documented CI signal.` Leave Symptom and Fix untouched; do not renumber or reflow other entries.
**Verify:**
```
command grep -qF 'was made marker-primary in #73' .roughly/known-pitfalls.md || { echo FAIL-not-updated; exit 1; }
command grep -qF 'aspirational intent' .roughly/known-pitfalls.md && { echo FAIL-stale-note-remains; exit 1; }
command grep -qF 'CI assertions on Roughly pipeline aborts must be marker-primary' .roughly/known-pitfalls.md || { echo FAIL-heading-lost; exit 1; }
echo "T3 PASS"
```
**UI:** no

### T4: Consistency sweep — ADR-013 + differential-gate spec (~3 min)
**Files:** docs/adrs/ADR-013-build-ci-runs-review-plan.md, docs/planning/differential-gate-allocation-specs.md
**Depends on:** T1, T2
**Action:** Reconcile the two remaining descriptive "exit non-zero" mentions with the new contract — ADR-013 via an **append-only correction footnote** (ADRs are immutable), the speculative planning doc via an in-place accuracy edit.
**Details:**
1. `docs/adrs/ADR-013-build-ci-runs-review-plan.md` — **append-only; do NOT edit line 19's Decision text.** ADRs are immutable per `.roughly/known-pitfalls.md` § "Append-only edits to immutable documents" (git history preserves the original wording, and leaving it is fine — an ADR is not build/fix `--ci` prose, so AC1 is not implicated). Instead, `Edit`-append a correction footnote as a new paragraph at the **end of the file** (match the file's current last line and place the footnote beneath it, blank line between): `**Correction (#73, 2026-07-24):** the "exit non-zero" phrasing in the Decision above is inaccurate — \`claude -p\` cannot set a process exit code, so the process exits 0 on a model-level abort; the structured marker described in the same paragraph is the actual CI signal. See \`skills/build/SKILL.md\`'s marker-primary \`--ci\` contract and \`.roughly/known-pitfalls.md\` § "CI assertions on Roughly pipeline aborts must be marker-primary, not exit-code-primary".`
2. `docs/planning/differential-gate-allocation-specs.md` line 197 currently reads "…The subagent's `ESCALATE` under `--ci` must exit non-zero like other `--ci` cap conditions — confirm against the ADR-011/ADR-013 `--ci` contract." This is a speculative future-work VERIFY note in a planning doc (not an ADR), so an in-place accuracy edit is appropriate: replace `must exit non-zero like other --ci cap conditions` with `must halt on a structured failure marker like other --ci cap conditions` so the misconception does not re-propagate.
Do not otherwise edit these files.
**Verify:**
```
command grep -qF 'Correction (#73' docs/adrs/ADR-013-build-ci-runs-review-plan.md || { echo FAIL-adr013-footnote; exit 1; }
command grep -qF 'must exit non-zero' docs/planning/differential-gate-allocation-specs.md && { echo FAIL-diffgate; exit 1; }
echo "T4 PASS"
```
**UI:** no

## Blast Radius
- **Do NOT modify:** `scripts/ci-dogfood.sh` (already correct and marker-primary — it is the reference behavior, not a defect); `.claude/hooks/verify-all.sh`; line 11 of either SKILL.md (CRITICAL preamble byte-identity); any stage logic, gate text, or abort-marker string (the marker literals must stay byte-stable — `scripts/ci-dogfood.sh` greps `cannot proceed: auto-fix cap reached on`); `CHANGELOG.md` and `docs/ROADMAP.md` / `docs/planning/epics/complete/E06-*.md` historical records; `skills/upgrade/SKILL.md` and `skills/help/SKILL.md` (their non-zero mentions are legitimate real shell exit codes, not this contract).
- **Watch for:** (a) accidentally changing a marker literal while rewording the sentence around it — the marker strings are a CI contract; (b) line-cap overflow, fix has only 12 lines of slack; (c) the shimmed `grep`/`diff` in this session — use `command grep` / `command diff`; (d) do not "fix" the build/fix asymmetry (build has a 2-verdict recovery loop, fix exits on first NEEDS REVISION) — that is intentional per ADR-013.

## Conventions
- No build step or test harness — this is pure markdown; the inline grep-based Verify blocks are the validation, consistent with how prose changes are checked in this repo.
- Cross-references to `.roughly/known-pitfalls.md` cite the section **heading**, not a line number (that file documents its own line-citation-rot pitfall).
- Out of scope (noted, not done): checking off the corresponding v0.1.9 candidate line in `docs/ROADMAP.md:131` / the E06 epic candidates section — those are historical planning records; the ACs do not require it.
