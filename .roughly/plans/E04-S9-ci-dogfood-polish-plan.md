# Implementation Plan: E04.S9 — CI dogfood polish (macOS `gtimeout` + `ANTHROPIC_API_KEY` empty-guard)

Plan-format-version: 1

## File Table

| File | Action | Task(s) |
|------|--------|---------|
| `scripts/ci-dogfood.sh` | Modify | T1, T2, T3 |
| `CONTRIBUTING.md` | Modify | T4 |

## Tasks

### T1: Add `$TIMEOUT` detection block after the repo-guard (~3 min)

**Files:** `scripts/ci-dogfood.sh`

**Action:** Insert a portability detection block selecting `timeout` (Linux/CI) or `gtimeout` (macOS coreutils) into `TIMEOUT`, with a friendly diagnostic if neither is available. Block lands after L11 (closing `fi` of the repo-guard), separated by L12's blank line, before L13's `# Resolve SHA` comment.

**Details:**

Insert exactly the following block immediately after line 12 (the existing blank line that follows the repo-guard's `fi`). The block uses multi-line `if` form matching the repo-guard's existing style (L8–11). Preserve the trailing blank line between this block and T2's guard.

```bash
# Portability: select timeout binary (Linux uses 'timeout'; macOS via coreutils uses 'gtimeout').
if command -v timeout >/dev/null 2>&1; then
  TIMEOUT=timeout
elif command -v gtimeout >/dev/null 2>&1; then
  TIMEOUT=gtimeout
else
  echo "ci-dogfood: FAIL — no timeout binary available (install coreutils on macOS via 'brew install coreutils')" >&2
  exit 1
fi
```

Diagnostic string is byte-verbatim from AC1. The detection block's two internal `command -v timeout` / `command -v gtimeout` references are bare binary-name arguments (intentionally not `$TIMEOUT`) and AC1 explicitly carves them out of the verify.

**Verify:**
- `bash -n scripts/ci-dogfood.sh` (parse-check, no execution) exits 0
- `grep -Fn 'command -v timeout' scripts/ci-dogfood.sh` returns exactly 1 match
- `grep -Fn 'command -v gtimeout' scripts/ci-dogfood.sh` returns exactly 1 match
- `grep -Fn 'install coreutils on macOS' scripts/ci-dogfood.sh` returns exactly 1 match

**UI:** no

---

### T2: Add `ANTHROPIC_API_KEY` empty-guard immediately after T1's block (~2 min)

**Files:** `scripts/ci-dogfood.sh`
**Depends on:** T1

**Action:** Insert an empty-guard for `ANTHROPIC_API_KEY` using the `${VAR:-}` form (load-bearing under `set -u`, already active at L2). Block lands directly after T1's `$TIMEOUT` detection block, separated by one blank line, before the `# Resolve SHA` comment.

**Details:**

Insert exactly the following block one blank line below T1's closing `fi`:

```bash
# Guard: ANTHROPIC_API_KEY must be set (the ${VAR:-} form is required because `set -u` is active above).
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  echo "ci-dogfood: FAIL — ANTHROPIC_API_KEY not set or empty (configure in GitHub Settings → Secrets and variables → Actions, or export for local repro)" >&2
  exit 1
fi
```

Diagnostic string is byte-verbatim from AC2. The `${ANTHROPIC_API_KEY:-}` form matches the existing precedent at L14 (`${GITHUB_SHA:-...}`) — not a new convention.

Preserve the blank line below this block separating it from the existing `# Resolve SHA` section.

**Verify:**
- `bash -n scripts/ci-dogfood.sh` exits 0
- `grep -Fn '[ -z "${ANTHROPIC_API_KEY:-}"' scripts/ci-dogfood.sh` returns exactly 1 match
- `grep -Fn 'ANTHROPIC_API_KEY not set or empty' scripts/ci-dogfood.sh` returns exactly 1 match
- `grep -cFn 'ANTHROPIC_API_KEY' scripts/ci-dogfood.sh` returns 2 (1 pre-existing comment at original L50 + 1 new guard text)

**UI:** no

---

### T3: Replace the three literal `timeout` invocations with `$TIMEOUT` (~3 min)

**Files:** `scripts/ci-dogfood.sh`
**Depends on:** T1, T2

**Action:** Replace the literal `timeout` binary name at exactly three invocation sites (smoke test, plugin-load test, full-scenario test) with the `$TIMEOUT` variable from T1. Use content-based replacement (line numbers will have shifted by ~17 lines after T1+T2).

**Details:**

Three replacements. Each target uses the existing `&& EXIT=0 || EXIT=$?` capture idiom that must be preserved untouched:

1. Smoke test (originally L58): replace `timeout 25 claude` with `$TIMEOUT 25 claude` inside the `SMOKE_OUT="$(timeout 25 claude --bare ...` line. Unique enough — only one `SMOKE_OUT="$(timeout` occurrence.
2. Plugin-load test (originally L84): replace `timeout 25 claude` with `$TIMEOUT 25 claude` inside the `PLUGIN_OUT="$(timeout 25 claude --bare ...` line. Unique — only one `PLUGIN_OUT="$(timeout` occurrence.
3. Full-scenario test (originally L124): replace `timeout 270 claude` with `$TIMEOUT 270 claude` inside the `SCENARIO_OUT="$(timeout 270 claude --bare ...` line. The `270` timeout is unique to this site — no other invocation uses 270.

Use `Edit` with content-unique `old_string` per replacement (e.g., `SMOKE_OUT="$(timeout 25 claude` → `SMOKE_OUT="$(timeout 25 claude` → swap to `SMOKE_OUT="$(${TIMEOUT} 25 claude` is wrong — use `$TIMEOUT` not `${TIMEOUT}` per AC1's verify pattern `rg -Fn '$TIMEOUT'`). Final form: `SMOKE_OUT="$($TIMEOUT 25 claude ...` (likewise PLUGIN_OUT and SCENARIO_OUT).

Do NOT modify the `command -v timeout` / `command -v gtimeout` references inside T1's detection block — those reference the bare binary name as an argument to `command -v`, not as an invocation, and AC1 explicitly excludes them from the verify.

**Verify:**
- `bash -n scripts/ci-dogfood.sh` exits 0
- `rg -Fn '$TIMEOUT' scripts/ci-dogfood.sh` returns exactly 3 matches (the three invocation lines). This is AC1's prescribed verify command.
- `grep -Fn 'SMOKE_OUT="$($TIMEOUT 25 claude' scripts/ci-dogfood.sh` returns 1 match
- `grep -Fn 'PLUGIN_OUT="$($TIMEOUT 25 claude' scripts/ci-dogfood.sh` returns 1 match
- `grep -Fn 'SCENARIO_OUT="$($TIMEOUT 270 claude' scripts/ci-dogfood.sh` returns 1 match
- `grep -Fn '$(timeout ' scripts/ci-dogfood.sh` returns 0 matches (no literal `timeout` invocations remain — note the trailing space disambiguates from `command -v timeout`)

**UI:** no

---

### T4: Append gtimeout note to `CONTRIBUTING.md` `## CI` section (~1 min)

**Files:** `CONTRIBUTING.md`

**Action:** Append AC5's one-line gtimeout note to the end of the `## CI` section, after the existing Auth paragraph at L132–L133 and before the `## Stop hook drift checks` heading at L135.

**Details:**

Insert exactly the following line (byte-verbatim from AC5) as a new paragraph at the end of the `## CI` section. Preserve blank-line spacing around it (one blank line before, the existing blank line at L134 between sections is preserved after):

```
macOS contributors running `scripts/ci-dogfood.sh` locally need `gtimeout` from `brew install coreutils`.
```

Landing slot: after L133's existing content, before L134's blank line. The result should be: existing Auth paragraph → blank line → new gtimeout sentence → blank line → `## Stop hook drift checks` heading.

Do NOT modify any other text in the `## CI` section (specifically: do NOT edit L109's existing description of the auth-failure path — the new empty-guard is additive, not a replacement, and rewording L109 is out of scope per the "do not modify existing prose" implicit constraint).

**Verify:**
- `grep -Fn 'gtimeout' CONTRIBUTING.md` returns exactly 1 match
- `grep -Fn 'brew install coreutils' CONTRIBUTING.md` returns exactly 1 match
- The new line falls between the `## CI` heading at L99 and the `## Stop hook drift checks` heading (use `awk '/^## CI$/,/^## Stop hook drift checks$/' CONTRIBUTING.md | grep -F 'gtimeout'` returns 1 match)

**UI:** no

---

## Blast Radius

- **Do NOT modify:**
  - `.github/workflows/dogfood.yml` (AC6 hard constraint — `git diff --stat` on the PR must show only `scripts/ci-dogfood.sh` and `CONTRIBUTING.md`)
  - `CONTRIBUTING.md` outside the `## CI` section
  - `scripts/ci-dogfood.sh` outside the new preflight blocks and the three invocation-site swaps
  - The `&& EXIT=0 || EXIT=$?` capture idiom on each `$TIMEOUT` invocation (load-bearing per known-pitfalls.md L28 — S11b-1 origin)
  - The pre-existing `${GITHUB_SHA:-...}` form at L14 (existing precedent, not the target)
  - The pre-existing `# --bare is mandatory: forces strict ANTHROPIC_API_KEY-only auth ...` comment at L50

- **Watch for:**
  - Line numbers shift after T1+T2. T3 must use content-based replacement, not original L58/L84/L124.
  - Two `if`/`fi` blocks are being added; ensure they balance (T1 = 7 lines + comment + blank; T2 = 4 lines + comment + blank).
  - `set -u` is already active (L2 `set -euo pipefail`) — the `${ANTHROPIC_API_KEY:-}` form is load-bearing for correctness, not just future-proofing. Any unguarded `"$ANTHROPIC_API_KEY"` would abort before the guard fires when the key is unset.
  - `rg -Fn '$TIMEOUT' scripts/ci-dogfood.sh` is AC1's exact verify — must return exactly 3, not 4 (no stray `$TIMEOUT` outside the three invocation sites) and not 2 (all three invocations swapped).
  - The diagnostic strings in T1 and T2 use an em-dash (`—`, U+2014), not a hyphen. Preserve verbatim from the ACs.

## Conventions

- **Existing repo-guard style (`ci-dogfood.sh` L4–11):** multi-line `if ... then ... fi`, 2-space indent, lowercase `ci-dogfood:` prefix on diagnostics, `>&2` for stderr, `exit 1` on guard failure. T1 and T2 follow this style exactly.
- **`${VAR:-}` defensive form precedent:** `ci-dogfood.sh` L14 (`SHA="${GITHUB_SHA:-...}"`). T2's `${ANTHROPIC_API_KEY:-}` matches.
- **`&& EXIT=0 || EXIT=$?` capture idiom:** preserved across all three T3 swaps. Per known-pitfalls.md L28 (S11b-1 origin), this idiom is required under `set -e` to prevent CI assertion failures being silently masked.
- **CONTRIBUTING.md style:** prose paragraphs, backticks for paths and commands. T4's note matches.
- **AC line-cap context:** `scripts/ci-dogfood.sh` has no caps (not a SKILL.md or agent.md). T1+T2 add ~14 lines (244 → ~258); well under any reasonable script soft cap and no enforcement hook targets `scripts/`.
- **No new ADR required:** this is mechanical defensive hardening; no architectural decision is being made.

## Out of Scope (per spec)

- Replacing `realpath`, `sed -i`, or other macOS-vs-Linux divergences
- Friendly diagnostics for other secrets (none exist beyond `ANTHROPIC_API_KEY`)
- Modifying the auth-failure regression step or its scoped `invalid-key-xyz` value
- Negative-path CI scenarios (deferred to v0.1.7 per OQ4)
- Caching node_modules / Claude state between runs
- Cross-platform fixture / assertion divergence (assertions run on Ubuntu only)
- Rewording `CONTRIBUTING.md` L109's pre-S9 description of the auth-failure path
