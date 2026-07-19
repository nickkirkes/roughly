# Runbooks

Operational, step-by-step procedures for developing and shipping Roughly. These are **maintainer/contributor** guides — distinct from [CONTRIBUTING.md](../../CONTRIBUTING.md) (how to make a good PR) and the [ADRs](../adrs/) (why the design is what it is).

Each runbook is single-purpose. Reach for the one that matches what you're doing:

| Runbook | Use it when… |
|---------|--------------|
| [local-dev.md](local-dev.md) | Setting up a local clone, running the plugin against a scratch project, and running the structural checks before you commit. |
| [dogfood-ci.md](dogfood-ci.md) | You want to run the **paid** end-to-end dogfood (real Claude sessions), or you're bumping the pinned Claude Code version. |
| [release.md](release.md) | Cutting a new version — CHANGELOG, version bump, tag. **(DRAFT — verify before first use.)** |

**Conventions for this directory**
- One procedure per file; keep them short and executable.
- Don't duplicate reference material — link to CONTRIBUTING.md / CLAUDE.md / ADRs for the *why* and the *conventions*; runbooks hold the *steps*.
- If a procedure grows a distinct sub-workflow, split it into its own runbook rather than nesting.
