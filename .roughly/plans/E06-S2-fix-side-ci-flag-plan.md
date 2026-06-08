> **Status:** Historical — implemented and merged in commit cef56b5008e4a76c85a8b2d1a1578af62d3fc3d2 on 2026-06-08. This plan was an active build/fix artifact; treat as historical reference only.

# Implementation Plan: E06.S2 — fix-side `--ci` flag (structural mirror of E03.S11b-2 build-side)

Plan-format-version: 1

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| skills/fix/SKILL.md | Modify | T1 |
| tests/fixtures/hello-roughly-bug/CLAUDE.md | Create | T2 |
| tests/fixtures/hello-roughly-bug/src/greeter.sh | Create | T2 |
| tests/fixtures/hello-roughly-bug/tests/greeter.test.sh | Create | T2 |
| tests/fixtures/hello-roughly-bug/README.md | Create | T2 |
| scripts/ci-dogfood.sh | Modify | T3 |
| .github/workflows/dogfood.yml | Modify | T4 |
| CHANGELOG.md | Modify | T5 |

## Design notes (read before implementing)

**Intentional divergence from build at Stage 4.** Build's `--ci` (skills/build/SKILL.md L100) *skips* the review-plan dispatch and emits the synthetic-PASS marker `[--ci] plan review skipped — synthetic PASS` (an explicit ADR-001 puncture). E06.S2 AC1 specifies a *different, richer* fix-side behavior: **run** review-plan and branch on the verdict — PASS → auto-progress; NEEDS REVISION → emit structured FAIL + non-zero exit (no ADR-001 puncture). This is per AC1's literal Stage-4 bullet. Consequence: the fix CI test (T3) does **NOT** assert the synthetic-PASS marker (fix never emits it); it asserts on completion artifacts (plan file + Status block + applied fix), mirroring build assertions 2–5c rather than build assertion 1.

**AC1 verify tension — reword the lead-in verb.** AC1 has a positive check (standalone-token language present) AND a negative check (`grep -Fn "contains \`--ci\`" skills/fix/SKILL.md` returns 0). Build's verbatim sentence "If it contains `--ci` as a standalone token…" literally contains the bytes `contains \`--ci\`` (confirmed: `grep -c "contains \`--ci\`" skills/build/SKILL.md` = 1), so a verbatim copy would FAIL the negative check. Resolution: keep the standalone-token **parenthetical verbatim** but reword the lead-in from "contains `--ci`" to "`--ci` appears … as a standalone token". Satisfies both checks.

**Backport-completeness pitfall (known-pitfalls L130).** This is a mirror-from-reference story, so per the pitfall the verification operates at "does the result cover every CI behavior" level — but because Stage 4 intentionally diverges from build, the check is behavior-enumerated (gates auto-proceed; Stage 4 run-and-branch; Stage 5 structured escalation; Stage 8 auto-commit), NOT a byte-identical diff against build.

## Tasks

### T1: Add `--ci` flag handling to skills/fix/SKILL.md (~5 min)
**Files:** skills/fix/SKILL.md
**Action:** Add `--ci` / `CI_MODE` non-interactive handling: description note, a Stage-1 flag-detection + global CI-mode rule, and a Stage-4 run-and-branch rule. Net additions must keep `wc -l skills/fix/SKILL.md` ≤277 (currently 271; cap allows +6, this plan adds +4 → 275).
**Details:**
1. **Description (L3).** Append to the description string, mirroring build's L3 CI clause:
   ` CI: pass \`--ci\` for non-interactive runs (runs review-plan and auto-acts on the verdict; CI-only).`
   (Same-line edit; +0 physical lines.)
2. **Stage 1 (insert a new paragraph immediately after L32 "Display: issue summary, reproduction steps (if available), affected area.", before the L34 gate).** Add this paragraph (one physical line + one blank line = +2 lines):
   `If \`$ARGUMENTS\` has \`--ci\` appearing as a standalone token (preceded by whitespace or string start, followed by whitespace or string end — not as a substring of \`--ci-cd\` or similar), set \`CI_MODE=true\`. When \`CI_MODE=true\`: every human gate in this pipeline auto-proceeds with its default (yes); each abort/cap-escalation condition (e.g. Stage 5c) emits its structured log message and exits non-zero instead of prompting; Stage 8 auto-progresses both commits with no approval gate; Stage 4 follows its \`--ci\` rule below. Never invoke \`--ci\` interactively. See ADR-011 (flags-not-env-vars) and known-pitfalls "standalone-token" detection.`
3. **Stage 4 (insert immediately after L111 "Dispatch `/roughly:review-plan` … Pass the plan file path from Stage 3 as the input.", before the L113 NEEDS REVISION block).** Add this paragraph (+2 lines):
   `**\`--ci\` non-interactive Stage 4:** If \`CI_MODE=true\`: dispatch review-plan as above (do NOT skip it), then act on the verdict without a human gate — on PASS, auto-progress to Stage 5; on NEEDS REVISION, emit structured \`FAIL — plan-review NEEDS REVISION: <verdict block>\` and exit non-zero (no revision loop, no human gate). This intentionally differs from build's \`--ci\` skip-and-synthesize (build/SKILL.md Stage 4) — fix keeps the review running, so it does not puncture ADR-001's blocking-subagent enforcement.`

   Total physical-line delta: +4 → 275 lines (≤277 ✓). Do NOT add separate Stage 5 / Stage 8 CI paragraphs — they are covered by the Stage-1 global rule (keeps CI behavior single-sourced and within cap).

   **Standalone-token wording is load-bearing:** the parenthetical "(preceded by whitespace or string start, followed by whitespace or string end — not as a substring of `--ci-cd` or similar)" must be byte-identical to build/SKILL.md L25's parenthetical. The lead-in must read "`--ci` appears … as a standalone token" — it MUST NOT contain the literal phrase `contains \`--ci\`` (AC1 negative grep).
**Verify:** `grep -Fc "CI_MODE" skills/fix/SKILL.md` ≥1; `grep -F "followed by whitespace or string end — not as a substring of \`--ci-cd\`" skills/fix/SKILL.md` returns 1 (standalone-token parenthetical present); `grep -Fc "contains \`--ci\`" skills/fix/SKILL.md` = 0 (substring trap precluded); `grep -Fc "FAIL — plan-review NEEDS REVISION" skills/fix/SKILL.md` ≥1; `wc -l skills/fix/SKILL.md` ≤277.
**UI:** no

### T2: Create fix happy-path fixture tests/fixtures/hello-roughly-bug/ (~5 min)
**Files:** tests/fixtures/hello-roughly-bug/CLAUDE.md, tests/fixtures/hello-roughly-bug/src/greeter.sh, tests/fixtures/hello-roughly-bug/tests/greeter.test.sh, tests/fixtures/hello-roughly-bug/README.md
**Action:** Create a minimal bash fixture mirroring `tests/fixtures/hello-roughly/` but containing ONE reproducible, single-Task-fixable bug. **This fixture intentionally ships broken — do NOT fix the bug; the bug is the test subject for `/roughly:fix`.**
**Details:**
- `CLAUDE.md` — mirror hello-roughly's CLAUDE.md, retitled `# hello-roughly-bug`, intro: "Minimal fixture project for Roughly's CI dogfood fix scenario (E06.S2). Not a Roughly install — this is the *target* that `/roughly:fix --ci` operates on. Ships with one intentional bug." Keep the same `## Stack`, `## Build / Test` (Type check: `bash -n src/greeter.sh`; Test: `bash tests/greeter.test.sh`), and `## Conventions` sections.
- `src/greeter.sh` — the buggy source (variable-name typo so the greeting drops the name):
  ```bash
  #!/usr/bin/env bash
  NAME="world"
  echo "hello $NMAE"
  ```
- `tests/greeter.test.sh` — a test that asserts the CORRECT behavior and therefore FAILS against the buggy source:
  ```bash
  #!/usr/bin/env bash
  set -euo pipefail
  OUT="$(bash "$(dirname "$0")/../src/greeter.sh")"
  EXPECTED="hello world"
  if [ "$OUT" != "$EXPECTED" ]; then
    echo "FAIL: expected '$EXPECTED', got '$OUT'" >&2
    exit 1
  fi
  echo "PASS: greeter output matches expected"
  ```
- `README.md` — enumerate: (1) the bug (typo `$NMAE` should be `$NAME`, so output is `hello ` not `hello world`); (2) the expected `/roughly:fix --ci` input (direct description, e.g. `"src/greeter.sh prints 'hello ' instead of 'hello world' — variable reference typo"`); (3) expected stage transitions (Stages 1–8, single Task, review-plan PASS on first pass, no Stage 6 cubic cycles, no NEEDS REVISION); (4) expected exit signature (exit 0; plan file `.roughly/plans/fix-*-plan.md` written with Status block after Stage 8; `tests/greeter.test.sh` passes post-fix).
- `chmod +x` is NOT required (build's fixture scripts are invoked via `bash <file>`, not executed directly).
**Verify:** `ls tests/fixtures/hello-roughly-bug/{CLAUDE.md,src/greeter.sh,tests/greeter.test.sh,README.md}` lists all four; `bash -n tests/fixtures/hello-roughly-bug/src/greeter.sh && bash -n tests/fixtures/hello-roughly-bug/tests/greeter.test.sh` (syntax OK); `bash tests/fixtures/hello-roughly-bug/tests/greeter.test.sh; [ $? -ne 0 ]` (the bug reproduces — test FAILS pre-fix, exit non-zero, confirming the fixture is correctly broken).
**UI:** no

### T3: Extend scripts/ci-dogfood.sh with fix happy-path test function (~5 min)
**Files:** scripts/ci-dogfood.sh
**Action:** After the existing build full-scenario block (ends at L258 `echo "ci-dogfood: full-scenario — all 7 structural assertions passed"`) and BEFORE the post-state pollution check (L260), add a new fix happy-path scenario block that mirrors the build block's structure.
**Details:** Insert a clearly-commented `# Fix scenario: /roughly:fix --ci against fixture` block:
- `cd "$WORKTREE/tests/fixtures/hello-roughly-bug"`.
- Dispatch with the exact exit-capture idiom (per known-pitfalls L28 — NOT `OUT="$(...)"` direct assignment under `set -e`):
  ```bash
  FIX_OUT="$($TIMEOUT 270 claude --bare --plugin-dir "$WORKTREE" \
    --no-session-persistence --max-budget-usd 1.50 \
    -p "/roughly:fix --ci src/greeter.sh prints 'hello ' instead of 'hello world' — variable reference typo in the echo" 2>&1)" \
    && FIX_EXIT=0 || FIX_EXIT=$?
  ```
- `case`/`if` exit ladder mirroring build: `124` → FAIL "fix-scenario step timed out"; non-zero (non-124) → FAIL "fix-scenario step claude exited $FIX_EXIT" with output dump; `0` → run assertions.
- Assertions (mirror build assertions 2–5c; do NOT assert a synthetic-PASS marker — fix runs review-plan, see Design notes):
  1. Plan file exists: `FIX_PLAN="$(ls "$WORKTREE/tests/fixtures/hello-roughly-bug/.roughly/plans/"*-plan.md 2>/dev/null | head -1)" && FIX_PLAN_EXIT=0 || FIX_PLAN_EXIT=$?` then guard `[ "$FIX_PLAN_EXIT" != 0 ] || [ -z "$FIX_PLAN" ] || [ ! -f "$FIX_PLAN" ]` → FAIL. (Same exit-capture idiom as build assertion 2.)
  2. `grep -q '^## Tasks' "$FIX_PLAN"` → FAIL if absent.
  3. `grep -qE '^### T1' "$FIX_PLAN"` → FAIL if absent.
  4. Status block (proves Stage 8 plan-historical marking ran — the fix-completion proof): `head -1 "$FIX_PLAN" | grep -qE '^> \*\*Status:\*\* Historical'` → FAIL if absent.
  5. Fix applied (behavioral proof): `grep -qE '^[[:space:]]*echo[[:space:]].*(\$\{NAME\}|\$NAME([^A-Za-z0-9_]|$))' "$WORKTREE/tests/fixtures/hello-roughly-bug/src/greeter.sh"` (echo now references `$NAME`/`${NAME}`) → FAIL if absent; AND `! grep -q 'NMAE' "$WORKTREE/tests/fixtures/hello-roughly-bug/src/greeter.sh"` (the typo is gone) → FAIL if `NMAE` still present.
- On all-pass: `echo "ci-dogfood: fix-scenario — all structural assertions passed"`.
- Each FAIL branch: `echo "ci-dogfood: FAIL — …" >&2`, `printf '%s\n' "$FIX_OUT" | sed 's/^/    /' >&2` (or the plan/source file for artifact assertions), `exit 1` — matching the build block's diagnostic style exactly.
- Use distinct variable names (`FIX_OUT`, `FIX_EXIT`, `FIX_PLAN`, `FIX_PLAN_EXIT`) so no collision with build's `SCENARIO_*`/`PLAN_*`.
**Verify:** `bash -n scripts/ci-dogfood.sh` (syntax OK); `grep -Fc "hello-roughly-bug" scripts/ci-dogfood.sh` ≥1; `grep -Fc "FIX_OUT" scripts/ci-dogfood.sh` ≥1; `grep -Fc 'OUT="$(' scripts/ci-dogfood.sh` = 0 (no naive direct-assignment introduced — known-pitfalls L28); if `shellcheck` is available, `shellcheck scripts/ci-dogfood.sh` clean (else note unavailable).
**UI:** no

### T4: Wire the fix happy-path into .github/workflows/dogfood.yml (~2 min)
**Files:** .github/workflows/dogfood.yml
**Action:** The fix scenario runs inside `scripts/ci-dogfood.sh`, which is already invoked by the existing "Run dogfood scaffolding" step (L23-26) — so the workflow already executes it. Make the workflow *visibly* invoke both build and fix by updating naming/comments only (no new step needed — AC4 "implementer chooses"; extending the existing entry point is the chosen form).
**Details:** Rename the job `dogfood-build-cycle` → `dogfood-build-fix-cycle` (L10) and the step name `Run dogfood scaffolding` → `Run dogfood scaffolding (smoke + build + fix happy-path)` (L23). Do NOT alter the auth-failure step or any `env`/secret wiring. Keep `bash scripts/ci-dogfood.sh` as the single command (the fix block added in T3 runs within it).
**Verify:** `grep -Fc "build + fix" .github/workflows/dogfood.yml` ≥1; `grep -Fc "dogfood-build-fix-cycle" .github/workflows/dogfood.yml` = 1; if `python3` available, `python3 -c "import yaml,sys; yaml.safe_load(open('.github/workflows/dogfood.yml'))"` parses clean (else `grep -c "bash scripts/ci-dogfood.sh" .github/workflows/dogfood.yml` = 1 confirms the invocation intact).
**UI:** no

### T5: CHANGELOG.md `### Added` entry (~3 min)
**Files:** CHANGELOG.md
**Action:** Add a bullet to the EXISTING `### Added` section under `## [0.1.8] — 2026-06-03` (the `### Added` at L7).
**Details:** Append a bullet documenting the fix-side `--ci` flag. Must enumerate: (1) flag-handling form (standalone-token detection, `CI_MODE` propagation); (2) non-interactive default behavior at each gate — Stage 4 (run review-plan; PASS→auto-progress, NEEDS REVISION→structured FAIL + non-zero exit), Stage 5 (structured-log escalation), Stage 8 (auto-progress both commits); (3) the intentional divergence from build's skip-and-synthesize (fix keeps review-plan running, no ADR-001 puncture); (4) new fixture name `tests/fixtures/hello-roughly-bug/`; (5) new CI test (fix happy-path scenario in `scripts/ci-dogfood.sh`, wired via `dogfood.yml`). Cross-reference: E03.S11b-2 (build-side precedent, commit `2e6548d`), known-pitfalls standalone-token detection convention, and the v0.1.6 CI-coverage cluster carry-forward (E04 v0.1.7 candidates "Negative-path CI scenarios + fix-side `--ci` flag").
**Verify:** `grep -Fc "fix-side" CHANGELOG.md` ≥1 within the `## [0.1.8]` `### Added` block; entry references `hello-roughly-bug`, `E03.S11b-2`, and standalone-token detection per inspection.
**UI:** no

## Blast Radius
- **Do NOT modify:** skills/build/SKILL.md (reference only — build's `--ci` is unchanged); `tests/fixtures/hello-roughly/` (the build fixture is untouched — additive new fixture only); `.claude/hooks/verify-all.sh` (stays 148/150); the auth-failure step or any secret/env wiring in dogfood.yml; the build full-scenario block and post-state pollution check in ci-dogfood.sh (insert fix block strictly between them).
- **Watch for:**
  - **Line cap:** fix/SKILL.md must land ≤277 (T1 budget +4 → 275). Do not add per-stage CI paragraphs beyond the two specified.
  - **Negative grep:** the lead-in must NOT contain the literal `contains \`--ci\`` (T1 verify).
  - **No naive `OUT="$(...)"`** under `set -e` in ci-dogfood.sh (known-pitfalls L28) — use the `&& EXIT=0 || EXIT=$?` idiom.
  - **`grep -Fc` counts lines not occurrences** (known-pitfalls L124) — the T1/T3/T4/T5 verifies use single-site or `≥1`/`=0` semantics, safe here.
  - **Fixture must stay broken** (T2) — do not let the implementer "fix" the seeded bug.
  - **Budget:** fix scenario shares the `--max-budget-usd 1.50` envelope; running review-plan (not skipping) adds one subagent dispatch vs build — acceptable per AC5/epic, but if the Stage 6/7 synthetic exercise overruns, note it in CHANGELOG per AC4.

## Conventions
- ADR-011: user-facing skill behavior modifiers are `$ARGUMENTS` flags, not env vars — `--ci` is the flag surface.
- ADR-001: blocking-subagent enforcement — fix's `--ci` deliberately does NOT puncture it (unlike build); review-plan still runs.
- ADR-012: stage-8-wrap-up.md is the shared Stage 8 procedure; CI auto-commit behavior is signaled from fix/SKILL.md's Stage-1 global rule, not duplicated into the shared file.
- known-pitfalls: standalone-token flag detection (parenthetical verbatim from build L25); `OUT_EXIT=$?` ladder (ci-dogfood.sh idiom); `grep -Fc`/`grep -Fn` line-vs-occurrence counting.
- Mirror existing diagnostic/comment style in ci-dogfood.sh (FAIL message prefix `ci-dogfood: FAIL — `, `sed 's/^/    /'` output indenting).
