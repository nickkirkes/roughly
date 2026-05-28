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

**Always on abort:** End with a clear message: "Pipeline aborted at Stage [N]. [cleanup summary]."
