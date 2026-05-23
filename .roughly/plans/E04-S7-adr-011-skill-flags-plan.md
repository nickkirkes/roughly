> **Status:** Historical — implemented and merged in commit b92e16f13220c80dca5f996a2d7f5d270d5f930a on 2026-05-15. This plan was an active build/fix artifact; treat as historical reference only.

# Implementation Plan: E04.S7 — ADR-011 Skill Flags as Public API

Plan-format-version: 1

## Scope

Create ADR-011 codifying the principle "User-facing skill behavior changes are flags in `$ARGUMENTS`, not environment variables. Env vars are reserved for debug-only, contributor-facing knobs." Update three cross-references (CLAUDE.md, ADR index, CONTRIBUTING.md). Doc-only; no skill/agent/hook/template changes (AC5).

## File Table

| File | Action | Task(s) |
|------|--------|---------|
| docs/adrs/ADR-011-skill-flags-as-public-api.md | Create | T1 |
| CLAUDE.md | Edit (2 hunks) | T2 |
| docs/adrs/README.md | Edit (append 1 line) | T3 |
| CONTRIBUTING.md | Edit (append 1 line) | T4 |

## Tasks

### T1: Create ADR-011 file (~5 min)
**Files:** docs/adrs/ADR-011-skill-flags-as-public-api.md
**Action:** Create new ADR file matching ADR-008/ADR-009 format precedent.
**Details:**

Use the `Write` tool to create the file. Exact structure:

- Line 1: `# ADR-011: Skill Flags as Public API, Env Vars as Debug-Only`
- Blank line
- `**Date:** 2026-05` (YYYY-MM format per ADR-008/ADR-009 precedent)
- `**Status:** Accepted` (verbatim — must match ADR-008/ADR-009; NOT "Approved")
- `**Decider:** Nick Kirkes`
- Blank line, then `---`, blank line.

Then required sections in this order:

1. `## Context` — Cite S11b-2 OQ1 resolution (2026-05-08). Name the three options considered: heredoc-fed stdin, override-token env var, flag (option (c) chosen). Identify env vars' silent-leak failure mode (CI debug sessions silently leaking into local development) as the primary motivation. AC1 requirement.

2. `## Decision` — State: user-facing skill behavior changes are flags in `$ARGUMENTS`, not environment variables. Flags are part of skill public API: visible in invocation history, self-documenting in CI scripts, harder to silently leak across contexts. AC1 requirement.

3. `## Consequences` — three subsections:
   - `### Positive`: Explicit invocation surface (auditable via `claude` invocation history); self-documenting in CI scripts and rerun history; flag-detection follows the standalone-token form documented in `.roughly/known-pitfalls.md` (cite by name, NOT by line number — see known-pitfalls "Doc claims citing specific line numbers rot silently").
   - `### Negative`: Flag proliferation risk on long-lived skills. Env-var-acceptable carve-out: debug-only, contributor-facing, no user-facing skill behavior change. Use a Haiku-routing budget threshold for cost-sensitive teams as a hypothetical example of an env-var case v0.2.0 might land. State explicitly: the example is hypothetical at ADR-write time — no real v0.2.0 env-var case has surfaced; if one does, ADR-011 may need amendment or carve-out extension. AC1 requirement.
   - `### Neutral` (optional; include if it adds clarity, omit otherwise).

4. `## Forward References` — Name v0.2.0's complexity flag (`Task N (Complexity: simple|standard|complex)`) as the first downstream consumer. State that the ADR covering plan-format-v2 (currently slotted as ADR-010) should treat ADR-011 as foundational. ADR-011 does NOT specify ADR-010's internal structure, citation form, or content placement — only the relationship: v0.2.0's user-facing surface inherits ADR-011's principle. AC1 requirement (state relationship by role, not by content).

5. `## Alternatives Considered` — Briefly cover: (a) override-token env var (rejected for silent-leak risk); (b) heredoc-fed stdin (rejected as ergonomically heavier and not pattern-portable across skills); (c) CONTRIBUTING.md note only (rejected — discoverability for a multi-release precedent).

Target body length: ~150–200 words content (epic target). Total file length will likely be ~50–80 lines including headings/blank lines.

**Critical content requirements (re-verified against AC1 before completion):**
- S11b-2 OQ1 cited by name with the 2026-05-08 resolution date
- v0.2.0 complexity flag named as first downstream consumer in Forward References
- Env-var carve-out present in Consequences/Negative with hypothetical Haiku-routing example
- Relationship to ADR-010 stated by ROLE, not by content/structure
- Status field exactly `**Status:** Accepted`

**Do NOT include:**
- Any line-number citations to other files
- Any specification of ADR-010's internal structure
- Any pre-drafted v0.2.0 ADR content
- Any forking of existing skill flags into env vars (no behavior changes per Out of Scope)

**Verify:** After write, run `wc -l docs/adrs/ADR-011-skill-flags-as-public-api.md` (sanity check it exists). Then `grep -Fn "Status: Accepted" docs/adrs/ADR-011-skill-flags-as-public-api.md` (verify exact verbatim status). Then `grep -Fn "S11b-2 OQ1" docs/adrs/ADR-011-skill-flags-as-public-api.md` (verify OQ1 cited). Then `grep -Fn "2026-05-08" docs/adrs/ADR-011-skill-flags-as-public-api.md` (verify resolution date). Then `grep -Fn "complexity flag" docs/adrs/ADR-011-skill-flags-as-public-api.md` (verify v0.2.0 consumer named).
**UI:** no

---

### T2: Update CLAUDE.md (2 hunks) (~3 min)
**Files:** CLAUDE.md
**Depends on:** none (T1 unnecessary for T2's edits, but T1 is the new artifact T2 references)
**Action:** Two surgical edits to CLAUDE.md per AC2.
**Details:**

**Hunk A — Structure table at line 17.** The current line reads:

```
| `docs/adrs/` | Architecture Decision Records (ADR-001 through ADR-009) |
```

Replace with:

```
| `docs/adrs/` | Architecture Decision Records (ADR-001 through ADR-011) |
```

Use the `Edit` tool with the full row as `old_string` for unique match. (Note: ADR-010 is reserved for v0.2.0 but not yet authored; the range "ADR-001 through ADR-011" accurately describes the inclusive range as ADR-011 exists and ADR-010 is the only gap — this matches the existing convention which states the range, not enumerates every file.)

**Hunk B — Key Design Decisions table at line 59.** Currently the last row is:

```
| ADR-009 | Plan-mode auto-detect via UserPromptSubmit hook + preamble substitution |
```

After this row, insert a new row:

```
| ADR-011 | User-facing skill behavior changes are flags, not env vars |
```

Use the `Edit` tool with `old_string` = the full ADR-009 row, `new_string` = the ADR-009 row + newline + the new ADR-011 row. This preserves table formatting and ensures the insert point is unique. (ADR-010 reserved for v0.2.0 — explicitly intentional gap in the sequential listing, matching the README.md convention.)

**Verify (using `grep -Fn` per the regex-metachar pitfall, NO regex):**

```
grep -Fn "ADR-001 through ADR-011" CLAUDE.md   # expect 1 hit (line 17)
grep -Fn "ADR-001 through ADR-009" CLAUDE.md   # expect 0 hits
grep -Fn "ADR-011 | User-facing skill" CLAUDE.md   # expect 1 hit (in table)
grep -Fn "9 ADRs" CLAUDE.md                    # expect 0 hits (already 0)
grep -Fn "9 Architecture Decision Records" CLAUDE.md   # expect 0 hits (already 0)
grep -Fn "ADR-009 in CLAUDE.md" CLAUDE.md      # expect 0 hits (already 0)
```

If any of the "expect 0 hits" checks return non-zero, the AC2 verification has failed and additional stale phrasings have been introduced — investigate.

**UI:** no

---

### T3: Update docs/adrs/README.md (~1 min)
**Files:** docs/adrs/README.md
**Action:** Append ADR-011 entry to the Current ADRs list per AC3.
**Details:**

Current last entry at line 36:

```
- [ADR-009](ADR-009-plan-mode-detection.md) — Plan-mode auto-detection via UserPromptSubmit hook + preamble update
```

Append after it (preserving the trailing newline structure):

```
- [ADR-011](ADR-011-skill-flags-as-public-api.md) — User-facing skill behavior changes are flags, not env vars
```

ADR-010 is intentionally skipped — it's reserved for v0.2.0 plan-format-v2 and not yet authored. This matches the convention (file does not exist → not listed).

Use `Edit` tool with the ADR-009 line as `old_string` and the ADR-009 line + ADR-011 line as `new_string` for unique-anchor insertion.

One-line summary must match the CLAUDE.md row text for consistency (AC3): "User-facing skill behavior changes are flags, not env vars."

**Verify:**

```
grep -Fn "[ADR-011]" docs/adrs/README.md       # expect 1 hit
grep -Fn "skill-flags-as-public-api.md" docs/adrs/README.md   # expect 1 hit
```

**UI:** no

---

### T4: Update CONTRIBUTING.md (~1 min)
**Files:** CONTRIBUTING.md
**Action:** Add one-line ADR-011 cross-reference in the `## Skill authoring conventions` section per AC4.
**Details:**

The `## Skill authoring conventions` section (added by E04.S6) ends at line 60 with:

```
When in doubt: if the cases are truly mutually exclusive, use case-dispatch language. If the steps must all run in order, use sequential language with explicit transitions.
```

Line 61 is blank; line 62 begins `## Tooling Pitfalls`.

Append after line 60 (before the blank line 61): one blank line, then the AC4 cross-reference verbatim:

```
User-facing skill behavior changes are flags, not environment variables (see [ADR-011](docs/adrs/ADR-011-skill-flags-as-public-api.md)).
```

Use `Edit` tool with `old_string` = the "When in doubt..." line, `new_string` = that line + blank line + AC4 cross-reference. This ensures unique anchor and preserves the blank-line spacing between sections.

**Note on phrasing:** AC4 specifies "environment variables" (full word) for the CONTRIBUTING.md prose, while CLAUDE.md's table cell uses "env vars" (abbreviated for table density). Both forms are acceptable — phrasing differs by venue.

**Verify:**

```
grep -Fn "ADR-011" CONTRIBUTING.md   # expect 1 hit
grep -Fn "skill-flags-as-public-api.md" CONTRIBUTING.md   # expect 1 hit
```

**UI:** no

---

## Blast Radius

- **Do NOT modify:** any file in `skills/`, `agents/`, `.claude/hooks/`, `scripts/`, `.github/`, `tests/`, `.claude-plugin/`, `.roughly/`. AC5 explicit: `git diff --stat` must show only paths in `docs/adrs/`, `CLAUDE.md`, `CONTRIBUTING.md`.
- **Do NOT create** ADR-010 or any other ADR file — ADR-010 reserved for v0.2.0.
- **Watch for:** Pre-existing markdown lint warnings on PostToolUse:Edit are normal and unrelated to changed lines — ignore out-of-hunk lint noise.

## Conventions

- ADR format matches ADR-008/ADR-009 precedent: `**Status:** Accepted` (verbatim), `**Date:** YYYY-MM`, `**Decider:** Nick Kirkes`, then `---`, then `## Context` / `## Decision` / `## Consequences` / `## Alternatives Considered`. Optional intermediate sections permitted (ADR-009 precedent).
- All verify-step greps use `grep -Fn` (fixed-string + line number) per known-pitfalls "Grep-metachar pitfall." NO regex anywhere.
- All existing-file edits use `Edit` with full-line unique-context `old_string` per known-pitfalls "Append-only edits must use Edit, not Write."
- Cross-references between files cite by section/concept name, NEVER by line number, per known-pitfalls "Doc claims citing specific line numbers rot silently."

## Final whole-PR verification (Stage 6/7 will re-run; capture here for completeness)

```
git diff --stat   # expect: only docs/adrs/ADR-011-..., docs/adrs/README.md, CLAUDE.md, CONTRIBUTING.md
```

If any file outside that allowlist appears in `git diff --stat`, AC5 has been violated — escalate.
