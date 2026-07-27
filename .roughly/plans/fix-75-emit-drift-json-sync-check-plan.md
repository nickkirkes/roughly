# Fix Plan: #75 — function-scoped drift check keeping `emit_drift_json` in sync (closes #68 root cause)

Plan-format-version: 1

## Root Cause

Issue #68 existed because the dogfood `.claude/hooks/verify-all.sh` `emit_drift_json` silently drifted from the hardened copy in `skills/setup/templates/verify-all-stop-hook.sh.template` (the template gained a 3-tier fallback; the dogfood copy never did; nothing caught it). `verify-all.sh`'s existing pair-checks (plan-mode-gate, preamble byte-identity, ADR-012 shared-reference "Check 8") do not cover this function, and both `verify-all.sh:77-78` and `CONTRIBUTING.md:208` explicitly state this template↔hook pair is "intentionally NOT enforced" — leaving the generic `emit_drift_json` infra free to diverge again undetected. The fix adds a lightweight **function-scoped** byte-equality check (not whole-file — the two files legitimately differ elsewhere) and qualifies the two now-misleading "NOT enforced" statements.

## Decisive precondition (verified during investigation)

The two `emit_drift_json` functions are **byte-identical today** (`verify-all.sh:168-209` ≡ `template:54-95`; `diff` of the extractions = empty). So the check is silent on day one — no companion normalization/fix commit is needed. The induced-divergence AC2 test is run against scratch copies so the real files are never mutated.

## Design notes
- **Extraction (robust):** `awk '/^emit_drift_json\(\) \{$/{f=1} f{print; if ($0=="}") exit}' <file>` — anchors on the exact signature line `emit_drift_json() {` and stops on the first line that is exactly `}`. Verified: each function body has exactly one column-0 `}` (its own close), no nested column-0 brace, so this is correct for both files.
- **Comparison idiom:** mirror the CRITICAL-preamble check (`verify-all.sh:99-107`) — extract each into a shell variable via `$(...)`, compare with `!=`, guard empty — composed with the plan-mode-gate check's explicit template-existence guard (`verify-all.sh:79-85`) for a directed diagnostic. **No process substitution** (keeps it shell-portable; matches existing idioms).
- **Self-reference is safe:** the check only compares source *text*; it does not invoke `emit_drift_json`. The function is defined at L168 and called once at L213; bash reads the whole script before executing, and all checks accumulate `$issues` at L14-166. Placing the new check at ~L86 is safe.
- **Paths:** bare repo-relative (`.claude/hooks/...`, `skills/setup/templates/...`) — correct for the dogfood hook running in THIS repo (matches every existing check in the file; NOT consumer-runtime skill prose, so no `${CLAUDE_PLUGIN_ROOT}`).
- **Enumeration collision:** do NOT number this "Check 8" — that name already denotes the ADR-012 shared-reference check. The CONTRIBUTING "seven structural invariants" list is already stale (omits CRITICAL-preamble, F1 tripwire, and the ADR-012 "Check 8"); a full refresh is out of scope. Qualify the specific false sentence rather than renumber.

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| .claude/hooks/verify-all.sh | Modify | T1 |
| CONTRIBUTING.md | Modify | T2 |

## Baseline facts (captured 2026-07-26, branch `fix/74-verify-all-drift-check`, at parity with `main`)
- `emit_drift_json`: `verify-all.sh:168-209`, `template:54-95`; byte-identical now.
- Existing analog check: plan-mode-gate hook-pair at `verify-all.sh:74-85` (its comment L77-78 carries the "intentionally NOT checked here" note to qualify). Insert the new check right after its closing `fi` (L85), before the blank line preceding the `PITFALLS_ORGANIZE_THRESHOLD` block (L87).
- `verify-all.sh` is 215 lines; no live line cap (the historical "150 soft cap" is unenforced and already exceeded).
- verify-all.sh has NO `set -e` (per known-pitfalls) — `$(...)` extraction + `!=` compare + `if ! ...` are safe.
- CONTRIBUTING.md: the "intentionally NOT enforced" claim is in item 6 (`CONTRIBUTING.md:208`); the "It enforces seven structural invariants" lead-in is at `CONTRIBUTING.md:201`.
- Session `grep`/`diff` are shimmed — use `command grep`/`command diff` in ad-hoc verification.

## Tasks

### T1: Add the `emit_drift_json` function-scoped drift check + qualify the stale comment (~6 min)
**Files:** .claude/hooks/verify-all.sh
**Action:** Insert a new function-scoped byte-equality check after the plan-mode-gate check, and qualify the now-misleading L77-78 comment.
**Details:**
1. **Qualify the comment.** The plan-mode-gate check's comment currently includes (L77-78):
   `# Note: a DIFFERENT pair — verify-all-stop-hook.sh.template ↔ dogfood verify-all.sh —`
   `# is intentionally NOT checked here (per E03.S2; see CONTRIBUTING.md "Stop hook drift checks").`
   Replace those two lines with:
   `# Note: a DIFFERENT pair — verify-all-stop-hook.sh.template ↔ dogfood verify-all.sh —`
   `# is intentionally NOT byte-identical as whole files (per E03.S2; see CONTRIBUTING.md "Stop hook drift checks"),`
   `# but their shared emit_drift_json function IS sync-checked just below (#75; the #68 root cause).`
2. **Insert the check.** Immediately after the plan-mode-gate check's closing `fi` (currently L85) and its following blank line, insert this block (keep a blank line before and after it):
```
# emit_drift_json function-scoped sync (closes #75; the #68 root cause).
# The dogfood hook and skills/setup/templates/verify-all-stop-hook.sh.template are
# intentionally NOT whole-file identical, but their shared emit_drift_json infra MUST
# stay in sync — a silent backport-drift of exactly this function caused #68.
if [ ! -f skills/setup/templates/verify-all-stop-hook.sh.template ]; then
  issues="${issues}- verify-all template missing: skills/setup/templates/verify-all-stop-hook.sh.template — emit_drift_json sync unverifiable\n"
else
  edj_hook=$(awk '/^emit_drift_json\(\) \{$/{f=1} f{print; if ($0=="}") exit}' .claude/hooks/verify-all.sh)
  edj_tmpl=$(awk '/^emit_drift_json\(\) \{$/{f=1} f{print; if ($0=="}") exit}' skills/setup/templates/verify-all-stop-hook.sh.template)
  if [ -z "$edj_hook" ] || [ "$edj_hook" != "$edj_tmpl" ]; then
    issues="${issues}- emit_drift_json drift: .claude/hooks/verify-all.sh and skills/setup/templates/verify-all-stop-hook.sh.template diverged (shared function must stay in sync — #68 root cause)\n"
  fi
fi
```
Do not change any other check, the `emit_drift_json` definition itself, or the final emit block.
**Verify:**
```
cd /Users/nickkirkes/rowdycloud/code/roughly
bash -n .claude/hooks/verify-all.sh || { echo FAIL-syntax; exit 1; }
# (a) silent on the real (identical) files — verify-all must still emit 0 bytes:
out=$(bash .claude/hooks/verify-all.sh 2>&1); [ -z "$out" ] || { echo "FAIL-not-clean: $out"; exit 1; }
# comment qualified:
command grep -qF 'shared emit_drift_json function IS sync-checked just below' .claude/hooks/verify-all.sh || { echo FAIL-comment; exit 1; }
# check block present:
command grep -qF 'emit_drift_json function-scoped sync (closes #75' .claude/hooks/verify-all.sh || { echo FAIL-check-missing; exit 1; }
# (b) AC2 induced-divergence test against scratch copies (real files untouched):
S=$(mktemp -d "${TMPDIR:-/tmp}/verify75.XXXXXX"); cp .claude/hooks/verify-all.sh "$S/hook.sh"; cp skills/setup/templates/verify-all-stop-hook.sh.template "$S/tmpl.sh"
# mutate one line inside emit_drift_json's body in the scratch hook copy
# (content-based, NOT a hardcoded line number — this check's own insertion shifts
# the function's line position, and an NR== target would silently miss post-insertion):
command sed -i.bak 's/for full fidelity\./for full fidelity CHANGED./' "$S/hook.sh"
ext() { awk '/^emit_drift_json\(\) \{$/{f=1} f{print; if ($0=="}") exit}' "$1"; }
if command diff <(ext "$S/hook.sh") <(ext "$S/tmpl.sh") >/dev/null 2>&1; then echo "FAIL-no-drift-detected"; rm -rf "$S"; exit 1; else echo "AC2: drift correctly detected on scratch mutation"; fi
# real files still identical (untouched):
command diff <(ext .claude/hooks/verify-all.sh) <(ext skills/setup/templates/verify-all-stop-hook.sh.template) >/dev/null 2>&1 && echo "real files still in sync" || { echo FAIL-real-files-diverged; rm -rf "$S"; exit 1; }
rm -rf "$S"
git status --porcelain skills/setup/templates/verify-all-stop-hook.sh.template | command grep -q . && { echo FAIL-template-mutated; exit 1; } || echo "template untouched"
echo "T1 PASS"
```
(Note the scratch mutation targets line 200, which falls inside emit_drift_json's body [L168-209] — the "install jq or python3 for full fidelity" comment; adjust only if that line moved. The test never writes the repo files.)
**UI:** no

### T2: Qualify the now-false "NOT enforced" statement in CONTRIBUTING.md (~3 min)
**Files:** CONTRIBUTING.md
**Depends on:** T1
**Action:** Update `CONTRIBUTING.md:208`'s "intentionally NOT enforced" sentence so it no longer contradicts the new check — qualify to whole-file and point at the function-scoped check. Do NOT renumber the enumeration (avoids the "Check 8" name collision; the list's broader staleness is out of scope).
**Details:** In item 6 of the structural-invariants list, the sentence currently reads:
`**A separate, unrelated pair — \`verify-all-stop-hook.sh.template\` ↔ dogfood \`verify-all.sh\` — is intentionally NOT enforced** (different files, different purpose): per \`docs/planning/epics/complete/E03-trust-and-ergonomics.md\` section \`#### E03.S2: Stop-hook-v1 maturity check completion\` under \`### Trust hardening cluster\`, the dogfood "stays as-is (project-specific drift checks for the plugin's own development); this story produces a separate, project-agnostic template."`
Replace the bold lead only — change `is intentionally NOT enforced** (different files, different purpose):` to `is intentionally NOT enforced as whole files** (different files, different purpose) — but their shared \`emit_drift_json\` function IS sync-checked (function-scoped; added for #75, since the silent divergence of exactly that function was the #68 root cause):` and leave the remainder of the sentence (the E03.S2 rationale quote) unchanged.
Do not change the "seven structural invariants" count or add an enumerated item (out of scope — see plan Design notes; the count is already inaccurate for unrelated reasons).
**Verify:**
```
cd /Users/nickkirkes/rowdycloud/code/roughly
command grep -qF 'is intentionally NOT enforced as whole files' CONTRIBUTING.md || { echo FAIL-not-qualified; exit 1; }
command grep -qF 'shared `emit_drift_json` function IS sync-checked' CONTRIBUTING.md || { echo FAIL-no-pointer; exit 1; }
command grep -qF 'E03.S2: Stop-hook-v1 maturity check completion' CONTRIBUTING.md || { echo FAIL-rationale-lost; exit 1; }
echo "T2 PASS"
```
**UI:** no

## Blast Radius
- **Do NOT modify:** the `emit_drift_json` function body in either file (it is the thing being protected; keep the two byte-identical), any other verify-all check, the final `emit_drift_json` call / emit block, `skills/setup/templates/verify-all-stop-hook.sh.template` (read-only from the check), the CONTRIBUTING "seven invariants" count/enumeration (out of scope — see Design notes).
- **Watch for:** (a) the awk pattern must be embedded verbatim (`\{$` start anchor, `$0=="}"` stop) — a looser pattern risks truncation or false-match; (b) no process substitution in the committed check (portability + matches existing idioms) — process substitution is fine in the *Verify* test which runs under bash; (c) verify-all.sh must still emit 0 bytes after the change (the new check is silent because the functions match today); (d) shimmed grep/diff — use `command grep`/`command diff`.

## Conventions
- No build/test harness — the inline `bash -n` + live-hook-run + scratch-copy induced-divergence Verify is the validation (consistent with how verify-all.sh changes are checked; mirrors the #68 restricted-PATH inline test pattern).
- New known-pitfalls entry (silent dogfood-hook↔template divergence, now guarded) is captured at Stage 8 wrap-up via the doc-writer question, not as a plan task.
