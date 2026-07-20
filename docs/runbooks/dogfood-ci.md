# Runbook: Dogfood CI (the paid end-to-end test)

## What it is

The dogfood ([`scripts/ci-dogfood.sh`](../../scripts/ci-dogfood.sh), workflow [`.github/workflows/dogfood.yml`](../../.github/workflows/dogfood.yml)) runs the **real product**: it launches actual `claude` sessions with the plugin loaded and drives real `/roughly:build --ci` and `/roughly:fix --ci` pipelines against the [`hello-roughly`](../../tests/fixtures/hello-roughly) fixture. A model-orchestration plugin can't be verified any other way — so this is a live Claude session, which means **real API calls billed to the `ANTHROPIC_API_KEY` GitHub secret.**

## When to run it

**Not on every push/PR** — deliberately, at a **version-pin / pre-ship moment** (before cutting a release, or when bumping the pinned Claude Code version). It is the pre-ship behavioral gate.

Two ways to trigger:

1. **Label a PR** with **`ci:dogfood`** — the job runs when the label is added and re-runs on each subsequent push while the label is present.
2. **Manual dispatch** — GitHub Actions tab → `dogfood` workflow → **Run workflow** (`workflow_dispatch`).

(The mechanics — the `on:`/`if:` gate — are in CONTRIBUTING.md's [`## CI`](../../CONTRIBUTING.md#ci) section.)

## Cost

Up to **~$10 per run**, billed to the account behind `ANTHROPIC_API_KEY`:

| Step | Budget cap |
|------|-----------|
| smoke (auth check) | $0.05 |
| plugin-load (`/roughly:help`) | $1.00 |
| 6 pipeline scenarios (build happy-path, fix, build-abort, build-abort-control, plan-revision, plan-clean) | $1.50 each = up to $9.00 |

**Use a dedicated, budget-capped API key** for CI — not a personal one. A depleted account fails the run at the first (smoke) step with `Credit balance is too low`. Set/rotate the key at **Settings → Secrets and variables → Actions → `ANTHROPIC_API_KEY`**.

## Reading the results

- **smoke** — proves auth + `--plugin-dir` acceptance. Fails ⇒ key invalid or out of credit.
- **plugin-load** — invokes `/roughly:help` and requires `/roughly:setup` in its rendered command list. This is a *deterministic* load proof (an unknown command couldn't render it). If it fails but `/roughly:help` clearly loaded, suspect the anchor/model output, not the plugin.
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
