# epic-reviewer Fixtures

Fixtures for the `epic-reviewer` agent's AC mutual satisfiability check (epic E05.S6 AC1).

**Fixture forms:** PASS (orthogonal-surfaces carve-out applies — the check does not fire), NEEDS REVISION (joint-impossibility per the E04.S8 contradiction pattern — blocker verdict cites "AC mutual satisfiability" by name).

## Fixture Inventory

| File | Targets | Expected verdict | Reason |
|------|---------|------------------|--------|
| `ac-mutual-satisfiability-pass.md` | E05.S6 AC1 (carve-out) | Ready / no blockers | AC mutual satisfiability — orthogonal ACs (carve-out applies, check does not fire). Story touches two different files in two different prose regions. |
| `ac-mutual-satisfiability-needs-revision.md` | E05.S6 AC1 | Blocker citing "AC mutual satisfiability" | AC mutual satisfiability — joint-impossibility per E04.S8 contradiction pattern. AC1 requires modification when a gate is closed; AC2 forbids modifying that very codepath. |

## How to Verify

The `epic-reviewer` agent (see `agents/epic-reviewer.md`) carries a Review Dimension #7 ("AC mutual satisfiability") added in E05.S6 T2. To verify a fixture:

**Path A — Manual desk-check (lowest-friction):**

Read each fixture and mentally apply Review Dimension #7 from `agents/epic-reviewer.md`. For every fixture, confirm the expected verdict in the inventory table above matches what the dimension prose would produce. The PASS fixture exercises the orthogonal-surfaces carve-out (different files, different prose regions → check does not fire). The NEEDS REVISION fixture mirrors the E04.S8 joint-impossibility pattern and must produce a blocker that cites the exact phrase "AC mutual satisfiability".

**Path B — Subagent dispatch (more rigorous):**

In a session with Roughly loaded, dispatch the `epic-reviewer` agent and pass it a single fixture as input. Instruct it to follow its review process exactly and produce the structured verdict block. Repeat per fixture. Required outcomes:

- `ac-mutual-satisfiability-pass.md` → **Ready / no blockers** (Review Dimension #7 carve-out applied — orthogonal surfaces noted)
- `ac-mutual-satisfiability-needs-revision.md` → **Blocker** whose text contains the exact phrase "AC mutual satisfiability"

## Note

Fixture content should be updated only when Review Dimension #7 wording in `agents/epic-reviewer.md` changes. Treat fixture drift as an indicator that the dimension has materially changed and warrants re-verification.
