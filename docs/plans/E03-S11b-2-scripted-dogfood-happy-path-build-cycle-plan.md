# Implementation Plan: E03.S11b-2 Scripted dogfood happy-path build cycle

Plan-format-version: 1

## Summary

Drive a full `/roughly:build` cycle end-to-end in GitHub Actions CI against a minimal fixture repo, without a human at Stage 4's plan-review gate. Mechanism (decided as OQ1 option (c) per epic): `--ci` flag in the build skill — Stage 1 detects it, Stage 4 skips the blocking `/roughly:review-plan` dispatch and emits a synthetic PASS marker. Existing CI scaffolding (S11a worktree isolation, S11b-1 plumbing) is reused; this story adds the build-cycle scenario block and the fixture it runs against.

## File Table

| File | Action | Task(s) |
|------|--------|---------|
| [skills/build/SKILL.md](../../skills/build/SKILL.md) | Modify (≤4 net additive lines) | T1 |
| [tests/fixtures/hello-roughly/CLAUDE.md](../../tests/fixtures/hello-roughly/CLAUDE.md) | Create | T2 |
| [tests/fixtures/hello-roughly/src/greeter.sh](../../tests/fixtures/hello-roughly/src/greeter.sh) | Create | T2 |
| [tests/fixtures/hello-roughly/tests/greeter.test.sh](../../tests/fixtures/hello-roughly/tests/greeter.test.sh) | Create | T2 |
| [scripts/ci-dogfood.sh](../../scripts/ci-dogfood.sh) | Modify (extend with full-scenario block) | T3 |
| [CONTRIBUTING.md](../../CONTRIBUTING.md) | Modify (`## CI` section update) | T4 |
| [CHANGELOG.md](../../CHANGELOG.md) | Modify (Unreleased entry) | T5 |

## Tasks

### T1: Add `--ci` flag handling to build skill (~5 min)
**Files:** [skills/build/SKILL.md](../../skills/build/SKILL.md)
**Action:** Add `--ci` flag handling: frontmatter description mention, Stage 1 detection setting `CI_MODE=true`, Stage 4 short-circuit emitting a synthetic-PASS marker.
**Details:**
- Skill is currently 296 lines. **Net additive ≤4 lines** (AC1; epic line-cap budget). Total target ≤300 lines.
- **Frontmatter description (line 3, modify in place — 0 net lines):** Append `CI: pass \`--ci\` for non-interactive runs (synthesizes Stage 4 PASS; CI-only).` to the existing description string. This stays on the same line.
- **Stage 1 detection (after line 25, before line 27 — +2 net lines):** Insert a new paragraph between the `Parse $ARGUMENTS` line and the `Ask:` line:
  ```
  If `$ARGUMENTS` contains `--ci`, set `CI_MODE=true` (CI-only; skips Stage 4's blocking review-plan dispatch).
  ```
  Plus one blank line above for readability.
- **Stage 4 short-circuit (after line 98, before line 100 — +2 net lines):** Insert a new paragraph between the pre-check block (ends line 98) and the dispatch line (line 100):
  ```
  **`--ci` short-circuit:** If `CI_MODE=true`, skip the dispatch below, emit `[--ci] plan review skipped — synthetic PASS`, and proceed to Stage 5. CI-only puncture of ADR-001's blocking-subagent enforcement; never invoke `--ci` interactively.
  ```
  Plus one blank line above for readability.
- **Marker string is the contract:** `[--ci] plan review skipped — synthetic PASS` is the literal string CI greps for in T3. Do not paraphrase or move emojis/dashes around.
- ADR-001 caveat language is mandatory in the Stage 4 short-circuit per Discovery section 8 — the prose must call out that the puncture is intentional and CI-only so future contributors don't treat it as precedent.
**Verify:** `wc -l skills/build/SKILL.md` returns ≤ 300; `grep -c '\-\-ci' skills/build/SKILL.md` returns ≥ 3 (description + Stage 1 + Stage 4); `grep -c '\[--ci\] plan review skipped' skills/build/SKILL.md` returns 1.
**UI:** no

### T2: Create minimal fixture repo (~6 min)
**Files:** `tests/fixtures/hello-roughly/CLAUDE.md`, `tests/fixtures/hello-roughly/src/greeter.sh`, `tests/fixtures/hello-roughly/tests/greeter.test.sh`
**Depends on:** none
**Action:** Create the minimum-viable target project that the build cycle will operate on. Bash-based to avoid toolchain install cost in CI; single-task buildable feature ("add a NAME constant").
**Details:**
- **`tests/fixtures/hello-roughly/CLAUDE.md`** — covers the three fields the build skill's Stage 8 CLAUDE.md quality check looks for (build command, type-check command, stack summary; see [skills/build/SKILL.md:252–255](../../skills/build/SKILL.md#L252-L255)). The check is **informational only** ("not a hard block, but a visible gap" — line 255), so missing fields would emit a warning, not abort the run. Including the fields anyway minimizes warning noise in CI logs and reduces the chance of surprising stdout that interferes with structural assertions in T3. Content:
  ```markdown
  # hello-roughly

  Minimal fixture project for Roughly's CI dogfood scenario (E03.S11b-2). Not a Roughly install — this is the *target* that `/roughly:build --ci` operates on.

  ## Stack
  Bash. No package manager, no compile step.

  ## Build / Test
  - Build: none (shell scripts run directly)
  - Type check: `bash -n src/greeter.sh` (syntax check)
  - Test: `bash tests/greeter.test.sh`

  ## Conventions
  - Source files in `src/`
  - Tests in `tests/`, named `*.test.sh`
  ```
- **`tests/fixtures/hello-roughly/src/greeter.sh`** — initial content:
  ```bash
  #!/usr/bin/env bash
  echo "hello"
  ```
  Make executable: `chmod +x`. The build feature will modify this file to add a `NAME` constant and have the echo use it.
- **`tests/fixtures/hello-roughly/tests/greeter.test.sh`** — initial content:
  ```bash
  #!/usr/bin/env bash
  set -euo pipefail
  OUT="$(bash "$(dirname "$0")/../src/greeter.sh")"
  if [ -z "$OUT" ]; then
    echo "FAIL: greeter produced empty output" >&2
    exit 1
  fi
  echo "PASS: greeter produced non-empty output"
  ```
  Make executable. Loose assertion (non-empty) survives the build cycle's modification (NAME constant + updated echo) without needing test changes.
- **Do NOT create:** `.roughly/`, `skills/`, `agents/`, `.claude-plugin/plugin.json`. The fixture is a target project, not a Roughly install. (Discovery §4.)
- **Do NOT commit `docs/plans/` or `.roughly/known-pitfalls.md` in the fixture** — these are generated by the build cycle inside the worktree at run time and live only in `/tmp`. Per AC9, fixture state reset is satisfied by the ephemeral-worktree boundary (S11a contract).
**Verify:** `bash tests/fixtures/hello-roughly/tests/greeter.test.sh` exits 0 from the repo root; `bash -n tests/fixtures/hello-roughly/src/greeter.sh` exits 0; `ls tests/fixtures/hello-roughly/` shows exactly `CLAUDE.md src/ tests/`.
**UI:** no

### T3: Extend ci-dogfood.sh with full-scenario invocation (~10 min)
**Files:** [scripts/ci-dogfood.sh](../../scripts/ci-dogfood.sh)
**Depends on:** T1, T2
**Action:** Add a new full-scenario block that invokes `/roughly:build --ci` against the fixture inside the worktree, asserts structural properties of the output, and runs before the existing post-state pollution check.
**Details:**
- **Insertion point:** after line 114 (`echo "ci-dogfood: smoke + plugin-load — both assertions passed"`), before line 116 (start of post-state check). The post-state check at the end of the script must still be the final guard so it catches any source-tree pollution from this new block too.
- **Block structure — mirror the smoke + plugin-load patterns at lines 46–112:**
  1. `cd "$WORKTREE/tests/fixtures/hello-roughly"` to operate inside the fixture (worktree boundary keeps mutations out of source tree).
  2. Capture invocation:
     ```bash
     SCENARIO_OUT="$(timeout 270 claude --bare --plugin-dir "$WORKTREE" \
       --no-session-persistence --max-budget-usd 1.50 \
       -p "/roughly:build --ci add a NAME constant to src/greeter.sh and update the echo to use it" 2>&1)" \
       && SCENARIO_EXIT=0 || SCENARIO_EXIT=$?
     ```
     - `timeout 270` = 4.5 min (under AC7's 5-min ceiling, leaves ~30s headroom for assertion overhead).
     - `--max-budget-usd 1.50` ≈ 150K Sonnet tokens at the current blended rate (Discovery §7); enforces AC8 mechanically. **Pricing-sensitive:** at $3/M input + $15/M output with an 80/20 mix, $1.50 buys ~278K mixed tokens — comfortable for a 150K target. If pricing skews more output-heavy, the budget could clip below 150K. Add an inline comment on the `--max-budget-usd 1.50` line in the script: `# 1.50 USD ≈ ~150K mixed Sonnet tokens at current pricing (3/M in + 15/M out, ~80/20 mix). Recompute if pricing changes.`
     - `--ci` is in `$ARGUMENTS`, not a top-level claude flag (the build skill detects it at Stage 1 per T1).
     - `&& EXIT=0 || EXIT=$?` idiom is **mandatory** per known-pitfalls.md (set -e + command-substitution).
  3. **Three-branch error handler** — copy the pattern from lines 61–77 / 87–96 verbatim:
     - `SCENARIO_EXIT == 124` → FAIL with timeout diagnostic.
     - `SCENARIO_EXIT != 0` → FAIL with exit-code diagnostic (covers budget breach, auth failure, claude crash).
     - Each branch dumps `$SCENARIO_OUT` indented via `printf '%s\n' "$OUT" | sed 's/^/    /' >&2` for diagnosability (AC9: failure logs include context).
  4. **Structural assertions** (each must FAIL the script with a clear diagnostic if it doesn't hold):
     - **Synthetic-PASS marker:** `printf '%s\n' "$SCENARIO_OUT" | grep -qE "\[--ci\] plan review skipped"` — proves Stage 4 took the `--ci` branch (AC5: regression protection that `--ci` doesn't drift back to invoking the gate).
     - **Plan file exists:** `ls "$WORKTREE/tests/fixtures/hello-roughly/docs/plans/"*-plan.md` returns at least one match. Capture the path: `PLAN_FILE="$(ls "$WORKTREE/tests/fixtures/hello-roughly/docs/plans/"*-plan.md 2>/dev/null | head -1)"`.
     - **Plan has `## Tasks` section:** `grep -q '^## Tasks' "$PLAN_FILE"`.
     - **Plan has at least T1:** `grep -qE '^### T1[: ]' "$PLAN_FILE"`. (S6 added a `Plan-format-version` line; the `### T1` anchor is stable across that change per epic note "S6 should not break the scenario.")
     - **Implementation ran:** `grep -q 'NAME' "$WORKTREE/tests/fixtures/hello-roughly/src/greeter.sh"` — proves the build cycle reached Stage 5 and modified the source. Loose-but-anchored per S11b-1 precedent (Discovery §6); the literal feature ("add a NAME constant") makes `NAME` a near-deterministic substring, but we keep the assertion structural (substring, not full-content match) per AC4.
- **Diagnostic dumps:** Every assertion failure must dump the offending state — `$SCENARIO_OUT` (last 50+ lines indented), the plan file contents if it exists but fails a sub-assertion, and the greeter.sh contents if the implementation assertion fails. Mirror the existing dump style (`sed 's/^/    /' >&2`).
- **Plain-text label before the block:** Add a banner comment in the same style as line 46–48 (`# ──────...` separator + section title). E.g., `# Full scenario: /roughly:build --ci against fixture`.
- **Post-state check unchanged:** Line 116–125's `PRE_STATE`/`POST_STATE` symmetry check still runs as the final guard. Because all mutations from the build cycle land inside `$WORKTREE/tests/fixtures/hello-roughly/`, which is itself part of the worktree, the source tree at `$ROOT` is untouched and the symmetry check passes. (This is also AC9 fixture-state-reset — the worktree boundary is the reset mechanism.)
- **Do NOT add a new workflow step in dogfood.yml.** Discovery §3 confirmed extending the script preserves the worktree lifecycle (cleanup trap + pre/post symmetry); a separate workflow step would split that lifecycle and break pollution detection.
**Verify:** `bash -n scripts/ci-dogfood.sh` exits 0; `shellcheck scripts/ci-dogfood.sh` (if available) reports no new warnings; manual trace through the file confirms the new block sits between line 114 and the post-state check, uses `&& EXIT=0 || EXIT=$?` for the claude invocation, has all 5 structural assertions wired with FAIL diagnostics. Local run validation deferred to Stage 7 (verify-all) — script execution against real `claude` requires `ANTHROPIC_API_KEY`.
**UI:** no

### T4: Update CONTRIBUTING.md `## CI` section (~3 min)
**Files:** [CONTRIBUTING.md](../../CONTRIBUTING.md)
**Depends on:** T1, T2, T3
**Action:** Document the `--ci` flag mechanism, the fixture path, and S11b-2's landed status; preserve token-cost expectations.
**Details:**
- **Section to edit:** lines 81–112.
- **Mechanism doc** — add 1–2 sentences explaining `/roughly:build --ci` semantics: synthesizes Stage 4 PASS, CI-only, never invoke interactively. Cite the build/SKILL.md description as authoritative. One natural home: a new short paragraph between "Reproducing a failure locally" (lines 85–91) and "In scope for v0.1.5 CI" (lines 93–97), titled `**`--ci` flag.**`.
- **Fixture path callout** — extend the local-repro paragraph to note that the script `cd`s into `tests/fixtures/hello-roughly/` inside the worktree to drive the build cycle. Make clear the fixture is a *target project* for the cycle, not a Roughly install.
- **In-scope list update** — change line 97 from `S11b-2 — happy-path build cycle` (forward-looking) to past-tense `S11b-2 — happy-path build cycle (landed in this story)` to match the prose style for S11a at line 95. Match the wording pattern; don't introduce new framings.
- **Out-of-scope list** — no change required; "Build-cycle negative-path scenarios" remains accurate post-S11b-2 (negative paths are v0.1.6 candidates per epic).
- **Token-cost expectations** — line 108 (`S11b-2: ≤150K Sonnet tokens per run`) stays as the documented ceiling. The `--max-budget-usd 1.50` flag added in T3 enforces it mechanically. No edit needed unless the Stage 7 verify-all exposes a different observed cost — in that case, defer to a follow-up commit per the S11b-1 pattern.
- **Auth section (line 112)** — no change; the same `ANTHROPIC_API_KEY` step-scope applies.
**Verify:** `grep -c '^## CI' CONTRIBUTING.md` outputs `1` (no accidental section duplication); `grep -c -- '--ci' CONTRIBUTING.md` outputs `≥1`; `grep -q 'tests/fixtures/hello-roughly' CONTRIBUTING.md && echo found` prints `found` (exit-code-as-match: `grep -q` exits 0 when a match exists); visual diff readthrough confirms the prose flows naturally with the existing S11a/S11b-1 style.
**UI:** no

### T5: Update CHANGELOG.md (~2 min)
**Files:** [CHANGELOG.md](../../CHANGELOG.md)
**Depends on:** T1, T2, T3, T4
**Action:** Add an Unreleased-section entry recording S11b-2's landing per repo convention.
**Details:**
- Read the existing CHANGELOG.md to identify the active Unreleased section heading and the bullet style used by S11a / S11b-1 entries; mirror it.
- Add bullets covering: `--ci` flag added to `/roughly:build`; minimal CI fixture at `tests/fixtures/hello-roughly/`; full-scenario block in `scripts/ci-dogfood.sh`; CONTRIBUTING.md `## CI` section updated.
- Cite this story (E03.S11b-2) and the AC reference if that's the existing pattern.
**Verify:** `grep -q 'S11b-2' CHANGELOG.md && echo found` prints `found` (exit-code-as-match); visual readthrough confirms entry style matches preceding S11b-1 entry.
**UI:** no

## Blast Radius

- **Do NOT modify:**
  - `skills/build/SKILL.md` outside the three identified anchor points (frontmatter line 3, after line 25, before line 100). Other stages' prose is out of scope.
  - `.github/workflows/dogfood.yml` — extending the script, not the workflow, per Discovery §3.
  - `agents/*.md`, `skills/*/SKILL.md` (other than build) — `--ci` is build-only for v0.1.5; fix-side parity is a v0.1.6 candidate per epic out-of-scope list.
  - `docs/adrs/ADR-001-*` — the puncture is documented inline in build/SKILL.md; no ADR amendment needed for v0.1.5 (would be appropriate at v0.1.6 if the principle is codified, per epic v0.1.6 candidates).
  - `.roughly/known-pitfalls.md` — Stage 8 wrap-up will surface any new pitfalls separately.
  - `docs/planning/epics/E03-trust-and-ergonomics.md` — epic-status update is a post-merge follow-up commit per S11a/S11b-1 precedent (see commits `504b024`, `acd1076`).

- **Watch for:**
  - **Skill line cap.** 296 → 300 is at the ceiling. The description-line append (T1) is byte-level immune to visual wrap because `wc -l` counts `\n` characters, not displayed lines — appending text to line 3 produces zero new newlines regardless of editor wrap. The risk lives entirely in the Stage 1 (+2) and Stage 4 (+2) inserts: each must add exactly one content line + one blank line above. Verify with `wc -l skills/build/SKILL.md` after every T1 edit; abort if >300.
  - **Worktree boundary integrity.** The fixture at `tests/fixtures/hello-roughly/` is a real path in the source tree (committed). The build cycle's mutations (plan files, modified greeter.sh) land inside the **worktree's copy** of that path at `$WORKTREE/tests/fixtures/hello-roughly/`, not the source. The cleanup trap removes the worktree, so source mutations are impossible by construction. AC9 (fixture state reset) and the existing post-state symmetry check both depend on this.
  - **Marker string drift.** `[--ci] plan review skipped — synthetic PASS` must be byte-identical between T1 (build/SKILL.md) and T3 (ci-dogfood.sh grep). Hyphenation, em-dashes, capitalization all matter. Use the same literal in both files.
  - **`-p` mode self-progression through other gates.** Stages 1, 5d, 6, 7, 8 each have conversational gates. In `-p` mode the model self-progresses past them (no real I/O block), so `--ci` only short-circuits Stage 4's *mechanical* dispatch. If the scenario hangs, that's a sign Claude is treating one of the conversational gates as blocking — worth flagging in Stage 6 review.
  - **Fixture file modes.** `src/greeter.sh` and `tests/greeter.test.sh` should be executable (`chmod +x`). Git stores the mode bit; if T2 forgets `chmod`, the test invocation in T3's verification may need `bash <path>` rather than `<path>` directly. The verification commands in T3 already use `bash <path>` to be defensive.
  - **Token budget headroom.** $1.50 is conservative-but-tight for a full pipeline run. If Stage 7 verify-all exposes consistent budget breaches, raise the cap and update CONTRIBUTING.md token expectation in a follow-up commit (do not lower assertions to fit; that defeats the regression guard).

## Conventions

- **ADR-001** (review-plan as blocking subagent): `--ci` is a *deliberate* puncture for non-interactive CI execution. Stage 4's inline prose must say so.
- **ADR-009** (plan-mode detection): the `UserPromptSubmit` hook matches `permission_mode == "plan"`; `--ci` is unrelated to plan mode and does not interact with the hook. No hook changes required.
- **Known pitfall: `set -e` + command-substitution-in-assignment** (`.roughly/known-pitfalls.md` lines 53–54): mandatory `&& EXIT=0 || EXIT=$?` idiom for any new `claude` invocation in ci-dogfood.sh. Without it, non-zero exits silently kill the script before the diagnostic fires.
- **Known pitfall: doc claims that cite line numbers rot silently** (`.roughly/known-pitfalls.md` lines 68–69): assertions in T3 must use content anchors (`grep -E '^### T1'`), not line numbers from the plan file.
- **S11b-1 plugin-load grep precedent**: anchored, liberal-but-bounded regex (Discovery §6, ci-dogfood.sh:108). T3's structural assertions follow the same design — strict enough to catch drift, liberal enough to survive plan-format evolution.
- **`{{PLACEHOLDER}}` convention**: the new prose in build/SKILL.md is *plugin-side* skill text (runs in user projects). The `--ci` flag string is a literal contract, not a project-specific placeholder, so it is correctly hardcoded. The fixture path `tests/fixtures/hello-roughly/` appears only in CI script + CONTRIBUTING.md (plugin-internal scope), never in skill prose.
- **Repo convention: separate epic-status follow-up commit.** S11a (PR #31 → `504b024`) and S11b-1 (PR #32 → `acd1076`) followed the pattern of landing implementation in one commit and recording epic status in a separate commit afterward. Stage 8 wrap-up here will commit only the implementation; the epic update is a post-merge follow-up.
