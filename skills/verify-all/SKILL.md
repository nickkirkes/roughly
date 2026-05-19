---
name: verify-all
description: "Build verification loop: type check, test suite, and build command. Iterates until clean or escalates. Uses project-specific commands from CLAUDE.md."
disable-model-invocation: true
---

# Verify All

Run all verification checks in sequence. Iterate until clean or escalate failures to the human.

## Context

Read CLAUDE.md to resolve verification commands. If commands are missing, warn and ask the human to provide them.

<!-- pre-flight:start --> **Pre-flight migration check:** If `.ruckus/.migration-in-progress`, `.ruckus/known-pitfalls.md`, or `.ruckus/workflow-upgrades` exists, OR if `.roughly/` AND `docs/plans/` BOTH exist AND `.roughly/plans/` does NOT exist (the `.roughly/plans/` absence is the load-bearing signal: it distinguishes a pre-v0.1.6 Roughly install with un-migrated plans from a Roughly project that has both a migrated `.roughly/plans/` and an unrelated `docs/plans/` used for non-Roughly documentation), abort with: "Legacy state detected (`.ruckus/` from v0.1.3 install or incomplete v0.1.4 migration; or pre-v0.1.6 plan-path location at `docs/plans/` alongside `.roughly/` with no `.roughly/plans/`). Run `/roughly:upgrade` to migrate or resume, then re-run." A `.ruckus/` directory containing only user-extras (post-`leave` state from a completed upgrade) is fine — proceed. A `docs/plans/` directory alongside an existing `.roughly/plans/` is treated as unrelated documentation — proceed. A `docs/plans/` directory in a project without `.roughly/` is also fine — proceed (not a Roughly install). <!-- pre-flight:end -->

---

## STEP 1: RESOLVE COMMANDS

Read CLAUDE.md and extract:
- **Type check:** {{TYPE_CHECK_COMMAND}} (e.g., `npx tsc --noEmit`)
- **Test:** {{TEST_COMMAND}} (e.g., `npm test`)
- **Build:** {{BUILD_COMMAND}} (e.g., `npm run build`)

If any command is missing from CLAUDE.md:
> "CLAUDE.md is missing [command]. Provide it now or skip this check?"

---

## STEP 2: RUN CHECKS

Run each check in sequence. Stop on first failure.

### 2a. Type Check
```bash
{{TYPE_CHECK_COMMAND}}
```
If "none" or not configured, skip with note.

### 2b. Test Suite
```bash
{{TEST_COMMAND}}
```
If "none yet" or not configured, skip with note.

### 2c. Build
```bash
{{BUILD_COMMAND}}
```

---

## STEP 3: HANDLE FAILURES

**If all pass:**
> "Verification passed: type check ✓, tests ✓, build ✓"

**If any fail:**
1. Display the failure output
2. Attempt to fix the issue (max 3 attempts per check)
3. Re-run the failing check after each fix attempt
4. If still failing after 3 attempts, escalate:
   > "Verification failed after 3 fix attempts. [check name]: [error summary]. Manual intervention needed."

---

## STEP 4: SUMMARY

```
# Verification Results

| Check | Status | Details |
|-------|--------|---------|
| Type check | ✓/✗/skipped | [command or reason skipped] |
| Tests | ✓/✗/skipped | [pass count or reason skipped] |
| Build | ✓/✗ | [command] |

**Overall:** PASS / FAIL
```
