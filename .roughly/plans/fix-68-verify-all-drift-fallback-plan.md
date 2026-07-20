# Fix Plan: #68 — verify-all.sh drift-report fallback when no jq/python3

Plan-format-version: 1

## Root Cause

`.claude/hooks/verify-all.sh`'s `emit_drift_json` (L160–170) emits the drift report only through `jq` or `python3`; when neither is on PATH it produces nothing, and the caller (`if [ -n "$issues" ]` … `exit 0`, L172–176) falls through silently — so on a minimal/BusyBox env or PATH misconfig the Stop hook becomes a total no-op that drops every drift finding. The consumer-facing template sibling `skills/setup/templates/verify-all-stop-hook.sh.template` (L54–95) was already hardened with a **3-tier fallback** (jq → python3 → hand-built JSON on stdout with escaping), but the dogfood copy was never updated — a "backport-from-template" drift (`.roughly/known-pitfalls.md:142`). Fix: port the template's `emit_drift_json` verbatim into the dogfood script.

## Channel rationale (AC-driven)

The hook's only surfacing channel is **stdout JSON** (`{systemMessage}`), which Claude Code parses (file header L4: "Outputs JSON with systemMessage … silent otherwise"). A plain-text-to-stderr fallback would satisfy AC2/AC3 but **fail AC1** — stderr is not read as the hook's message channel, so drift would still not surface. The template's hand-built-JSON-on-stdout tier (strip control chars, escape `\ " \n \t \r`) satisfies **all three ACs**: AC1 (drift surfaces on the real channel), AC2 (exit 0 preserved — call site unchanged), AC3 (escaping guarantees well-formed JSON).

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| .claude/hooks/verify-all.sh | Modify | T1 |

## Baseline facts (captured 2026-07-20, branch fix/68-verify-all-drift-fallback)
- Broken function: `.claude/hooks/verify-all.sh:160–170` (the `if command -v jq … elif python3 …` two-tier form with the "drop the structured output" comment).
- Reference (source of the correct pattern; DO NOT modify): `skills/setup/templates/verify-all-stop-hook.sh.template:54–95`.
- Call site `.claude/hooks/verify-all.sh:172–176` builds `msg=$(printf 'verify-all drift detected:\n%b' "$issues")` then `emit_drift_json "$msg"` — identical to the template's caller, so the ported function is signature-compatible; the call site does NOT change.
- The template port introduces one new external tool, `tr` (POSIX-standard, present on BusyBox); all other tools already used.
- Running verify-all.sh today always produces at least one drift line (the `.roughly/known-pitfalls.md` >80-line advisory, currently ~192 lines), so `$issues` is reliably non-empty for the Verify test — no need to manufacture drift.

## Tasks

### T1: Port the template's 3-tier `emit_drift_json` into verify-all.sh (~4 min)
**Files:** .claude/hooks/verify-all.sh
**Action:** Replace the current two-tier `emit_drift_json` function (L160–170, from `emit_drift_json() {` through its closing `}`) with the template's three-tier version — copied from `skills/setup/templates/verify-all-stop-hook.sh.template:54–95` (port by diffing against the reference, per `.roughly/known-pitfalls.md:142`, not by re-deriving). Do NOT touch the call site (L172–176) or the final `exit 0`.
**Details:** The new function body (`verbatim:` — copy from the template reference; reproduced here for the implementer):
```
emit_drift_json() {
  local m="$1" out=""
  # Each encoder attempt captures stdout into $out via $(...) and only
  # commits the output on exit-0. A runtime failure (jq OOM, python3
  # broken install, etc.) falls through to the next encoder rather than
  # silently emitting nothing — the prior structure ('if command -v jq;
  # then jq ...; elif python3 ...') would produce no output when jq
  # existed but failed at runtime, defeating the hook's enforcement
  # purpose.

  if command -v jq >/dev/null 2>&1; then
    if out=$(jq -nc --arg m "$m" '{systemMessage: $m}' 2>/dev/null); then
      printf '%s\n' "$out"
      return 0
    fi
  fi

  if command -v python3 >/dev/null 2>&1; then
    if out=$(python3 -c 'import json,sys; print(json.dumps({"systemMessage": sys.argv[1]}))' "$m" 2>/dev/null); then
      printf '%s\n' "$out"
      return 0
    fi
  fi

  # Final fallback: hand-build minimal JSON via bash parameter expansion
  # (bash 3+ syntax). Pre-strip all U+0000–U+001F control characters
  # except tab/newline/CR (which we escape explicitly below) so strict
  # JSON parsers accept the output even when input contains ANSI color
  # codes (ESC = 0x1b), form feed, vertical tab, backspace, etc.
  # Cosmetic residue from stripped ANSI sequences (e.g., '[31m'
  # fragments) may remain in the message — the result is a well-formed
  # `systemMessage` the model can always read; install jq or python3
  # for full fidelity.
  local cleaned
  cleaned=$(printf '%s' "$m" | LC_ALL=C tr -d '\000-\010\013-\014\016-\037')
  local escaped="${cleaned//\\/\\\\}"
  escaped="${escaped//\"/\\\"}"
  escaped="${escaped//$'\n'/\\n}"
  escaped="${escaped//$'\t'/\\t}"
  escaped="${escaped//$'\r'/\\r}"
  printf '{"systemMessage":"%s"}\n' "$escaped"
}
```
After the edit, `diff` the two functions to confirm the port is exact (allowing only the surrounding-context/indentation to match the dogfood file — the function body must be byte-identical to the template's).
**Verify:** run the script with a restricted PATH that excludes both encoders, and confirm it still emits valid `{systemMessage}` JSON and exits 0:
```
bash -n .claude/hooks/verify-all.sh || exit 1
TMPBIN="$(mktemp -d)/bin"; mkdir -p "$TMPBIN"
# Discover REAL binaries by probing standard bin dirs directly — do NOT use
# `command -v`, which in a Claude Code session resolves grep/diff to shell
# FUNCTIONS (bare names, no path), producing broken symlinks that misfire the
# script's grep-based checks under the restricted PATH (review finding).
for t in git rg wc grep awk sort diff shasum sha1sum tr bash cat; do
  for d in /usr/bin /bin /usr/local/bin /opt/homebrew/bin /sbin; do
    [ -x "$d/$t" ] && { ln -sf "$d/$t" "$TMPBIN/$t"; break; }
  done
done
# sanity: the restricted PATH genuinely has neither encoder (use bash — it IS in the allowlist)
env -i PATH="$TMPBIN" bash -c 'command -v jq >/dev/null 2>&1 || command -v python3 >/dev/null 2>&1' && { echo "TMPBIN leaked an encoder"; exit 1; }
out="$(cd "$(git rev-parse --show-toplevel)" && env -i PATH="$TMPBIN" HOME="$HOME" bash .claude/hooks/verify-all.sh)"; ec=$?
[ "$ec" = 0 ] || { echo "exit $ec (expected 0)"; exit 1; }
[ -n "$out" ] || { echo "no output (AC1 fail)"; exit 1; }
printf '%s' "$out" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d.get("systemMessage"); print("T1 VERIFY PASS: valid JSON + systemMessage, exit 0, no-encoder path")'
```
(The JSON validation runs in the normal shell where python3 exists; only the script-under-test runs under the encoder-free `$TMPBIN`. AC1 = non-empty output; AC2 = exit 0; AC3 = `json.load` succeeds → well-formed.)
**UI:** no

## Blast Radius
- **Do NOT modify:** the call site `.claude/hooks/verify-all.sh:172–176` or the final `exit 0` (already correct and compatible); any other check in the script; the template `skills/setup/templates/verify-all-stop-hook.sh.template` (it is the reference — already correct, and intentionally not byte-identical to the dogfood per CONTRIBUTING.md:208).
- **Watch for:** `LC_ALL=C` on the `tr` control-char strip (locale-dependent byte-range handling — keep it exactly as the template has it); the ported function must keep `return 0` after each successful encoder tier (so a working jq/python3 short-circuits before the hand-built fallback).

## Conventions
- Backport-from-template: port by diffing against the reference (`.roughly/known-pitfalls.md:142`), not re-deriving — the function body is copied verbatim from the template.
- No automated test harness exists (tests/fixtures/ is fixture-only); the inline restricted-PATH Verify is the validation, consistent with how verify-all.sh changes are checked in this repo.
- Out of scope (noted, not done): there is no drift check keeping the dogfood and template `emit_drift_json` copies in sync — the very gap that let this bug persist. A lightweight function-level sync check is a reasonable **follow-up**, but #68 is scoped to the fallback fix only.
