Procedural reference invoked by `skills/build/SKILL.md` and `skills/fix/SKILL.md` at the `## ABORT HANDLING` section head. See ADR-012 for the runtime-shared-reference pattern.

## ABORT HANDLING

When the human selects "abort" at any gate, respond based on how far the pipeline progressed:

**Stages 1-2 (no files written):** Acknowledge abort. No cleanup needed.

**Stages 3-4 (plan written, no implementation):** Ask: "Delete the plan file at [path]? (yes / keep it)"
- If yes: delete the plan file
- Clear any TodoWrite entries created for this pipeline run

**Stages 5-7 (implementation started):** Offer rollback:
> "Implementation is in progress. Options:
> 1. `git stash -u` — stash all uncommitted changes including new files (recoverable via `git stash pop`)
> 2. `git reset --hard HEAD && git clean -fd` — discard all uncommitted changes (staged and unstaged) and remove new files (**irreversible — cannot be undone**)
> 3. Keep changes as-is — leave working tree dirty for manual review"

If the human selects option 2, require explicit re-confirmation: "This will permanently delete all uncommitted changes. Type 'discard' to confirm."

Wait for human choice. Execute their selection. Then:
- Clear all TodoWrite entries for this pipeline run
- Delete the plan file only if the human also confirms

**Stage 8 (after step 3 commit, before step 4 commit — rare: no human gate exists in this window):** Commit 1 already landed; do not revert. Recovery options: (a) manually run `git rev-parse HEAD` to capture `IMPL_SHA`, prepend the Status block per Stage 8 step 4 template, commit 2 (`docs: mark <feature> plan historical`); OR (b) accept the implementation-only commit and skip plan-historical marking — the plan stays as a Stage-3 snapshot per E05.S6's plan-implementation-drift framing. Recovery path (a) preserves the canonical 2-commit pattern (the 2-commit window's intended end-state); (b) accepts a 1-commit story as a documented exception.

**Always on abort:** End with a clear message: "Pipeline aborted at Stage [N]. [cleanup summary]."
