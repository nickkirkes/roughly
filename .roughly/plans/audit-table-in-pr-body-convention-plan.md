> **Status:** Historical — implemented and merged in commit 91f0b8719a8d42ec8fa5b24c89013be184e19008 on 2026-06-09. This plan was an active build/fix artifact; treat as historical reference only.

# Implementation Plan: E06.S7 — audit-table-in-PR-body CONTRIBUTING.md convention

Plan-format-version: 1

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| CONTRIBUTING.md | Modify (additive) | T1 |
| CHANGELOG.md | Modify (additive) | T2 |

## Tasks

### T1: Add `## Audit conventions` section to CONTRIBUTING.md (~3 min)
**Files:** CONTRIBUTING.md
**Action:** Insert a new top-level `## Audit conventions` section codifying the audit-table-in-PR-body convention.
**Details:**
Insert the new section **between** the end of the `## Cross-epic AC amendments` section (its last content line is the paragraph ending `... → E06.S1 (latest amender).` at L93) and the `## Tooling Pitfalls` heading (L95). Use the Edit tool with `old_string` anchored on the `## Tooling Pitfalls` heading so the new section is inserted immediately before it.

The new section text (matches the bold-lead-sentence + prose style of the three preceding convention sections):

```markdown
## Audit conventions

When a story produces audit-style output — an audit table, scope enumeration, or finding inventory (for example, the per-site `mkdir -p` audit table in E05.S4.5, or the per-AC table in `/roughly:audit-epic` output) — the audit content MUST be pasted into the GitHub PR body at PR-creation time. The PR body is the canonical discoverable artifact for code reviewers; plan-appendix copies and commit-body copies are secondary records only. Use `gh pr create --body-file <file>` at creation time, or `gh api PATCH /repos/<owner>/<repo>/pulls/<pr>` for programmatic updates when the PR was created before the audit table was finalized.

**Pitfall:** `gh pr edit --body-file` silently no-ops in the after-PR-creation case (verified 2026-05-31) — use `gh api PATCH` to ensure the update lands.

```

Concretely, the Edit replaces:
```
## Tooling Pitfalls
```
with:
```
## Audit conventions

When a story produces audit-style output — an audit table, scope enumeration, or finding inventory (for example, the per-site `mkdir -p` audit table in E05.S4.5, or the per-AC table in `/roughly:audit-epic` output) — the audit content MUST be pasted into the GitHub PR body at PR-creation time. The PR body is the canonical discoverable artifact for code reviewers; plan-appendix copies and commit-body copies are secondary records only. Use `gh pr create --body-file <file>` at creation time, or `gh api PATCH /repos/<owner>/<repo>/pulls/<pr>` for programmatic updates when the PR was created before the audit table was finalized.

**Pitfall:** `gh pr edit --body-file` silently no-ops in the after-PR-creation case (verified 2026-05-31) — use `gh api PATCH` to ensure the update lands.

## Tooling Pitfalls
```
(This is the safest anchor because the `## Tooling Pitfalls` heading is a unique literal. Do NOT modify any existing `## Cross-epic AC amendments` content.)

**Verify:** `grep -Fn "audit table" CONTRIBUTING.md` returns ≥1 match in the new section AND `grep -Fn "gh api PATCH" CONTRIBUTING.md` returns ≥1 match in the same section AND `grep -Fn "## Audit conventions" CONTRIBUTING.md` returns exactly 1 match positioned before `## Tooling Pitfalls`.
**UI:** no

### T2: Add CHANGELOG `### Added` entry for E06.S7 (~3 min)
**Files:** CHANGELOG.md
**Depends on:** T1
**Action:** Append a new bullet to the existing `### Added` subsection under `## [0.1.8] — 2026-06-03`.
**Details:**
The `### Added` subsection is at L7 under `## [0.1.8] — 2026-06-03`. The last current bullet is the E06.S2 entry whose final sub-bullet (L28) reads:
`  - **Line cap held:** \`skills/fix/SKILL.md\` 271 → 275/300 (AC5 ceiling ≤277). \`.claude/hooks/verify-all.sh\` unchanged at 148/150.`
A blank line (L29) separates it from `### Changed` (L30).

Use the Edit tool. Anchor `old_string` on the E06.S2 entry's final sub-bullet line plus the blank line plus the `### Changed` heading, and insert the new bullet between the E06.S2 entry and the blank line. Specifically replace:
```
  - **Line cap held:** `skills/fix/SKILL.md` 271 → 275/300 (AC5 ceiling ≤277). `.claude/hooks/verify-all.sh` unchanged at 148/150.

### Changed
```
with:
```
  - **Line cap held:** `skills/fix/SKILL.md` 271 → 275/300 (AC5 ceiling ≤277). `.claude/hooks/verify-all.sh` unchanged at 148/150.

- **Audit-table-in-PR-body convention — CONTRIBUTING.md codification (E06.S7).** New contributor-facing convention: when a story produces audit-style output (audit table, scope enumeration, finding inventory), the content MUST be pasted into the GitHub PR body at PR-creation time via `gh pr create --body-file <file>`, or backfilled via `gh api PATCH /repos/<owner>/<repo>/pulls/<pr>` if the PR predates the finalized table. The PR body is the canonical discoverable artifact for reviewers; plan-appendix and commit-body copies are secondary. Documents the `gh pr edit --body-file` silent-no-op pitfall (verified 2026-05-31) — `gh api PATCH` is required to land an after-creation update. Codified in [CONTRIBUTING.md](CONTRIBUTING.md) `## Audit conventions` (new top-level subsection after `## Cross-epic AC amendments`, resolving OQ-S7-section-location toward the new-section option per the same authoring-convention-cluster rationale as E06.S4's `## AC authoring conventions`). Contributor-facing only — no runtime enforcement (no `.claude/hooks/verify-all.sh` check). Cross-references:
  - **First instance:** E05.S4.5.AC3 PARTIALLY MET — the per-site `mkdir -p` audit table was discoverable only via plan-appendix + commit-body, backfilled into the PR #54 body via `gh api PATCH` external to the working tree.
  - **Codification trigger:** E05 audit recommendation #4 (audit L156) — "codify in `CONTRIBUTING.md` `## Audit conventions` if a second instance arises."
  - **Pre-emptive codification:** per user OQ6 confirmation to codify now rather than waiting for a second instance.

### Changed
```
Do NOT cite any line number within CHANGELOG.md itself (stale-line-reference drift). Match the existing bullet format exactly.

**Verify:** `grep -Fn "Audit-table-in-PR-body convention" CHANGELOG.md` returns exactly 1 match positioned under `### Added` (before `### Changed`); `grep -Fn "E05 audit recommendation #4" CHANGELOG.md` returns ≥1 match; `grep -Fn "E05.S4.5.AC3" CHANGELOG.md` returns ≥1 match.
**UI:** no

## Blast Radius
- Do NOT modify: any `## Cross-epic AC amendments` content, any `skills/*/SKILL.md`, any `agents/*.md`, `.claude/hooks/verify-all.sh`, or any other file.
- Do NOT touch PR #54 (out of scope — already backfilled externally).
- Watch for: same-file CHANGELOG line citations (forbidden); accidental edit of the `## Tooling Pitfalls` heading; preserving the exact bold-lead bullet format in CHANGELOG.

## Conventions
- Both files are additive-only; no line cap applies to CONTRIBUTING.md or CHANGELOG.md (no verify-all.sh check targets them — confirmed in discovery).
- New CONTRIBUTING.md section follows the bold-lead-sentence + prose pattern of the adjacent `## Skill authoring conventions` / `## AC authoring conventions` / `## Cross-epic AC amendments` sections.
- New CHANGELOG entry follows the E06.S4/S5/S2 house style: `- **<descriptor> (E06.S7).**` bold lead + prose + sub-bullets for cross-references.
- AC1 required literals present verbatim: `audit table`, `gh api PATCH`, section heading `## Audit conventions`.
- AC3: convention text is prose (no metasyntactic notation in quoted ACs) so the post-E06.S4 quoted-wording marker check should not fire — expect review-plan PASS.
