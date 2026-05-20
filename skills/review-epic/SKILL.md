---
name: review-epic
description: "Pre-implementation epic review. Dispatches epic-reviewer agent (Opus) to check technical accuracy, best practices, risks, and overengineering. Run before starting implementation of an epic."
disable-model-invocation: true
---

# Epic Review

Review an epic file before implementation begins. Catches technical issues, overengineering, missing acceptance criteria, and risk factors before any code is written.

## Input

Epic file: $ARGUMENTS

If `$ARGUMENTS` is empty, ask: **"Which epic file should I review? (provide path)"**

<!-- pre-flight:start --> **Pre-flight migration check:** If `.ruckus/.migration-in-progress`, `.ruckus/known-pitfalls.md`, or `.ruckus/workflow-upgrades` exists, OR if `.roughly/` exists AND any file matching `docs/plans/*-plan.md` exists (the `*-plan.md` filename pattern is Roughly's plan naming convention — its presence inside `docs/plans/` alongside an existing `.roughly/` install distinguishes a pre-v0.1.6 Roughly install with un-migrated plans from a Roughly project that has an unrelated `docs/plans/` documentation directory using non-Roughly filenames), abort with: "Legacy state detected (`.ruckus/` from v0.1.3 install or incomplete v0.1.4 migration; or pre-v0.1.6 Roughly plans matching `docs/plans/*-plan.md` alongside `.roughly/`). Run `/roughly:upgrade` to migrate or resume, then re-run." A `.ruckus/` directory containing only user-extras (post-`leave` state from a completed upgrade) is fine — proceed. A `docs/plans/` directory without any `*-plan.md` files (or in a project without `.roughly/`) is also fine — proceed (not a Roughly install or an unrelated documentation tree). <!-- pre-flight:end -->

---

## STEP 1: READ AND VALIDATE

Read the epic file at `$ARGUMENTS`. Confirm it contains:
- Story/task breakdown
- Acceptance criteria
- Technical approach or architecture notes

If the file is missing critical sections, note the gaps but proceed with review.

---

## STEP 2: DISPATCH EPIC REVIEWER

Dispatch the `epic-reviewer` agent (model: `opus`) with:
- The full epic file content
- Instruction to read CLAUDE.md and .roughly/known-pitfalls.md for project context
- The review dimensions below

**Review dimensions:**
1. **Technical accuracy** — Are the proposed approaches feasible given the current codebase?
2. **Best practices** — Does the epic follow established patterns? Are there better approaches?
3. **Risks** — What could go wrong? Missing edge cases? Integration risks?
4. **Overengineering** — Is anything more complex than necessary for current requirements?
5. **Acceptance criteria quality** — Are ACs specific, testable, and complete?
6. **Dependencies** — Are cross-story dependencies identified? Correct ordering?

---

## STEP 3: PRESENT REVIEW

When the agent returns, display the review with:
- Summary verdict (Ready / Needs Revision / Major Concerns)
- Findings grouped by dimension
- Specific suggestions for improvement (referencing story IDs)

---

## STEP 4: SAVE REVIEW

Save the review alongside the epic file:
- If epic is at `docs/epics/E02.md`, save review at `docs/epics/E02-review.md`
- Include date and reviewer (Roughly epic-reviewer)

Ask: **"Review saved. Address findings before implementation, or proceed as-is?"**
