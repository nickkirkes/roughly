**Fixture purpose:** AC2 NEEDS REVISION — grep -Fc verify counts N sites within a single paragraph, same-line co-location plausible.

# Implementation Plan: Add Recovery labels to Stage 4 gate description in build skill

Plan-format-version: 1

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| `skills/build/SKILL.md` | edit | T1 |

## Tasks

### T1: Add "Recovery:" prefix to three abort-action sentences in Stage 4 prose (~10 min)
**Files:** `skills/build/SKILL.md`
**Action:** Insert the label `Recovery:` at the start of three existing abort-action sentences within the Stage 4 gate description paragraph. The paragraph is a continuous block of prose; each abort-action sentence currently begins with an imperative verb.
**Details:**
Edit site 1: `skills/build/SKILL.md` Stage 4 gate description paragraph — locate the sentence beginning "Emit the abort message …" and prepend `Recovery: `.
Edit site 2: `skills/build/SKILL.md` Stage 4 gate description paragraph — locate the sentence beginning "Do not proceed to Stage 5 …" and prepend `Recovery: `.
Edit site 3: `skills/build/SKILL.md` Stage 4 gate description paragraph — locate the sentence beginning "Surface the blocking issue …" and prepend `Recovery: `.

The three sentences are within the same dense prose paragraph. Paragraph wrapping and editor line-length settings may place two or more of these sentences on the same physical line in the file.

**Verify:** `test $(grep -Fc "Recovery:" skills/build/SKILL.md) -eq 3`

**UI:** no
