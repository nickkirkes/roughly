> **Status:** Historical — implemented and merged in commit 9dddf9d08f9cdda5edeff43394fe1a9f5f880ec8 on 2026-05-22. This plan was an active build/fix artifact; treat as historical reference only.

# Implementation Plan: E04.S2 — Marker-aware resume reporting in `/roughly:upgrade`

Plan-format-version: 1

## Feature summary

Add explicit "Resuming v0.1.X migration from step N of M…" reporting and a shared "Marker preserved at <path>…" abort suffix to `skills/upgrade/SKILL.md`. Resume detection logic exists silently in v0.1.4; v0.1.6 has no explicit resume branch yet. This story adds user-visible reporting at three resume-report sites (v0.1.4 + v0.1.6) and three abort-suffix sites (v0.1.4 mv-non-zero, v0.1.4 data-loss, v0.1.6 mv-non-zero).

## Scope decisions (from discovery)

1. **v0.1.2 is excluded from AC1.** v0.1.2's migration step has no `.migration-in-progress` marker and no numbered sub-steps. AC1's trigger condition ("when it detects an existing `.migration-in-progress` marker") is structurally impossible for v0.1.2 — adding a marker mechanic is out of scope per the story's "Out of scope: changing the marker file format, location, or contents" clause. The AC is vacuously satisfied for v0.1.2; this is documented in the plan and the implementation does not touch L16–L19. (Side note: AC1 in the epic spec labels v0.1.2's destination as `.ruckus/`; the actual SKILL.md L19 target is `.roughly/`. This is a spec typo; it does not affect the vacuous-satisfaction conclusion.)

2. **v0.1.4 resume-report N/M values:** When the v0.1.4 resume branch fires, steps 1–4 have effectively run (1 detection, 2 conflict-check-hits-marker, 3 marker-write skipped, 4 co-existence note) and step 5 is the next mutation. → **N=5, M=10**.

3. **v0.1.6 resume-report N/M values:** When the v0.1.6 marker is detected at step 1, step 1 itself is running (detection) and step 2 is the next mutation. The marker write at step 2 will be skipped on resume because the marker already exists. → **N=2, M=3**.

4. **AC1 canonical format follows the story spec verbatim.** Even when N-1=1, we emit `"steps 1-1 already ran"` (not the more natural "step 1 already ran"). This is a deliberate choice — the story spec quotes the canonical template; deviating to handle the singular case would invent semantics. If the awkwardness blocks shipping, the human can revise at review.

5. **AC5 ("existing successful-completion summary line is unchanged") is vacuously satisfied.** Discovery confirmed none of the three migrations emit a completion-summary line today. Nothing to preserve, nothing to disturb. No task addresses AC5 because there is no baseline to compare against.

6. **AC3 suffix applies only where the marker is guaranteed to be on disk.** Marker-write-failure aborts (v0.1.4 L34, v0.1.6 L64-write-fail) do NOT receive the suffix — the marker was not successfully written at those abort points. Three landing sites total: v0.1.4 mv-non-zero (L44), v0.1.4 data-loss emit (L44), v0.1.6 mv-non-zero (L64).

## File Table

| File | Action | Task(s) |
|------|--------|---------|
| skills/upgrade/SKILL.md | Modify | T1, T2, T3 |

## Tasks

### T1: Add v0.1.4 resume-report emit (~3 min)
**Files:** skills/upgrade/SKILL.md
**Action:** Modify the v0.1.4 step-2 resume branch (currently L26) to read the marker file contents and emit the canonical AC1 resume-report line BEFORE any subsequent mutation.
**Details:**

Current text at L25–L26 (after the parent bullet "Conflict check or partial-failure resume:" at L25):
```
   - If `.ruckus/.migration-in-progress` exists, set `mode = resume` (skip step 3's marker write; the existing marker is preserved) and proceed — steps 5–7 are idempotent so resume is safe.
```

Replace the entire L26 bullet with:
```
   - If `.ruckus/.migration-in-progress` exists, set `mode = resume` (skip step 3's marker write; the existing marker is preserved). Read the first line of `.ruckus/.migration-in-progress` and extract the ISO date (the first whitespace-separated token; the second token is the plugin version, per step 3's marker format). Emit: `"Resuming v0.1.4 migration from step 5 of 10 (marker dated YYYY-MM-DD; steps 1-4 already ran)."` (substitute the extracted date for `YYYY-MM-DD`). Then proceed — steps 5–7 are idempotent so resume is safe.
```

**Key constraints:**
- The emit string must appear BEFORE any of step 5's `mv`/`git mv` invocations fire — AC2. The current step-2 bullet runs entirely before step 3, 4, 5; insertion here is structurally pre-mutation. Confirm by reading the bullet ordering: step 2 → step 3 (skipped on resume) → step 4 (prose-only) → step 5 (first mutation site).
- Explicit `Read the first line of ... and extract the ISO date` instruction satisfies `.roughly/known-pitfalls.md` L52 (observable-signal grounding).
- The trailing `"` includes the period inside the backtick-quoted emit string per `.roughly/known-pitfalls.md` L68.

**Verify:**
```
grep -Fn 'Resuming v0.1.4 migration from step 5 of 10' skills/upgrade/SKILL.md
grep -Fn 'Read the first line of `.ruckus/.migration-in-progress`' skills/upgrade/SKILL.md
grep -Fn 'steps 1-4 already ran' skills/upgrade/SKILL.md
```
All three commands must return exactly one match each.

**UI:** no

---

### T2: Add v0.1.6 resume-detection branch with emit (~4 min)
**Files:** skills/upgrade/SKILL.md
**Action:** Modify v0.1.6 step 1 (currently L62) to add a new resume-detection branch that fires before the dirty-check and destination-conflict mutations. Emit the canonical AC1 resume-report line.
**Details:**

Current text at L62 (excerpt — full bullet is long):
```
1. **Detection and safety check:** If `docs/plans/` does not exist, skip this step entirely (idempotent). Otherwise check `git status --porcelain docs/plans/ 2>/dev/null` — if non-empty (uncommitted edits to historical plans), abort with: ...
```

Insert a new sentence between `(idempotent).` and `Otherwise check \`git status...`:

```
If `docs/plans/.migration-in-progress` exists (resume from a prior failed attempt), read the first line of the marker and extract the ISO date (the first whitespace-separated token; the second token is the plugin version, per step 2's marker format). Emit: `"Resuming v0.1.6 migration from step 2 of 3 (marker dated YYYY-MM-DD; steps 1-1 already ran)."` (substitute the extracted date for `YYYY-MM-DD`); set `mode = resume` (step 2's marker write becomes a no-op because the marker is already present — overwriting would lose the original migration date). Continue with the safety checks below.
```

So the final bullet reads:
```
1. **Detection and safety check:** If `docs/plans/` does not exist, skip this step entirely (idempotent). If `docs/plans/.migration-in-progress` exists (resume from a prior failed attempt), read the first line of the marker and extract the ISO date (the first whitespace-separated token; the second token is the plugin version, per step 2's marker format). Emit: `"Resuming v0.1.6 migration from step 2 of 3 (marker dated YYYY-MM-DD; steps 1-1 already ran)."` (substitute the extracted date for `YYYY-MM-DD`); set `mode = resume` (step 2's marker write becomes a no-op because the marker is already present — overwriting would lose the original migration date). Continue with the safety checks below. Otherwise check `git status --porcelain docs/plans/ 2>/dev/null` — if non-empty ...
```

**Key constraints:**
- AC2: emit must precede any mutation. The dirty-check (`git status`) is read-only; the destination-conflict ABORT path is read-only (it exits before any mutation); the destination-clearing `rm -rf .roughly/plans/` branch IS a mutation but fires AFTER the emit because the emit insertion point precedes ALL step-1 safety checks; step 2's `mv`/`git mv` is the mutation that completes the migration. Resulting execution order: emit → git-status check → conflict abort or rm-rf clear → step 2 mv. The emit always precedes every mutation.
- The new branch sets `mode = resume` so step 2's marker write becomes a no-op (parallel to v0.1.4's pattern at step 3). T2 must also update step 2 to honor `mode = resume` — see "step 2 marker-write no-op" sub-edit below.
- The canonical format requires "steps 1-1 already ran" (per scope decision 4). Do not "fix" this to "step 1 already ran".
- The `.roughly/plans/` destination-conflict abort at the end of step 1 (`"Both docs/plans/ and .roughly/plans/ exist with content..."`) remains untouched — it fires only when `.roughly/plans/` has non-marker content, which is a different state from "fresh resume from `docs/plans/.migration-in-progress`."

**Step 2 marker-write no-op sub-edit:**
The current step 2 text (L64) reads:
```
2. **Move:** Write marker at `docs/plans/.migration-in-progress` (the SOURCE dir — writing into the destination would create `.roughly/plans/` and make `git mv` nest `docs/plans/` INSIDE the destination rather than renaming) containing the current ISO date and plugin version. If the marker write fails ...
```

Change the opening sentence to honor `mode = resume`:
```
2. **Move:** Skip the marker write if `mode = resume` (existing marker is preserved; overwriting would lose the original migration date — matches v0.1.4 step 3's idiom). Otherwise write marker at `docs/plans/.migration-in-progress` (the SOURCE dir — writing into the destination would create `.roughly/plans/` and make `git mv` nest `docs/plans/` INSIDE the destination rather than renaming) containing the current ISO date and plugin version. If the marker write fails ...
```

**Verify:**
```
grep -Fn 'Resuming v0.1.6 migration from step 2 of 3' skills/upgrade/SKILL.md
grep -Fn 'If `docs/plans/.migration-in-progress` exists (resume from a prior failed attempt)' skills/upgrade/SKILL.md
grep -Fn 'Skip the marker write if `mode = resume`' skills/upgrade/SKILL.md
grep -Fn 'steps 1-1 already ran' skills/upgrade/SKILL.md
```
All four commands must return exactly one match each.

**UI:** no

---

### T3: Add AC3 abort-suffix at all three landing sites (~5 min)
**Files:** skills/upgrade/SKILL.md
**Depends on:** none (independent of T1/T2 — touches different abort paths)
**Action:** Append the canonical shared suffix `"Marker preserved at <path> for resume on next /roughly:upgrade."` to each of the three abort paths where the marker is guaranteed to be on disk.
**Details:**

**Landing site 1: v0.1.4 `mv` non-zero (L44).** Current trailing prose of the step-5 bullet:
```
If the move command returns non-zero, surface the error output verbatim and abort the migration step — the marker stays in place so a future re-run can resume from step 2.
```

Append the shared suffix as a follow-on sentence:
```
If the move command returns non-zero, surface the error output verbatim and abort the migration step — the marker stays in place so a future re-run can resume from step 2. Emit: `"Marker preserved at .ruckus/.migration-in-progress for resume on next /roughly:upgrade."`
```

**Landing site 2: v0.1.4 data-loss emit (L44).** Current emit string:
```
"Possible data loss: neither .ruckus/[file] nor .roughly/[file] found — the marker will stay in place for inspection."
```

Modify to append the suffix as a second sentence within the emit (single emit, two sentences):
```
"Possible data loss: neither .ruckus/[file] nor .roughly/[file] found — the marker will stay in place for inspection. Marker preserved at .ruckus/.migration-in-progress for resume on next /roughly:upgrade."
```

Note: this is a single backtick-quoted emit; the suffix becomes the second sentence of the same emit string per the story's "shared suffix" framing. Period inside backticks per pitfall L68.

**Landing site 3: v0.1.6 `mv` non-zero (L64).** Current trailing prose:
```
If the move command returns non-zero, surface the error verbatim and abort — the marker stays at `docs/plans/.migration-in-progress` for re-run.
```

Append the shared suffix as a follow-on sentence:
```
If the move command returns non-zero, surface the error verbatim and abort — the marker stays at `docs/plans/.migration-in-progress` for re-run. Emit: `"Marker preserved at docs/plans/.migration-in-progress for resume on next /roughly:upgrade."`
```

**Key constraints:**
- One shared idiom, three sites — the wording template `"Marker preserved at <path> for resume on next /roughly:upgrade."` is identical at all three sites; only the path substitution varies.
- Sites 1 and 3 wrap the suffix as a second sentence with `Emit:` prefix because the surrounding prose is descriptive ("the marker stays in place..."); the explicit `Emit:` clarifies this is a user-facing emit, not orchestrator narration. Site 2 differs: the surrounding context is already an `Emit:` quoted string, so the suffix is appended as a second sentence inside the same backtick-quoted emit string (no second `Emit:` wrapper).
- Marker-write-failure aborts (v0.1.4 L34, v0.1.6 mid-L64 marker-write branch) do NOT get the suffix — marker is not on disk at those abort points.

**Verify:**
```
grep -Fo 'Marker preserved at .ruckus/.migration-in-progress for resume on next /roughly:upgrade.' skills/upgrade/SKILL.md | wc -l
grep -Fo 'Marker preserved at docs/plans/.migration-in-progress for resume on next /roughly:upgrade.' skills/upgrade/SKILL.md | wc -l
```
First command must return `2` (sites 1 and 2 — both land on the same physical line L44; `grep -Fc`/`grep -Fn` would count lines and return `1`, hence `-Fo | wc -l` to count occurrences). Second command must return `1` (site 3 on L64).

Confirm marker-write-failure aborts did NOT receive the suffix:
```
grep -A1 'Cannot write marker' skills/upgrade/SKILL.md | grep -Fc 'Marker preserved'
```
Must return `0`.

**UI:** no

---

### T4: Final line-budget and structural verification (~2 min)
**Files:** skills/upgrade/SKILL.md (read-only)
**Depends on:** T1, T2, T3
**Action:** Verify the file remains under the 300-line cap (AC4), the AC1 canonical format appears exactly twice (once per migration with marker), the AC3 suffix appears exactly three times, and no extraneous structural changes occurred.
**Details:**

Run the verification commands below. All must pass before declaring T4 complete.

**Verify:**
```bash
# AC4: line cap
LC=$(wc -l < skills/upgrade/SKILL.md); test "$LC" -le 300 && echo "OK ($LC/300)" || echo "FAIL ($LC/300)"

# AC1: exactly two resume-report emits (v0.1.4 + v0.1.6)
grep -Fc 'Resuming v0.1.' skills/upgrade/SKILL.md  # expect 2

# AC3: exactly three abort-suffix emits (sites 1 and 2 are on the same line L44, so -Fc would return 2 not 3; use -Fo | wc -l for occurrence count)
grep -Fo 'Marker preserved at' skills/upgrade/SKILL.md | wc -l  # expect 3

# AC5: no completion-summary emits introduced (sanity — story says existing summaries unchanged; we never added one)
grep -Fc 'migration complete' skills/upgrade/SKILL.md  # expect 0 (none existed, none added)

# Existing migration-summary bullets at step 7 still intact
grep -Fn 'Updated' skills/upgrade/SKILL.md | grep -Fc 'path references in CLAUDE.md'  # expect 1
```

**UI:** no

---

## Blast Radius

- **Do NOT modify:**
  - Any agent files (`agents/*.md`)
  - Any other skill files (`skills/build/`, `skills/fix/`, `skills/setup/`, etc.) — the marker is referenced as a pre-flight signal in 7 other skills but those references are out of scope
  - `.roughly/known-pitfalls.md`
  - CHANGELOG.md (wrap-up adds a note if requested by human at Stage 8)
  - ADRs (no ADR governs the marker mechanic; the story does not add one)

- **Watch for:**
  - The marker file path differs between sites: `.ruckus/.migration-in-progress` (v0.1.4) vs `docs/plans/.migration-in-progress` (v0.1.6 pre-move). Do not cross the paths.
  - The "shared suffix" is a template, not a literal string match across sites — path substitution varies.
  - Existing step numbering (1–10 in v0.1.4, 1–3 in v0.1.6) must remain intact; do not renumber.

## Conventions

- **CLAUDE.md → Skill bodies ≤300 lines.** AC4 enforces this; T4 verifies.
- **`.roughly/known-pitfalls.md`:**
  - L52 (observable signals) — emit instructions reference file reads explicitly (`Read the first line of \`.ruckus/.migration-in-progress\``), not abstract "use the marker date."
  - L66 (discrete emit sites) — three AC3 sites are enumerated separately in T3, not collapsed into "apply at the relevant places."
  - L68 (period inside backtick) — the canonical emit string `"... for resume on next /roughly:upgrade."` has the period inside the closing quotation.
  - L102 (use `grep -Fn`) — all `Verify:` commands use `grep -Fn` / `grep -Fc` for literal-substring matching against emit strings containing backticks, periods, and slashes.
- **ADR-006 (CLAUDE.md at runtime):** No CLAUDE.md changes in this story. The runtime model reads CLAUDE.md when the upgrade skill runs, but no new CLAUDE.md fields are introduced.
- **No agent-preamble sync impact:** This story touches only one skill file; no agent files reference the resume-report mechanism.
