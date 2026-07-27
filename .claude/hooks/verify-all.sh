#!/usr/bin/env bash
# Stop hook: structural verify-all for the roughly plugin.
# Fires after every Claude turn. Non-blocking — informational only.
# Outputs JSON with systemMessage when drift is detected; silent otherwise.

shopt -s nullglob  # globs that match nothing expand to empty, not literal pattern

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$ROOT" ] || [ ! -f "$ROOT/.claude-plugin/plugin.json" ]; then
  exit 0  # not in the roughly repo — silent no-op
fi
cd "$ROOT" 2>/dev/null || exit 0  # exit-0 contract: silent no-op on cd failure (see template L16–25)

issues=""

# Skill line cap (300)
for f in skills/*/SKILL.md; do
  n=$(wc -l < "$f")
  [ "$n" -gt 300 ] && issues="${issues}- $f: $n lines exceeds 300 cap\n"
done

# Agent word cap (650)
for f in agents/*.md; do
  n=$(wc -w < "$f")
  [ "$n" -gt 650 ] && issues="${issues}- $f: $n words exceeds 650 cap\n"
done

# HTML comment integrity in agent-preamble.md
preamble="agents/agent-preamble.md"
opens=$(grep -c '<!--' "$preamble" 2>/dev/null || echo 0)
closes=$(grep -c '\-\->' "$preamble" 2>/dev/null || echo 0)
if [ "$opens" != "1" ] || [ "$closes" != "1" ]; then
  issues="${issues}- agent-preamble.md HTML comment broken: $opens openers, $closes closers\n"
fi

# plan-mode-gate hook-pair presence + byte-identity.
# Both files MUST exist in this plugin source repo; missing either is a structural break
# (plan-mode protection silently unregistered — the failure mode ADR-009 was written to prevent).
# Note: a DIFFERENT pair — verify-all-stop-hook.sh.template ↔ dogfood verify-all.sh —
# is intentionally NOT byte-identical as whole files (per E03.S2; see CONTRIBUTING.md "Stop hook drift checks"),
# but their shared emit_drift_json function IS sync-checked just below (#75; the #68 root cause).
if [ ! -f skills/setup/templates/plan-mode-gate.sh.template ]; then
  issues="${issues}- plan-mode-gate template missing: skills/setup/templates/plan-mode-gate.sh.template — Check 2 canonical source absent\n"
elif [ ! -f .claude/hooks/plan-mode-gate.sh ]; then
  issues="${issues}- plan-mode-gate hook missing: .claude/hooks/plan-mode-gate.sh — plan-mode protection may be unregistered\n"
elif ! diff -q .claude/hooks/plan-mode-gate.sh skills/setup/templates/plan-mode-gate.sh.template >/dev/null 2>&1; then
  issues="${issues}- plan-mode-gate hook drift: .claude/hooks/plan-mode-gate.sh and skills/setup/templates/plan-mode-gate.sh.template differ (run \`diff\` for details)\n"
fi

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

# .roughly/known-pitfalls.md organize-suggestion threshold (closes E03.S3 manual-edit coverage gap).
# Bidirectional sync: matching policy parameter in agents/doc-writer.md Process step 5
# ("Organize suggestion"). Update both if the threshold changes.
# Value 300 mirrors the SKILL.md line cap: known-pitfalls is an append-only corpus, so this flags "genuinely large" (was 80, permanent noise from ~36 lines up).
PITFALLS_ORGANIZE_THRESHOLD=300
if [ -f .roughly/known-pitfalls.md ]; then
  n=$(wc -l < .roughly/known-pitfalls.md)
  if [ "$n" -gt "$PITFALLS_ORGANIZE_THRESHOLD" ]; then
    issues="${issues}- .roughly/known-pitfalls.md is $((n)) lines (>${PITFALLS_ORGANIZE_THRESHOLD} threshold) — consider organizing\n"
  fi
fi

# build/fix CRITICAL preamble byte-identity (ADR-009 sync pair; carries the closed-world
# gate prohibition + anti-laundering rule — ADR-015). The GATE PROTOCOL section check below
# does NOT cover this line; without this check a silent revert of one preamble to permit
# AskUserQuestion would pass undetected (the exact F1 regression).
critical_build=$(grep -m1 -F '**CRITICAL:**' skills/build/SKILL.md 2>/dev/null)
critical_fix=$(grep -m1 -F '**CRITICAL:**' skills/fix/SKILL.md 2>/dev/null)
if [ -z "$critical_build" ] || [ "$critical_build" != "$critical_fix" ]; then
  issues="${issues}- CRITICAL preamble drift: skills/build/SKILL.md and skills/fix/SKILL.md line differ or are missing (ADR-009 byte-identical pair — carries the closed-world gate prohibition)\n"
fi
# F1 content tripwire (parity with the F2 boundary content check below): byte-identity alone
# does not catch a COORDINATED revert of BOTH preambles to an enumerated-only ban — they would
# stay identical and pass the check above while reintroducing F1. Assert the load-bearing
# closed-world + anti-laundering phrases are actually present. This is a phrase tripwire, not
# semantic validation (deep prose strength remains a review responsibility — ADR-015).
if [ -n "$critical_build" ]; then
  case "$critical_build" in
    *"structured or interactive prompt tool"*"never treat wording you authored"*) : ;;
    *) issues="${issues}- CRITICAL preamble weakened: skills/build|fix SKILL.md no longer states the closed-world gate prohibition + anti-laundering rule (expected phrases: 'structured or interactive prompt tool', 'never treat wording you authored')\n" ;;
  esac
fi

# Shared procedural reference drift (ADR-012). Four modes:
#   (a) skills/shared/ directory missing (directed diagnostic)
#   (b) either shared file missing
#   (c) either consumer's Read directive absent or not at line-start within 3 lines of
#       its section heading (ADR-012/AC5). awk index()==1 enforces line-start with
#       fixed-string match — regex metacharacters in filenames cannot bypass.
#   (d) either consumer contains inline duplication of a shared-file load-bearing phrase.
# Bidirectional sync: load-bearing phrases below MUST appear in the shared files too.
if [ ! -d skills/shared ]; then
  issues="${issues}- shared procedural reference drift: skills/shared/ directory missing\n"
else
  for shared in abort-handling.md stage-8-wrap-up.md gate-protocol.md spec-candidate-escalation.md; do
    [ ! -f "skills/shared/${shared}" ] && issues="${issues}- shared procedural reference drift: skills/shared/${shared} missing\n"
  done
  for skill in build fix; do
    for pair in "STAGE 8: WRAP-UP|stage-8-wrap-up.md" "ABORT HANDLING|abort-handling.md" "GATE PROTOCOL|gate-protocol.md" "SPEC-REVISION-CANDIDATE ESCALATION|spec-candidate-escalation.md"; do
      heading="${pair%%|*}"
      shared="${pair##*|}"
      window=$(grep -A 3 "^## ${heading}\$" "skills/${skill}/SKILL.md" 2>/dev/null)
      if [ -z "$window" ]; then
        issues="${issues}- shared procedural reference drift: skills/${skill}/SKILL.md missing ## ${heading} section heading\n"
      elif ! printf '%s\n' "$window" | awk -v p="Read \`\${CLAUDE_PLUGIN_ROOT}/skills/shared/${shared}\`" 'index($0, p) == 1 {f=1} END {exit !f}'; then
        issues="${issues}- shared procedural reference drift: skills/${skill}/SKILL.md missing Read directive for ${shared} at line-start within 3 lines of ## ${heading}\n"
      fi
    done
    if grep -qF 'When the human selects "abort"' "skills/${skill}/SKILL.md" 2>/dev/null; then
      issues="${issues}- shared procedural reference drift: skills/${skill}/SKILL.md contains inline duplication of abort-handling.md content (matched phrase: When the human selects \"abort\")\n"
    fi
    if grep -qF '1. `git add` changed files' "skills/${skill}/SKILL.md" 2>/dev/null; then
      issues="${issues}- shared procedural reference drift: skills/${skill}/SKILL.md contains inline duplication of stage-8-wrap-up.md content (matched phrase: 1. \`git add\` changed files)\n"
    fi
    if grep -qF 'Field constraints keep the block closed-form' "skills/${skill}/SKILL.md" 2>/dev/null; then
      issues="${issues}- shared procedural reference drift: skills/${skill}/SKILL.md contains inline duplication of gate-protocol.md content (matched phrase: Field constraints keep the block closed-form)\n"
    fi
    # Inline local-commit boundary must survive a skipped/compacted Read of stage-8-wrap-up.md (ADR-015, F2 defense-in-depth).
    if ! grep -qF 'never pushes, opens a PR' "skills/${skill}/SKILL.md" 2>/dev/null; then
      issues="${issues}- local-commit boundary drift: skills/${skill}/SKILL.md STAGE 8 is missing the inline never-push boundary sentence (ADR-015)\n"
    fi
    # De-dogfood revert tripwire (issue #72): the pre-T2 epic-file leak phrases must not reappear.
    if grep -qF 'v0.1.X candidates section' "skills/${skill}/SKILL.md" 2>/dev/null; then
      issues="${issues}- de-dogfood regression: skills/${skill}/SKILL.md still names the epic-file escalation target 'v0.1.X candidates section' (issue #72 — escalate via SPEC-REVISION-CANDIDATE ESCALATION)\n"
    fi
    if grep -qF 'appended to the epic file' "skills/${skill}/SKILL.md" 2>/dev/null; then
      issues="${issues}- de-dogfood regression: skills/${skill}/SKILL.md still names the epic-file escalation target 'appended to the epic file' (issue #72 — escalate via SPEC-REVISION-CANDIDATE ESCALATION)\n"
    fi
  done
fi

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

if [ -n "$issues" ]; then
  msg=$(printf 'verify-all drift detected:\n%b' "$issues")
  emit_drift_json "$msg" || true
fi
exit 0
