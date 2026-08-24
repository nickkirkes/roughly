#!/usr/bin/env bash
# E07.S6.AC8 — executable behavioural check of the Stage 1 epic-vs-story intake guard.
#
# Why this is a script and not prose in the epic: AC8's procedure is security-sensitive
# shell (sandboxing, credential scoping, temp-dir lifetime, exit-status handling). Twelve
# review rounds put nine defects in it while it lived as markdown — unapplied sandbox
# wrappers, inert flags, unreachable cleanup, an uninitialised variable, placeholder paths
# that were shell redirection. Prose cannot be shellcheck'd or executed. This can.
#
# Usage:  bash scripts/verify-intake-guard.sh            # arms 1-9 + 12-13 (print mode)
#         bash scripts/verify-intake-guard.sh --interactive   # + arms 10-11
#
# Arms: 1-4 one per accepted OQ8 heading form · 5 story-ID enumeration · 6 negative
#       control · 7-9 fix-side mirror · 10-11 interactive confirm path · 12-13 --ci
#       must-not-hang, run unconditionally in both modes.
#
# Requires: coreutils timeout (macOS: brew install coreutils), ANTHROPIC_API_KEY,
#           /usr/bin/sandbox-exec.
# Cost: 11 print-mode arms x $0.50 cap = $5.50, plus 2 interactive arms bounded only
#       by a 180s wall clock (--max-budget-usd is print-mode only) — budget ~$6.50.
#       Arms 12-13 were added after the "~$5 / eleven arms" figure and it was not
#       updated; corrected 2026-08-24.

set -uo pipefail

# Host-side commands run BEFORE the child's env -i, with ANTHROPIC_API_KEY already in
# this process's environment — so git, mktemp, find, cat, rm and the rest were as
# capable of exfiltrating it as claude was, and only claude and timeout were vetted.
# Fix the PATH for everything, first thing. (Fixed 2026-08-21.)
CALLER_PATH=$PATH          # only used to LOCATE claude, which lives outside the
PATH=/usr/bin:/bin:/usr/sbin:/sbin   # trusted PATH by design (nvm/homebrew)
export PATH

REPO=$(cd "$(git rev-parse --show-toplevel)" && pwd -P) || { echo 'FAIL: not in a git repo'; exit 1; }
cd "$REPO" || exit 1

# ── preconditions ────────────────────────────────────────────────────────────
[ -n "${ANTHROPIC_API_KEY:-}" ] || { echo 'FAIL: ANTHROPIC_API_KEY unset'; exit 1; }

TRUSTED_PATH=/usr/bin:/bin:/usr/sbin:/sbin
REAL_HOME=$HOME

# Resolve every binary we will run, then check nobody but the owner can rewrite it.
# Resolving from the caller's PATH and only *later* handing the child a trusted PATH
# is backwards: the shadowed binary runs first, with the API key already in the
# environment. `claude` legitimately lives outside the trusted PATH (nvm, homebrew),
# so it cannot simply be looked up there — it is resolved, then vetted.
vet() {   # vet <path> — reject if it or its dir is group/other-writable
  local f=$1 d; d=$(dirname "$f")
  [ -x "$f" ] || { echo "FAIL: $(basename "$f") not executable"; return 1; }
  [ -z "$(find "$f" -perm -o+w -o -perm -g+w 2>/dev/null)" ] \
    || { echo "FAIL: $(basename "$f") is group/other-writable"; return 1; }
  # Group-writable counts too: on a shared box a group member can swap the binary.
  # (-maxdepth works fine on BSD find — verified; the gap was the missing -g+w.)
  # Walk every ancestor, not just the immediate parent: a writable grandparent lets an
  # attacker rename the vetted directory out from under us between check and exec.
  # (Fixed 2026-08-24.)
  while [ "$d" != / ]; do
    [ -z "$(find "$d" -maxdepth 0 \( -perm -o+w -o -perm -g+w \) 2>/dev/null)" ] \
      || { echo "FAIL: $(basename "$f") has a group/world-writable ancestor"; return 1; }
    d=$(dirname "$d")
  done
}

if   TIMEOUT=$(command -v timeout);  then :
elif TIMEOUT=$(PATH=$CALLER_PATH command -v timeout || PATH=$CALLER_PATH command -v gtimeout); then :
else echo 'FAIL: install coreutils (brew install coreutils) — arms cannot be time-boxed'; exit 1; fi
vet "$TIMEOUT" || exit 1

SANDBOX=/usr/bin/sandbox-exec
[ -x "$SANDBOX" ] || { echo 'FAIL: sandbox-exec unavailable — no sandbox, no arm'; exit 1; }

CLAUDE=$(PATH=$CALLER_PATH command -v claude) || { echo 'FAIL: claude not on PATH'; exit 1; }
CLAUDE=$(cd "$(dirname "$CLAUDE")" && pwd -P)/$(basename "$CLAUDE")
vet "$CLAUDE" || exit 1
# The sandbox denies /Users wholesale, but claude itself usually lives there (nvm,
# homebrew). Allow exactly its own tree back, nothing wider.
# Just the bin dir, not the whole install root. Reopening dirname(dirname(claude))
# handed back a user-owned tree (node_modules, caches) that Read/Grep/Glob could then
# be steered through — broader than the documented repo-and-scratch confinement.
# Verified claude still loads with only its bin dir readable. (Narrowed 2026-08-21.)
CLAUDE_BIN=$(dirname "$CLAUDE")
# The child PATH gets claude's own bin dir prepended. On this machine claude is a native
# binary and runs on the system PATH alone, but npm/nvm/homebrew installs ship a JS shim
# whose `node` sits in that same dir — with a system-only PATH those launchers cannot
# resolve their runtime and every arm dies before reaching the plugin. The dir is already
# vetted above and already read-allowed in the profile, so this widens nothing new.
CHILD_PATH="$CLAUDE_BIN:$TRUSTED_PATH"

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

# Drop the key for the duration of the checkout. Repository-controlled git config —
# filters, clean/smudge, hooks — executes during `worktree add`, and until now it did
# so with ANTHROPIC_API_KEY still in this process's environment. -c disables the two
# config surfaces that run code; env -u removes the key regardless. (Fixed 2026-08-24.)
env -u ANTHROPIC_API_KEY git -c core.fsmonitor=false -c filter.lfs.smudge= \
    -c filter.lfs.process= -c core.hooksPath=/dev/null \
    worktree add --detach "$WT" HEAD >/dev/null 2>&1 \
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
(allow network-outbound (remote tcp "*:443"))   ; port 443 only — NOT TLS enforcement:
;; the sandbox cannot inspect the protocol, so plaintext on 443 is still permitted.
;; Port restriction is the available control, not a guarantee. (Relabelled 2026-08-24.)
(allow file-read*)
(deny  file-read* (subpath "/Users") (subpath "/private/tmp")
                  (subpath "/private/var") (subpath "/private/etc") (subpath "/etc"))
(allow file-read* (subpath (param "PLUGINDIR")) (subpath (param "CLAUDEBIN")))
(allow file-read* file-write* (subpath (param "OWNED")))
(allow file-write* (literal "/dev/null") (literal "/dev/tty")
                   (literal "/dev/stdout") (literal "/dev/stderr"))
SBEOF

# Arms run INSIDE the worktree, against the worktree's own plugin copy. Running them
# from $REPO with --plugin-dir "$REPO" made the worktree dead weight: the sessions saw
# the live checkout, and since the profile only permits writes under $OWNED, any
# pipeline write would have been denied against the wrong tree anyway. The worktree is
# at HEAD, which is what AC8 means by "commit the S6 work locally first".
# (Fixed 2026-08-19.)
confined() {   # confined <prompt>  → runs claude sandboxed in $WT, prints combined output
  ( cd "$WT" || exit 1
    "$TIMEOUT" 120 "$SANDBOX" -f "$OWNED/confine.sb" \
      -D OWNED="$OWNED" -D PLUGINDIR="$WT" -D CLAUDEBIN="$CLAUDE_BIN" \
      env -i PATH="$CHILD_PATH" HOME="$OWNED/home" TERM=dumb \
             ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
      "$CLAUDE" --bare --plugin-dir "$WT" --no-session-persistence \
                --max-budget-usd 0.50 --strict-mcp-config \
                --allowed-tools "$ALLOWLIST" -p "$1" 2>&1 )
}
mkdir -p "$OWNED/home"

# Prove the profile before trusting it. If this can read the real home, stop.
sb() { "$SANDBOX" -f "$OWNED/confine.sb" -D OWNED="$OWNED" -D PLUGINDIR="$WT" -D CLAUDEBIN="$CLAUDE_BIN" "$@"; }
sb /bin/echo probe >/dev/null 2>&1 \
  || { echo 'FAIL: sandbox profile cannot exec — refusing to run'; exit 1; }
! sb /bin/ls "$REAL_HOME" >/dev/null 2>&1 \
  || { echo 'FAIL: sandbox does not deny the real home — refusing to run'; exit 1; }
sb /bin/cat "$WT/CLAUDE.md" >/dev/null 2>&1 \
  || { echo 'FAIL: sandbox denies the worktree — arms could not read their inputs'; exit 1; }

# ── assertion strings, owned by E07.S6.AC1 ───────────────────────────────────
CLASSIFIER='Stage 1 intake: epic-shaped input detected'
# Full string including the options, per AC1. Asserting only the prefix ending in '?'
# let a prompt that omits '(narrow / monolithic)' pass every positive arm — and the
# options are what make it answerable. (Fixed 2026-08-21.)
QUESTION='Narrow to one story, or confirm monolithic treatment? (narrow / monolithic)'
PROCEEDED='Is this the correct'

# Frozen here, deliberately NOT read from the environment: an exported ALLOWLIST
# containing Bash would let the model run commands in a process that holds the API
# key and has outbound network. Widening is a reviewable edit to this line, not a
# caller-side override.
readonly ALLOWLIST='Read,Grep,Glob'

# ── inputs ───────────────────────────────────────────────────────────────────
# Repo-relative: resolved inside $WT, which is where the arms now run.
E06=docs/planning/epics/complete/E06-anchoring-closure-and-ci-coverage.md
E06A=docs/planning/epics/complete/E06-anchoring-closure-and-ci-coverage-audit.md
E07=docs/planning/epics/E07-codification-closeout-and-release-gate-repair.md
for f in "$E06" "$E06A" "$E07"; do
  [ -f "$WT/$f" ] || { echo "FAIL: input missing from the worktree: $(basename "$f")"; exit 1; }
done

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
  # Line numbers, not booleans: the classifier must come BEFORE the question, or the
  # gate was not the classifier's. Independent substring hits also pass on reordered
  # or incidental prose. (Added 2026-08-18.)
  local lc lq lp hasC hasQ hasP
  lc=$(grep -nE "^[^A-Za-z]*$CLASSIFIER" <<<"$out" | head -1 | cut -d: -f1)
  lq=$(grep -nF  "$QUESTION"             <<<"$out" | head -1 | cut -d: -f1)
  lp=$(grep -nF  "$PROCEEDED"            <<<"$out" | head -1 | cut -d: -f1)
  hasC=$([ -n "$lc" ] && echo 1 || echo 0)
  hasQ=$([ -n "$lq" ] && echo 1 || echo 0)
  hasP=$([ -n "$lp" ] && echo 1 || echo 0)
  if [ "$expect" = pos ] && [ -n "$lc" ] && [ -n "$lq" ] && [ "$lc" -ge "$lq" ]; then
    echo "FAIL arm $n: question precedes classifier (lines $lq, $lc)"; failed=$((failed+1)); return
  fi
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
arm 4 build "two-story.md"       pos
arm 5 build "id-enum.md"         pos    # AC1's second trigger: story-ID enumeration
arm 6 build "one-story.md"       neg    # negative control
arm 7 fix   "$E06"               pos    # fix side: insertion points differ structurally
arm 8 fix   "id-enum.md"         pos
arm 9 fix   "one-story.md"       neg

# Arms 12-13: --ci must NOT hang. AC1's positional insertion point exists because a
# gate placed before the CI_MODE assignment blocks every --ci run — yet no arm used
# --ci at all, so the regression the rule was written to prevent went untested.
# Under --ci every gate auto-proceeds, so an epic-shaped input must classify AND
# proceed rather than stop at the sub-gate. A hang surfaces as timeout 124.
ci_arm() {   # ci_arm <n> <pipeline>
  local n=$1 pipe=$2 out rc
  out=$(confined "/roughly:$pipe --ci $E06"); rc=$?
  if [ "$rc" -eq 124 ]; then
    echo "FAIL arm $n: --ci hung — classifier is almost certainly above the CI_MODE assignment"
    failed=$((failed+1)); return
  fi
  [ "$rc" -eq 0 ] || { echo "FAIL arm $n: --ci exited $rc"; failed=$((failed+1)); return; }
  # Both, not just continuation: asserting PROCEEDED alone passes a build where the
  # classifier was deleted outright, since the pre-existing Stage 1 gate still fires.
  # Under --ci the sub-gate auto-proceeds, so the marker must appear AND the run go on.
  # (Fixed 2026-08-24.)
  if grep -qE "^[^A-Za-z]*$CLASSIFIER" <<<"$out" && grep -qF "$PROCEEDED" <<<"$out"; then
    echo "pass arm $n (--ci classified and proceeded)"; pass=$((pass+1))
  elif grep -qF "$PROCEEDED" <<<"$out"; then
    echo "FAIL arm $n: --ci proceeded but never classified — classifier missing or broken"
    failed=$((failed+1))
  else
    echo "FAIL arm $n: --ci did not reach the Stage 1 gate"; failed=$((failed+1))
  fi
}
ci_arm 12 build
ci_arm 13 fix


interactive_incomplete=0
if [ "${1:-}" = --interactive ]; then
  # Arms 10-11 cannot be automated: answering a gate needs a second turn, which print
  # mode has no way to supply. Printing instructions and then exiting 0 would report a
  # complete verification with two required arms unrun — so this marks the run
  # INCOMPLETE and the script exits non-zero unless the operator confirms both arms
  # passed by re-invoking with ARMS_10_11_PASSED=yes. (Fixed 2026-08-18.)
  interactive_incomplete=1
  cat <<'EOF'

Arms 10-11 (confirm path) are interactive: a gate needs a second turn, which print
mode cannot supply. Run each by hand from inside the worktree, answer the sub-gate
with monolithic confirmation, and confirm Stage 1 then proceeds. Note that
--max-budget-usd and --no-session-persistence are print-mode only, so these arms are
time-boxed instead and their sessions live under $OWNED/home, removed by the trap.
EOF
  echo "  worktree: (scratch, removed on exit)"   # path carries the operator's username
  # Drive the arms here when a terminal is available, rather than asking the operator
  # to reproduce the invocation and hand back logs we cannot attribute to a real
  # session. Raw output stays inside $OWNED (trap-removed); only markers are kept.
  # (Fixed 2026-08-21.)
  if [ -t 0 ] && [ -t 1 ]; then
    for spec in "10 build" "11 fix"; do
      set -- $spec; a=$1; pipe=$2
      echo "--- arm $a ($pipe): answer the sub-gate with monolithic confirmation, then exit ---"
      # 180s, not 300: --max-budget-usd is print-mode only, so wall-clock is the ONLY
      # ceiling these two arms have. At ~$0.50/arm the advertised total assumes they
      # are short; an unbounded interactive session breaks that. (Tightened 2026-08-24.)
      ( cd "$WT" || exit 1
        "$TIMEOUT" 180 "$SANDBOX" -f "$OWNED/confine.sb" \
          -D OWNED="$OWNED" -D PLUGINDIR="$WT" -D CLAUDEBIN="$CLAUDE_BIN" \
          env -i PATH="$CHILD_PATH" HOME="$OWNED/home" TERM="${TERM:-xterm}" \
                 ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
          "$CLAUDE" --bare --plugin-dir "$WT" --strict-mcp-config \
                    --allowed-tools "$ALLOWLIST" "/roughly:$pipe $E06" 2>&1 ) \
        | tee "$OWNED/raw$a.log" >/dev/null
      # Exit status of claude, not of tee — a timed-out session that happened to print
      # the markers was being accepted by the log-only assertions. (Fixed 2026-08-24.)
      irc=${PIPESTATUS[0]}
      # Extract the matched marker SUBSTRING, not the whole line: a line can carry a
      # marker alongside session content, which "markers, not transcripts" forbids.
      : > "$OWNED/arm$a.log"
      for m in "$CLASSIFIER" "$QUESTION" "$PROCEEDED"; do
        grep -oF "$m" "$OWNED/raw$a.log" | head -1 >> "$OWNED/arm$a.log" || true
      done
      rm -f "$OWNED/raw$a.log"
      if [ "$irc" -eq 124 ]; then
        echo "FAIL arm $a: interactive session timed out"; failed=$((failed+1))
      elif [ "$irc" -ne 0 ]; then
        echo "FAIL arm $a: interactive session exited $irc"; failed=$((failed+1))
      fi
    done
    ARMS_10_11_EVIDENCE=$OWNED
  fi
fi

echo "---"
echo "arms passed: $pass, failed: $failed"
[ "$failed" -eq 0 ] || exit 1

if [ "$interactive_incomplete" -eq 1 ]; then
  # Evidence, not an assertion by the operator. ARMS_10_11_PASSED=yes was an
  # honour-system flag: it recorded a pass without anything having run, which is the
  # failure mode arms 10-11 exist to prevent. The manual runs must leave their marker
  # lines in two files, and those are asserted here exactly as arms 1-9 are.
  # (Fixed 2026-08-19.)
  ev=${ARMS_10_11_EVIDENCE:-}
  # Produced above when a terminal was available; otherwise operator-supplied.
  # Operator-supplied logs CANNOT be attributed to a real session — hand-written files
  # containing the three markers in order pass identically. There is no fix inside this
  # script: attribution would need a session artifact only claude can mint. So the
  # provenance is recorded and the two paths are not treated as equivalent.
  if [ "$ev" = "$OWNED" ]; then prov="script-driven"; else prov="operator-supplied (UNATTRIBUTED)"; fi
  [ -n "$ev" ] && [ -d "$ev" ] || {
    echo 'INCOMPLETE: arms 10-11 not executed.'
    echo 'Run each by hand as described above, capturing the session output to'
    echo '  <dir>/arm10.log and <dir>/arm11.log, then re-invoke with'
    echo '  ARMS_10_11_EVIDENCE=<dir>'
    exit 2; }
  for a in 10 11; do
    f="$ev/arm$a.log"
    [ -s "$f" ] || { echo "FAIL arm $a: no evidence at arm$a.log"; failed=$((failed+1)); continue; }
    lc=$(grep -nE "^[^A-Za-z]*$CLASSIFIER" "$f" | head -1 | cut -d: -f1)
    lq=$(grep -nF  "$QUESTION"             "$f" | head -1 | cut -d: -f1)
    lp=$(grep -nF  "$PROCEEDED"            "$f" | head -1 | cut -d: -f1)
    if [ -z "$lc" ] || [ -z "$lq" ] || [ -z "$lp" ]; then
      echo "FAIL arm $a: evidence lacks classifier/question/proceeded"; failed=$((failed+1))
    elif [ "$lc" -ge "$lq" ] || [ "$lq" -ge "$lp" ]; then
      echo "FAIL arm $a: markers out of order (classifier $lc, question $lq, proceeded $lp)"
      failed=$((failed+1))
    else
      echo "pass arm $a (evidence: $prov)"; pass=$((pass+1))
    fi
  done
  echo "arms passed: $pass, failed: $failed"
  [ "$failed" -eq 0 ] || exit 1
fi
