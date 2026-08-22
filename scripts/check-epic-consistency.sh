#!/usr/bin/env bash
# E07 planning-artifact consistency check — extracted from the epic 2026-08-21.
# Living in the epic made it layout-sensitive and unrunnable by anything that
# does not first parse markdown out of a fenced block; four of its own bugs
# (self-matching marker, uninitialised var, sed delimiter, watermark scope)
# reached the branch because nothing executed it. Run: bash scripts/check-epic-consistency.sh
# Requires bash (process substitution, ${var:0:n}) and gh.
# Requires bash: uses process substitution and ${var:0:n}. Fenced `sh` until
# 2026-08-19, which would fail under /bin/sh before validating anything.
EPIC=docs/planning/epics/E07-codification-closeout-and-release-gate-repair.md
fail=0

# 1. Predecessor set. Every site that restates it carries a marker comment; AC1's is
#    AUTHORITATIVE, the rest DERIVED. Four regex attempts preceded this and each failed
#    differently — prose cannot tell a restatement from a nearby story list — so the
#    sites are tagged instead. Values must be non-empty so this comment cannot match
#    itself. (Reworked 2026-08-18.)
auth=$(grep -oh 'predecessor-set:AUTHORITATIVE=[A-Za-z0-9,]\+' "$EPIC" | cut -d= -f2 | sort -u)
[ "$(printf '%s\n' "$auth" | grep -c .)" -eq 1 ] \
  || { echo "FAIL: expected exactly one AUTHORITATIVE marker, got: $auth"; fail=1; }

# 1b. A marker can agree while the sentence it annotates says something else, so also
#     compare the story IDs visible on the marker's own line. (Added 2026-08-18.)
while IFS= read -r line; do
  claimed=$(printf '%s' "$line" | grep -o 'predecessor-set:[A-Z]*=[A-Za-z0-9,]\+' | cut -d= -f2)
  # The LAST enumeration (2+ ids) before the marker is the restatement it annotates.
  # Taking every id on the line instead swept in 'S4 not required' and 'S2.AC1'.
  visible=$(printf '%s' "$line" | sed 's/<!--.*//' \
            | grep -oE '(E07\.)?S[0-9]([,/]| and )[ ]*(E07\.)?S[0-9](([,/]| and )[ ]*(E07\.)?S[0-9])*' \
            | tail -1 | grep -oE 'S[0-9]' | paste -sd, -)
  [ "$claimed" = "$visible" ] \
    || { echo "FAIL: marker says $claimed but the restatement reads $visible -- ${line:0:60}"; fail=1; }
  # …and every DERIVED value must equal the AUTHORITATIVE one. Checking each marker only
  # against its own line let all derived views agree on the same WRONG set and pass.
  # (The comparison existed before 1b was added and was dropped in that rewrite; restored
  # 2026-08-18.)
  # Reject unknown types outright. Matching [A-Z]* accepted anything, and only
  # DERIVED was compared to $auth — so a typo'd or invented type (RESTATED=S1,S5,S7)
  # passed on its own line's agreement alone and never met the authoritative set.
  # (Fixed 2026-08-19.)
  kind=$(printf '%s' "$line" | grep -o 'predecessor-set:[A-Za-z]*' | cut -d: -f2)
  case "$kind" in
    AUTHORITATIVE) : ;;
    DERIVED)
      [ "$claimed" = "$auth" ] \
        || { echo "FAIL: derived '$claimed' != authoritative '$auth'"; fail=1; } ;;
    *) echo "FAIL: unknown predecessor-set marker type '$kind' — use AUTHORITATIVE or DERIVED"; fail=1 ;;
  esac
done < <(grep -h 'predecessor-set:' "$EPIC" | grep -v 'grep -o')

# 2. Stamps: each table row against the stamp its issue actually carries.
# gh stderr can carry request ids and authorization fragments; keep it out of the
# terminal and report only a classification. (Added 2026-08-18.)
ghbody() { gh issue view "$1" --json body -q .body 2>"$errlog" || { echo "GH-ERROR"; }; }
errlog=$(mktemp); trap 'rm -f "$errlog"' EXIT

while read -r issue stamp; do
  live=$(ghbody "$issue" \
         | grep -oE 'epic commit `[0-9a-f]{7}`' | tail -1 | tr -d '`' | awk '{print $3}')
  [ "$stamp" = "$live" ] || { echo "FAIL: #$issue table=$stamp issue=${live:-none}"; fail=1; }
done < <(grep -oE 'issues/[0-9]+\) [|] `[0-9a-f]{7}`' "$EPIC" \
         | sed -E 's#issues/([0-9]+)\) [|] `([0-9a-f]{7})`#\1 \2#' | sort -u)

# 2b. Body hash: a stamp is metadata, so an edited brief keeps a matching SHA. This is
#     the only part of the obligation that detects tampering rather than staleness.
while read -r issue want; do
  got=$(ghbody "$issue" | shasum -a 256 | cut -c1-12)
  [ "$want" = "$got" ] || { echo "FAIL: #$issue body hash $got != recorded $want"; fail=1; }
done < <(grep -oE 'issues/[0-9]+\) [|] `[0-9a-f]{7}` [|] `[0-9a-f]{12}`' "$EPIC" \
         | sed -E 's#issues/([0-9]+)\).*`([0-9a-f]{12})`#\1 \2#' | sort -u)

# 3. Stale-but-matching, per stamp and ADVISORY ONLY. Rows legitimately hold different
#    SHAs, so any watermark — row 1's or the oldest — reports valid partial re-stamps as
#    failures; both were tried and both were wrong. This lists what each stamp may have
#    missed and never sets fail: deciding whether a commit was editorial for a given
#    story is judgement the script cannot make. (Downgraded 2026-08-18.)
# Uncommitted edits first: this runs BEFORE pushing, so `git log …HEAD` is blind to
# exactly the change being reviewed — a story section could be edited, its issue left
# alone, the check report clean, and the stale pair then committed. (Added 2026-08-18.)
if ! git diff --quiet -- "$EPIC" || ! git diff --cached --quiet -- "$EPIC"; then
  echo "NOTE: $EPIC has uncommitted changes — re-sync any issue whose story they touch before pushing"
fi

for s in $(grep -oE '\| `[0-9a-f]{7}` \|' "$EPIC" | tr -d '| `' | sort -u); do
  n=$(git log --oneline --invert-grep --grep='^docs(planning): re-stamp' "$s"..HEAD -- "$EPIC" | grep -c .)
  [ "$n" -eq 0 ] || echo "NOTE: $n non-re-stamp commit(s) since $s — confirm each is editorial for the rows still on it"
done

exit $fail
