**Fixture purpose:** AC1 NEEDS REVISION — verify scope broader than enumeration with NO acknowledgment.

# Implementation Plan: Add `disable-model-invocation` frontmatter to build and fix skills

Plan-format-version: 1

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| `skills/build/SKILL.md` | edit | T1 |
| `skills/fix/SKILL.md` | edit | T1 |

## Tasks

### T1: Insert `disable-model-invocation: true` into build and fix skill frontmatter (~5 min)
**Files:** `skills/build/SKILL.md`, `skills/fix/SKILL.md`
**Action:** Add `disable-model-invocation: true` to the YAML frontmatter of both pipeline skill files.
**Details:**
Edit site 1: `skills/build/SKILL.md` — in the YAML frontmatter block (between `---` delimiters), insert `disable-model-invocation: true` after the `description:` line.
Edit site 2: `skills/fix/SKILL.md` — in the YAML frontmatter block (between `---` delimiters), insert `disable-model-invocation: true` after the `description:` line.
**Verify:** `rg -Fn "disable-model-invocation: true" skills/`
**UI:** no
