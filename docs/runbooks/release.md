# Runbook: Cut a release

> **⚠ DRAFT — verify before first use.** This was reconstructed from release signals in the repo (CHANGELOG structure, tags `v0.1.4`–`v0.1.8`, the `chore: release-prep for vX.Y.Z` commit convention), not from a maintainer's written process. Confirm each **[VERIFY]** point below against how you actually ship, then remove this banner.

Roughly is distributed as a Claude Code **marketplace plugin** ([`.claude-plugin/marketplace.json`](../../.claude-plugin/marketplace.json), `source: ./`). A release is: bump the version, record the changes, and tag the commit. **[VERIFY]** there is no separate publish step (no npm package — consumers install via the marketplace git repo).

## Version sources (what a release changes)

- **`.claude-plugin/plugin.json`** → `"version"` — **the only version field.** `marketplace.json` carries no version and is not bumped.
- **`CHANGELOG.md`** → a new `## [X.Y.Z] — YYYY-MM-DD` section.
- **git tag** `vX.Y.Z` (lightweight, pointing at the release-prep commit).

## Preconditions

- `main` is up to date, clean, and contains all intended changes.
- You've picked `X.Y.Z` (semver).
- **Pre-ship behavioral gate is green** — run the paid dogfood (see [dogfood-ci.md](dogfood-ci.md)); this is the moment the `ci:dogfood` label exists for. **[VERIFY]** whether a green dogfood is a hard gate or advisory for you.

## Steps

1. **Update `CHANGELOG.md`.** Add a new top section following the existing format:
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
2. **Bump the version** in `.claude-plugin/plugin.json` (`"version": "X.Y.Z"`).
3. **Run the dogfood** and confirm green (label a release PR with `ci:dogfood`, or dispatch it). See [dogfood-ci.md](dogfood-ci.md).
4. **Commit** the prep:
   ```bash
   git commit -am "chore: release-prep for vX.Y.Z"
   ```
   **[VERIFY]** whether this lands directly on `main` or via a release PR (branch protection). History shows direct `chore: release-prep …` commits on `main`.
5. **Tag and push:**
   ```bash
   git tag vX.Y.Z            # lightweight, matching existing tags
   git push origin main --follow-tags
   ```
6. **GitHub Release (optional).** **[VERIFY / DECIDE]** — Releases were published through `v0.1.5` then lapsed (`v0.1.6`–`v0.1.8` have tags but no GitHub Release). If resuming:
   ```bash
   gh release create vX.Y.Z --title "vX.Y.Z — <headline>" --notes-file <changelog-section>
   ```
7. **Post-release sanity.** From a scratch project, install/update the plugin from the marketplace and confirm `/roughly:help` reports the new version. **[VERIFY]** the exact consumer install/update command.

## Assumptions to confirm and bake in

- [ ] No npm (or other registry) publish step — marketplace/git distribution only.
- [ ] Release lands on `main` directly vs. via a PR.
- [ ] Whether GitHub Releases resume from this version.
- [ ] Whether the dogfood is a hard pre-ship gate.
- [ ] Any `README.md` / `docs/ROADMAP.md` version references that need updating at release time.

Once confirmed, replace the **[VERIFY]** markers with the real steps and delete the DRAFT banner.
