---
name: review
description: "Parallel 3-agent code review: code-reviewer, static-analysis, and silent-failure-hunter. Synthesizes findings into severity-grouped report. Use after implementation or standalone."
disable-model-invocation: true
---

# Code Review

Dispatch three review agents in parallel, synthesize their findings, and present a unified report.

## Input

Review scope: $ARGUMENTS

If `$ARGUMENTS` is empty, review all uncommitted changes:
!`git diff --name-only HEAD 2>/dev/null || echo "no changes"`

<!-- pre-flight:start --> **Pre-flight migration check:** If `.ruckus/.migration-in-progress`, `.ruckus/known-pitfalls.md`, or `.ruckus/workflow-upgrades` exists, OR if `.roughly/` AND `docs/plans/` BOTH exist AND `.roughly/plans/` does NOT exist (the `.roughly/plans/` absence is the load-bearing signal: it distinguishes a pre-v0.1.6 Roughly install with un-migrated plans from a Roughly project that has both a migrated `.roughly/plans/` and an unrelated `docs/plans/` used for non-Roughly documentation), abort with: "Legacy state detected (`.ruckus/` from v0.1.3 install or incomplete v0.1.4 migration; or pre-v0.1.6 plan-path location at `docs/plans/` alongside `.roughly/` with no `.roughly/plans/`). Run `/roughly:upgrade` to migrate or resume, then re-run." A `.ruckus/` directory containing only user-extras (post-`leave` state from a completed upgrade) is fine — proceed. A `docs/plans/` directory alongside an existing `.roughly/plans/` is treated as unrelated documentation — proceed. A `docs/plans/` directory in a project without `.roughly/` is also fine — proceed (not a Roughly install). <!-- pre-flight:end -->

---

## STEP 1: DISPATCH AGENTS

Launch all three agents in parallel (single message, multiple tool calls):

### Agent 1: `code-reviewer`
Dispatch the `code-reviewer` agent with:
- The review scope description
- List of changed files
- Instruction to read CLAUDE.md and .roughly/known-pitfalls.md first

### Agent 2: `static-analysis`
Dispatch the `static-analysis` agent with:
- List of changed files
- Instruction to run type check, lint, and build commands from CLAUDE.md

### Agent 3: `silent-failure-hunter`
Dispatch the `silent-failure-hunter` agent with:
- List of changed files
- Instruction to read .roughly/known-pitfalls.md for domain-specific risk patterns

---

## STEP 2: SYNTHESIZE REPORT

When all agents return, merge findings into a single report grouped by severity:

```
# Review Report

**Scope:** [description of what was reviewed]
**Changed files:** [count]

## Critical (must fix)
- [finding — source: agent name]

## Warning (should fix)
- [finding — source: agent name]

## Info (consider)
- [finding — source: agent name]

## Clean
- [areas that passed all three reviews]
```

**Deduplication:** If multiple agents flag the same issue, merge into one finding and note which agents caught it.

---

## STEP 3: KNOWN PITFALLS UPDATE

Ask: **"Did this review reveal patterns that should be added to `.roughly/known-pitfalls.md`?"**

If yes, dispatch the `doc-writer` agent with the new pitfall description.

---

## STEP 4: VERDICT

If critical findings exist:
> "Review found [N] critical issues. These must be fixed before proceeding. Re-invoke `/roughly:review` after fixing to confirm resolution."

If only warnings/info:
> "Review passed with [N] warnings. Proceed or address warnings?"

If clean:
> "Review passed clean across all three agents."
