# FX02 — Joint-Impossibility Fixture Epic (NEEDS REVISION)

Synthetic single-story epic mirroring the E04.S8 contradiction pattern. Required
verdict from `epic-reviewer` (Review Dimension #7): blocker citing the exact phrase
"AC mutual satisfiability".

## Story FX02.S1 — Gate-guarded preflight rewrite

**Goal:** Guard the preflight-rewrite codepath behind a runtime gate, while
preserving the rewrite behavior when the gate is closed.

**ACs:**

1. When the runtime gate `preflight.enabled` reads `false` (gate closed), the
   preflight handler in `src/preflight/rewrite.ts` MUST still rewrite the incoming
   request body in-place before returning. The rewrite must fire on every request
   while the gate is closed; skipping the rewrite is a defect.

2. The file `src/preflight/rewrite.ts` MUST NOT be modified by this story. Any
   change to the rewrite codepath is out of scope and forbidden; reviewers should
   reject diffs that touch this file.

**Notes:** AC1 requires new conditional behavior inside the rewrite codepath
(`src/preflight/rewrite.ts`) when the gate is closed, while AC2 forbids any
modification of that very file. The joint state "gate closed AND file unmodified
AND rewrite still fires on every request" is structurally impossible — the
existing handler has no such conditional branch. This is the AC mutual
satisfiability failure pattern from E04.S8.
