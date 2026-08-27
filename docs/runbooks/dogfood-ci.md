# Runbook: Dogfood CI (the paid end-to-end test)

## What it is

The dogfood ([`scripts/ci-dogfood.sh`](../../scripts/ci-dogfood.sh), workflow [`.github/workflows/dogfood.yml`](../../.github/workflows/dogfood.yml)) runs the **real product**: it launches actual `claude` sessions with the plugin loaded and drives real `/roughly:build --ci` and `/roughly:fix --ci` pipelines against the [`hello-roughly`](../../tests/fixtures/hello-roughly) fixture. A model-orchestration plugin can't be verified any other way — so this is a live Claude session, which means **real API calls billed to the `ANTHROPIC_API_KEY` GitHub secret.**

## When to run it

**Not on every push/PR** — deliberately, at a **version-pin / pre-ship moment** (before cutting a release, or when bumping the pinned Claude Code version). It is the pre-ship behavioral gate.

Two ways to trigger:

1. **Label a PR** with **`ci:dogfood`** — the job runs when the label is added and re-runs on each subsequent push while the label is present.
2. **Manual dispatch** — GitHub Actions tab → `dogfood` workflow → **Run workflow** (`workflow_dispatch`).

The `ci:dogfood` label path only ever produces PR-ref runs — it checks out the PR's branch, never `main`. `workflow_dispatch` is therefore the sole route to a run against `main`, which is the fact any consecutive-green tracking depends on, since only `main` runs qualify.

(The mechanics — the `on:`/`if:` gate — are in CONTRIBUTING.md's [`## CI`](../../CONTRIBUTING.md#ci) section.)

## Cost

Up to **~$10 per run**, billed to the account behind `ANTHROPIC_API_KEY`:

| Step | Budget cap |
|------|-----------|
| smoke (auth check) | $0.05 |
| plugin-load (`/roughly:help`) | $1.00 |
| 6 pipeline scenarios (build happy-path, fix, build-abort, build-abort-control, plan-revision, plan-clean) | $1.50 each = up to $9.00 |
| **Total** | **$10.05** |

**Use a dedicated, budget-capped API key** for CI — not a personal one. A depleted account fails the run at the first (smoke) step with `Credit balance is too low`. Set/rotate the key at **Settings → Secrets and variables → Actions → `ANTHROPIC_API_KEY`**.

## Risk 3 consecutive-green accounting

Tracks E06 Risk 3 — the "3 consecutive green `main` runs" gate carried in [`docs/ROADMAP.md`](../ROADMAP.md)'s v0.1.9 retrospective DoD. No canonical location for the running count existed before this section; the count lived only as narrative prose scattered across epic files and had to be re-derived by memory every release — which is how it reached 0 unnoticed. **This section is that location.** Update the count below whenever a qualifying run lands or the counter resets.

**What resets the counter.** The canonical rule, quoted from [`docs/ROADMAP.md:202`](../ROADMAP.md): *"Counter restarts after every `main` change touching the workflow **or its inputs**."* State it this way deliberately — as the criterion, not as an enumerated file list. A closed list here would recreate the closed-world-vs-enumerated-list failure `CLAUDE.md` warns about (an earlier draft of this accounting requirement made exactly that mistake and had to be corrected), and it would silently stop covering inputs added after this was written. Current membership, given as a **non-exhaustive illustration**, not a definition:

- the workflow itself, [`.github/workflows/dogfood.yml`](../../.github/workflows/dogfood.yml)
- the harness, [`scripts/ci-dogfood.sh`](../../scripts/ci-dogfood.sh)
- the fixtures it drives, [`tests/fixtures/*`](../../tests/fixtures)
- the class most often missed — **the pipeline skill bodies.** `scripts/ci-dogfood.sh` invokes the pipelines six times (five `/roughly:build`, one `/roughly:fix`), so `skills/build/SKILL.md`, `skills/fix/SKILL.md`, and any `skills/shared/*.md` they `Read` at runtime are inputs; a change to any of them changes what the six scenarios execute and resets the count.

(E06's own S3 close criterion — *"3 consecutive runs on `main` without harness modification post-merge"* — is a related but narrower rule limited to the harness and silent on inputs; it is not the source of the "or its inputs" wording above, which is [`docs/ROADMAP.md:202`](../ROADMAP.md) alone.)

**What a qualifying run is.** All five conditions must hold — this is the canonical definition E07.S2's executable check points at:

| Field | Required value |
|-------|-----------------|
| `event` | `workflow_dispatch` |
| `headBranch` | `main` |
| `workflowName` | `dogfood` |
| run `conclusion` | `success` |
| `dogfood-build-cycle` job `conclusion` | `success` |

Take every field from the run object itself, never from a local ref — a local `git rev-parse main` proves nothing about what a runner actually checked out. Project all five in one call:

```sh
gh run view <run-id> --json databaseId,url,event,headBranch,headSha,workflowName,conclusion,createdAt,jobs \
  --jq '{id:.databaseId, url, event, branch:.headBranch, sha:.headSha, workflow:.workflowName,
         run:.conclusion, job:[.jobs[]|select(.name=="dogfood-build-cycle")|.conclusion], at:.createdAt}'
```

Pass condition: `event` = `workflow_dispatch`, `branch` = `main`, `workflow` = `dogfood`, `run` = `success`, `job` = `["success"]` exactly. **An empty `job` array means `dogfood-build-cycle` never executed and the run does not qualify, however green the workflow reads** — a workflow-level `conclusion` of `success` cannot by itself catch a run whose `if:` guard skipped the job entirely.

**Current count.** **0 consecutive greens** on the post-#65 `main` (as of 2026-08-27). All-time the workflow has 6 successes, all on 2026-05-08 against the pre-scenario E03.S11a scaffolding — before the real pipeline scenarios existed — against 138 failures since. The last executed run (2026-07-18) died in 11 seconds on `Credit balance is too low`; no run has landed on `main` since 2026-07-17.

## Reading the results

- **smoke** — proves auth + `--plugin-dir` acceptance. `ci-dogfood: FAIL — API account state: <classification>` (insufficient credit, invalid or revoked API key, rate limited) ⇒ no Roughly *pipeline* behavior was exercised — not a pipeline regression, and reruns reproduce it while the account remains in that state. A generic `… claude exited N` FAIL is the one worth investigating.
- **plugin-load** — invokes `/roughly:help` and requires `/roughly:setup` in its rendered command list; same `API account state` marker and read as smoke applies here too. Otherwise this is a *deterministic* load proof (an unknown command couldn't render it) — if the generic FAIL fires but `/roughly:help` clearly loaded, suspect the anchor/model output, not the plugin.
- **scenarios** — each asserts pipeline-specific markers (e.g. `[--ci] plan review verdict: PASS`, abort markers). A 124 exit is a hard timeout FAIL.

## Local reproduction

```bash
export ANTHROPIC_API_KEY=sk-ant-...        # a real key; you are billed
bash scripts/ci-dogfood.sh
```

Run from the repo root on a clean tree (the script asserts pre/post `git status --porcelain` symmetry). macOS needs `gtimeout` (`brew install coreutils`). Mutations land in a throwaway worktree and are cleaned up by the trap.

## Bumping the pinned Claude Code version

The workflow pins an **exact** Claude Code version (e.g. `@anthropic-ai/claude-code@2.1.198`) rather than the floating `@2` tag, so a silent CC release can't change `--bare`/`--plugin-dir` or model behavior and break the harness with no repo change. To bump it:

1. Update the pin in `.github/workflows/dogfood.yml` (the `Install Claude Code` step) to the new version.
2. **Re-validate the harness against that version** — ideally run the full dogfood (label a PR), or at minimum reproduce the smoke + plugin-load steps locally with the new CLI installed and confirm `/roughly:help` still resolves under `--bare --plugin-dir`.
3. Commit the pin bump only after the re-validation is green.

> Why this matters: a prior floating-`@2` run broke CI because the current model no longer enumerates plugin skills when asked to "list your slash commands" — the load probe was rewritten to *invoke* `/roughly:help` instead, and the version pinned, precisely so this class of drift is caught deliberately, not silently. See the memory note / issue history.
