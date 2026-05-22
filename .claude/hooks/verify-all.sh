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

# Path drift: agents/ should not reference legacy .ruckus/known-pitfalls
if rg -q '\.ruckus/known-pitfalls' agents/ 2>/dev/null; then
  issues="${issues}- stale .ruckus/known-pitfalls reference in agents/ (S2.3 drift)\n"
fi

# Skill line cap (300)
for f in skills/*/SKILL.md; do
  n=$(wc -l < "$f")
  [ "$n" -gt 300 ] && issues="${issues}- $f: $n lines exceeds 300 cap\n"
done

# Agent word cap (500)
for f in agents/*.md; do
  n=$(wc -w < "$f")
  [ "$n" -gt 500 ] && issues="${issues}- $f: $n words exceeds 500 cap\n"
done

# HTML comment integrity in agent-preamble.md
preamble="agents/agent-preamble.md"
opens=$(grep -c '<!--' "$preamble" 2>/dev/null || echo 0)
closes=$(grep -c '\-\->' "$preamble" 2>/dev/null || echo 0)
if [ "$opens" != "1" ] || [ "$closes" != "1" ]; then
  issues="${issues}- agent-preamble.md HTML comment broken: $opens openers, $closes closers\n"
fi

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

# plan-mode-gate hook-pair byte-identity.
# Note: a DIFFERENT pair — verify-all-stop-hook.sh.template ↔ dogfood verify-all.sh —
# is intentionally NOT checked here (per E03.S2; see CONTRIBUTING.md "Stop hook drift checks").
if [ -f .claude/hooks/plan-mode-gate.sh ] && [ -f skills/setup/templates/plan-mode-gate.sh.template ]; then
  if ! diff -q .claude/hooks/plan-mode-gate.sh skills/setup/templates/plan-mode-gate.sh.template >/dev/null 2>&1; then
    issues="${issues}- plan-mode-gate hook drift: .claude/hooks/plan-mode-gate.sh and skills/setup/templates/plan-mode-gate.sh.template differ (run \`diff\` for details)\n"
  fi
fi

# .roughly/known-pitfalls.md organize-suggestion threshold (closes E03.S3 manual-edit coverage gap).
# Bidirectional sync: matching policy parameter in agents/doc-writer.md Process step 5
# ("Organize suggestion"). Update both if the threshold changes.
PITFALLS_ORGANIZE_THRESHOLD=80
if [ -f .roughly/known-pitfalls.md ]; then
  n=$(wc -l < .roughly/known-pitfalls.md)
  if [ "$n" -gt "$PITFALLS_ORGANIZE_THRESHOLD" ]; then
    issues="${issues}- .roughly/known-pitfalls.md is $((n)) lines (>${PITFALLS_ORGANIZE_THRESHOLD} threshold) — consider organizing\n"
  fi
fi

emit_drift_json() {
  local m="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -nc --arg m "$m" '{systemMessage: $m}'
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c 'import json,sys; print(json.dumps({"systemMessage": sys.argv[1]}))' "$m"
  fi
  # If neither is available, drop the structured output rather than emit
  # malformed JSON. The hook still exits 0 below; drift is detected on
  # the next run when a JSON encoder is available.
}

if [ -n "$issues" ]; then
  msg=$(printf 'verify-all drift detected:\n%b' "$issues")
  emit_drift_json "$msg" || true
fi
exit 0
