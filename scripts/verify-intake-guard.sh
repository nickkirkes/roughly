#!/usr/bin/env bash
# E07.S6.AC8 — executable behavioural check of the Stage 1 epic-vs-story intake guard.
#
# Why this is a script and not prose in the epic: AC8's procedure is security-sensitive
# shell (sandboxing, credential scoping, temp-dir lifetime, exit-status handling). Twelve
# review rounds put nine defects in it while it lived as markdown — unapplied sandbox
# wrappers, inert flags, unreachable cleanup, an uninitialised variable, placeholder paths
# that were shell redirection. Prose cannot be shellcheck'd or executed. This can.
#
# Usage:  bash scripts/verify-intake-guard.sh            # arms 1-9 (print mode)
#         bash scripts/verify-intake-guard.sh --interactive   # + arms 10-11 (manual)
#
# Requires: coreutils timeout (macOS: brew install coreutils), ANTHROPIC_API_KEY,
#           /usr/bin/sandbox-exec. Costs ~$5 at four accepted OQ8 heading forms.

set -uo pipefail

REPO=$(cd "$(git rev-parse --show-toplevel)" && pwd -P) || { echo 'FAIL: not in a git repo'; exit 1; }
cd "$REPO" || exit 1

# ── preconditions ────────────────────────────────────────────────────────────
[ -n "${ANTHROPIC_API_KEY:-}" ] || { echo 'FAIL: ANTHROPIC_API_KEY unset'; exit 1; }

if   command -v timeout  >/dev/null; then TIMEOUT=$(command -v timeout)
elif command -v gtimeout >/dev/null; then TIMEOUT=$(command -v gtimeout)
else echo 'FAIL: install coreutils (brew install coreutils) — arms cannot be time-boxed'; exit 1; fi

SANDBOX=/usr/bin/sandbox-exec
[ -x "$SANDBOX" ] || { echo 'FAIL: sandbox-exec unavailable — no sandbox, no arm'; exit 1; }

CLAUDE=$(command -v claude) || { echo 'FAIL: claude not on PATH'; exit 1; }

# A fixed, trusted PATH. Inheriting the caller's PATH while handing the child an API key
# lets any writable PATH entry shadow `claude` or `timeout` and capture the key.
TRUSTED_PATH=/usr/bin:/bin:/usr/sbin:/sbin
REAL_HOME=$HOME

# ── owned scratch, cleaned on every exit path ────────────────────────────────
OWNED=$(cd "$(mktemp -d -t e07s6-verify.XXXXXX)" && pwd -P) || { echo 'FAIL: mktemp'; exit 1; }
WT="$OWNED/wt"
cleanup() {
  git worktree remove --force "$WT" 2>/dev/null || true
  rm -rf "$OWNED" 2>/dev/null || true
  # Report status only — never a path, which carries the operator's username.
  [ -e "$OWNED" ] && echo 'WARN: scratch dir not fully removed' || echo 'cleanup: ok'
}
trap cleanup EXIT INT TERM

git worktree add --detach "$WT" HEAD >/dev/null 2>&1 \
  || { echo 'FAIL: worktree not created'; exit 1; }

# ── sandbox: default-deny reads, allow only what the arms legitimately touch ──
# `(allow default)` with a home-only deny still exposed /tmp, sibling checkouts and /etc.
# Profile tuned empirically, not by inspection — three earlier shapes either failed to
# exec (scoped file-read starves dyld) or left /tmp, /etc and sibling checkouts readable.
# SBPL is last-match-wins: open reads broadly so exec works, deny the sensitive trees,
# then re-open only the repo and this scratch dir. Paths must be RESOLVED (/private/var,
# not /var) because the sandbox matches after symlink resolution.
cat > "$OWNED/confine.sb" <<'SBEOF'
(version 1)
(deny default)
(allow process* signal sysctl-read mach-lookup mach-register ipc-posix-shm)
(allow network-outbound (remote ip))
(allow file-read*)
(deny  file-read* (subpath "/Users") (subpath "/private/tmp"))
(allow file-read* (subpath (param "PLUGINDIR")))
(allow file-read* file-write* (subpath (param "OWNED")))
(allow file-write* (literal "/dev/null") (literal "/dev/tty")
                   (literal "/dev/stdout") (literal "/dev/stderr"))
SBEOF

confined() {   # confined <prompt>  → runs claude sandboxed, prints combined output
  "$TIMEOUT" 120 "$SANDBOX" -f "$OWNED/confine.sb" \
      -D OWNED="$OWNED" -D PLUGINDIR="$REPO" \
      env -i PATH="$TRUSTED_PATH" HOME="$OWNED/home" TERM=dumb \
             ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
      "$CLAUDE" --bare --plugin-dir "$REPO" --no-session-persistence \
                --max-budget-usd 0.50 --strict-mcp-config \
                --allowed-tools "$ALLOWLIST" -p "$1" 2>&1
}
mkdir -p "$OWNED/home"

# Prove the profile before trusting it. If this can read the real home, stop.
sb() { "$SANDBOX" -f "$OWNED/confine.sb" -D OWNED="$OWNED" -D PLUGINDIR="$REPO" "$@"; }
sb /bin/echo probe >/dev/null 2>&1 \
  || { echo 'FAIL: sandbox profile cannot exec — refusing to run'; exit 1; }
! sb /bin/ls "$REAL_HOME" >/dev/null 2>&1 \
  || { echo 'FAIL: sandbox does not deny the real home — refusing to run'; exit 1; }
sb /bin/cat "$REPO/CLAUDE.md" >/dev/null 2>&1 \
  || { echo 'FAIL: sandbox denies the repo — arms could not read their inputs'; exit 1; }

# ── assertion strings, owned by E07.S6.AC1 ───────────────────────────────────
CLASSIFIER='Stage 1 intake: epic-shaped input detected'
QUESTION='Narrow to one story, or confirm monolithic treatment?'
PROCEEDED='Is this the correct'

# Resolve once by dry run, then frozen for every arm (see AC8).
ALLOWLIST=${ALLOWLIST:-'Read,Grep,Glob'}

# ── inputs ───────────────────────────────────────────────────────────────────
E06=docs/planning/epics/complete/E06-anchoring-closure-and-ci-coverage.md
E06A=docs/planning/epics/complete/E06-anchoring-closure-and-ci-coverage-audit.md
E07=docs/planning/epics/E07-codification-closeout-and-release-gate-repair.md

# Arm 4 needs the PRE-AC4 two-story README form; AC4 reduces the in-tree example to one.
cat > "$WT/two-story.md" <<'EOF'
# E02: User Authentication
## Story 1: Login Flow
**AC:** user can log in
## Story 2: Password Reset
**AC:** reset link expires
EOF
cat > "$WT/id-enum.md" <<'EOF'
# Release scope
Deliver E07.S1, E07.S5 and E07.S6 in this pass.
EOF
cat > "$WT/one-story.md" <<'EOF'
# Add Health Endpoint
## Story 1: GET /health
**AC:** returns 200
EOF

pass=0; failed=0
arm() {   # arm <n> <pipeline> <input> <expect: pos|neg>
  local n=$1 pipe=$2 input=$3 expect=$4 out rc
  out=$(confined "/roughly:$pipe $input"); rc=$?
  if [ "$rc" -eq 124 ]; then echo "FAIL arm $n: timed out"; failed=$((failed+1)); return; fi
  if [ "$rc" -ne 0 ];   then echo "FAIL arm $n: claude exited $rc"; failed=$((failed+1)); return; fi
  local hasC hasQ hasP
  grep -qE "^[^A-Za-z]*$CLASSIFIER" <<<"$out" && hasC=1 || hasC=0
  grep -qF  "$QUESTION"             <<<"$out" && hasQ=1 || hasQ=0
  grep -qF  "$PROCEEDED"            <<<"$out" && hasP=1 || hasP=0
  if [ "$expect" = pos ]; then
    [ "$hasC$hasQ$hasP" = "110" ] \
      && { echo "pass arm $n"; pass=$((pass+1)); } \
      || { echo "FAIL arm $n: want CLASSIFIER+QUESTION, no PROCEEDED (got $hasC$hasQ$hasP)"; failed=$((failed+1)); }
  else
    [ "$hasC$hasQ$hasP" = "001" ] \
      && { echo "pass arm $n"; pass=$((pass+1)); } \
      || { echo "FAIL arm $n: want PROCEEDED only (got $hasC$hasQ$hasP)"; failed=$((failed+1)); }
  fi
}

# Arms 1-4: one per accepted OQ8 heading form. Adjust to OQ8's enumeration.
arm 1 build "$E06"               pos
arm 2 build "$E07"               pos
arm 3 build "$E06A"              pos
arm 4 build "$WT/two-story.md"   pos
arm 5 build "$WT/id-enum.md"     pos    # AC1's second trigger: story-ID enumeration
arm 6 build "$WT/one-story.md"   neg    # negative control
arm 7 fix   "$E06"               pos    # fix side: insertion points differ structurally
arm 8 fix   "$WT/id-enum.md"     pos
arm 9 fix   "$WT/one-story.md"   neg

if [ "${1:-}" = --interactive ]; then
  cat <<'EOF'

Arms 10-11 (confirm path) are interactive: a gate needs a second turn, which print
mode cannot supply. Run each by hand from inside the worktree, answer the sub-gate
with monolithic confirmation, and confirm Stage 1 then proceeds. Note that
--max-budget-usd and --no-session-persistence are print-mode only, so these arms are
time-boxed instead and their sessions live under $OWNED/home, removed by the trap.
EOF
  echo "  worktree: \$WT (printed by: echo \"\$WT\")"
fi

echo "---"
echo "arms passed: $pass, failed: $failed"
[ "$failed" -eq 0 ] || exit 1
