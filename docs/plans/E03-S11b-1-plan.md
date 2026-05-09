Plan-format-version: 1

# Implementation Plan: E03.S11b-1 — CLI plumbing smoke test

**Source:** [docs/planning/epics/E03-trust-and-ergonomics.md:680-710](../planning/epics/E03-trust-and-ergonomics.md#L680-L710)

**Goal:** Replace the S11a no-op stub in [scripts/ci-dogfood.sh](../../scripts/ci-dogfood.sh) with a real `claude` CLI invocation that proves plugin loading, authenticated API access, and a deterministic auth-failure path. Add the corresponding `Install Claude Code` and auth-failure negative-test steps to [.github/workflows/dogfood.yml](../../.github/workflows/dogfood.yml).

## File Table

| File | Action | Task(s) |
|------|--------|---------|
| scripts/ci-dogfood.sh | Modify | T1 |
| .github/workflows/dogfood.yml | Modify | T2, T3 |
| CONTRIBUTING.md | Modify | T4 |
| CHANGELOG.md | Modify | T5 |
| docs/ROADMAP.md | Modify | T6 |

## Tasks

### T1: Replace stub with smoke + plugin-loading assertions in ci-dogfood.sh (~5 min)
**Files:** scripts/ci-dogfood.sh
**Action:** Replace the no-op stub block (lines 46-51) with two real `claude` invocations: (1) a trivial-prompt smoke test that proves auth + API exercise, and (2) a slash-command-listing assertion that proves plugin loading.
**Details:**
- The replacement block sits between line 44 (`cd "$WORKTREE"`) and line 52 (`POST_STATE=...`). Do NOT move, modify, or duplicate the surrounding worktree, cleanup-trap, or pollution-symmetry logic.
- Use `claude --bare --plugin-dir "$WORKTREE" --no-session-persistence -p "<prompt>"` for both calls.
  - `--bare` is mandatory: it forces strict `ANTHROPIC_API_KEY`-only auth (no keychain/OAuth fallback). Without it, a missing/invalid secret in CI may hang or prompt for OAuth instead of failing cleanly. Document this rationale in an inline comment.
  - `--no-session-persistence` prevents writing session files to disk (avoids any chance of session-state pollution; only valid with `--print`).
  - `--plugin-dir "$WORKTREE"` points at the ephemeral worktree (already the cwd).
- Wrap each call in `timeout 25` so the combined wall-clock budget stays under 60s (AC4) even with a worst-case retry.
- Capture combined stdout+stderr (`2>&1`) for each call into a shell variable so failure diagnostics include the full output.
- Smoke call (AC1):
  - Prompt: `"respond with the literal string ok"`
  - Assertion: `grep -q "ok"` against captured output (case-sensitive — the prompt asks for the literal token).
  - On failure: emit `ci-dogfood: FAIL — smoke step did not produce expected response`, indent-dump captured output to stderr, `exit 1`.
- Plugin-loading call (AC2):
  - Prompt: `"List each of your available slash commands on a separate line with the / prefix. Do not include any other text."` — explicit and structured, to minimize natural-language drift.
  - Assertion: `grep -q "roughly:setup"` against captured output. The smoke fixture in this repo always loads its own plugin via `--plugin-dir "$WORKTREE"`, so `/roughly:setup` is the deterministic anchor.
  - **Note (LLM-output dependency):** The slash-command listing relies on the model's compliance with the prompt format. `claude` has no deterministic `--list-commands` flag in `-p` mode (verified in Stage 2 discovery), so this is the most reliable approximation. If the assertion regresses, the failure log will show the captured output for diagnosis. Document this caveat in an inline `# NOTE:` comment above the call.
  - On failure: emit `ci-dogfood: FAIL — plugin loading not verified (no /roughly:setup in slash command list)`, indent-dump captured output to stderr, `exit 1`.
- Both calls add `--max-budget-usd 0.05` to enforce AC5's ≤5K-token cap as a hard gate (Sonnet pricing puts ~5K tokens around $0.04). If the budget is breached, claude exits non-zero and the script's `set -euo pipefail` propagates the failure. This converts the AC5 cap from aspirational to enforced.
- Preserve the existing log conventions: `ci-dogfood: <verb> — <detail>` (em-dash, not hyphen), `>&2` for failures, `printf '%s\n' "$VAR" | sed 's/^/    /' >&2` for multi-line indented diagnostic dumps.
- Replace the stub's `# ──────…` block delimiter with a new `# Smoke test: …` block delimiter in the same style.
- After both calls succeed, emit a single-line success log before falling through to the pollution check.

**Verify:**
- `bash -n scripts/ci-dogfood.sh` (syntax)
- `shellcheck scripts/ci-dogfood.sh` (style + bug check)
- `grep -c "claude --bare" scripts/ci-dogfood.sh` returns 2 (both invocations present)
- `grep -c "stub" scripts/ci-dogfood.sh` returns 0 (stub language removed)

**UI:** no

---

### T2: Add Claude Code install step to dogfood.yml (~3 min)
**Files:** .github/workflows/dogfood.yml
**Action:** Add a workflow step that installs `@anthropic-ai/claude-code` from npm so the `claude` binary is available before `Run dogfood scaffolding` executes.
**Details:**
- Insert a new step between `Checkout` (line 15-18) and `Run dogfood scaffolding` (line 20-23).
- Step name: `Install Claude Code`.
- Implementation: `run: npm install -g @anthropic-ai/claude-code` — `ubuntu-latest` ships with Node and npm pre-installed, so no `actions/setup-node` is required.
- After the install step, add a one-line `claude --version` smoke step (or include it as the last command of this step) so install failures fail fast with a clear log line. Pin format: `run: npm install -g @anthropic-ai/claude-code && claude --version`.
- Do NOT pin a specific version of `@anthropic-ai/claude-code` in this story — the dogfood is meant to track latest. (If pinning is later judged necessary, that's a follow-on.)
- The existing `Run dogfood scaffolding` step keeps its step-scoped `ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}` env block — the secret consumption shifts from "stub-no-op" to "real-smoke" without changing scope.

**Verify:**
- `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/dogfood.yml'))"` parses cleanly
- `grep -c "ANTHROPIC_API_KEY" .github/workflows/dogfood.yml` returns 2 (one for the existing scaffolding step, one for the new auth-failure step from T3)
- Visual inspection: `Install Claude Code` step is between `Checkout` and `Run dogfood scaffolding`

**UI:** no

---

### T3: Add auth-failure negative-test step to dogfood.yml (~5 min)
**Files:** .github/workflows/dogfood.yml
**Action:** Add a workflow step that deliberately runs `claude --bare` with an invalid `ANTHROPIC_API_KEY` and asserts the recognizable auth-error string appears in the output (AC3 ongoing protection — not just a one-time manual verification).
**Details:**
- Insert a new step AFTER `Run dogfood scaffolding`. This is a permanent regression check: every CI run proves that a missing/invalid secret produces a clean, fast failure rather than a hang.
- Step name: `Verify auth failure mode (no hang)`.
- The step's `env:` block sets `ANTHROPIC_API_KEY: invalid-key-xyz` (step-scoped — the real secret must NOT be in scope here, or the test is meaningless).
- Inline bash body (use `run: |` block, NOT a separate script — keeps the negative test colocated with the workflow contract):
  - `set -uo pipefail` (NOT `set -e` — we expect the inner claude invocation to fail; `set -e` would short-circuit the assertion logic).
  - Capture output with `OUT="$(timeout 30 claude --bare --plugin-dir "$GITHUB_WORKSPACE" --no-session-persistence -p "respond with ok" 2>&1 || true)"` — the `|| true` ensures claude's nonzero exit doesn't kill the step. Use exactly this idiom (do NOT use `set +e` / `set -e` windows — `|| true` is simpler and the rest of the step relies on it).
  - Assert the recognizable auth-error string is present. Match either `Invalid API key` (literal-bad-key path) or `Not logged in` (empty/missing-key path). GitHub Actions expands an unconfigured `${{ secrets.ANTHROPIC_API_KEY }}` to an empty string `""`, which produces `Not logged in · Please run /login` rather than `Invalid API key · Fix external API key`. The assertion must accept both: `grep -qE "Invalid API key|Not logged in" <<< "$OUT"`. If neither matches, emit `::error::auth-failure test FAILED — expected 'Invalid API key' or 'Not logged in' in output` and exit 1.
  - On pass: echo the matched error string back (`auth-failure test PASSED — clean error (no hang): <first matching line>`) so CI logs show which path fired without dumping the full output by default.
- Use `::error::` GitHub Actions log annotation on assertion failure for visibility in PR review UIs.
- The 30-second timeout is generous: `--bare` should reject within ~2-3 seconds. If `timeout` itself fires (exit code 124), that IS the hang case — emit a distinct error message (`auth-failure test FAILED — claude timed out (hang regression?)`) and exit 1. The `|| true` strips the inner exit code, so detect the timeout by the absence of any error-string match plus an empty/short captured output, OR capture the exit code via a small wrapper before the `|| true` collapse.

**Verify:**
- `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/dogfood.yml'))"` parses cleanly
- `grep "invalid-key-xyz" .github/workflows/dogfood.yml` shows one occurrence (the step env, not the step body)
- Local smoke of the auth-failure path: `ANTHROPIC_API_KEY=invalid-key-xyz claude --bare -p "test" 2>&1 | grep -E "Invalid API key|Not logged in"` should match. This is sufficient to validate the inner assertion; only the step-env-isolation property (real secret not leaking into this step's scope) requires GitHub Actions to verify end-to-end.

**UI:** no

---

### T4: Update CONTRIBUTING.md to reflect S11b-1 shipped (~2 min)
**Files:** CONTRIBUTING.md
**Action:** Update the two forward-looking sentences about S11b-1 to past-tense, reflecting the smoke step now exists.
**Details:**
- Line 91: replace `The S11a stub does not require ANTHROPIC_API_KEY. Once S11b-1 lands, set the env var to exercise the smoke-test path.` with prose that says: "The smoke-test step requires `ANTHROPIC_API_KEY`. Set the env var locally before running, or omit it to exercise the auth-failure path (the script will fail with `Invalid API key`)."
- Line 112: replace `The S11a stub does not consume it; … S11b-1 will add its own step-level env: mapping when it consumes the secret.` with: "The smoke step consumes the secret via a step-scoped `env:` mapping on `Run dogfood scaffolding`; the auth-failure negative-test step uses a deliberately-invalid placeholder, also step-scoped. The real secret is never exposed at workflow-global scope."
- Do NOT modify the In-scope/Out-of-scope or token-cost-expectations bullet lists in this story (S11b-1 still in-scope; S11b-2 still pending). The `S11b-1: ~5K tokens per run` budget remains the cap.

**Verify:**
- `grep -c "S11a stub" CONTRIBUTING.md` returns 0 (forward-looking S11a-stub language removed)
- `grep "Invalid API key" CONTRIBUTING.md` returns at least 1 (auth-failure prose present)

**UI:** no

---

### T5: Add CHANGELOG.md entry for E03.S11b-1 (~2 min)
**Files:** CHANGELOG.md
**Action:** Add a new bullet under `## v0.1.5 Unreleased` → `### Added` describing what S11b-1 ships.
**Details:**
- Match the prose density of the existing S11a entry on line 9 (one long, dense sentence; markdown links to touched files).
- The entry should mention: smoke-test step replaces the S11a stub; uses `claude --bare --plugin-dir "$WORKTREE" --no-session-persistence -p` to prove auth + plugin-load; AC anchors are slash-command listing (`/roughly:setup`) and `Invalid API key` recognizable string; auth-failure negative test runs every CI run as ongoing regression protection; secrets remain step-scoped (real key on smoke step, invalid placeholder on negative-test step).
- Update the trailing "CI cluster now 1/3" tracking line on line 9 (or append a new tracking sentence) to reflect S11b-1 done — CI cluster now 2/3, S11b-2 happy-path remains.

**Verify:**
- `grep -c "S11b-1" CHANGELOG.md` returns at least 1 (entry present)
- `grep "v0.1.5" CHANGELOG.md` confirms entry is under the unreleased section, not a shipped one

**UI:** no

---

### T6: Mark S11b-1 complete in docs/ROADMAP.md (~1 min)
**Files:** docs/ROADMAP.md
**Action:** Update item #11 to record that S11b-1 has shipped, leaving S11b-2 as the remaining gap.
**Details:**
- Edit the existing "S11a scaffolding ✅ — landed in this story; S11b-1 plumbing and S11b-2 happy-path pending." prose on line 71.
- Replacement: keep the S11a record, add `S11b-1 plumbing ✅`, leave `S11b-2 happy-path pending`.
- Do NOT modify any other ROADMAP item.

**Verify:**
- `grep "S11b-1 plumbing" docs/ROADMAP.md` shows the marker
- `git diff docs/ROADMAP.md` shows a single-line change inside item #11

**UI:** no

---

## Blast Radius

**Do NOT modify:**
- The cleanup trap, stale-worktree guard, worktree create, or pollution-symmetry check in [scripts/ci-dogfood.sh](../../scripts/ci-dogfood.sh) (lines 4-44 and 52-63 — the entire shell except for the stub block).
- The `permissions: contents: read` block in [.github/workflows/dogfood.yml](../../.github/workflows/dogfood.yml) — least-privilege locked in S11a.
- Any other workflow file under `.github/workflows/`.
- The In-scope / Out-of-scope / Token-cost bullet lists in CONTRIBUTING.md — those are forward-looking against S11b-2 and the v0.1.6 cluster.
- The epic file (`docs/planning/epics/E03-trust-and-ergonomics.md`) — per S11a precedent, the epic-completion update is a separate doc-only commit on main, not part of the implementation PR.
- Any skill, agent, or `agent-preamble.md` content — none of those are touched by this story.

**Watch for:**
- The pollution-symmetry check at [scripts/ci-dogfood.sh:53-61](../../scripts/ci-dogfood.sh#L53) compares `git status --porcelain` of `$ROOT` (the source repo). The smoke step's claude invocations run with `cwd = $WORKTREE` — they MUST NOT write into `$ROOT`. If a future regression introduces a path that escapes the worktree, this check will fire and fail CI. That is the intended fail-loud behavior.
- `--bare` mode disables CLAUDE.md auto-discovery and hooks. The smoke step is a minimal end-to-end auth+plugin-load proof, NOT a substitute for the full pipeline scenarios in S11b-2.
- Token cost: the trivial-prompt + list-commands prompts together should be a few hundred tokens. AC5's ≤5K cap leaves significant headroom; if a future change pushes near the cap, that's a signal of fixture growth.

## Conventions

- Bash: `set -euo pipefail` (already in place); error messages route to `>&2`; multi-line dumps via `printf '%s\n' "$VAR" | sed 's/^/    /' >&2`.
- Diagnostic prefix: `ci-dogfood: <verb> — <detail>` (em-dash separator).
- Block delimiters: `# ──────────────────────────────────────────────────────────────────────` (matches existing style at line 46).
- Workflow steps: each step has a clear `name:` describing the assertion it makes; secrets stay step-scoped (per S11a least-privilege fix on line 23 of dogfood.yml); permissions stay read-only.
- Markdown: prose entries in CHANGELOG.md and CONTRIBUTING.md use markdown reference links (`[name](path)`), not bare paths.
- Plan format version 1 marker is at the top of this file per E03.S6 convention.
