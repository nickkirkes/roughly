# Implementation Plan: E03.S11a Plugin self-test CI scaffolding

Plan-format-version: 1

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| scripts/ci-dogfood.sh | Create (executable) | T1 |
| .github/workflows/dogfood.yml | Create | T2 |
| CONTRIBUTING.md | Modify (insert `## CI` section) | T3 |
| CHANGELOG.md | Modify (Unreleased entry) | T4 |
| docs/ROADMAP.md | Modify (item #11 progress marker) | T4 |

## Tasks

### T1: Create scripts/ci-dogfood.sh with isolation contract (~5 min)
**Files:** scripts/ci-dogfood.sh
**Action:** Create the dogfood driver script with ephemeral worktree, trap cleanup, no-pollution self-check, and a stub at the claude invocation point. Make the file executable.
**Details:**
- Shebang: `#!/usr/bin/env bash`
- `set -euo pipefail`
- Resolve SHA: `SHA="${GITHUB_SHA:-$(git rev-parse HEAD)}"`
- Resolve repo root: `ROOT="$(git rev-parse --show-toplevel)"` and refuse to run if `[ ! -f "$ROOT/.claude-plugin/plugin.json" ]` (clear error: "ci-dogfood: must run from the roughly plugin repo").
- Worktree path: `WORKTREE="/tmp/roughly-dogfood-${SHA}"`
- Capture pre-state: `PRE_STATE="$(git -C "$ROOT" status --porcelain)"`
- Cleanup function: `cleanup() { git -C "$ROOT" worktree remove --force "$WORKTREE" 2>/dev/null || true; rm -rf "$WORKTREE"; }`
- `trap cleanup EXIT` (registered BEFORE the worktree is created so partial-failure cleanup still fires)
- **Stale-worktree guard** (handles same-SHA reruns where a prior run left `/tmp/roughly-dogfood-${SHA}` populated — `git worktree add` would otherwise exit 128 with a confusing `fatal: '<path>' already exists`). Run BEFORE worktree creation:
  ```bash
  git -C "$ROOT" worktree prune 2>/dev/null || true
  if [ -d "$WORKTREE" ]; then
    git -C "$ROOT" worktree remove --force "$WORKTREE" 2>/dev/null || true
    rm -rf "$WORKTREE"
  fi
  ```
- Create worktree: `git -C "$ROOT" worktree add "$WORKTREE" HEAD`
- `cd "$WORKTREE"`
- **Stub block** at the claude invocation point. Comment block explicitly labels: `# STUB: real claude invocation lands in S11b-1 (smoke test) and S11b-2 (full scenario).` The stub echoes `ci-dogfood: stub claude invocation, returning 0` and falls through (does NOT `exit 0` from inside the stub — control must continue to the post-state check).
- Post-state check: `POST_STATE="$(git -C "$ROOT" status --porcelain)"`; if `[ "$PRE_STATE" != "$POST_STATE" ]` print mismatch with diff and exit 1.
- Final echo: `ci-dogfood: SUCCESS — no source-tree pollution`
- Make executable: `chmod +x scripts/ci-dogfood.sh` (and verify the file is staged with executable bit so the CI workflow can `bash scripts/ci-dogfood.sh` without explicit chmod).
**Verify:**
- `bash -n scripts/ci-dogfood.sh` exits 0 (syntax)
- `[ -x scripts/ci-dogfood.sh ]` true (executable bit)
- End-to-end: `bash scripts/ci-dogfood.sh` exits 0 AND `git status --porcelain` output is **identical** before and after (not necessarily empty — the script does not require a clean tree, only a stable one) AND `[ ! -d /tmp/roughly-dogfood-* ]` after run (cleanup ran)
**UI:** no

### T2: Create .github/workflows/dogfood.yml (~3 min)
**Files:** .github/workflows/dogfood.yml
**Action:** Create the GitHub Actions workflow that runs ci-dogfood.sh on push to main and on pull_request.
**Details:**
- `name: dogfood`
- `on:` block — `push: { branches: [main] }` AND `pull_request: {}` (default `pull_request` trigger; `pull_request_target` is NOT used — no secrets needed in S11a stub, and using `pull_request` keeps fork PRs safe).
- `jobs.dogfood-build-cycle:`
  - `runs-on: ubuntu-latest`
  - `steps:`
    - `actions/checkout@v4` with `fetch-depth: 0` (full history needed so `git worktree add HEAD` resolves correctly and `git rev-parse HEAD` returns the merge SHA in PR runs).
    - Run step name: `Run dogfood scaffolding`. Command: `bash scripts/ci-dogfood.sh`. Env: `ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}` (plumbed now so S11b-1 inherits a working scaffolding; the S11a stub does not consume it).
- 2-space YAML indent.
**Verify:**
- File exists at `.github/workflows/dogfood.yml`
- `python3 -c 'import yaml; yaml.safe_load(open(".github/workflows/dogfood.yml"))'` exits 0 (well-formed YAML — Python ships with PyYAML on most macOS/Linux dev boxes; if not available, `head -30` and visual review suffices).
- Job name `dogfood-build-cycle` and workflow name `dogfood` are present.
**UI:** no

### T3: Add `## CI` section to CONTRIBUTING.md (~4 min)
**Files:** CONTRIBUTING.md
**Action:** Insert a new `## CI` section between `## Testing` (currently lines 71–79) and `## License` (currently lines 81–83). The section addresses S11a AC-7: workflow logs location, local repro, in/out of scope, token-cost expectations, auth secret name.
**Details:**
- Anchor for Edit: replace the boundary string `\n## License\n` with `\n## CI\n\n[CI body]\n\n## License\n` to keep the Edit deterministic.
- Subsections / paragraphs the body must cover:
  - **Workflow logs location.** GitHub Actions tab → `dogfood` workflow → most recent run; per-job logs under `dogfood-build-cycle`.
  - **Reproducing a failure locally.** `bash scripts/ci-dogfood.sh` from a clean working tree (`git status --porcelain` empty). Optionally `ANTHROPIC_API_KEY=...` once S11b-1 lands; not required for the S11a stub.
  - **In scope for v0.1.5 CI.** Three stories named: S11a (scaffolding stub — landed in this story), S11b-1 (CLI plumbing smoke test), S11b-2 (happy-path build cycle).
  - **Out of scope for v0.1.5 CI.** `/roughly:fix`, `/roughly:setup`, `/roughly:upgrade` coverage; negative-path scenarios; caching of Claude state or node_modules between runs.
  - **Token-cost expectations.** S11b-1: ~5K tokens per run. S11b-2: ≤150K Sonnet tokens per run. CI is non-trivial at high PR push frequency — flag this as a release-cost driver to watch.
  - **Auth.** Requires `ANTHROPIC_API_KEY` repo secret (Settings → Secrets and variables → Actions). The S11a stub does not consume the secret; the env is plumbed so S11b-1 inherits without scaffolding changes.
- Length budget: 25–40 content lines (CONTRIBUTING.md is short and terse — match that tone). Final file expected ~108–115 lines, no cap on CONTRIBUTING.md.
**Verify:**
- `grep -n "^## " CONTRIBUTING.md` shows the section list in order: Getting Started, What to Contribute, What NOT to Contribute Without Discussion, PR Process, Code Standards, Tooling Pitfalls, Testing, **CI**, License.
- `grep -c "ANTHROPIC_API_KEY" CONTRIBUTING.md` ≥ 1
- `grep -c "scripts/ci-dogfood.sh" CONTRIBUTING.md` ≥ 1
- File compiles as plain markdown (visual scan).
**UI:** no

### T4: Update CHANGELOG.md and docs/ROADMAP.md (~2 min)
**Files:** CHANGELOG.md, docs/ROADMAP.md
**Action:** Add E03.S11a entry to CHANGELOG `[Unreleased] — v0.1.5` "Added" list (top of list, above the existing E03.S12.0 bullet); update ROADMAP item #11 with an in-flight marker for S11a.
**Details:**
- **CHANGELOG.md:** Insert a new bullet immediately under `### Added` (i.e., between line containing `### Added` and the existing `- **E03.S12.0 — Resolve roughly.dev source location ...` bullet). Format mirrors prior entries:
  - Bold story tag: `**E03.S11a — Plugin self-test CI scaffolding.**`
  - Summary mentioning: ephemeral `/tmp/roughly-dogfood-${SHA}` worktree, trap cleanup, no-pollution AC, stub at `claude` invocation point (real CLI invocation deferred to S11b-1/S11b-2).
  - Markdown links to: `.github/workflows/dogfood.yml` (new), `scripts/ci-dogfood.sh` (new), `CONTRIBUTING.md` (CI section).
  - Note that `ANTHROPIC_API_KEY` env is plumbed but unused in the stub.
- **docs/ROADMAP.md:** Amend item #11 (line 71) to mark S11a in flight. Replacement format mirrors how item #4 is annotated (`✅ Done — landed in E03.S4.`). For #11, append: ` **S11a scaffolding ✅ — landed in this story; S11b-1 plumbing and S11b-2 happy-path pending.**` to the existing bullet.
**Verify:**
- `grep -n "E03.S11a" CHANGELOG.md` returns at least 1 line in the Unreleased section.
- `grep -n "S11a" docs/ROADMAP.md` returns at least 1 line on or near the existing item #11.
- `head -10 CHANGELOG.md` confirms placement order: heading → Unreleased → Added → S11a bullet → S12.0 bullet (existing).
**UI:** no

## Blast Radius
- **Do NOT modify:** `skills/**`, `agents/**`, `.claude/**`, `.roughly/**`, `CLAUDE.md`, `docs/adrs/**`, `docs/planning/**`, `.claude/hooks/plan-mode-gate.sh`, `.claude/hooks/verify-all.sh`, `.gitignore`, `.claude-plugin/plugin.json`, any existing skill/agent prompts.
- **No new ADR needed** — S11a is scaffolding, not a novel design decision (confirmed in Stage 2 discovery).
- **Watch for:** source-tree pollution during local verification of T1 — run only from a clean working tree, otherwise the pre-state check will pass on a dirty baseline and the post-check will not detect actual mutation. The script's own pre/post symmetry doesn't validate this for you.

## Conventions
- **Shell:** shebang `#!/usr/bin/env bash`, `set -euo pipefail` for new freestanding scripts. Existing hooks (`verify-all.sh`, `plan-mode-gate.sh`) use `set -e` only — that's intentional for hooks (they shouldn't crash Claude on minor failures) and is NOT precedent for standalone scripts. Pattern-match `verify-all.sh:9-12` for repo-root detection (`git rev-parse --show-toplevel` + `.claude-plugin/plugin.json` presence check).
- **YAML:** 2-space indent; quote string values only when needed (bare identifiers fine).
- **CONTRIBUTING.md:** terse, numbered/bulleted lists, code in backticks, sections ordered by reader workflow. Match the existing tone — short paragraphs, not prose blocks.
- **CHANGELOG entries:** bold story tag prefix (`**E03.S11a — ...**`), markdown links to touched files in [text](path) form, summary leads with "what" then "why".
- **Order of operations during implementation:** T1 must complete and be verified before T2 (workflow calls the script), but T2 doesn't need to be verified end-to-end (no GH Actions runner locally). T3 and T4 are independent of T1/T2 mechanics — can run after.
