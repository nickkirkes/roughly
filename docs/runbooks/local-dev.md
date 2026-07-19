# Runbook: Local development

How to work on the Roughly plugin locally and validate a change before committing.

Roughly is a **Claude Code plugin — pure markdown, no build step.** "Running" it means loading it into a Claude Code session against some target project and invoking its `/roughly:*` skills.

## Prerequisites

- `claude` (Claude Code CLI) — `npm install -g @anthropic-ai/claude-code`
- `git`
- Optional: `jq`, `shasum`/`sha1sum` (used by the structural checks; both are standard on macOS/Linux)

## 1. Clone

```bash
git clone https://github.com/nickkirkes/roughly.git
cd roughly
```

## 2. Run the plugin against a scratch project

From **any** project directory (not the plugin repo — skills run in the *user's* project context), point Claude Code at your clone:

```bash
cd /path/to/some/scratch-project
claude --plugin-dir /path/to/roughly
```

The skills load as namespaced slash commands: `/roughly:help`, `/roughly:build`, `/roughly:fix`, etc. `/roughly:help` is the safe read-only one to confirm the plugin loaded.

There is a minimal target fixture in the repo at [`tests/fixtures/hello-roughly/`](../../tests/fixtures/hello-roughly) if you want a throwaway project to drive a pipeline against.

## 3. Iterate

- Skills live in `skills/<name>/SKILL.md`; agents in `agents/<name>.md`.
- Runtime-shared procedural prose lives in `skills/shared/*.md` and is pulled in via a `Read` directive (see [ADR-012](../adrs/ADR-012-runtime-shared-procedural-references.md)).
- Edits take effect on the next `claude --plugin-dir` session (there's no compile/watch step).

## 4. Validate before committing

The repo ships a **Stop hook** ([`.claude/hooks/verify-all.sh`](../../.claude/hooks/verify-all.sh)) that runs structural checks after every Claude turn *while you work inside the repo* — silent on success, prints a `systemMessage` on drift. You can also run it directly:

```bash
bash .claude/hooks/verify-all.sh    # prints nothing when clean (except advisory notes)
```

It enforces, among others:

- Skill bodies **< 300 lines**; agent prompts **< 650 words**.
- `build:11` ↔ `fix:11` CRITICAL preamble byte-identity, plus the closed-world gate + anti-laundering phrasing (ADR-009 / ADR-015).
- Pre-flight block byte-identity across the 7 hard-abort skills.
- `plan-mode-gate.sh` hook↔template pair presence + identity.
- Shared-reference (ADR-012) drift for `abort-handling.md`, `stage-8-wrap-up.md`, `gate-protocol.md`, and the inline local-commit boundary.

Also confirm by hand:

- Frontmatter is valid YAML — skills need `name` + `description`; pipeline/coordinator skills need `disable-model-invocation: true`; agents need `name`, `description`, `tools`, `model`.
- Cross-references (agent names in skills, file paths) resolve.
- No unreplaced `{{PLACEHOLDER}}` markers outside `skills/setup/templates/`.

See [CLAUDE.md](../../CLAUDE.md) `## Conventions` for the full list.

## What local dev does *not* cover

- **End-to-end behavioral testing** (does a real `/roughly:build` pipeline actually work?) is the **dogfood** — it costs money and is run deliberately, not on every change. See [dogfood-ci.md](dogfood-ci.md).
- **PR process / what to contribute** — see [CONTRIBUTING.md](../../CONTRIBUTING.md).
