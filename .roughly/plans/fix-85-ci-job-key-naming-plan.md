> **Status:** Historical — implemented and merged in commit 4be5854 on 2026-07-28. This plan was an active build/fix artifact; treat as historical reference only.

# Fix Plan: #85 — codify CI job key naming convention (do not rename in-place)

Plan-format-version: 1

## Root Cause

A GitHub Actions job key (the map key under `jobs:` in a workflow file) is the stable identifier that branch-protection required-status-check rules bind to. Renaming it in-place silently breaks required-status-check enforcement for in-flight PRs until every protection rule is updated by hand — the workflow still runs, but its *required*-ness lapses invisibly. This discipline was applied once in E06.S2 (an initial commit renamed `dogfood-build-cycle` → `…-fix-cycle`; PR review flagged it P1 and reverted the rename, changing only the step name) but was never codified, so a future CI-scope restructure could re-introduce the same silent break. Docs-convention codification, not a code bug.

## Scope (2 tasks — enforcement verdict: CONTRIBUTING-only + known-pitfalls companion; NO review-plan check, same profile as #82)
- **T1:** `CONTRIBUTING.md` — append a SECOND convention paragraph (`**CI job key stability.**`) to the existing `## CI conventions` section that #82 created (after the `**Behavioral + structural fixture assertions.**` paragraph, before `## CI`). This is the co-location #82's investigation and the E06 epic candidate both predicted; #85 does NOT create a section.
- **T2:** `.roughly/known-pitfalls.md` — new companion entry under `## Build & Deploy`, immediately after #82's `### CI fixture assertions must be behavioral + structural…` entry (shared E06.S2 origin), before `### Plugin-bundled file references…`. Symptom/Cause/Fix template.
- Enforcement: governs GitHub-Actions workflow-file authoring, not plan ACs — no `review-plan` surface. Convention paragraph OMITS the "Enforcement is at plan-review time…" closer (matching #82; contrast the AC-authoring conventions which carry it).
- Cite the concrete job key `dogfood-build-cycle` as an **"e.g." illustration**, not load-bearing, to avoid name-rot (the convention itself says job keys should be stable, so the citation is durable — but phrase defensively). Cross-refs by section name, not line number.

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| CONTRIBUTING.md | Modify (append 1 paragraph to `## CI conventions`) | T1 |
| .roughly/known-pitfalls.md | Modify (append 1 `### ` entry within `## Build & Deploy`) | T2 |

## Baseline facts (captured 2026-07-28, branch `fix/81-86-contributing-convention-bundle`, 8 commits ahead of main = #81/#83/#84/#82)
- `CONTRIBUTING.md`: `## CI conventions` (heading) → `**Behavioral + structural fixture assertions.**` paragraph ending "…— and `.roughly/known-pitfalls.md` § "Build & Deploy"." → blank → `## CI` (operational, body begins `**Triggering.** The dogfood runs real, **billed** Claude sessions…`). No line cap.
- `.github/workflows/dogfood.yml`: top-level job key is `dogfood-build-cycle` (map key under `jobs:`); NO job-level `name:` field — only step-level `name:` fields. CONTRIBUTING's `## CI` § "Workflow logs" bullet already references `dogfood-build-cycle`.
- `.roughly/known-pitfalls.md` `## Build & Deploy`: last section entry sequence is #82's `### CI fixture assertions must be behavioral + structural, not structural-only` (ends "…Origin: E06.S2 PR-review / AC3 strengthening (2026-06-08).") then `### Plugin-bundled file references must be anchored with `${CLAUDE_PLUGIN_ROOT}`…`; section ends before `## Skill & Agent Authoring`. Entries use `### <title>` + `**Symptom:**`/`**Cause:**`/`**Fix:**`. File 202 lines, well under the 300 organize-threshold.
- Origin (verified quote, E06 epic "New from E06.S2 build (2026-06-08)"): "CI job key naming convention (do not rename in-place) (E06.S2 PR-review correction). An initial E06.S2 commit renamed the GitHub Actions job key from `dogfood-build-cycle` to `…-fix-cycle`; PR review flagged this as a P1 branch-protection / required-status-check risk and the rename was reverted (only the step name changed; job key preserved)."
- No existing job-key / required-status-check entry in known-pitfalls or review-plan (grepped, zero matches). Session shims `grep` — use `command grep`.

## Tasks

### T1: Add the `**CI job key stability.**` convention to CONTRIBUTING.md (~4 min)
**Files:** CONTRIBUTING.md
**Action:** Append ONE convention paragraph to the END of the `## CI conventions` section — immediately after the `**Behavioral + structural fixture assertions.**` paragraph (which ends "…— and `.roughly/known-pitfalls.md` § "Build & Deploy".") and before the blank line preceding `## CI`. Keep exactly one blank line before and after the new paragraph.
**Details:** Do a single exact-string Edit. Match the seam `§ "Build & Deploy".\n\n## CI` (the F6 paragraph's ending + the operational heading) and insert the new paragraph between them **as plain prose** — the triple-backtick fence below delimits the copy content ONLY and is NOT part of the inserted text; do not add any leading/trailing backtick around the paragraph (the paragraph starts with `**CI` and ends with `"Build & Deploy".`). Insert this EXACT paragraph:

```
**CI job key stability.** A GitHub Actions job key — the map key under `jobs:` in a workflow file — is the stable identifier that branch-protection required-status-check rules (and external integrations) bind to. Never rename a job key in-place: the rename silently breaks required-status-check enforcement for in-flight PRs until every protection rule is updated, and the gap stays invisible until a PR merges without the check it should have required. To restructure a job's scope, add a new job alongside the old key and migrate the protection rules to it before retiring the old key. A step's `name:` field (and a job-level `name:`, if present) is free-form display text and may change freely; only the top-level job key is load-bearing. Precipitating evidence: an initial E06.S2 commit renamed this repo's dogfood job key (e.g. `dogfood-build-cycle`) to a `…-fix-cycle` variant; PR review flagged it as a P1 branch-protection risk and the rename was reverted, changing only the step name (E06.S2 PR-review correction, 2026-06-08). See `.github/workflows/dogfood.yml` (whose `dogfood-build-cycle` job key the `## CI` section's Workflow-logs bullet already references) and `.roughly/known-pitfalls.md` § "Build & Deploy".
```

Do not modify the `**Behavioral + structural fixture assertions.**` paragraph, the `## CI` operational section, or any other section. Do NOT add an "Enforcement is at plan-review time…" closer.
**Verify:**
```
cd "$(git rev-parse --show-toplevel)"
command grep -qF -e '**CI job key stability.**' CONTRIBUTING.md || { echo FAIL-not-added; exit 1; }
# guard: paragraph must NOT have a stray leading backtick before the bold marker
command grep -qF -e '`**CI job key stability.**' CONTRIBUTING.md && { echo FAIL-stray-leading-backtick; exit 1; }
command grep -qF -e 'Never rename a job key in-place' CONTRIBUTING.md || { echo FAIL-no-rule; exit 1; }
# new paragraph sits inside ## CI conventions (between it and operational ## CI)
awk '/^## CI conventions$/{a=1} /^## CI$/{a=0} a && /CI job key stability/{f=1} END{exit !f}' CONTRIBUTING.md || { echo FAIL-wrong-section; exit 1; }
# #82's F6 convention still present
command grep -qF -e '**Behavioral + structural fixture assertions.**' CONTRIBUTING.md || { echo FAIL-82-conv-lost; exit 1; }
# operational CI intact
command grep -qF -e '**Triggering.** The dogfood runs real' CONTRIBUTING.md || { echo FAIL-ci-body-lost; exit 1; }
echo "T1 PASS"
```
**UI:** no

### T2: Add the known-pitfalls companion entry under `## Build & Deploy` (~4 min)
**Files:** .roughly/known-pitfalls.md
**Action:** Append ONE `### ` entry (Symptom/Cause/Fix) to `## Build & Deploy`, placed immediately after #82's `### CI fixture assertions must be behavioral + structural, not structural-only` entry (which ends "…Origin: E06.S2 PR-review / AC3 strengthening (2026-06-08).") and before the `### Plugin-bundled file references must be anchored…` entry. Keep one blank line before and after the new entry.
**Details:** Do a single exact-string Edit anchored on #82's entry ending + the next heading. Match `Origin: E06.S2 PR-review / AC3 strengthening (2026-06-08).\n\n### Plugin-bundled file references` and insert the new entry between #82's ending and the `### Plugin-bundled file references` heading. Insert this EXACT block (one blank line each side):

```
### Renaming a GitHub Actions job key in-place silently breaks required-status-check enforcement

**Symptom:** After a workflow edit renames the top-level job key (the map key under `jobs:`), in-flight PRs stop enforcing the required status check that branch-protection bound to the old key — a PR can merge without the check that should have gated it, with no error surfaced. The workflow still runs; only its *required*-ness silently lapses.
**Cause:** Branch-protection required-status-check rules (and external integrations) bind to the job KEY, not to any `name:` display field. Renaming the key in-place makes those rules reference a check that no longer reports, so enforcement quietly no-ops until the rules are updated by hand.
**Fix:** Treat job keys as stable identifiers — never rename one in-place. To restructure job scope, add a new job alongside and migrate protection rules to it before retiring the old key. Step `name:` fields may change freely; the job key must not. Codified in `CONTRIBUTING.md` § "CI conventions". Origin: E06.S2 PR-review correction — an initial commit renamed the dogfood job key `dogfood-build-cycle` → `…-fix-cycle`, flagged P1, reverted (2026-06-08).
```

Do not modify #82's F6 entry, the `### Plugin-bundled file references` entry, or any other section.
**Verify:**
```
cd "$(git rev-parse --show-toplevel)"
command grep -qF -e '### Renaming a GitHub Actions job key in-place silently breaks required-status-check enforcement' .roughly/known-pitfalls.md || { echo FAIL-not-added; exit 1; }
# lands inside ## Build & Deploy (before ## Skill & Agent Authoring)
awk '/^## Build & Deploy/{a=1} /^## Skill & Agent Authoring/{a=0} a && /Renaming a GitHub Actions job key in-place/{f=1} END{exit !f}' .roughly/known-pitfalls.md || { echo FAIL-wrong-section; exit 1; }
# #82 sibling entry still intact
command grep -qF -e '### CI fixture assertions must be behavioral + structural, not structural-only' .roughly/known-pitfalls.md || { echo FAIL-82-entry-lost; exit 1; }
# cross-ref present (now appears in both #82 + #85 entries → assert >=2)
c=$(command grep -cF -e 'Codified in `CONTRIBUTING.md` § "CI conventions"' .roughly/known-pitfalls.md); [ "$c" -ge 2 ] || { echo "FAIL-crossref ($c)"; exit 1; }
n=$(wc -l < .roughly/known-pitfalls.md); [ "$n" -le 300 ] || { echo "FAIL-over-threshold $n"; exit 1; }
out=$(bash .claude/hooks/verify-all.sh 2>&1); [ -z "$out" ] || { echo "FAIL-verify-not-clean: $out"; exit 1; }
echo "T2 PASS ($n lines)"
```
**UI:** no

## Blast Radius
- **Do NOT modify:** #82's `**Behavioral + structural fixture assertions.**` paragraph or `### CI fixture assertions…` entry (directly adjacent to both seams); the operational `## CI` section; the `## Skill authoring conventions` / `## AC authoring conventions` sections; the `### Plugin-bundled file references` known-pitfalls entry; `.github/workflows/dogfood.yml` (cited, not edited); any code/agent/other file; the E06 epic (historical source).
- **Watch for:** (a) append the paragraph to the EXISTING `## CI conventions` section — do NOT create a second `## CI conventions` heading; (b) the convention paragraph must NOT carry an "Enforcement is at plan-review time…" closer; (c) cite `dogfood-build-cycle` as "e.g."/illustration, not load-bearing (name-rot); (d) cross-refs by section name, never line number; (e) known-pitfalls stays under 300; (f) shimmed grep — use `command grep`; (g) all Verify greps here are POSITIVE-presence checks for literals being added — none self-defeating.

## Conventions
- No build/test harness — inline `command grep`/`awk`/verify-all-clean Verify blocks are the validation.
- T1/T2 touch 2 distinct files → parallelizable.
