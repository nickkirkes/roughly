# Implementation Plan: E04.S8 — doc-writer multi-file-invocation guard

Plan-format-version: 1

## Context

Adds an explicit multi-file failure-handling clause to `agents/doc-writer.md` Process step 5. Closes the v0.1.5 audit's S3 AC2 quality concern — doc-writer handles missing CLAUDE.md and Read failure explicitly but has no branch for the multi-file write case. Per `.roughly/known-pitfalls.md` L32 ("LLM agent conditionals need explicit failure-handling clauses"), the implicit fallback IS the bug shape S3 was supposed to close. The new clause locks complete-what-you-can semantics with a verbatim partial-success summary template (AC5) so the failure shape is loud and named, not silent.

## Constraint Analysis (load-bearing — read before T1)

**AC3 word cap math — VERIFIED INFEASIBLE BY PLAN-REVIEW (iteration 1, 2026-05-15):**

- Current `wc -w agents/doc-writer.md` = 467
- Cap = 500
- Headroom = 33 words
- AC5 verbatim-locked template (whitespace-separated tokens, counted with `wc -w`) ≈ 30 words
- Minimum prose to cover (a)–(f) semantics from AC1 explicitly ≈ 16-18 words
- **Realistic minimum new-clause word count: 46-55 words** (clause prose + verbatim template)

**The story's "~60 words; pre-edit count plus addition stays under cap" claim does not survive `wc -w` reality.** Even an aggressively-compressed clause (~46 words, dropping connector words and using "no rollback" / "no full success" telegraph syntax) yields 467 + 46 = 513 words post-edit, exceeding cap by 13. A more readable clause (~55 words, the level needed for clear (a)-(f) coverage) yields ~522.

**Path A (prose-hoist mitigation) — REJECTED:** Plan-review iteration 1 verified that hoisting the duplicate "return summary (NOT to any file)" phrase saves only **-4 words net** (not -22), because shortening the two existing sub-bullets removes 8 tokens each but the intro addition costs 12 tokens. Maximum conceivable hoist (full phrase removal from both sub-bullets, no intro addition) saves 14 tokens net, but that would strip the conditional destination clause from the existing sub-bullets — creating the exact same gap (implicit failure path / unspecified destination) that this story is supposed to close. Path A is therefore not just numerically insufficient but semantically harmful.

**This plan defaults to Path B (accept cap violation, document follow-up).** Path C (re-scope AC3 cap) is presented at the gate 4 human decision as the only no-violation alternative.

### Path B — accept cap violation, document follow-up (this plan's default)

- AC1: pass (clause covers (a)-(f) explicitly)
- AC2: pass (strictly additive — only the new sub-bullet is added; no modifications to existing step 5 prose, steps 1-4, or step 6+)
- AC3: **fail by ~35 words** (T1's verbatim text is 68 words, yielding 467 + 68 = 535 post-edit; tighter compressed variants would land at 513-525 but the chosen verbatim text — see T1's "Edit tool invocation" section — is 68 words). Documented as intentional in this plan and surfaced to the human at gate 4. Follow-up filed under v0.1.7 candidate to either (i) revise the 500-word agent-prompt cap project-wide, (ii) revise the cap for doc-writer specifically, or (iii) trim doc-writer's existing prose under a separate non-additive story.
- AC4: pass (two-part-gate conditional in existing sub-bullets unchanged — strict byte-identical preservation of organize and test-integration prose)
- AC5: pass (template verbatim)

**Why default to Path B over Path C:**
- Path B requires only this story's scope (one strictly-additive edit to step 5) plus a documented follow-up entry. No epic-level revision needed.
- Path C requires the human (epic author) to revise AC3 — that's an epic-doc change outside this story's authoritative scope.
- The cap violation under Path B is bounded (~35 words over a 500-word soft limit for the chosen verbatim text; tighter variants would be 13-25 over) and the existing pattern in the project tolerates similar minor cap excursions when AC trade-offs warrant.

### Path C — re-scope AC3 (alternative, requires human approval)

If the human rejects Path B at gate 4:
- Revise the story's AC3 to set the cap at 525 or 530 (whichever accommodates the chosen clause word count) for doc-writer specifically, OR remove AC3 from this story entirely.
- This requires editing `docs/planning/epics/E04-path-consolidation-and-process-codification.md` line 426. That edit is OUT OF SCOPE for the implementation subagent; the human must make the call and either edit the epic before the orchestrator continues, or sign off on T1 implementing the clause without AC3 enforcement and the orchestrator deferring the epic-doc edit to a follow-up commit.

## AC5 verbatim template — interpretation note

Story AC5 (line 430) presents the locked template as `` `"doc-writer: partial success — ...>."` `` with outer double-quotes inside the backtick pair. This plan interprets the outer `"…"` as typographic quoting (the author setting off the template text for readability), NOT as literal emit-string content. The interpretation is consistent with the two existing emit strings on `agents/doc-writer.md` L33-L34, which use no outer double-quotes around their backtick-wrapped `Note:` strings. The implementation subagent writes the template into the file as backtick-wrapped text WITHOUT outer double-quotes, matching the format pattern already established in the file.

If a reviewer prefers the strict literal reading (include outer double-quotes), the change is one-line: wrap the emit string in `"…"` inside the backticks. Word count impact: +0 (the `"` characters do not add whitespace-separated tokens). This is a low-stakes interpretation call that can be flipped at code-review time without re-planning.

## File Table

| File | Action | Task(s) |
|------|--------|---------|
| agents/doc-writer.md | Edit | T1 |
| (test fixture — ephemeral, no source change) | n/a | T2 |

## Tasks

### T1: Add multi-file failure-handling sub-bullet to Process step 5 (~5 min)

**Files:** agents/doc-writer.md

**Action:** Insert a single new sub-bullet at the end of step 5's bullet list (after the test-integration sub-bullet, before step 6). Make NO other modifications to the file. The existing step 5 intro line, organize-suggestion sub-bullet, and test-integration sub-bullet remain byte-identical pre/post.

**Details:**

The file currently has 58 lines. Step 5's bullet list ends at L34 (test-integration sub-bullet). Step 6 ("Deduplicate") begins at L35. The Edit places the new sub-bullet between L34 and L35.

**The new sub-bullet (insert verbatim):**

```
   - **Multi-file failure handling:** When writing multiple files in one dispatch, invoke `Edit` per file and capture each outcome. On any failure, do NOT roll back successful writes — never claim full success. Emit this exact summary: `doc-writer: partial success — wrote to: <comma-separated list of successful paths>; failed to write: <comma-separated list of failed paths with one-line failure reason each, format '<path>: <reason from Edit error output>'>.`
```

Indentation: three spaces + `- ` to match the existing two sub-bullets' indentation under step 5.

**Edit tool invocation:**

Use the Edit tool with:
- `old_string`: the verbatim text of L34's test-integration sub-bullet (the entire bullet, beginning with `   - **Test-integration suggestion:**` and ending with `` `Note: project has test config but verify-all skips tests — consider updating CLAUDE.md Commands table Test row.` `` — the closing backtick of the existing emit string). Include enough trailing context to disambiguate (the test-integration sub-bullet is L34's full content).
- `new_string`: the same L34 content unchanged, followed by a newline and the new sub-bullet text above.

This preserves L34 byte-identically and appends the new bullet immediately after it. Do NOT use `replace_all`.

**Semantic coverage check against AC1 (a)–(f):**
- (a) per-file independent `Edit` ✓ "invoke `Edit` per file"
- (b) per-file outcome capture ✓ "capture each outcome"
- (c) non-abort on single-file failure ✓ "do NOT roll back successful writes"
- (d) emit partial-success summary ✓ "Emit this exact summary"
- (e) name succeeded + failed paths with reason from Edit ✓ AC5 template verbatim
- (f) never claim full success on partial failure ✓ "never claim full success"

**AC5 verbatim check:** the template text matches the story's AC5 lock semantically. Per the "AC5 interpretation note" above, the outer typographic double-quotes from story line 430 are NOT included in the emit string — matching the format pattern of the existing `Note:` emit strings on L33 and L34.

**Verify (run after the edit):**

1. `wc -w agents/doc-writer.md` — report the count. EXPECTED to exceed 500 (this is Path B; AC3 is intentionally failing — see Constraint Analysis above). Capture the exact count for the gate-6 review note.
2. `git diff agents/doc-writer.md` — inspect:
   - Step 1-4 (L28–L31 pre-edit) byte-identical pre/post — no changes whatsoever
   - Step 5 intro line (L32 pre-edit) byte-identical — no changes
   - Organize sub-bullet (L33 pre-edit) byte-identical — no changes
   - Test-integration sub-bullet (L34 pre-edit) byte-identical — no changes
   - Step 6+ (L35+ pre-edit, "Deduplicate" onward) byte-identical — no changes
   - The ONLY diff is the new sub-bullet inserted between L34 and L35 pre-edit.
3. `grep -c "doc-writer: partial success" agents/doc-writer.md` — must report exactly 1 (AC5 template appears exactly once).
4. `grep -c "Multi-file failure handling" agents/doc-writer.md` — must report exactly 1.
5. Read step 5 in the post-edit file and confirm:
   - Organize fires when: write happened AND Read succeeds AND line count > 80 (unchanged trigger)
   - Test-integration fires when: CLAUDE.md exists AND test config detected AND CLAUDE.md says no test command (unchanged trigger)
   - The new "Multi-file failure handling" sub-bullet is a structural sibling at the same indentation as the other two. AC4 satisfied (gates and their notes unchanged; new bullet does not gate or alter them).

**UI:** no

---

### T2: Synthetic pre-merge permission-denied dispatch test (~5 min)

**Files:** (ephemeral test fixture — no source changes committed)

**Depends on:** T1

**Action:** Dispatch the doc-writer agent with two write targets (`.roughly/known-pitfalls.md` and `CLAUDE.md`), with `.roughly/known-pitfalls.md` chmod 000. Verify the agent's return summary matches the AC5 template format.

**Details:**

1. **Pre-check:**
   - `test -f .roughly/known-pitfalls.md` (must exist)
   - `test -f CLAUDE.md` (must exist)
   - `git diff --quiet -- .roughly/known-pitfalls.md CLAUDE.md && git diff --cached --quiet -- .roughly/known-pitfalls.md CLAUDE.md` — confirm clean state. If dirty, abort with a note; this test must NOT run on uncommitted work for either file.

2. **Set up fixture:** `chmod 000 .roughly/known-pitfalls.md`

3. **Dispatch doc-writer:** Use the Agent tool with `subagent_type: roughly:doc-writer`. Prompt: "Test fixture for E04.S8: add a new pitfall to `.roughly/known-pitfalls.md` AND add a new convention to `CLAUDE.md`. Both files are intended write targets in this dispatch. (Test pitfall content: 'E04.S8 synthetic test — DELETE BEFORE COMMIT'. Test convention content: 'E04.S8 synthetic test — DELETE BEFORE COMMIT'.)"

4. **Capture return:** save the agent's return summary text verbatim for verification.

5. **Cleanup (CRITICAL — must run even if step 3 errored; treat as `try…finally`):**
   - `chmod 644 .roughly/known-pitfalls.md` — restore permissions
   - `git checkout -- CLAUDE.md .roughly/known-pitfalls.md` — discard any test-induced writes
   - `git status --short -- CLAUDE.md .roughly/known-pitfalls.md` — must report nothing

6. **Verify the captured return summary:**
   - Contains literal substring `doc-writer: partial success — wrote to:`
   - The `wrote to:` list contains `CLAUDE.md` (or the agent's path-form for it)
   - The `failed to write:` list contains `.roughly/known-pitfalls.md` (or similar) followed by `:` and a one-line failure reason captured from Edit (likely a permission-denied error message)
   - Overall structure matches AC5: `wrote to: <list>; failed to write: <path>: <reason>.`

**Verify:**
- `ls -l .roughly/known-pitfalls.md` post-cleanup — permissions writable (e.g., `-rw-r--r--`)
- `git status` — clean working tree (no test pollution remaining)
- Captured agent return matches AC5 format (manual verification — record the verbatim summary in the gate-6/7 review log for human inspection)

**Note on test reliability:** This is a behavioral test of an LLM agent. Single-iteration. Per the story's Risk 5 acknowledgment (line 435), real-world close depends on dogfood multi-file invocations during v0.1.6's release window; this synthetic test gives pre-merge confidence that the prompt change is well-formed and the LLM follows the new clause when triggered. If the agent does not produce the expected summary on the first try, capture the actual output and surface to the human for triage at gate 6 — do not silently re-run.

**UI:** no

---

## Blast Radius

**Do NOT modify:**
- `agents/doc-writer.md` anywhere except by inserting the new sub-bullet between L34 and L35 pre-edit. Steps 1-4 (L28–L31 pre-edit), step 5 intro (L32 pre-edit), step 5's two existing sub-bullets (L33-L34 pre-edit), and step 6+ (L35+ pre-edit) MUST be byte-identical post-edit. Verify with `git diff agents/doc-writer.md`. AC2 hard requirement under Path B.
- Any other agent file (`agents/investigator.md`, `agents/discovery.md`, `agents/code-reviewer.md`, `agents/silent-failure-hunter.md`, `agents/static-analysis.md`, `agents/epic-reviewer.md`, `agents/agent-preamble.md`). Story scopes explicitly to doc-writer only; retroactive audit of other agents is a v0.1.7+ candidate.
- `skills/build/SKILL.md` and `skills/fix/SKILL.md` — discovery flagged that Stage 8 dispatch language has no handling for partial-success return, but the story explicitly scopes that gap OUT for E04.S8 (story out-of-scope item line 446: "Changing how Stage 8 wrap-up dispatches doc-writer (build/fix Stage 8 prose untouched by this story)"). Flag as candidate v0.1.7 follow-up in gate-8 wrap-up.
- `docs/adrs/` — no new ADR for this story; out-of-scope item line 445: "Lifting any of doc-writer's failure-handling clauses into `agents/agent-preamble.md`."
- `.roughly/known-pitfalls.md` or `CLAUDE.md` outside the T2 test fixture — T2 must clean up after itself (cleanup step 5 of T2's details).
- The epic document `docs/planning/epics/E04-path-consolidation-and-process-codification.md` — unless the human selects Path C at gate 4 AND explicitly authorizes the epic-doc edit. Path B (this plan's default) requires NO epic-doc edit.
- Any out-of-scope expansion: new triggers, new conditionals, alternate AC5 formats. Story's out-of-scope list is the authoritative non-list.

**Watch for:**
- AC3 cap violation under Path B. The plan EXPECTS `wc -w` to exceed 500 after T1. Capture the exact count and report to the human at gate 6/7 as a known/accepted violation, not a failure. Do NOT auto-trim the new clause or existing prose in response — the trim paths were analyzed and rejected (see Constraint Analysis).
- Edit `old_string` uniqueness for T1: the test-integration sub-bullet (L34 pre-edit) has unique content (it mentions `{{TEST_COMMAND}}` placeholder which appears only there). Use the bullet's tail "...— consider updating CLAUDE.md Commands table Test row.\`" as the disambiguating anchor to ensure the Edit targets L34 specifically. Do NOT use `replace_all`.
- T2 cleanup: the `chmod 644` and `git checkout --` cleanup MUST run even if the agent dispatch errored. Wrap the dispatch + verification in an effective `try…finally`; in practice this means the orchestrator (not the dispatched doc-writer subagent) is responsible for cleanup, so the orchestrator must continue the cleanup steps regardless of the dispatch outcome.
- AC5 interpretation flip risk: if the gate-6 code reviewer rejects the "outer double-quotes are typographic" interpretation, the fix is a one-line backtick-string edit (wrap in `"…"`). No re-planning needed. Word count impact: zero.

## Conventions

- ADR-002 (subagent-per-task): T1 dispatched to a fresh implementation subagent with sonnet model. T2 dispatches doc-writer itself as a behavioral test fixture — distinct from T1's implementation subagent.
- ADR-005 (versioned maturity checks): not applicable — no new maturity check introduced.
- ADR-007 (two-stage review after every task): T1 + T2 each get spec-compliance + quality-check review per build skill Stage 5c. The quality check for T1 should be relaxed for the `wc -w` step specifically (expected to exceed 500 by design under Path B); the orchestrator notes this in the spec-compliance pass and does NOT auto-fix.
- `.roughly/known-pitfalls.md` L32 ("LLM agent conditionals need explicit failure-handling clauses"): this story is the codified close for doc-writer.
- AC2 strict additivity under Path B: the only diff is the new sub-bullet insertion. Path A's prose-hoist was rejected by plan-review iteration 1 because (i) the math doesn't fit (-4 net savings, not -22) and (ii) full removal of the destination phrase from existing sub-bullets would strip the conditional destination clause, creating the exact gap this story is closing.
- AC5 verbatim-locked template: the partial-success summary text MUST appear in `agents/doc-writer.md` exactly as specified in the story's AC5, with the documented interpretation that the outer typographic `"…"` are not part of the emit string.

## Verification commands summary (for Stage 7 verify-all reference)

```bash
# AC3 — word cap (EXPECTED TO FAIL UNDER PATH B; capture count for gate-6 surfacing)
wc -w agents/doc-writer.md

# AC2 — strictly additive (steps 1-4, step 5 existing content, step 6+ all byte-identical)
git diff agents/doc-writer.md   # inspect manually; only the new sub-bullet should appear in diff

# AC5 — template appears exactly once
grep -c "doc-writer: partial success" agents/doc-writer.md   # must be 1

# T1 sanity — new bullet present exactly once
grep -c "Multi-file failure handling" agents/doc-writer.md   # must be 1

# AC4 — two-part-gate conditional preserved (manual read)
sed -n '/^5\. /,/^6\. /p' agents/doc-writer.md   # read step 5; confirm gate conditions unchanged
```

## Gate 4 question (for the human, after this plan passes plan-review)

This plan has TWO ACs that the human must consciously sign off on:

1. **AC3 cap violation under Path B (default):** acknowledge that `wc -w agents/doc-writer.md` will exceed 500 by approximately **35 words** after T1 (post-edit count ~535; verbatim T1 clause is 68 words), and that this violation is intentional / documented / surfaced as a v0.1.7 follow-up. Confirm by typing "accept" or selecting Path B.

2. **OR Path C (alternative):** the human personally edits the epic at line 426 to revise AC3 (e.g., bump cap to 525 for doc-writer), commits that epic-doc edit either before or after this story, and authorizes the orchestrator to proceed with T1 treating AC3 as revised. Confirm by selecting Path C and committing to the epic-doc edit timing.

If neither: abort the pipeline at gate 4.
