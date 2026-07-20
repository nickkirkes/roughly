# Implementation Plan: Gate protocol + local-commits-only boundary (issue #66)

Plan-format-version: 1

Hardens the build/fix pipelines against two composing guardrail gaps found in the 2026-07-16 dogfood run:
- **F1** — all gates were presented via `AskUserQuestion` because the only prohibition (`build/SKILL.md:11`, `fix/SKILL.md:11`) enumerated just `EnterPlanMode`/`ExitPlanMode`; nothing forbade other structured-prompt tools, and no gate text was marked verbatim.
- **F2** — an unauthorized `git push` was attempted at wrap-up because the "do NOT push" rule is five words, single-sited in `skills/shared/stage-8-wrap-up.md:27`, reachable only via a runtime `Read`, and bans only the literal verb "push."

Fix strategy is defense-in-depth: a closed-world gate protocol (F1) **and** a local-commits-only boundary that survives a skipped/compacted `Read` (F2). Either layer alone blocks the observed incident.

**Scope boundary:** this story targets the `build` and `fix` pipelines only (the surfaces the incident and issue #66 name). The `gate-protocol.md` reference is consumed by build/fix only. Repo-wide adoption across the other prompt-bearing skills (`review`, `audit-epic`, `review-epic`, `setup`, `upgrade`, `verify-all`) is an intentional follow-up, not part of this story — see Blast Radius.

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| skills/shared/gate-protocol.md | Create | T1 |
| skills/build/SKILL.md | Modify | T2, T4 |
| skills/fix/SKILL.md | Modify | T3, T4 |
| skills/shared/stage-8-wrap-up.md | Modify | T5 |
| CONTRIBUTING.md | Modify | T5 |
| .claude/hooks/verify-all.sh | Modify | T6 |
| docs/adrs/ADR-015-gate-protocol-and-local-commit-boundary.md | Create | T7 |
| docs/adrs/README.md | Modify | T7 |
| docs/adrs/ADR-014-local-only-gate-instrumentation.md | Modify | T7 |
| .roughly/known-pitfalls.md | Modify | T8 |
| CLAUDE.md | Modify | T8 |

## Baseline facts (captured pre-implementation, 2026-07-17)
- `skills/build/SKILL.md` = 270 lines; `skills/fix/SKILL.md` = 275 lines (cap 300; ~23–30 lines headroom each).
- `skills/build/SKILL.md:11` and `skills/fix/SKILL.md:11` are currently **byte-identical** (verified via `diff <(sed -n '11p' …build) <(sed -n '11p' …fix)`), an ADR-009 manual-sync pair.
- `AskUserQuestion` appears **0 times** repo-wide today (`rg -c AskUserQuestion` over the repo, excluding scratchpad). After this story it appears only in intended files (build:11, fix:11, gate-protocol.md, known-pitfalls.md).
- The string `implemented and merged in commit` appears in **two live surfaces** that must move together: the template at `skills/shared/stage-8-wrap-up.md:28` and its canonical worked example at `CONTRIBUTING.md:133` (the "Plan-file lifecycle" section, which states "Format is fully specified — no LLM creative writing"). Both are updated in T5. It also appears in `docs/planning/epics/complete/E04-*.md` — those are **completed-epic historical records** and are intentionally NOT changed (rewriting them would falsify the record of what E04 shipped). No dependents in `scripts/` or `tests/` (`rg "merged in commit" skills/ scripts/ tests/ CONTRIBUTING.md README.md docs/`).
- `scripts/ci-dogfood.sh` contains no `push`/`gh pr`/`merged` assertions.
- `.claude/hooks/verify-all.sh` = 148 lines. Its ADR-012 shared-reference drift check (L98–130) is a data-driven loop over a shared-file existence list (L109) and a `heading|file` pair list (L113); both are extended in place, so registering a third shared file adds **0 net lines**.
- `verify-all.sh` runs as this repo's Stop hook; running it and observing exit 0 with no drift JSON is the canonical "no structural regression" signal.

## Tasks

### T1: Create the shared gate-protocol reference (~4 min)
**Files:** skills/shared/gate-protocol.md
**Action:** Create the new shared procedural reference that build/fix read at runtime.
**Details:** Create `skills/shared/gate-protocol.md` with the following content **verbatim** (this is the authoritative wording; Rules 1, 2, 4 are the safety layer, Rule 3 is the UX layer):

```
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

Field constraints keep the block closed-form: `[M]` is the pipeline's total stage count (count the `## STAGE` headings); stage names are copied from the SKILL.md headings, never composed; each `->` consequence is drawn only from the gate's own on-abort text, the gate's option text, or the next `## STAGE` heading — never introduce an action the SKILL.md does not name at this gate. If a field's source text does not exist, omit the line rather than invent it. Sub-gates that are not numbered stage gates — the override confirmation, the `discard` confirmation, maturity-check offers, and abort menus — skip the header block; Rules 1, 2, and 4 still apply to them in full.

### Rule 4 — Interpreting the answer

- Accept obvious variants of a listed option (case, minor typos, `y`/`yeah` for `yes`).
- Anything else — "looks good", "sure, and also …", or a fresh instruction — is NOT a selection. Ask one clarifying question, re-offering the gate's options. Never infer approval from enthusiasm or from an unrelated request, and never treat wording you authored (an option label, a summary line) as the human's authorization.
- Typed-string confirmations are stricter, per their own SKILL.md text: `override` and `discard` must be typed literally; variants and synonyms are refusals to confirm.
- When `CI_MODE=true`: render no header block and ask nothing; follow the stage's `--ci` rule (auto-default or structured-marker exit) exactly as the SKILL.md specifies.
```

**Verify:** `test -f skills/shared/gate-protocol.md && grep -q '^## GATE PROTOCOL$' skills/shared/gate-protocol.md && grep -qF 'closed-world' skills/shared/gate-protocol.md && grep -qF 'never treat wording you authored' skills/shared/gate-protocol.md`
**UI:** no

### T2: Wire the gate protocol into build/SKILL.md (~4 min)
**Files:** skills/build/SKILL.md
**Depends on:** T1
**Action:** Replace the enumerated tool ban at L11 with a closed-world prohibition, and add a `## GATE PROTOCOL` section (with the runtime `Read` directive) between the pre-flight block and `## STAGE 1`.
**Details:** Two edit sites in this file:
1. **L11 preamble rewrite.** Replace the current line (`verbatim:` — must match the existing text byte-for-byte as the `old_string`):
   `**CRITICAL:** This skill is gated by a UserPromptSubmit hook (\`.claude/hooks/plan-mode-gate.sh\`) that blocks invocation when Claude Code's plan mode is active — exit plan mode (Shift+Tab) and re-invoke. Pipeline gates are inline conversation prompts; never use EnterPlanMode/ExitPlanMode mid-pipeline. See ADR-009.`
   with (`verbatim:` — this exact text; it MUST be byte-identical to fix/SKILL.md L11 produced in T3, per ADR-009):
   `**CRITICAL:** This skill is gated by a UserPromptSubmit hook (\`.claude/hooks/plan-mode-gate.sh\`) that blocks invocation when Claude Code's plan mode is active — exit plan mode (Shift+Tab) and re-invoke. Pipeline gates are plain-text questions rendered verbatim in your reply; never present a gate through any structured or interactive prompt tool (AskUserQuestion, EnterPlanMode/ExitPlanMode, or any other), and never re-author a gate's wording or options. See the GATE PROTOCOL section below and ADR-009.`
2. **Insert the `## GATE PROTOCOL` section.** The current lines 19–23 are: the pre-flight `<!-- ... -->` block (L19), blank (L20), `---` (L21), blank (L22), `## STAGE 1: INTAKE` (L23). Insert immediately after the `---` on L21 (i.e., before `## STAGE 1`) so the section is read before the first gate. Insert this block (`verbatim:` — byte-identical to the T3 insertion in fix/SKILL.md):
   ```
   ## GATE PROTOCOL

   Read `skills/shared/gate-protocol.md` and apply it at every gate in this pipeline. Gates are plain-text questions in your reply — never presented through any structured prompt tool.

   ---
   ```
   The `Read \`skills/shared/gate-protocol.md\`` directive MUST be at line-start and within 3 lines of the `## GATE PROTOCOL` heading (the verify-all drift check in T6 enforces this).
**Structural uniformity:** the L11 line and the `## GATE PROTOCOL` block are 2 byte-identical blocks shared across build/SKILL.md (this task) and fix/SKILL.md (T3) — the ADR-009 manual-sync pair. Both tasks must produce byte-identical text at both sites.
**Verify:** `grep -qF 'never present a gate through any structured or interactive prompt tool' skills/build/SKILL.md && grep -A3 '^## GATE PROTOCOL$' skills/build/SKILL.md | grep -qF 'Read `skills/shared/gate-protocol.md`' && [ "$(wc -l < skills/build/SKILL.md)" -le 300 ]`
**UI:** no

### T3: Wire the gate protocol into fix/SKILL.md (~3 min)
**Files:** skills/fix/SKILL.md
**Depends on:** T1
**Action:** Apply the identical L11 rewrite and `## GATE PROTOCOL` insertion as T2, byte-for-byte.
**Details:** Two edit sites, identical wording to T2:
1. **L11 preamble rewrite.** `fix/SKILL.md:11` is currently byte-identical to `build/SKILL.md:11`. Replace it with the exact same new L11 text specified in T2 (item 1). It MUST end byte-identical to build/SKILL.md L11.
2. **Insert the `## GATE PROTOCOL` section.** In fix/SKILL.md the layout mirrors build: pre-flight block (L19), blank (L20), `---` (L21), blank (L22), `## STAGE 1: INTAKE` (L23). Insert the same `## GATE PROTOCOL` block from T2 (item 2) immediately after the `---` on L21, before `## STAGE 1`.
**Structural uniformity:** same 2 byte-identical blocks as T2; verify cross-file identity in the verify step.
**Verify:** `diff <(sed -n '11p' skills/build/SKILL.md) <(sed -n '11p' skills/fix/SKILL.md) && grep -A3 '^## GATE PROTOCOL$' skills/fix/SKILL.md | grep -qF 'Read `skills/shared/gate-protocol.md`' && [ "$(wc -l < skills/fix/SKILL.md)" -le 300 ]` (the `diff` exits 0 only when L11 is byte-identical across both files).
**UI:** no

### T4: Push-boundary restatement + compaction preserve-list in build and fix Stage 8 (~4 min)
**Files:** skills/build/SKILL.md, skills/fix/SKILL.md
**Depends on:** T2, T3
**Action:** Add a one-line local-commits-only boundary inside each Stage 8 section (so it survives a skipped/compacted `Read` of the shared file), and add the boundary to each pre-wrap-up compaction preserve-list.
**Details:** Four edit sites (structural uniformity: 2 byte-identical additions across build/fix):
1. **build/SKILL.md Stage 8** (currently: `## STAGE 8: WRAP-UP` at L227, blank L228, `Read \`skills/shared/stage-8-wrap-up.md\` and apply the procedure documented there.` at L229). Add a new line immediately after the Read directive (`verbatim:`):
   `The pipeline ends with local commits only — never push, open a PR, or contact a remote, regardless of any gate answer. See stage-8-wrap-up.md step 7.`
   Do NOT alter the Read directive line itself (the verify-all drift check requires it at line-start within 3 lines of the heading; a trailing sibling line is fine).
2. **build/SKILL.md compaction preserve-list** at L223 (`Compact context before wrap-up. Preserve: feature summary, files changed, task completion count, verification verdict.`). Append `, and the local-commits-only wrap-up boundary` before the closing period → `… verification verdict, and the local-commits-only wrap-up boundary.` (`form:` — preserve-list wording is a list; keep the existing items, add this item).
3. **fix/SKILL.md Stage 8** (mirror of site 1: `## STAGE 8: WRAP-UP` L234, Read directive L236). Add the same `verbatim:` boundary line after the Read directive.
4. **fix/SKILL.md compaction preserve-list** at L230 (`Compact context before wrap-up. Preserve: issue summary with root cause, files changed, task completion count, verification verdict.`). Append the same `, and the local-commits-only wrap-up boundary` item before the closing period.
**Note on line numbers:** the L223/L227/L228/L229/L230/L234/L236 citations above are the pre-implementation baseline; T2/T3 insert ~5 lines earlier in each file and run before T4 (per Depends-on), so these numbers shift down by ~5 at edit time. Every instruction here is **content-anchored** ("after the Read directive", "the compaction preserve-list line") — do not edit by line number.
**Verify:** `[ -z "$(grep -L 'The pipeline ends with local commits only' skills/build/SKILL.md skills/fix/SKILL.md)" ] && grep -q 'local-commits-only wrap-up boundary' skills/build/SKILL.md && grep -q 'local-commits-only wrap-up boundary' skills/fix/SKILL.md` — the `grep -L` clause lists files with ZERO matches; asserting that list is empty requires the boundary line in BOTH files (a one-file implementation fails). Also re-confirm caps: `for f in skills/build/SKILL.md skills/fix/SKILL.md; do [ "$(wc -l < "$f")" -le 300 ] || echo "CAP EXCEEDED $f"; done` prints nothing.
**UI:** no

### T5: Local-commits-only terminal step + accurate marker wording (stage-8-wrap-up.md + CONTRIBUTING.md) (~5 min)
**Files:** skills/shared/stage-8-wrap-up.md, CONTRIBUTING.md
**Action:** Add an explicit terminal boundary step to the wrap-up procedure, and correct the plan-marker template string (which claims "merged" at local-commit time) in both the live template and its canonical worked example.
**Details:** Three edit sites:
1. **Add terminal step 7.** After the existing step 6 (the known-pitfalls `Ask:` on L32), append (`verbatim:`):
   `7. **The pipeline ends here — local commits only.** Never \`git push\`, open a pull request, run \`gh\`, or contact any remote as part of this pipeline, under any gate answer or prior approval. Pushing and PR creation are a separate action the human must request explicitly, after the pipeline completes. If a gate answer seemed to include pushing or a PR (e.g. it mentioned "open the PR"), do NOT infer authorization — ask in plain text: "The commits are local. Push and open a PR? (yes / no)" and act only on an explicit \`yes\`.`
2. **Correct the marker template wording** on L28 of `skills/shared/stage-8-wrap-up.md`. The Status-block template currently reads `implemented and merged in commit <SHA>` — but at Stage 8 nothing is merged (local commits only), and the word primes a merge/push mental model. In the `new_string` literal on L28, change the phrase `implemented and merged in commit <SHA>` to `implemented and committed in commit <SHA>` (`verbatim:` for the target phrase). Change ONLY this phrase; leave the rest of step 4 (the `<SHA>`/`<YYYY-MM-DD>` substitution mechanics, the `do NOT push` parenthetical, the failure handling) unchanged. Do NOT touch L30's "post-merge cubic-fix iterations" prose — that legitimately describes the later post-merge lifecycle and remains accurate.
3. **Update the canonical worked example in `CONTRIBUTING.md:133`** (the "Plan-file lifecycle" section, which states "Format is fully specified — no LLM creative writing" — so it MUST match the live template byte-for-byte). Change the quoted Status block's `implemented and merged in commit <SHA>` to `implemented and committed in commit <SHA>` (`verbatim:` for the target phrase), byte-identical to the corrected phrase in `stage-8-wrap-up.md:28`. Change ONLY this phrase; leave surrounding prose (L136 "The SHA is…", the sweep-verification section) unchanged. Do NOT touch the copies in `docs/planning/epics/complete/E04-*.md` — those are historical epic records (see Blast Radius).
**Verify:** `grep -qF 'The pipeline ends here — local commits only' skills/shared/stage-8-wrap-up.md && grep -c 'implemented and committed in commit' skills/shared/stage-8-wrap-up.md | grep -qx 1 && ! grep -qF 'implemented and merged in commit' skills/shared/stage-8-wrap-up.md && grep -qF 'implemented and committed in commit' CONTRIBUTING.md && ! grep -qF 'implemented and merged in commit' CONTRIBUTING.md`
**UI:** no

### T6: Register gate-protocol.md in the verify-all drift check (~3 min)
**Files:** .claude/hooks/verify-all.sh
**Depends on:** T1, T2, T3
**Action:** Extend the ADR-012 shared-reference drift check to cover `gate-protocol.md`, reusing the existing data-driven loops (no new lines / no new control flow).
**Details:** Two in-place list extensions in the shared-reference drift block (L98–130):
1. **Existence list** (currently L109: `for shared in abort-handling.md stage-8-wrap-up.md; do`). Add `gate-protocol.md` to the list → `for shared in abort-handling.md stage-8-wrap-up.md gate-protocol.md; do`.
2. **Heading|file pair list** (currently L113: `for pair in "STAGE 8: WRAP-UP|stage-8-wrap-up.md" "ABORT HANDLING|abort-handling.md"; do`). Add the pair `"GATE PROTOCOL|gate-protocol.md"` → `for pair in "STAGE 8: WRAP-UP|stage-8-wrap-up.md" "ABORT HANDLING|abort-handling.md" "GATE PROTOCOL|gate-protocol.md"; do`.
This makes the existing machinery assert, for both build and fix: the `## GATE PROTOCOL` heading exists and a `Read \`skills/shared/gate-protocol.md\`` directive is at line-start within 3 lines of it, and that `skills/shared/gate-protocol.md` exists. Do NOT add a new inline-duplication guard (the L123–128 guards are phrase-specific to abort/wrap-up content; gate-protocol content is not inlined anywhere).
**Verify:** `bash -n .claude/hooks/verify-all.sh && ! bash .claude/hooks/verify-all.sh | grep -qF 'gate-protocol'` — first clause: the script parses. Second: run the hook from the repo root; it must NOT emit a drift line mentioning `gate-protocol` (negate a plain positive-match `grep -q`, which correctly returns "no match" / exit 1 even on empty stdin — avoiding the `grep -v` empty-input edge case). Additionally confirm no new lines were needed: `[ "$(wc -l < .claude/hooks/verify-all.sh)" -le 149 ]` (was 148; the two edits extend existing lines).
**UI:** no

### T7: ADR-015 + README index + ADR-014 no-egress extension (~5 min)
**Files:** docs/adrs/ADR-015-gate-protocol-and-local-commit-boundary.md, docs/adrs/README.md, docs/adrs/ADR-014-local-only-gate-instrumentation.md
**Action:** Record the gate-presentation + local-commit-boundary decision as a new ADR, index it, and extend ADR-014's no-egress claim to cover git objects.
**Details:** Three edit sites:
1. **Create `docs/adrs/ADR-015-gate-protocol-and-local-commit-boundary.md`.** Read an existing neighbor (e.g. `docs/adrs/ADR-013-build-ci-runs-review-plan.md`) first to mirror the exact house ADR structure/headings. Content (`form:` — match house style; substance must include): **Status** Accepted, 2026-07-17. **Context** — the 2026-07-16 dogfood incident (F1 gate substitution via `AskUserQuestion`; F2 unauthorized `git push` laundered through a re-authored gate option); the prior enumerated ban forbade only `EnterPlanMode`/`ExitPlanMode`; the "do NOT push" rule was single-sited and verb-narrow. **Decision** — (a) gates are plain-text, rendered verbatim, presented through no structured prompt tool (closed-world prohibition), specified in `skills/shared/gate-protocol.md` and referenced from a `## GATE PROTOCOL` section in build/fix; (b) the pipeline terminates at local commits — no push/PR/remote under any gate answer — stated in `stage-8-wrap-up.md` and restated inline in both SKILL.md Stage 8 sections so it survives a skipped `Read`. **Consequences** — text-only gates keep the typed-friction safety gates (`override`, `discard`) intact; `AskUserQuestion` is rejected (runtime placeholders make "verbatim options" impossible; buttons would erode typed friction); scope is build/fix, repo-wide adoption is a follow-up.
2. **Update `docs/adrs/README.md`.** Add the ADR-015 row/entry mirroring the existing index format (read the file to match its table/list style).
3. **Extend `docs/adrs/ADR-014-local-only-gate-instrumentation.md`.** ADR-014 asserts "Roughly never transmits any data off your machine" scoped to telemetry. Add one sentence (`form:`) clarifying that the no-egress posture also covers version-control egress: the pipeline never pushes commits or opens PRs to a remote — that is an explicit, separate human action outside the pipeline (cross-reference ADR-015). Read the file first to place the sentence where the no-egress claim lives.
**Verify:** `test -f docs/adrs/ADR-015-gate-protocol-and-local-commit-boundary.md && grep -q 'ADR-015' docs/adrs/README.md && grep -qiF 'push' docs/adrs/ADR-014-local-only-gate-instrumentation.md`
**UI:** no

### T8: known-pitfalls + contributor-pitfall documentation (~3 min)
**Files:** .roughly/known-pitfalls.md, CLAUDE.md
**Action:** Record the gate-re-authoring / consent-laundering pattern for future runtime runs, and add a contributor pitfall beside the existing gate pitfall.
**Details:** Two edit sites:
1. **Append to `.roughly/known-pitfalls.md`** a new `###` entry (`form:` — match the file's existing Symptom/Cause/Fix structure) titled for the pattern: gates presented via a structured prompt tool (`AskUserQuestion`) let the model re-author gate wording, and selection of self-authored option text was laundered into authorization for an out-of-scope action (an unauthorized `git push`). **Fix:** gates are plain-text verbatim per `skills/shared/gate-protocol.md`; the pipeline ends at local commits per `stage-8-wrap-up.md` step 7; never treat wording you authored as the human's authorization. Reference issue #66 and the 2026-07-16 dogfood run. (Appending is fine; the file is 180 lines and already past the advisory 80-line organize threshold — that warning is non-blocking.)
2. **Add a bullet to `CLAUDE.md`** in the `## Known Pitfalls for Contributors` section, immediately after the existing `- **Avoid ambiguous override language in gates.**` bullet (read the file to place it exactly). New bullet (`form:`): **Gates are verbatim text, never a UI tool.** LLMs will substitute a structured prompt tool (e.g. `AskUserQuestion`) for a text gate and re-author its options, which becomes a scope-injection surface; the prohibition must stay closed-world (see `skills/shared/gate-protocol.md`, ADR-015). Also note the pipeline ends at local commits — never push/PR from a pipeline.
**Verify:** `grep -qiF 'AskUserQuestion' .roughly/known-pitfalls.md && grep -qiF 'verbatim' CLAUDE.md && grep -qiF 'Gates are verbatim text' CLAUDE.md`
**UI:** no

## Blast Radius
- **Do NOT modify:** the `implemented and merged in commit` copies in `docs/planning/epics/complete/E04-path-consolidation-and-process-codification.md` and its `-review.md` sibling — completed-epic historical records; rewriting them would falsify the record of what E04 shipped. Only the two live surfaces (`stage-8-wrap-up.md:28`, `CONTRIBUTING.md:133`) move in T5.
- **Do NOT modify:** the `## STAGE 8: WRAP-UP` Read-directive line in either SKILL.md (drift check requires it at line-start within 3 lines of the heading — T4 adds a sibling line, does not alter the directive); the pre-flight `<!-- pre-flight:start/end -->` blocks (byte-checked against a fixture); `L30` "post-merge cubic-fix iterations" prose in stage-8-wrap-up.md (legitimately post-merge); `build/SKILL.md:207` / `fix/SKILL.md:214` "post-merge re-runs" Stage 6 prose (describes the real later cubic lifecycle, not a pipeline merge — changing it would introduce inaccuracy and is out of scope).
- **Do NOT extend** gate-protocol consumption to skills other than build/fix in this story (review/audit-epic/review-epic/setup/upgrade/verify-all have their own prompts; repo-wide adoption is a deliberate follow-up, tracked separately).
- **Watch for:** ADR-009 byte-identity of `build/SKILL.md:11` ↔ `fix/SKILL.md:11` (T2/T3 must produce identical text — the T3 verify `diff` enforces it); the 300-line skill cap (T2/T3/T4 verifies re-check it); verify-all.sh must still parse and run clean after T6 (T6 verify runs it); self-reference in verifies — do NOT verify "`AskUserQuestion` absent repo-wide" (it is intentionally present in build:11, fix:11, gate-protocol.md, known-pitfalls.md after this story); verifies assert presence in intended files instead.

## Conventions
- ADR-012 runtime-shared-reference pattern: new shared file `skills/shared/gate-protocol.md`, consumed via a line-start `Read` directive within 3 lines of a `## GATE PROTOCOL` heading; drift-enforced by verify-all Check-8's existing loops (T6). See also ADR-003 (shared-reference precedent).
- ADR-009: `build/SKILL.md:11` and `fix/SKILL.md:11` are a manual byte-identical sync pair; the new `## GATE PROTOCOL` section and its Read directive are likewise mirrored across both pipelines (drift-checked by T6's pair-loop entry).
- ADR-015 (new, this story): gates are verbatim plain text via a closed-world prohibition; pipeline ends at local commits.
- Verify commands are scoped to intended files and use presence assertions (not repo-wide absence) to avoid the review-plan "self-defeating verify" pitfall, since the new prose intentionally contains the `AskUserQuestion` / `push` literals.
- No build step (pure markdown + one bash hook); `bash -n` + running verify-all.sh is the structural check.
