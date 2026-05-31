Procedural reference invoked by `skills/build/SKILL.md` and `skills/fix/SKILL.md` at the `## STAGE 8: WRAP-UP` section head. Two sites embed pipeline-conditional prose using the inline pattern "When invoked from /roughly:build: X. When invoked from /roughly:fix: Y." — the runtime LLM applies the branch matching its dispatch context. See ADR-012.

## STAGE 8: WRAP-UP

1. `git add` changed files
2. Draft commit message:

   When invoked from /roughly:build:
   ```
   feat: [short description]

   [What was built and why]
   Tasks: [N] completed
   Changes: [file list with one-line descriptions]
   Tested: [verification summary]
   ```

   When invoked from /roughly:fix:
   ```
   fix: [short description]

   Root cause: [one line]
   Issue: [issue ID if provided]
   Changes: [file list with one-line descriptions]
   Tested: [verification summary]
   ```
3. Show commit for approval. Commit but do NOT push.
4. **Plan historical marking (2nd commit, post-implementation):** Read the plan file from Stage 3 to capture its current first line. Run `IMPL_SHA=$(git rev-parse HEAD)`. Prepend Status block via `Edit` (not `Write` — append-only pitfall; `replace_all: false`): `old_string` = the plan file's first line; `new_string` = literal text `> **Status:** Historical — implemented and merged in commit <SHA> on <YYYY-MM-DD>. This plan was an active build/fix artifact; treat as historical reference only.` (substituting `$IMPL_SHA` for `<SHA>` and today's date in ISO `YYYY-MM-DD` form for `<YYYY-MM-DD>` — the resulting first line MUST NOT contain literal `<SHA>` or `<YYYY-MM-DD>` text), then a blank line, then the original first line. Then `git add <plan-file>` and `git commit -m "docs: mark <feature> plan historical"` (do NOT push; deterministic content — no approval gate needed). On any failure (empty SHA, Edit no-match, commit hook rejection), halt and escalate to the human. The plan file's parent directory `.roughly/plans/` is guaranteed to exist because Stage 3 created it with `mkdir -p` when writing the plan; no defensive `mkdir -p` is needed at this Edit site.

   The Status block frames the plan as a Stage-3 snapshot. Implementation actuals may differ from the plan — e.g., post-merge cubic-fix iterations that modify the shipped code without re-editing the plan — and that drift is expected, not a defect (scoped narrowly: this is plan-file drift, not code-quality drift; cubic findings about code quality still require triage per Stage 6's termination criteria). Downstream review tools (cubic and similar) should treat the plan as historical context, not authoritative spec — the Status block + first-line marker signals this intent.
5. Run maturity checks (see below).
6. When invoked from /roughly:build: Ask: "Did this work reveal any new pitfalls or conventions for `.roughly/known-pitfalls.md`?" When invoked from /roughly:fix: Ask: "Did this fix reveal any new pitfalls or conventions for `.roughly/known-pitfalls.md`?" If yes, dispatch `doc-writer` agent.
