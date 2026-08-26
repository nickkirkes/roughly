> **Status:** Historical — implemented and merged in commit d34eaf30421025e269a1a198b4121ce057ca82a8 on 2026-08-26. This plan was an active build/fix artifact; treat as historical reference only.

# Implementation Plan: E07.S3 — CHANGELOG v0.1.9 backfill + heading revert

Plan-format-version: 1

**Story:** E07.S3 · **Issue:** [#93](https://github.com/nickkirkes/roughly/issues/93)
**Canonical ACs:** `docs/planning/epics/E07-codification-closeout-and-release-gate-repair.md` lines 239–257 (the epic wins over the issue brief if they disagree).

## File Table

| File | Action | Task(s) |
|------|--------|---------|
| CHANGELOG.md | Modify | T1, T2, T3, T4 |
| (none — verification only) | Verify | T5 |

`CHANGELOG.md` is the **only** file this story may modify. Every task below edits the v0.1.9 section and nothing else.

## Ground truth established at discovery

These facts were verified against the actual diffs (`git show dec9d28`, `git show 43e1e48`) — do not re-derive them from issue titles or epic prose, and do not contradict them:

- **PR #90 = commit `dec9d28`** (squash commit, single parent — the commit's own diff is the full PR diff). Delivered #81–#87.
- **PR #91 = commit `43e1e48`** (squash commit). Delivered #89.
- **Both PRs merged 2026-07-29.** The `2026-07-27` date currently on the premature heading is wrong; it must not appear in any entry prose.
- **#84 and #86 EXTEND existing `.roughly/known-pitfalls.md` entries in place** (the diffs show `-`/`+` replacement of the same bullet). They do NOT add new entries. Writing "added a new pitfalls entry" for either is a factual error of exactly the class epic Risk R5 warns about.
- **#87 touched four files**, not one: `.roughly/known-pitfalls.md`, `docs/adrs/ADR-009-plan-mode-detection.md`, `CONTRIBUTING.md`, `skills/review-plan/SKILL.md`.
- **#83 and #84 both legitimately touch `skills/review-plan/SKILL.md` § Completeness** — same section, same PR. This is accurate, not duplicated content.
- **All eight issues are `### Added`** — each introduces new normative text or new detection logic; none modifies already-shipped behavior. No `### Changed` section is created by this story.

## Current file state

`CHANGELOG.md` opens:

```
1  # Changelog
2
3  ## [0.1.9] — 2026-07-27
4
5  ### Removed
6
7  - **Obsolete `ruckus` / pre-v0.1.6 legacy machinery (#80).** …
8
9  ## [0.1.8] — 2026-06-10
```

## House style (match the v0.1.8 section)

- Section order within a release: `### Added`, then `### Changed`, then `### Removed`.
- Entry form: `- **Bold lead-in naming the change (#NN).** Prose paragraph.`
- File references are inline markdown links to bare relative paths — `[CONTRIBUTING.md](CONTRIBUTING.md)` — **never** with line numbers in the link text (line-cite rot).
- Refer to `CONTRIBUTING.md` sections by name in backticks, e.g. `` `## CI conventions` ``.
- `CHANGELOG.md:87` and `CHANGELOG.md:89` are the closest length/shape templates: one medium paragraph naming what changed, where it landed, and why.

---

## Tasks

### T1: Revert the v0.1.9 heading to pre-tag form (~2 min)

**Files:** CHANGELOG.md
**Action:** Satisfy AC1 — replace the prematurely-renamed, misdated heading.
**Details:**
Change line 3 from:

```
## [0.1.9] — 2026-07-27
```

to exactly:

```
## [Unreleased] — v0.1.9
```

Note the em dash (`—`, U+2014) — it must be an em dash, not a hyphen, matching every other heading in the file. Change nothing else: do not touch line 5's `### Removed`, the #80 entry on line 7, or the `## [0.1.8]` heading on line 9.

Rationale (do not add this to the file, it is context for you): the DoD requires the version rename to happen at tag time. The tag-time re-date is E07.S7's job, explicitly out of scope here. This matches the E06 post-audit precedent (Rec 2, 2026-06-10) where the identical premature rename was reverted for v0.1.8.

**Verify:** `grep -c '^## \[Unreleased\] — v0.1.9' CHANGELOG.md` outputs exactly `1`, and `grep -c '^## \[0.1.9\]' CHANGELOG.md` outputs exactly `0`.
**UI:** no

---

### T2: Add the `### Added` section with entries for #81, #82, #83 (~5 min)

**Files:** CHANGELOG.md
**Action:** Create the `### Added` subsection in the v0.1.9 block (above the existing `### Removed`, per house order) and write the first three Cluster A entries. Partial satisfaction of AC2 and AC5.
**Details:**
Insert a new `### Added` heading immediately after the `## [Unreleased] — v0.1.9` heading and its blank line, i.e. **above** the existing `### Removed` heading. The existing `### Removed` section and its #80 entry must survive byte-identical.

Write three bullets under `### Added`, in ascending issue order. Each must cite **PR #90** and name at least one file it touched (AC4). Each must name the `CONTRIBUTING.md` section it created or extended (AC2). Facts per entry:

**#81 — verified-tag provenance rule.** Appended a paragraph to the **existing** `## Audit conventions` section of [CONTRIBUTING.md](CONTRIBUTING.md) (it did not create a new section). The rule: an inference must be marked `inferred from <observation>` or "hypothesized" — never "verified" — because a "verified" tag on an inferred mechanism propagates a false claim downstream. Companion entry added to [.roughly/known-pitfalls.md](.roughly/known-pitfalls.md) under `## Documentation Hygiene`. Delivered by PR #90.

**#82 — CI assertion authoring convention.** Created the **new** top-level `## CI conventions` section in [CONTRIBUTING.md](CONTRIBUTING.md) (this issue is the section's first content). The convention: a CI fixture assertion must combine structural signals with at least one discriminating behavioral signal — structural-only assertions pass against a broken implementation. Cites the `F6` assertion in [scripts/ci-dogfood.sh](scripts/ci-dogfood.sh) as the canonical example. Companion entry added to [.roughly/known-pitfalls.md](.roughly/known-pitfalls.md) under `## Build & Deploy`. Delivered by PR #90.

**#83 — spec-example command validation.** Added an "Executable example content" paragraph to `## AC authoring conventions` in [CONTRIBUTING.md](CONTRIBUTING.md), with a paired enforcement check added to the `## Completeness` block of [skills/review-plan/SKILL.md](skills/review-plan/SKILL.md). The convention: an example command embedded in a normative doc or AC must be validated against **that specific invocation**, not a bare `--help` exit-0 check. Precipitating evidence: the malformed `gh api PATCH …` example shipped in E06.S7.AC1. Companion entry added to [.roughly/known-pitfalls.md](.roughly/known-pitfalls.md) under `## Documentation Hygiene`. Delivered by PR #90.

Match the v0.1.8 entry style: bold lead-in ending in the issue number in parentheses, then one medium prose paragraph. Do not invent cross-reference sub-bullets, counts, line numbers, or claims not stated above.

**Verify:** `grep -c '^### Added' CHANGELOG.md` increases by 1 versus before the edit; `grep -c '(#81)\|(#82)\|(#83)' CHANGELOG.md` outputs `3`; `grep -c '^### Removed' CHANGELOG.md` is unchanged; the #80 entry still present via `grep -c 'Obsolete `ruckus`' CHANGELOG.md` = 1.
**UI:** no

---

### T3: Add entries for #84, #85, #86 (~5 min)

**Files:** CHANGELOG.md
**Depends on:** T2
**Action:** Complete AC2 — write the remaining three Cluster A entries under the `### Added` section created in T2.
**Details:**
Append three bullets after the #83 entry, in ascending issue order, same style. Each cites **PR #90** and names ≥1 touched file.

**#84 — mirror-verbatim vs negative-grep cross-test.** Added a "Mirror-verbatim vs negative-grep cross-test" paragraph to `## AC authoring conventions` in [CONTRIBUTING.md](CONTRIBUTING.md), with a paired check in the `## Completeness` block of [skills/review-plan/SKILL.md](skills/review-plan/SKILL.md). Precipitating evidence: the actual self-contradiction in E06.S2.AC1, where a mirror-verbatim requirement and a negative-grep assertion could not both hold. **Also extended the existing self-contradiction entry** in [.roughly/known-pitfalls.md](.roughly/known-pitfalls.md) under `## Planning & Scoping` — it amended that entry in place; it did **not** add a new one. Delivered by PR #90.

**#85 — CI job-key stability.** Appended a "CI job key stability" paragraph to the `## CI conventions` section that #82 created in [CONTRIBUTING.md](CONTRIBUTING.md). The rule: renaming a GitHub Actions job key in place silently breaks required-status-check enforcement, because the branch protection rule references the old key and simply never matches. Names the real job key `dogfood-build-cycle` and the rename attempt that was reverted. Companion entry added to [.roughly/known-pitfalls.md](.roughly/known-pitfalls.md) under `## Build & Deploy`. Delivered by PR #90.

**#86 — epic Open Question resolution annotation.** Created the **new** top-level `## Epic Open Question resolution` section in [CONTRIBUTING.md](CONTRIBUTING.md), placed between `## Cross-epic AC amendments` and `## Audit conventions`. Specifies the annotation form: the original question struck through, followed by a bolded resolution naming the story and date. **Also extended the existing Open Question entry** in [.roughly/known-pitfalls.md](.roughly/known-pitfalls.md) under `## Planning & Scoping`, tightening its timing requirement from "at ship time" to "in the same commit that ships the resolution" — an amendment to that entry, **not** a new entry. Delivered by PR #90.

Critical accuracy constraint: for #84 and #86 the known-pitfalls change was an **extension of an existing entry**, verified in the diff. Do not write "added a new entry" or "new pitfall documented" for either.

**Verify:** `grep -c '(#84)\|(#85)\|(#86)' CHANGELOG.md` outputs `3`; `grep -ci 'added a new.*pitfall\|new pitfalls entry' CHANGELOG.md` outputs `0` for the newly written text (inspect the #84 and #86 entries by eye to confirm they say "extended"/"amended", not "added").
**UI:** no

---

### T4: Add entries for #87 and #89 (~5 min)

**Files:** CHANGELOG.md
**Depends on:** T3
**Action:** Satisfy AC3 — write the two remaining entries under `### Added`.
**Details:**
Append two bullets after the #86 entry, same style.

**#87 — known-pitfalls navigability reorg (PR #90).** A pure-move reorganization of [.roughly/known-pitfalls.md](.roughly/known-pitfalls.md): two misfiled entries were relocated verbatim — the CHANGELOG intra-file line-cite entry moved to `## Documentation Hygiene`, and the gate-UI-laundering / ADR-015 entry moved to `## Skill & Agent Authoring`. Net-zero line count (208 lines before and after — nothing was added or deleted, only moved). In the same change, stale absolute-line citations pointing into known-pitfalls.md were replaced with topic-form section-name citations across three other files: [docs/adrs/ADR-009-plan-mode-detection.md](docs/adrs/ADR-009-plan-mode-detection.md), [CONTRIBUTING.md](CONTRIBUTING.md), and [skills/review-plan/SKILL.md](skills/review-plan/SKILL.md). Name more than one of these files in the entry — this issue touched four files, and naming only known-pitfalls.md would understate it.

**#89 — Stage 6 epic Open Question resolution enforcement (PR #91).** Added **Process step 8** to [agents/code-reviewer.md](agents/code-reviewer.md): when a diff resolves an epic Open Question — whether asserted in the CHANGELOG or commit message, or implemented as a decision mapping to an open epic OQ — the reviewer confirms the same diff also annotates that epic's `## Open questions` section with a matching strikethrough + resolution annotation, per the `## Epic Open Question resolution` convention #86 codified. Flags **Critical** if an OQ is resolved without its epic entry reflecting it; the check is inert and skipped in projects with no epic docs carrying open questions. The same change broadened a Rules bullet from "convention violations documented in CLAUDE.md" to "documented in CLAUDE.md **or** CONTRIBUTING.md."

**AC3 has a mandatory clause for the #89 entry:** it must state that **both the build and fix pipelines inherit this check via `/roughly:review`** — it is not build-only. This was verified directly at discovery, not taken from the commit message: [skills/build/SKILL.md](skills/build/SKILL.md) Stage 6 and [skills/fix/SKILL.md](skills/fix/SKILL.md) Stage 6 both invoke `/roughly:review`, which dispatches `code-reviewer` in parallel with the other two reviewers, so step 8 — a property of the agent — reaches both pipelines identically. Write this as a DRY-inheritance statement.

**Verify:** `grep -c '(#87)\|(#89)' CHANGELOG.md` outputs `2`; and the AC3 inheritance clause is present in the #89 entry specifically — `grep -c '(#89).*roughly:review\|roughly:review.*(#89)' CHANGELOG.md` outputs `1`.

Note on that second check: a bare `grep -c 'roughly:review' CHANGELOG.md` would **not** work here — the string already occurs 7 times in pre-existing E05/E06 entries, so a `≥ 1` threshold passes whether or not this task runs. The check above is anchored to `(#89)` on the same physical line, which only exists once this entry is written (house style puts each bullet on one long unwrapped line). Additionally **read the #89 entry** and confirm by eye that it names both `build` and `fix` as inheriting the check — the grep confirms the entry cites `/roughly:review`, not that the DRY-inheritance claim is stated correctly.
**UI:** no

---

### T5: AC4 spot-diff verification of every new entry (~5 min)

**Files:** none (read-only verification; may return findings for correction)
**Depends on:** T4
**Action:** Satisfy AC4 — prove each of the eight new entries is checkable against its merging PR's diff.
**Details:**
`CHANGELOG.md` is subject to **no** structural check in `.claude/hooks/verify-all.sh` (confirmed: zero references). AC1's grep and this spot-diff are therefore the only real gates on this story. Do not skip or assume.

For each of the eight new entries (#81, #82, #83, #84, #85, #86, #87, #89):

1. Read the entry and extract (a) the PR number it cites, (b) every file path it names.
2. Run `git show --stat <sha>` for the cited PR — `dec9d28` for PR #90, `43e1e48` for PR #91 — and confirm every named file actually appears in that commit's diff.
3. For entries naming a `CONTRIBUTING.md` section, run `git show <sha> -- CONTRIBUTING.md` and confirm the named section heading appears in the diff as created or modified.
4. For #84 and #86, inspect the `.roughly/known-pitfalls.md` change and confirm it is an in-place amendment (paired `-`/`+` on the same bullet), matching what the entry claims. **Use the isolated pre-squash commit — `aea184c` for #84, `9d98d46` for #86 — not `dec9d28`.**
5. For #87, confirm the 208-line net-zero claim **against the isolated pre-squash commit `70f007e`, not `dec9d28`**: `git show 70f007e --stat -- .roughly/known-pitfalls.md` should show equal insertions and deletions, and `git show 70f007e:.roughly/known-pitfalls.md | wc -l` should match `git show 70f007e^:.roughly/known-pitfalls.md | wc -l`.
6. For #89, confirm `agents/code-reviewer.md` is in `43e1e48`'s diff and that Process step 8 text is present in the current file.

**Do not measure an issue-scoped count against a squash SHA.** `dec9d28` aggregates all seven of #81–#87's edits to `.roughly/known-pitfalls.md`; measured there, #87's net-zero claim reads as 30 insertions / 14 deletions and 208-vs-192 lines, which is a **false fail against a true claim**. Step 2's `<sha>` binding is for file-presence checks only — any check that isolates one issue's effect must cite that issue's pre-squash sub-commit. (Recorded as a v0.1.10 candidate in the E07 epic.)

Report a table: entry → cited PR → named files → present in diff (yes/no) → any correction applied.

If a check fails, first confirm you measured against the right commit — a mismatch sourced from a squash SHA is a defect in the check, not in the entry. Once the measurement is sound, a genuine mismatch is a defect in the entry: fix the entry text to match the diff, then re-verify. Report honestly if a claim could not be substantiated.

**Verify:** `grep -c '^## \[Unreleased\] — v0.1.9' CHANGELOG.md` = 1; every one of `(#81)` through `(#87)` and `(#89)` present exactly once; `bash .claude/hooks/verify-all.sh` runs clean.
**UI:** no

---

## Blast Radius

- **Do NOT modify:** any file other than `CHANGELOG.md`. Specifically not `CONTRIBUTING.md`, `.roughly/known-pitfalls.md`, `agents/code-reviewer.md`, `skills/*/SKILL.md`, or any epic file — those are the *subjects* of the entries, already merged, and must be read-only here.
- **Do NOT touch** the `## [0.1.8]` section or anything below it. The v0.1.8 section is the style template, read-only.
- **Do NOT touch** the existing `### Removed` heading or the #80 entry (AC5 requires it survive).
- **Out of scope (all E07.S7):** the tag-time re-date, `plugin.json` version bump, the ROADMAP Current marker. Do not anticipate them.
- **Out of scope:** entries for E07 work that has not shipped (S1, S2, S4, S5, S6, S7). Only #81–#87 and #89 get entries.
- **Watch for:** the em dash in the heading; the wrong `2026-07-27` date leaking into entry prose (both PRs merged 2026-07-29); markdown links carrying line numbers.

## Conventions

- Match the `## [0.1.8]` section's structure and entry shape (epic AC5). `CHANGELOG.md:87` and `:89` are the closest shape templates.
- Section order within a release: Added → Changed → Removed.
- File references as inline markdown links to bare relative paths, no line numbers (the line-cite-rot pitfall documented in `.roughly/known-pitfalls.md` `## Documentation Hygiene` — which #87 itself reorganized).
- Epic Risk R5 governs this whole story: these entries are written ~3 weeks post-merge from diffs, not from build context, and the E06 audit previously caught an inaccurate claim in an entry written *with* fresh context. **Every factual claim in an entry must be traceable to the diff.** When in doubt, write less and stay checkable rather than more and risk an unsupported claim.
- The epic is canonical for ACs; the GitHub issue brief summarizes and links. If they disagree, the epic wins.
