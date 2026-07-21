> **Status:** Historical — implemented and committed in commit 610b169d4fc78e99b4df2e98c76d522ac6410f6c on 2026-07-21. This plan was an active build/fix artifact; treat as historical reference only.

# Fix Plan: #72 — de-dogfood the Stage 6 spec-revision-candidate escalation target

Plan-format-version: 1

## Root Cause

Two byte-identical Stage 6 paragraphs in each pipeline — the `spec-revision-candidate` disposition (`skills/build/SKILL.md:211` / `skills/fix/SKILL.md:218`) and the cubic-termination option (c) (`build:213` / `fix:220`) — instruct the orchestrator to escalate findings to "the active epic's v0.1.X candidates section" and "the epic file." Those targets exist only in Roughly's own repo; in any consumer project the escalation points at nothing, so a real spec-gap finding is silently dropped. This is Roughly's dogfooding vocabulary leaking into consumer runtime prose (same class as #67). Fix: replace the epic-specific target with a tool-neutral, single-sourced escalation procedure (default `.roughly/spec-candidates.md`, overridable via the project's CLAUDE.md per ADR-006), extracted to `skills/shared/` per ADR-012 and `${CLAUDE_PLUGIN_ROOT}`-anchored per #67.

## Design decisions (from Stage 2)

- **Target resolution:** default append to `.roughly/spec-candidates.md`; a project may redirect via a documented line in its own `CLAUDE.md` (uses the existing ADR-006 runtime-CLAUDE.md mechanism — **no new config-file parser**, avoids B3 scope). Roughly's own repo uses that override to keep routing to its epic files.
- **Structure:** a new standalone `## SPEC-REVISION-CANDIDATE ESCALATION` H2 section in build/fix (mirrors `## ABORT HANDLING`) holding a `${CLAUDE_PLUGIN_ROOT}`-anchored `Read` of the new shared file; Stage 6's two paragraphs cross-reference it ("per SPEC-REVISION-CANDIDATE ESCALATION"). A dedicated heading is required so verify-all Check 8 can anchor the Read within 3 lines of a heading.
- **ADR number = ADR-019** (per ROADMAP.md:177 — 014–018 are reserved for the differential-gate spec set; new ADRs start ≥019). The stale ADR-reservation table in `differential-gate-allocation-specs.md` is a *separate* housekeeping item — not touched here.
- **Subsumes** the E06 "verdict persistent-artifact" carry-forward (ROADMAP:147/153).
- **Not a line saving:** the extraction nets ~+5–6 lines per file (new section), contra the ROADMAP's stale "frees budget" claim. Both files stay well under the 300 cap.

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| skills/shared/spec-candidate-escalation.md | Create | T1 |
| skills/build/SKILL.md | Modify | T2 |
| skills/fix/SKILL.md | Modify | T2 |
| .claude/hooks/verify-all.sh | Modify | T3 |
| CLAUDE.md | Modify | T4 |
| docs/adrs/ADR-019-tool-neutral-spec-candidate-escalation.md | Create | T5 |
| docs/adrs/README.md | Modify | T5 |

## Baseline facts (captured 2026-07-20, branch fix/72-de-dogfood-stage-6-spec-revision)
- build/fix = 277/282 lines (cap 300). The two target paragraphs are byte-identical across build and fix.
- The ONLY runtime consumer-leak sites are build:211,213 / fix:218,220 (grep `v0.1.X`/`candidates section`/`epic file` in skills/). audit-epic/review-epic "epic file" = designed function (out of scope); `.roughly/plans/*.md` = frozen historical (out of scope).
- verify-all Check 8 (`.claude/hooks/verify-all.sh`): existence loop L130 (`for shared in abort-handling.md stage-8-wrap-up.md gate-protocol.md`), pair loop L134 (`for pair in "STAGE 8: WRAP-UP|..." ...`), `${CLAUDE_PLUGIN_ROOT}`-anchored awk matcher L140 (already generic — needs no change).
- `${CLAUDE_PLUGIN_ROOT}` anchoring convention is live (from #67); the shared-file `Read` directive must use it.
- `.roughly/` today holds known-pitfalls.md, workflow-upgrades, plans/. No `.roughly/config` exists (planned for B3 only).

## Tasks

### T1: Create the shared escalation procedure (~4 min)
**Files:** skills/shared/spec-candidate-escalation.md
**Action:** Create the new shared file defining the tool-neutral escalation procedure, following the existing shared-file convention (one-line preamble descriptor → `## HEADING` → body), matching `skills/shared/abort-handling.md`/`gate-protocol.md` style.
**Details:** Content (`form:` — match house style; substance required):
- Preamble line: `Procedural reference invoked by `skills/build/SKILL.md` and `skills/fix/SKILL.md` from the `## SPEC-REVISION-CANDIDATE ESCALATION` section head. See ADR-012 (runtime-shared-reference pattern) and ADR-019 (tool-neutral escalation target).`
- `## SPEC-REVISION-CANDIDATE ESCALATION`
- Body procedure: (1) **Determine the target** — default `.roughly/spec-candidates.md` at the project root (`mkdir -p .roughly` then create the file if missing); if the project's `CLAUDE.md` documents a different spec-candidate escalation target (e.g. an epic file or issue tracker), use that instead. (2) **Append** the candidate (append-only via `Edit`/append — never overwrite) as a dated entry: the finding, why it can't be fixed in-task (AC contradiction / missing failure-mode coverage / prose ambiguity / anchoring weakness), and its source (task/story/PR). The appended entry is the evidence that it was recorded. (3) Do NOT silently accept (leaves the finding unaddressed) and do NOT attempt to fix (expands scope beyond the task, may collide with shipped AC contracts). Contains NO reference to "epic file" or "v0.1.X candidates" as the default (those are only the *example override*, phrased as one possible project target).
**Verify:** `test -f skills/shared/spec-candidate-escalation.md && grep -q '^## SPEC-REVISION-CANDIDATE ESCALATION$' skills/shared/spec-candidate-escalation.md && grep -qF '.roughly/spec-candidates.md' skills/shared/spec-candidate-escalation.md`
**UI:** no

### T2: Rewrite build/fix Stage 6 to reference the shared procedure + add the section (~5 min)
**Files:** skills/build/SKILL.md, skills/fix/SKILL.md
**Depends on:** T1
**Action:** In each file: (a) rewrite the two Stage 6 paragraphs' escalation clauses to cross-reference the new section instead of naming the epic target; (b) add a new standalone `## SPEC-REVISION-CANDIDATE ESCALATION` section (with the `${CLAUDE_PLUGIN_ROOT}`-anchored Read directive) immediately before the `## ABORT HANDLING` section. Structural uniformity: 2 byte-identical rewrites + 1 byte-identical new section shared across build/fix.
**Details:** Four edit sites (`verbatim:` for the replacement clauses):
1. **Paragraph A** (build:211, fix:218) — replace `Escalate via the active epic's v0.1.X candidates section as a documented candidate; do NOT silently accept` with `Escalate it per **SPEC-REVISION-CANDIDATE ESCALATION** (below); do NOT silently accept`.
2. **Paragraph B** (build:213, fix:220) — replace `escalate as a candidate via the active epic's v0.1.X candidates section, then accept the current state as documented-deferral.` with `escalate it per **SPEC-REVISION-CANDIDATE ESCALATION** (below), then accept the current state as documented-deferral.` AND replace `option (c) requires the candidate to be appended to the epic file (the diff to the v0.1.X candidates section is the evidence) before accepting the deferral.` with `option (c) requires the candidate to be recorded per SPEC-REVISION-CANDIDATE ESCALATION (the appended entry is the evidence) before accepting the deferral.`
3. **New section** (both files, byte-identical), inserted immediately before the `## ABORT HANDLING` heading:
   ```
   ## SPEC-REVISION-CANDIDATE ESCALATION

   Read `${CLAUDE_PLUGIN_ROOT}/skills/shared/spec-candidate-escalation.md` and apply the procedure documented there.

   ---
   ```
After the edits, NO occurrence of `v0.1.X candidates section` or `` appended to the epic file `` remains in build/fix (the revert-tripwire in T3 enforces this). Do not touch the disposition menu's other text, the cubic (a)/(b) criteria, or the evidence-artifact sentence for (b).
**Verify:** `! grep -qF 'v0.1.X candidates section' skills/build/SKILL.md && ! grep -qF 'v0.1.X candidates section' skills/fix/SKILL.md && grep -A3 '^## SPEC-REVISION-CANDIDATE ESCALATION$' skills/build/SKILL.md | grep -qF 'Read `${CLAUDE_PLUGIN_ROOT}/skills/shared/spec-candidate-escalation.md`' && grep -A3 '^## SPEC-REVISION-CANDIDATE ESCALATION$' skills/fix/SKILL.md | grep -qF 'Read `${CLAUDE_PLUGIN_ROOT}/skills/shared/spec-candidate-escalation.md`' && diff <(grep -A3 '^## SPEC-REVISION-CANDIDATE ESCALATION$' skills/build/SKILL.md) <(grep -A3 '^## SPEC-REVISION-CANDIDATE ESCALATION$' skills/fix/SKILL.md) && for f in skills/build/SKILL.md skills/fix/SKILL.md; do [ "$(wc -l < "$f")" -le 300 ] || echo "CAP $f"; done` (use `command grep`/`command diff` given the ugrep/function shims).
**UI:** no

### T3: Extend verify-all Check 8 for the new shared file + add a de-dogfood revert tripwire (~3 min)
**Files:** .claude/hooks/verify-all.sh
**Depends on:** T2
**Action:** Register `spec-candidate-escalation.md` in the ADR-012 drift check (existence + heading-pair loops), and add a tripwire that fails loudly if the epic-file leak phrase reappears in build/fix.
**Details:** Three in-place edits in the Check 8 block:
1. **Existence loop (L130):** add `spec-candidate-escalation.md` → `for shared in abort-handling.md stage-8-wrap-up.md gate-protocol.md spec-candidate-escalation.md; do`.
2. **Pair loop (L134):** add the pair → `... "GATE PROTOCOL|gate-protocol.md" "SPEC-REVISION-CANDIDATE ESCALATION|spec-candidate-escalation.md"; do` (the `${CLAUDE_PLUGIN_ROOT}`-anchored awk matcher at L140 is already generic and needs no change).
3. **Revert tripwire** — inside the existing `for skill in build fix` loop (alongside the inline-duplication guards ~L144–152), add TWO fixed-string checks (both original leak phrases, to catch a partial revert that reintroduces only one): if `skills/${skill}/SKILL.md` contains `v0.1.X candidates section` OR `appended to the epic file`, emit a drift line, e.g. `- de-dogfood regression: skills/${skill}/SKILL.md still names the epic-file escalation target (issue #72 — use SPEC-REVISION-CANDIDATE ESCALATION)`. Two `grep -qF` guards mirroring the existing inline-duplication-guard structure.
**Verify:** `bash -n .claude/hooks/verify-all.sh && ! bash .claude/hooks/verify-all.sh | grep -qF 'shared procedural reference drift' && ! bash .claude/hooks/verify-all.sh | grep -qF 'de-dogfood regression'` — script parses; after T2 the new shared-ref check passes and the revert tripwire is silent (no leak phrase present). The pre-existing known-pitfalls size advisory is unrelated.
**UI:** no

### T4: Document Roughly's own epic-file override in CLAUDE.md (~2 min)
**Files:** CLAUDE.md
**Action:** Add a line so Roughly's own runs keep routing spec candidates to its epic files (dogfood continuity), exercising the CLAUDE.md-override mechanism the shared procedure reads.
**Details:** Add (`form:`) a short statement in a sensible location (e.g. the `## Conventions` or `## Key Design Decisions` area): spec-revision-candidate escalation in THIS repo targets the active epic's `## v0.1.X candidates` section (overriding the default `.roughly/spec-candidates.md` per `skills/shared/spec-candidate-escalation.md` / ADR-019). Confirm placement by reading CLAUDE.md first.
**Verify:** `grep -qiF 'spec-revision-candidate' CLAUDE.md && grep -qF 'v0.1.X candidates' CLAUDE.md`
**UI:** no

### T5: ADR-019 + README index (~4 min)
**Files:** docs/adrs/ADR-019-tool-neutral-spec-candidate-escalation.md, docs/adrs/README.md
**Action:** Record the tool-neutral escalation-target decision as a new ADR and index it.
**Details:** Read a neighbor ADR (e.g. ADR-015) for house format. ADR-019 content (`form:`): **Status** Accepted 2026-07-20. **Context** — the Stage 6 spec-revision-candidate/cubic-(c) escalation named "the active epic's v0.1.X candidates section" / "the epic file," which exist in no consumer project → findings silently dropped (issue #72; same class as #67). **Decision** — escalation is a tool-neutral procedure single-sourced in `skills/shared/spec-candidate-escalation.md` (`${CLAUDE_PLUGIN_ROOT}`-anchored): default target `.roughly/spec-candidates.md` (append-only, zero-setup), overridable via the project's CLAUDE.md (ADR-006 mechanism — no new config parser); Roughly's own repo overrides to its epic files. Subsumes the E06 verdict-persistent-artifact carry-forward. **Consequences** — consumers get a working escalation target; drift guarded by verify-all Check 8 + a revert tripwire; note ADR numbering starts at 019 per ROADMAP (014–018 reserved), and the differential-gate reservation table's ADR-015 slot is stale (separate follow-up). Update `docs/adrs/README.md` index: add the ADR-019 row (mirror the existing row format), AND — since 019 skips 016–018 — add a one-line reserved-gap note before it (precedent: the ADR-010 "reserved, not yet written" row already in the index), e.g. `- ADR-016–018 — Reserved for the differential-gate-allocation spec set (not yet written); see docs/planning/differential-gate-allocation-specs.md`. This explains the 015→019 jump the way 009→011 is explained.
**Verify:** `test -f docs/adrs/ADR-019-tool-neutral-spec-candidate-escalation.md && grep -q 'ADR-019' docs/adrs/README.md && grep -qF 'ADR-016' docs/adrs/README.md && grep -qF '.roughly/spec-candidates.md' docs/adrs/ADR-019-tool-neutral-spec-candidate-escalation.md`
**UI:** no

## Blast Radius
- **Do NOT modify:** `skills/audit-epic/SKILL.md` / `skills/review-epic/SKILL.md` "epic file" references (their designed function, not a leak); any `.roughly/plans/*.md` "v0.1.X candidates"/"epic file" references (frozen historical records); the disposition menu's non-escalation text, the cubic (a)/(b) criteria; `build:11`≡`fix:11` preamble; the differential-gate-allocation-specs ADR reservation table (separate housekeeping item).
- **Watch for:** the new `## SPEC-REVISION-CANDIDATE ESCALATION` section must be byte-identical across build/fix and its Read directive line-start-anchored within 3 lines of the heading (Check 8, T3); the shared file's DEFAULT must be `.roughly/spec-candidates.md` (the epic file is only the override example) — otherwise the leak persists; use `command grep`/`command diff` in verifies (ugrep + shell-function shims); `${CLAUDE_PLUGIN_ROOT}` fixed-string greps need `-F` not `-E`.

## Conventions
- ADR-012 runtime-shared-reference pattern + `${CLAUDE_PLUGIN_ROOT}` anchoring (#67); ADR-006 (CLAUDE.md as runtime config); ADR-009 (build:11≡fix:11 sync pair — the new section is likewise mirrored, drift-checked by T3).
- Verifies assert the new anchored form's presence and the old leak phrase's absence; `${CLAUDE_PLUGIN_ROOT}` and the leak phrase are distinctive enough to avoid self-defeating greps.
- No automated test harness; structural greps + running verify-all.sh is the validation.
