# Runbook: Cut a release

Roughly is distributed as a Claude Code **marketplace plugin** ([`.claude-plugin/marketplace.json`](../../.claude-plugin/marketplace.json), `source: ./`). A release is: bump the version, record the changes in a review PR, merge to `main`, and tag. **There is no npm/registry publish step** — consumers install from the marketplace git repo.

## Version sources (what a release changes)

- **`.claude-plugin/plugin.json`** → `"version"` — **the only version field.** `marketplace.json` carries no version and is not touched.
- **`CHANGELOG.md`** → a new `## [X.Y.Z] — YYYY-MM-DD` section.
- **git tag** `vX.Y.Z` (lightweight, on the merged release commit).

## Preconditions

- `main` is up to date and contains all intended changes.
- You've picked `X.Y.Z` (semver).

## Steps

1. **Branch from `main`:**
   ```bash
   git checkout main && git pull
   git checkout -b release/vX.Y.Z
   ```
2. **Update `CHANGELOG.md`** — add a new top section in the existing format:
   ```markdown
   ## [X.Y.Z] — YYYY-MM-DD

   > One-line scope summary (link the epic/issue if applicable).

   ### Added
   - …
   ### Changed
   - …
   ### Fixed
   - …
   ```
3. **Bump the version** in `.claude-plugin/plugin.json` (`"version": "X.Y.Z"`).
4. **Align the docs to the new version.** Review [`README.md`](../../README.md) and [`docs/ROADMAP.md`](../ROADMAP.md) and update anything that references the old version, shipped/unshipped status, counts, or behavior that changed this release. Docs must match what `vX.Y.Z` actually is.
5. **Commit:**
   ```bash
   git commit -am "chore: release-prep for vX.Y.Z"
   ```
6. **Open a PR to `main`** and **add the `ci:dogfood` label.** This triggers the paid dogfood, which is a **hard pre-ship gate** — the PR does not merge until the dogfood run is green (see [dogfood-ci.md](dogfood-ci.md)). Also get the normal review approval.
7. **Merge the PR to `main`** once the dogfood is green and review is approved.
8. **Tag and push the tag:**
   ```bash
   git checkout main && git pull
   git tag vX.Y.Z          # lightweight, on the merged release commit
   git push origin vX.Y.Z
   ```
   Tagging is the release. (No GitHub Release object is created — the tag is the artifact; new work continues on branches off `main`.)
9. **Post-release sanity — the consumer update path.** From a project that has the plugin installed:
   ```bash
   claude plugin marketplace update nickkirkes   # refresh the marketplace from source
   claude plugin update roughly                  # upgrade the installed plugin
   ```
   Confirm the installed plugin version deterministically with `claude plugin list` (shows `roughly` → `Version: X.Y.Z`). **Note:** `/roughly:help`'s "Plugin version" line does **not** reflect this yet — it reads the `roughly-version` marker in the project's `.roughly/workflow-upgrades`, which only `/roughly:setup` and `/roughly:upgrade` write (never `claude plugin update`). A consumer must run **`/roughly:upgrade`** in their project — it syncs installed files from the new templates and records the version — before `/roughly:help` reports `vX.Y.Z`.

## Checklist

- [ ] `CHANGELOG.md` section added for `X.Y.Z`
- [ ] `.claude-plugin/plugin.json` version bumped
- [ ] `README.md` + `docs/ROADMAP.md` reviewed and aligned to the version
- [ ] Release PR opened, `ci:dogfood` label added, **dogfood green**, review approved
- [ ] `/roughly:setup` smoke-tested in a scratch project — the dogfood exercises build/fix (and `/roughly:upgrade` runs in the consumer-update step below), but **not** `/roughly:setup`; its `${CLAUDE_PLUGIN_ROOT}`-anchored template reads (issue #67) have no other coverage path
- [ ] Merged to `main`
- [ ] `vX.Y.Z` tag pushed
- [ ] Consumer update verified (`marketplace update` → `plugin update` → `claude plugin list` shows `Version: X.Y.Z`; `/roughly:help` reflects it only after a project runs `/roughly:upgrade`)

_Last validated: 2026-07-19._
