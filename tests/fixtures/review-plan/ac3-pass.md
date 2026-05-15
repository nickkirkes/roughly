**Fixture purpose:** AC3 PASS — skill body uses explicit top-to-bottom case-dispatch with no-accumulation guard.

## Step 3: Determine release type

Evaluate the conditions in order top-to-bottom; execute ONLY the first matching case's emit logic, then end Step 3. Cases are NOT cumulative — do NOT execute logic from later cases after an earlier one has already matched.

### Case A — Patch release

If `git diff main...HEAD --name-only` returns only `docs/` files: emit "Patch release detected. Increment v0.X.Y → v0.X.Y+1."

### Case B — Minor release

If non-`docs/` files were modified but no `ADR-` file was added: emit "Minor release detected. Increment v0.X → v0.X+1.0."

### Case C — Major release

If any `docs/adrs/ADR-*.md` file was newly added: emit "Major release detected. Increment v0.X → v1.0.0 requires human sign-off."
