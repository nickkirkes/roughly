**Fixture purpose:** AC5 PASS — verify scope explicitly excludes the directory containing the literal as historical reference.

# Implementation Plan: Add legacy `.ruckus/` directory detection to build pipeline

Plan-format-version: 1

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| `skills/build/SKILL.md` | edit | T1 |
| `scripts/preflight-check.sh` | edit | T2 |
| `README.md` | edit | T3 |

## Tasks

### T1: Add legacy-state detection block to build SKILL.md (~5 min)
**Files:** `skills/build/SKILL.md`
**Action:** Insert a new pre-flight gate (Stage 2a) that detects a leftover `.ruckus/` directory and halts with an instructional error.
**Details:**
Edit site 1: `skills/build/SKILL.md` Stage 2, after the existing "Read project CLAUDE.md" step — insert a new Stage 2a block:

```
**Stage 2a — Legacy directory pre-flight**
If `.ruckus/` exists in the project root, halt immediately and output:
  "legacy-ruckus-dir detected: remove `.ruckus/` before running /roughly:build (see migration guide)"
Do not proceed past Stage 2a when this condition is true.
```

Note: The phrase "legacy-ruckus-dir detected" appears in the new detection prose above as instructional/error-message text. `skills/build/SKILL.md` is therefore a self-reference site for this literal.
**Verify:** (no verify for T1 — T2 owns the behavioral verify; T1 is prose only)
**UI:** no

### T2: Wire detection into preflight script (~8 min)
**Files:** `scripts/preflight-check.sh`
**Action:** Add a bash guard that checks for `.ruckus/` and exits non-zero with the canonical error message.
**Details:**
Edit site 1: `scripts/preflight-check.sh` after the existing `check_node_version` call — add:

```bash
if [ -d ".ruckus" ]; then
  echo "legacy-ruckus-dir detected: remove \`.ruckus/\` before running /roughly:build (see migration guide)" >&2
  exit 1
fi
```

**Verify:** `rg -Fn "legacy-ruckus-dir detected" scripts/ README.md CONTRIBUTING.md`
Verify scope explicitly excludes `skills/` — the detection-prose location (`skills/build/SKILL.md`) is a documented self-reference site and is NOT in the verify scope. The runtime files under `scripts/`, `README.md`, and `CONTRIBUTING.md` do not contain the literal except where intentionally added by T2/T3. This verify is not self-defeating because `skills/build/SKILL.md` is outside the scanned paths.
**UI:** no

### T3: Document the migration error in README (~4 min)
**Files:** `README.md`
**Action:** Add a Troubleshooting entry explaining the `legacy-ruckus-dir detected` error and the remediation step.
**Details:**
Edit site 1: `README.md` Troubleshooting section — append:

```
### `legacy-ruckus-dir detected`
Remove the `.ruckus/` directory from your project root. This directory was created by an older version of the tool and is no longer used. Run `rm -rf .ruckus/` then retry.
```

**Verify:** covered by T2's verify (README.md is in scope).
**UI:** no
