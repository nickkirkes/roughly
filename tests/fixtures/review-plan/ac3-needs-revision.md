**Fixture purpose:** AC3 NEEDS REVISION — skill body uses fall-through prose that invites cumulative execution across multiple cases.

## Step 3: Determine release type

If `git diff main...HEAD --name-only` returns only `docs/` files, this is a patch release — increment v0.X.Y → v0.X.Y+1.

Then if non-`docs/` files were modified, check whether an ADR was added. If yes, this is a major release — emit the major-release prompt. Otherwise, this is a minor release — increment v0.X → v0.X+1.0.

Also: if multiple of these conditions apply, run the patch-release emit first, then escalate to minor or major.
