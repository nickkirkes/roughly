**Fixture purpose:** AC2 PASS — runtime detection with named signal source

# Implementation Plan: Add git-aware mode to repo-init script

Plan-format-version: 1

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| `scripts/repo-init.sh` | edit | T1 |

## Tasks

### T1: Branch on git working-tree detection (~5 min)
**Files:** `scripts/repo-init.sh`
**Action:** Add a conditional that detects whether the repo is a git working tree and selects the appropriate initialisation mode.
**Details:**
Edit site 1: `scripts/repo-init.sh` line 14 — insert detection block.
Detect whether the repo has a `.git/` directory by running `git rev-parse --git-dir 2>/dev/null`. Read the exit code: if `0`, the repo is a git working tree and the conditional should branch to "git-aware mode"; if non-zero, the conditional should branch to "fallback mode". The signal source is the command's exit code as observed by the surrounding bash script.
Edit site 2: `scripts/repo-init.sh` line 32 — add `# git-aware mode` and `# fallback mode` branch stubs.
**Verify:** `bash scripts/repo-init.sh` exits 0 both inside and outside a git repo.
**UI:** no
