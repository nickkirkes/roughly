# Fix Plan: #67 — plugin-root Read path resolution (`${CLAUDE_PLUGIN_ROOT}`)

Plan-format-version: 1

## Root Cause

Claude Code does **not** auto-rewrite bare relative paths in skill prose — per the official plugins reference, only `${...}` placeholders resolve in skill/agent content; a bare `Read \`skills/shared/X.md\`` resolves against the **user's current working directory**. In a consumer project (cwd ≠ plugin root) `skills/shared/` does not exist, so the read fails and the ADR-012 shared procedures (`gate-protocol.md`, `stage-8-wrap-up.md`, `abort-handling.md`) — plus `skills/setup/templates/*` and the upgrade skill's `plugin.json` read — can silently fail to load. It has appeared to work only because (a) the dogfood runs with cwd = the plugin repo and (b) the model can sometimes locate the file by agency ("resolution by luck"). The documented, reliable, cwd-independent mechanism is `${CLAUDE_PLUGIN_ROOT}`, which the harness interpolates inside skill/agent content (confirmed via claude-code-guide against the official plugins reference; stable through CC 2.1.207+).

## Scope decision

Fix **all 14 plugin-root-relative runtime directives** (verb-agnostic — `Read` and `Copy` both resolve against cwd): 6 build/fix shared reads + 5 setup template `Read`s + 1 setup `Copy` (plan-mode-gate hook source) + 2 `.claude-plugin/plugin.json` version reads (upgrade + setup). One consistent, documented convention — not just the 3 named in the issue. Leave unchanged: (a) user-project-relative reads (`.roughly/workflow-upgrades`, consumer `CLAUDE.md`, write targets like `.claude/hooks/plan-mode-gate.sh`) — they correctly resolve against the consumer repo; (b) `skills/help/SKILL.md:168`'s `` read `skills/<name>/SKILL.md` in the plugin source `` — that is user-facing *advice text* with a `<name>` placeholder, not a runtime directive the model executes.

## Verification note (AC1 — empirical)

A live cross-cwd runtime test needs `claude -p` and the CI/API account is currently **out of credits**, so per-task `Verify` steps below are **structural** (grep the directive form; run `verify-all.sh`). Runtime/empirical confirmation that `${CLAUDE_PLUGIN_ROOT}` interpolates inside a prose `Read` directive is deferred to the **`ci:dogfood` pre-ship gate** (a hard gate per `docs/runbooks/release.md`) — the build/fix scenarios exercise all three shared reads from a foreign cwd. **Residual risk:** setup/upgrade reads are NOT covered by the dogfood; they need a manual smoke (run `/roughly:setup` in a scratch project) before the version pin — see Blast Radius.

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| skills/build/SKILL.md | Modify | T1 |
| skills/fix/SKILL.md | Modify | T1 |
| skills/setup/SKILL.md | Modify | T2, T3 |
| skills/upgrade/SKILL.md | Modify | T3 |
| .claude/hooks/verify-all.sh | Modify | T4 |
| docs/adrs/ADR-012-runtime-shared-procedural-references.md | Modify | T5 |
| CLAUDE.md | Modify | T5 |
| CONTRIBUTING.md | Modify | T5 |
| .roughly/known-pitfalls.md | Modify | T5 |

## Baseline facts (captured 2026-07-20, on branch fix/67-verify-shared-read-path-resolution)
- build/fix = 277/282 lines (cap 300). Adding the `${CLAUDE_PLUGIN_ROOT}/` prefix adds no lines.
- `CLAUDE_PLUGIN_ROOT` currently appears **0 times** repo-wide, so post-fix greps for it test only the new content.
- verify-all.sh Check 8: existence loop L130, pair loop L134, awk matcher L140 (`p="Read \`skills/shared/${shared}\`"`).
- The `${CLAUDE_PLUGIN_ROOT}/skills/shared/…` form still contains the substring `skills/shared/`; the OLD bare form is distinguished by the backtick immediately preceding `skills/` (`` Read `skills/shared/ ``). Verifies below rely on that distinction.

## Tasks

### T1: Anchor the build/fix shared reads to `${CLAUDE_PLUGIN_ROOT}` (~4 min)
**Files:** skills/build/SKILL.md, skills/fix/SKILL.md
**Action:** Replace the 3 shared `Read` directives in each file so the path is `${CLAUDE_PLUGIN_ROOT}/skills/shared/<file>` instead of the bare `skills/shared/<file>`.
**Details:** Six edit sites (structural uniformity: 3 byte-identical directive changes shared across build/fix — the gate-protocol lines at build:25/fix:25 are already a byte-identical pair and must remain so). Change only the backtick-quoted path; leave the surrounding sentence intact (`verbatim:` for each target path):
1. build/SKILL.md:25 & fix/SKILL.md:25 — `` Read `skills/shared/gate-protocol.md` `` → `` Read `${CLAUDE_PLUGIN_ROOT}/skills/shared/gate-protocol.md` ``
2. build/SKILL.md:235 & fix/SKILL.md:242 — `` Read `skills/shared/stage-8-wrap-up.md` `` → `` Read `${CLAUDE_PLUGIN_ROOT}/skills/shared/stage-8-wrap-up.md` ``
3. build/SKILL.md:277 & fix/SKILL.md:282 — `` Read `skills/shared/abort-handling.md` `` → `` Read `${CLAUDE_PLUGIN_ROOT}/skills/shared/abort-handling.md` ``
Do NOT alter: the `.roughly/workflow-upgrades` reads (build:242, fix:249), the "See `skills/shared/stage-8-wrap-up.md` step 7" prose pointer (it is a cross-reference, not a content-loading Read), or the CRITICAL preamble.
**Verify:** `[ "$(grep -c 'Read `\${CLAUDE_PLUGIN_ROOT}/skills/shared/' skills/build/SKILL.md)" = 3 ] && [ "$(grep -c 'Read `\${CLAUDE_PLUGIN_ROOT}/skills/shared/' skills/fix/SKILL.md)" = 3 ] && ! grep -qE 'Read `skills/shared/' skills/build/SKILL.md && ! grep -qE 'Read `skills/shared/' skills/fix/SKILL.md && diff <(sed -n '25p' skills/build/SKILL.md) <(sed -n '25p' skills/fix/SKILL.md) && [ "$(wc -l < skills/build/SKILL.md)" -le 300 ] && [ "$(wc -l < skills/fix/SKILL.md)" -le 300 ]`
**UI:** no

### T2: Anchor the setup template Read/Copy directives to `${CLAUDE_PLUGIN_ROOT}` (~3 min)
**Files:** skills/setup/SKILL.md
**Depends on:** none
**Action:** Replace the 5 `Read` template-directive paths AND the 1 `Copy` template-source path so each plugin-bundled path is `${CLAUDE_PLUGIN_ROOT}/skills/setup/templates/<file>`. (6 sites: 5 Read + 1 Copy — the root cause is verb-agnostic.)
**Details:** Six edit sites; change only the backtick-quoted **plugin-bundled** path, leave the rest of each instruction intact (`verbatim:` for each target path):
1. setup/SKILL.md:92 — `Read \`…/CLAUDE.md.template\``
2. setup/SKILL.md:108 — `Read \`…/known-pitfalls.md.template\``
3. setup/SKILL.md:111 — `Read \`…/claudeignore.template\``
4. setup/SKILL.md:121 — `Read \`…/settings.json.template\``
5. setup/SKILL.md:197 — `Read \`…/verify-all-stop-hook.sh.template\``
6. setup/SKILL.md:116 — `Copy \`skills/setup/templates/plan-mode-gate.sh.template\`` → `Copy \`${CLAUDE_PLUGIN_ROOT}/skills/setup/templates/plan-mode-gate.sh.template\`` (security-relevant: this installs the plan-mode-gate safety hook; the `to \`.claude/hooks/plan-mode-gate.sh\`` DEST stays consumer-relative).
Do NOT change the WRITE/DEST targets on these lines (`.roughly/known-pitfalls.md`, `.claudeignore`, `.claude/settings.json`, `.claude/hooks/verify-all.sh.new`, `.claude/hooks/plan-mode-gate.sh`) — those are correctly consumer-project-relative.
**Verify:** `[ "$(grep -cE '(Read|Copy) `\${CLAUDE_PLUGIN_ROOT}/skills/setup/templates/' skills/setup/SKILL.md)" = 6 ] && ! grep -qE '(Read|Copy) `skills/setup/templates/' skills/setup/SKILL.md`
**UI:** no

### T3: Anchor the two `.claude-plugin/plugin.json` version reads to `${CLAUDE_PLUGIN_ROOT}` (~2 min)
**Files:** skills/upgrade/SKILL.md, skills/setup/SKILL.md
**Action:** Anchor the plugin-manifest version reads in BOTH skills — `upgrade:68` and `setup:229` read the same plugin-bundled `.claude-plugin/plugin.json`.
**Details:** Two edit sites (`verbatim:` targets):
1. **upgrade/SKILL.md:68** — contains TWO reads: `Read \`.roughly/workflow-upgrades\`` (consumer-relative — LEAVE UNCHANGED) and `Read \`.claude-plugin/plugin.json\`` (plugin-root — change to `Read \`${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json\``).
2. **setup/SKILL.md:229** — `Read the current plugin version from \`.claude-plugin/plugin.json\` (the \`version\` field).` → change the path to `Read the current plugin version from \`${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json\` (the \`version\` field).`
**Verify:** `[ "$(grep -rcF '${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json' skills/upgrade/SKILL.md skills/setup/SKILL.md | grep -c ':1')" = 2 ] && ! grep -rqE '`\.claude-plugin/plugin\.json`' skills/upgrade/SKILL.md skills/setup/SKILL.md && grep -qF 'Read `.roughly/workflow-upgrades`' skills/upgrade/SKILL.md` (both files carry the anchored form; no bare backtick-quoted `.claude-plugin/plugin.json` remains; the consumer-relative workflow-upgrades read is preserved).
**UI:** no

### T4: Update verify-all.sh Check 8 to match the anchored directive form (~3 min)
**Files:** .claude/hooks/verify-all.sh
**Depends on:** T1
**Action:** Update the ADR-012 drift-check's awk matcher (L140) so it looks for the `${CLAUDE_PLUGIN_ROOT}`-anchored Read directive; otherwise the check false-fails ("missing Read directive") after T1.
**Details:** On L140, change the awk pattern variable from `p="Read \`skills/shared/${shared}\`"` to `p="Read \`\${CLAUDE_PLUGIN_ROOT}/skills/shared/${shared}\`"`. The `${shared}` loop variable must stay bash-expanded; `${CLAUDE_PLUGIN_ROOT}` must be a **literal** in the pattern (escape as `\${CLAUDE_PLUGIN_ROOT}` inside the double-quoted bash string). Leave the existence loop (L130) and pair loop (L134) unchanged (they check file existence and heading presence, not the path form). Leave the inline-duplication guards and the CRITICAL-preamble/boundary checks unchanged.
**Verify:** `bash -n .claude/hooks/verify-all.sh && ! bash .claude/hooks/verify-all.sh | grep -qF 'shared procedural reference drift'` — the script parses, and after T1's directive change the drift check no longer false-fails (a clean run emits no `shared procedural reference drift` line; the pre-existing known-pitfalls advisory is unrelated).
**UI:** no

### T5: Document the resolution rule (ADR-012, CLAUDE.md pitfall carve-out, CONTRIBUTING, known-pitfalls) (~5 min)
**Files:** docs/adrs/ADR-012-runtime-shared-procedural-references.md, CLAUDE.md, CONTRIBUTING.md, .roughly/known-pitfalls.md
**Depends on:** none
**Action:** Record that plugin-bundled files must be referenced via `${CLAUDE_PLUGIN_ROOT}` and reconcile the contradicting pitfall (AC3 + AC4).
**Details:** Four edit sites:
1. **ADR-012** — add a subsection (`form:`) stating: runtime `Read` directives that load plugin-bundled files MUST use `${CLAUDE_PLUGIN_ROOT}/…`; bare relative paths resolve against the consumer's cwd and silently fail in non-dogfood projects (root cause of #67). Reference issue #67.
2. **CLAUDE.md** `## Known Pitfalls for Contributors` — amend the "User context, not plugin context" bullet (`form:`) to carve out the exception: paths the model **writes/reads in the consumer's project** stay repo-relative (`.roughly/…`, `CLAUDE.md`, `.claude/settings.json`), but paths that load **plugin-bundled** files (`skills/shared/*`, `skills/setup/templates/*`, `.claude-plugin/plugin.json`) MUST use `${CLAUDE_PLUGIN_ROOT}` — they do not exist in the consumer's cwd.
3. **CONTRIBUTING.md** — if the ADR-012 shared-reference form is documented there (near the Check 8 / "Shared procedural reference" text), update the example directive to the `${CLAUDE_PLUGIN_ROOT}` form so contributors copy the correct pattern. If no such example exists, add a one-line note. (Confirm at edit time via `grep -n 'skills/shared' CONTRIBUTING.md`.)
4. **.roughly/known-pitfalls.md** — append an entry (`form:` — match the file's Symptom/Cause/Fix structure): plugin-bundled file reads must be `${CLAUDE_PLUGIN_ROOT}`-anchored or they silently fail for consumers; reference #67.
**Verify:** `grep -qF 'CLAUDE_PLUGIN_ROOT' docs/adrs/ADR-012-runtime-shared-procedural-references.md && grep -qF 'CLAUDE_PLUGIN_ROOT' CLAUDE.md && grep -qF 'CLAUDE_PLUGIN_ROOT' CONTRIBUTING.md && grep -qF 'CLAUDE_PLUGIN_ROOT' .roughly/known-pitfalls.md` (all four T5 edit-site files carry the new convention; CONTRIBUTING.md:66's stale `` Read `skills/shared/<file>.md` `` example is confirmed present and must be updated).
**UI:** no

## Blast Radius
- **Do NOT modify:** user-project-relative reads — `.roughly/workflow-upgrades` (build:242, fix:249, upgrade:68, help:48), consumer `CLAUDE.md`/`.claude/settings.json` write targets, `.claudeignore`. These correctly resolve against the consumer repo; anchoring them to the plugin root would break them.
- **Do NOT modify:** the "See `skills/shared/stage-8-wrap-up.md` step 7" prose pointer or "See the GATE PROTOCOL section" cross-references — they are human/model references, not content-loading `Read` directives. Likewise `skills/help/SKILL.md:168`'s `` read `skills/<name>/SKILL.md` in the plugin source `` — user-facing advice text with a `<name>` placeholder, not a runtime directive (confirmed via exhaustive `grep -rnE '(Read|Copy|read|copy) .{0,40}\`(skills/|\.claude-plugin/)' skills/` that these 14 sites + this excluded advice line are the complete set).
- **Do NOT modify:** `scripts/ci-dogfood.sh` — it passes `--plugin-dir "$WORKTREE"`, so `${CLAUDE_PLUGIN_ROOT}` resolves to the worktree; the harness keeps working and now actually exercises the anchored form from a foreign cwd (this is the empirical gate).
- **Watch for:** build:25 ≡ fix:25 byte-identity (T1 verify diffs them); the 300-line cap (unchanged — no new lines); verify-all.sh Check 8 must change in lockstep with T1 (T4) or it false-fails; the `${shared}` vs literal `${CLAUDE_PLUGIN_ROOT}` bash-escaping in T4.
- **Verification gap:** the build/fix shared reads are dogfood-covered (empirical closure at the pre-ship `ci:dogfood` gate); **setup (T2) and upgrade (T3) are NOT dogfood-covered** — run `/roughly:setup` in a scratch project (and an `/roughly:upgrade`) to confirm templates/manifest resolve before the version pin. Flagged, not silently assumed.

## Conventions
- `${CLAUDE_PLUGIN_ROOT}` is the CC-documented mechanism for plugin-bundled file references in skill/agent content (plugins reference; resolves anywhere the placeholder appears). New convention for this repo (0 prior occurrences).
- ADR-012 (shared-reference pattern) + ADR-009 (build:11≡fix:11 sync pair; the gate-protocol section is likewise mirrored).
- Verify commands assert the new anchored form's presence and the old bare form's absence (distinguished by the backtick before `skills/`), avoiding the self-defeating-verify pitfall since `${CLAUDE_PLUGIN_ROOT}` is new repo-wide.
- Empirical (runtime) verification deferred to the `ci:dogfood` gate per `docs/runbooks/dogfood-ci.md` (API credits currently depleted).
