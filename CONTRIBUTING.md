# Contributing to Roughly

This project follows the [Contributor Covenant Code of Conduct](./CODE_OF_CONDUCT.md). By participating, you agree to uphold it.

## Getting Started

1. Fork and clone the repo
2. Test locally from a scratch project: `claude --plugin-dir /path/to/your/roughly-clone`
3. Run `/roughly:setup` in the scratch project to verify the bootstrap flow
4. Try `/roughly:build` on a small feature to see the full pipeline

## What to Contribute

Improvements to Roughly — built with Roughly. Use `/roughly:build` to implement your changes.

- Bug reports with reproduction steps (include Claude Code version)
- Documentation improvements (README, ADRs, CLAUDE.md)
- New agent definitions
- Template improvements (setup templates, ignore patterns)
- Maturity check additions (with versioned IDs)

## What NOT to Contribute Without Discussion

These are covered by ADRs and require an ADR amendment before changing:

- Pipeline stage structure — number, order, or gating behavior (ADR-001, ADR-002)
- Subagent dispatch model — how tasks are scoped and coordinated (ADR-002)
- Adding new pipeline commands — build and fix are intentionally the only two (ADR-004)
- Removing `disable-model-invocation: true` from coordinator skills (see CLAUDE.md)

Open an issue to discuss before submitting a PR for these areas.

## PR Process

1. For non-trivial changes, open an issue first to discuss the approach
2. Fork → branch → PR against `main`
3. Include an updated CHANGELOG entry under `[Unreleased]`
4. If the change involves a design decision, draft an ADR (see `docs/adrs/README.md`)
5. Ensure skills stay under 300 lines and agents under 500 words

## Code Standards

All conventions are documented in [CLAUDE.md](CLAUDE.md). The key ones:

- Skills: YAML frontmatter with `name`, `description`; pipeline/coordinator skills need `disable-model-invocation: true`
- Agents: YAML frontmatter with `name`, `description`, `tools`, `model`
- Templates: use `{{PLACEHOLDER}}` markers — never hardcode project-specific values
- Maturity check IDs must be versioned (e.g., `investigator-v1`)

## Skill authoring conventions

**Multi-branch case dispatch.** When a skill body partitions behavior across mutually-exclusive cases (Case A / Case B / Case C), the dispatch instruction must explicitly state: *"evaluate top-to-bottom; execute only the first matching case."* Reject fall-through prose ("then do X; if not, otherwise do Y") — it invites cumulative execution where later cases run on top of earlier ones.

Canonical example: `skills/help/SKILL.md` Step 3 (Cases A–E) opens with: "The remaining logic is a mutually-exclusive case partition. Determine which case applies by evaluating the conditions in order top-to-bottom; execute ONLY the first matching case's emit logic, then end Step 3. Cases are NOT cumulative — do NOT execute logic from later cases after an earlier one has already matched."

**Sequential-structure carve-out.** Ordered enumeration (Step A → Step B → Step C → Step D, or numbered 1 → 2 → 3 → 4) paired with explicit sequencing prose that *positively asserts all steps execute in order* — an opening invariant clause stating run-in-order semantics, or explicit "previous step" / "next step" references between steps — is intentionally sequential and does NOT require case-dispatch language. Both conditions are required: named/numbered steps in sequence AND prose that commits to all-run-in-order semantics. Functional role labels per step (e.g., "Step A — validation / Step B — prompt") are neutral on whether steps are cumulative or exclusive and do NOT, by themselves, qualify for the carve-out — they must be accompanied by one of the two prose forms above.

Canonical example: `skills/setup/SKILL.md` Step 5d Branch 4 opens with the invariant clause "collect ALL decisions BEFORE any disk mutations" and proceeds through Step A (read-only checks) → Step B (settings-conflict resolution) → Step C (file-conflict prompt) → Step D (commit phase) — each step labeled with its functional role, the opening invariant fixing the ordering.

When in doubt: if the cases are truly mutually exclusive, use case-dispatch language. If the steps must all run in order, use sequential language with explicit transitions.

User-facing skill behavior changes are flags, not environment variables (see [ADR-011](docs/adrs/ADR-011-skill-flags-as-public-api.md)).

## Tooling Pitfalls

Bulk replacement of a token silently corrupts code when the same token serves dual semantic roles in one file — for example, user-facing prose AND a legacy detector that intentionally references the old name. The replace succeeds, the build passes, and the detector becomes a no-op no one notices.

At-risk tools:

- `Edit` with `replace_all: true`
- `sed -i` (and any non-interactive stream replace)
- IDE find/replace ("replace all in file")

Each rewrites every match in one pass with no per-site review.

Worked example: `.claude/hooks/verify-all.sh`. During the `ruckus` → `roughly` migration, the intent was to update user-facing comment prose at lines 2 and 11. A single `replace_all: true` edit also rewrote the legacy drift detector at lines 17–19 — the comment, the `rg` pattern, and the error string all flipped from `.ruckus/known-pitfalls` to `.roughly/known-pitfalls`. The detector was designed to catch stale references to the *old* path; after the bulk replace it hunted for the *current* path and would never fire. Surgical `Edit` calls scoped by surrounding context restored the legacy lines.

Before any bulk replace, scan the file for occurrences where the OLD form is intentional — legacy detectors, migration-context strings, "renamed FROM X" prose — and use targeted `Edit` calls per site instead. Verify with two greps that should match expectations exactly:

- `rg -nw 'ruckus' .claude/hooks/verify-all.sh` should return 3 matches at lines 17, 18, 19 (legacy detector lines that MUST retain `ruckus`)
- `rg -nw 'roughly' .claude/hooks/verify-all.sh` should return 2 matches at lines 2 and 11 (user-facing prose, legitimately renamed)

New pitfalls discovered during a build are recorded in `.roughly/known-pitfalls.md` — the runtime catalog the build pipeline updates at wrap-up when a contributor confirms a new one.

## Migration

v0.1.6 relocated `docs/plans/` to `.roughly/plans/` to consolidate all Roughly runtime state under a single root. Existing projects with historical plans run `/roughly:upgrade` to migrate; `--force-plans` overrides the dirty-tree safety check. Plan files written by the build/fix pipelines now land in `.roughly/plans/<feature>-plan.md`. The pre-flight migration check in the 7 hard-abort skills + setup soft-abort detects either `.ruckus/` or `docs/plans/` legacy state and redirects to `/roughly:upgrade`.

## Testing

There is no automated test suite — this is pure markdown. To verify changes:

1. Run `claude --plugin-dir /path/to/your/roughly-clone` in a test project
2. Exercise the skill you changed (e.g., `/roughly:build` for build changes)
3. Check that frontmatter is valid YAML
4. Check that cross-references (agent names in skills, file paths) are accurate
5. Verify line/word limits: skills < 300 lines, agents < 500 words

## CI

**Workflow logs.** GitHub Actions tab → `dogfood` workflow → most recent run. Per-job logs live under `dogfood-build-cycle`.

**Reproducing a failure locally.**

```bash
bash scripts/ci-dogfood.sh
```

Run from the plugin repo root, ideally from a clean working tree. The script asserts pre/post symmetry of `git status --porcelain`, so a dirty tree at entry will mask any new pollution introduced by the run (the assertion catches deltas, not absolute cleanliness). CI checks out a clean tree, so this concern is local-only. The smoke-test step requires `ANTHROPIC_API_KEY`. Set the env var locally before running, or omit it to exercise the auth-failure path (the script will fail with a recognizable `Invalid API key` or `Not logged in` error rather than hanging). The full-scenario step `cd`s into the worktree's copy of `tests/fixtures/hello-roughly/` (a minimal target project — *not* a Roughly install) before invoking `/roughly:build --ci`; mutations land inside the worktree and are torn down by the cleanup trap, so the source tree is untouched.

**`--ci` flag.** `/roughly:build --ci` is the non-interactive mode used by the dogfood scenario. Stage 1 of the build skill detects `--ci` in `$ARGUMENTS` and sets internal `CI_MODE=true`; Stage 4 then skips the blocking `/roughly:review-plan` dispatch and emits a synthetic `PASS` marker. All other stages run normally (conversational gates self-progress under `claude -p`). `--ci` is the only legitimate non-interactive entry point — never invoke it from a normal interactive session, and do not treat its Stage 4 puncture as precedent (see ADR-001). See `skills/build/SKILL.md` Stage 1 + Stage 4 for the canonical implementation.

**In scope for v0.1.5 CI.**

- S11a — scaffolding stub (landed in this story)
- S11b-1 — CLI plumbing smoke test
- S11b-2 — happy-path build cycle (landed in this story)

**Out of scope for v0.1.5 CI.**

- `/roughly:fix`, `/roughly:setup`, `/roughly:upgrade` coverage
- Build-cycle negative-path scenarios (review-plan NEEDS REVISION, Stage 6 max cycles, etc.) — S11b-1 ships an auth-failure regression check at the smoke layer, but full pipeline negative paths land with S11b-2 or later
- Caching of Claude state or `node_modules` between runs

**Token-cost expectations.**

- S11b-1: ~5K tokens per run
- S11b-2: ≤150K Sonnet tokens per run

CI cost is a non-trivial release-cost driver at high PR push frequency — flag for monitoring.

**Auth.** Requires the `ANTHROPIC_API_KEY` repo secret (Settings → Secrets and variables → Actions). The smoke step consumes the secret via a step-scoped `env:` mapping on `Run dogfood scaffolding`; the auth-failure negative-test step uses a deliberately-invalid placeholder, also step-scoped. The real secret is never exposed at workflow-global scope.

## Stop hook drift checks

`.claude/hooks/verify-all.sh` runs as a non-blocking Stop hook after every Claude turn (always exits 0, informational only — see `skills/setup/templates/verify-all-stop-hook.sh.template` header). It enforces seven structural invariants:

1. **Path drift** — `agents/` files must not reference legacy `.ruckus/known-pitfalls`.
2. **Skill line cap** — every `skills/*/SKILL.md` stays ≤ 300 lines.
3. **Agent word cap** — every `agents/*.md` stays ≤ 500 words.
4. **HTML comment integrity** — `agents/agent-preamble.md` contains exactly one `<!--` opener and one `-->` closer.
5. **Pre-flight wording byte-identity across 7 hard-abort skills** — `audit-epic`, `build`, `fix`, `review`, `review-plan`, `review-epic`, `verify-all` must have byte-identical pre-flight migration check blocks (canonical source: `tests/fixtures/canonical-preflight-block.txt`). `skills/setup/SKILL.md` uses an intentionally-divergent soft-abort form and is excluded.
6. **`plan-mode-gate` hook-pair byte-identity** — `.claude/hooks/plan-mode-gate.sh` and `skills/setup/templates/plan-mode-gate.sh.template` must be byte-identical. The `verify-all-stop-hook.sh.template` ↔ dogfood `verify-all.sh` pair is **explicitly out of scope**: per `docs/planning/epics/complete/E03-trust-and-ergonomics.md` section `#### E03.S2: Stop-hook-v1 maturity check completion` under `### Trust hardening cluster`, the dogfood "stays as-is (project-specific drift checks for the plugin's own development); this story produces a separate, project-agnostic template."
7. **`.roughly/known-pitfalls.md` organize threshold** — fires when `wc -l > PITFALLS_ORGANIZE_THRESHOLD` (currently 80). The matching policy parameter lives in `agents/doc-writer.md` Process step 5 ("Organize suggestion") — bidirectional sync comments name each consumer.

Checks 1–4 are pre-existing (S2-era structural invariants). Checks 5–7 land in E04.S5 as a coverage-completion bundle.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
