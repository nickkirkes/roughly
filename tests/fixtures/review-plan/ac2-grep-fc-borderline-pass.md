**Fixture purpose:** AC2 BORDERLINE-PASS — grep -Fc verify counts N sites in plausibly-co-locatable region WITH explicit distinctness rationale (exercises carve-out boundary).

# Implementation Plan: Add step numbers to three checklist items in setup skill

Plan-format-version: 1

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| `skills/setup/SKILL.md` | edit | T1 |

## Notes

The three edit sites target items 2, 4, and 6 of an existing ordered list in `skills/setup/SKILL.md`. Markdown ordered-list items must each begin on their own line — a line starting with `2.`, `4.`, or `6.` cannot share a physical line with another list item. Each addition therefore lands at the head of a distinct numbered list item (positions 2, 4, and 6 in the existing ordered list) — guaranteed one-per-line by markdown ordered-list structure. The `grep -Fc "Step-label:"` count equals the occurrence count under this structural guarantee.

## Tasks

### T1: Insert "Step-label:" prefix on items 2, 4, and 6 of the pre-flight checklist (~8 min)
**Files:** `skills/setup/SKILL.md`
**Action:** Prepend `Step-label:` to the text of checklist items 2, 4, and 6 in the pre-flight ordered list. These items currently begin with bare imperative phrases; the label makes them scannable in downstream verification.
**Details:**
Edit site 1: `skills/setup/SKILL.md` ordered list item 2 — change `2. Confirm the target directory exists` to `2. Step-label: Confirm the target directory exists`.
Edit site 2: `skills/setup/SKILL.md` ordered list item 4 — change `4. Verify placeholder values are populated` to `4. Step-label: Verify placeholder values are populated`.
Edit site 3: `skills/setup/SKILL.md` ordered list item 6 — change `6. Run the smoke test` to `6. Step-label: Run the smoke test`.

The three items are at positions 2, 4, and 6 in the list. The surrounding items (1, 3, 5) are unmodified. Because markdown ordered-list syntax places each item on its own line, no two of the three `Step-label:` insertions can share a physical line — they are structurally isolated by the list items between them.

**Verify:** `test $(grep -Fc "Step-label:" skills/setup/SKILL.md) -eq 3`

**UI:** no
