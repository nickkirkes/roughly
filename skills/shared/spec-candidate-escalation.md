Procedural reference invoked by `skills/build/SKILL.md` and `skills/fix/SKILL.md` from the `## SPEC-REVISION-CANDIDATE ESCALATION` section head. See ADR-012 (runtime-shared-reference pattern) and ADR-019 (tool-neutral escalation target).

## SPEC-REVISION-CANDIDATE ESCALATION

A Stage 6 spec-revision-candidate finding, or a cubic termination option (c) finding, identifies a problem with the spec itself rather than the implementation. These findings must be persisted so they are not silently dropped. Do not silently accept the finding (leaves it unaddressed) and do not attempt to fix it in place (expands scope beyond the current task and may collide with already-shipped AC contracts). Instead, escalate:

1. **Determine the target.** First **read (or re-read) the project's `CLAUDE.md`** — it may have been read early and compacted out of context — to check whether it documents a spec-candidate escalation target. If it does (e.g. an epic file or an issue tracker), that is the target; otherwise the target is the default `.roughly/spec-candidates.md` at the project root. If the chosen target file does not exist, create it first: `mkdir -p` its parent directory (e.g. `mkdir -p .roughly`, per the mkdir-p pitfall), then `Write` it with a one-line header — `Edit` cannot create a file, so a first-time target needs `Write` before any append.

2. **Append the candidate** (append-only — never overwrite; use `Edit` with `replace_all: false` or an append) as a dated entry capturing:
   - The finding itself, stated precisely.
   - Why it can't be fixed in the current task's scope — categorize as one of: AC contradiction, missing failure-mode coverage, prose ambiguity, or anchoring weakness.
   - Its source: the task, story, or PR the finding surfaced from.

   The appended entry is the evidence that the finding was recorded. If the append fails (missing target file, unwritable path), surface the failure to the human rather than proceeding as if escalation succeeded.

3. Do NOT silently accept and do NOT attempt to fix. Escalation is complete only once the entry is appended — reporting the finding in conversation without appending it does not satisfy this procedure.

The `.roughly/spec-candidates.md` ledger is a durable, tracked project record of deferred spec findings (like `.roughly/known-pitfalls.md`) — commit it; it is not a scratch file and should not be gitignored.
