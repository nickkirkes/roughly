Procedural reference invoked by `skills/build/SKILL.md` and `skills/fix/SKILL.md` from the `## GATE PROTOCOL` section head. Read ONCE before the first gate; apply at EVERY gate for the rest of the run. See ADR-012 for the runtime-shared-reference pattern and ADR-015 for the gate-presentation decision.

## GATE PROTOCOL

A "gate" is any point where the pipeline stops for a human decision: every prompt marked `**Gate:**` or `Ask:` in the SKILL.md, every escalation whose recovery asks the human to choose, the Stage 4 override protocol, the maturity-check offers, and the abort-handling confirmations.

### Rule 1 — Gates are plain text in your reply, always

Every gate is a plain-text question in your own reply, answered by the human as an ordinary user message. Never present a gate through any tool that renders a structured prompt, choice list, form, or plan-approval flow — not `AskUserQuestion`, not `EnterPlanMode`/`ExitPlanMode`, not any MCP tool, not any tool added to the harness in the future, whatever its name. The test is closed-world: if the question would appear anywhere other than as ordinary text in your reply, the mechanism is forbidden. Re-fitting a gate's wording or its options into a tool's input schema is itself a violation, even when the words look equivalent.

### Rule 2 — The gate question is verbatim

The quoted question in the SKILL.md gate is the exact text you print, as the LAST line of your reply. Fill bracketed placeholders (`[N]`, `[Review summary]`, `[task list with status]`, …) with facts from this run; change nothing else. The parenthesized options are the complete, closed set — never add, remove, merge, or reword an option, and never fold an action into an option that the SKILL.md's own gate text does not name. Adding an action (committing, pushing, opening a PR, deploying) to a gate that does not name it is a scope change, not a rewording, and is prohibited.

### Rule 3 — Frame each stage gate with a header block

Immediately before the verbatim question at a numbered pipeline stage (Stages 1–8), print this block so the human sees where they are and what each answer does:

    ---
    GATE — [build|fix] pipeline · Stage [N] of [M]: [stage name, copied from the ## STAGE N heading]

    Completed: [one line — what this stage produced, with its key artifact path or verdict]
    - [first option, verbatim]  -> [consequence, from the gate's own text or the next ## STAGE heading]
    - [middle option, verbatim] -> [consequence, from the gate's own text]
    - abort -> per ABORT HANDLING
    ---

    [verbatim gate question]

Field constraints keep the block closed-form: `[M]` is the pipeline's total stage count (count the `## STAGE` headings); stage names are copied from the SKILL.md headings, never composed; each `->` consequence is drawn only from the gate's own on-abort text, the gate's option text, or the next `## STAGE` heading. The `Completed:` line is the one field you compose, and it is tightly bounded: state only what this stage already produced (its key artifact path or verdict) — like every field in this block it must NEVER name a next action or any action the SKILL.md does not name at this gate (committing, pushing, opening a PR, deploying). If a field's source text does not exist, omit the line rather than invent it. Sub-gates that are not numbered stage gates — the override confirmation, the `discard` confirmation, maturity-check offers, and abort menus — still obey Rules 1, 2, and 4 in full; they only skip the header block of Rule 3.

### Rule 4 — Interpreting the answer

- Accept obvious variants of a listed option (case, minor typos, `y`/`yeah` for `yes`).
- Anything else — "looks good", "sure, and also …", or a fresh instruction — is NOT a selection. Ask one clarifying question, re-offering the gate's options. Never infer approval from enthusiasm or from an unrelated request, and never treat wording you authored (an option label, a summary line) as the human's authorization.
- Typed-string confirmations are stricter, per their own SKILL.md text: `override` and `discard` must be typed literally; variants and synonyms are refusals to confirm.
- When `CI_MODE=true`: render no header block and ask nothing; follow the stage's `--ci` rule (auto-default or structured-marker exit) exactly as the SKILL.md specifies.
