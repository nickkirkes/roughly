**Fixture purpose:** AC3 BORDERLINE-PASS — plan adds count-bounded check that looks like a new invariant but is structurally-bounded by an existing rule (exercises carve-out boundary).

# Implementation Plan: Add upper-bound guard to process-entries pipeline

Plan-format-version: 1

## Acceptance Criteria (from epic)

**AC2:** The `process-entries` function must maintain three named invariants: ordering (entries are processed in insertion order), deduplication (no entry is processed twice), and count-correctness (the reported count matches the number of successfully processed entries). No new structural rules beyond the three named invariants.

## File Table

| File | Action | Task(s) |
|------|--------|---------|
| `scripts/process-entries.sh` | edit | T1 |
| `tests/process-entries.bats` | edit | T1 |

## Tasks

### T1: Add upper-bound precondition guard derived from count-correctness invariant (~6 min)

**Files:** `scripts/process-entries.sh`, `tests/process-entries.bats`

**Action:** Add a precondition guard at the top of `process_entries()` that aborts if the entries array exceeds MAX_ENTRIES (255).

**Details:**

Defensive guard for the named count-correctness invariant, no new invariant added — MAX_ENTRIES is structurally derived from the count-correctness invariant. (defensive guard for named invariant, structurally bounded by count-correctness)

**Derivation rationale:** The count-correctness invariant (from AC2) requires that the reported count matches the number of successfully processed entries. The internal counter is stored as an 8-bit unsigned integer (`uint8_t processed_count`), which holds values 0–255. After processing 255 entries the counter reads 255; the 256th increment overflows silently (wraps 255 → 0), making the reported count no longer match the actual number of processed entries — the count-correctness invariant is violated. MAX_ENTRIES=255 is not a new bound introduced by this plan; it is the upper limit implied by the existing count-correctness invariant given the 8-bit counter representation. The guard enforces that bound before the loop begins, preventing silent overflow that would corrupt the invariant.

Edit site 1: `scripts/process-entries.sh` line 14 — insert the following block immediately after the function opens:

```bash
MAX_ENTRIES=255
if [ ${#entries[@]} -gt $MAX_ENTRIES ]; then
  echo "entries array exceeds MAX_ENTRIES (${MAX_ENTRIES}); aborting to preserve count-correctness invariant" >&2
  return 1
fi
```

This check is bounded by the count-correctness invariant, not a new freestanding bound. The error message names the invariant explicitly so reviewers can trace the derivation.

Edit site 2: `tests/process-entries.bats` line 95 — add a test case:

```bash
@test "process_entries: rejects oversized array to preserve count-correctness" {
  # Generate 256 entries — exactly the boundary where the uint8_t counter would
  # overflow on the 256th increment; this is the strictest test of the guard.
  entries=( $(seq 1 256) )
  run process_entries
  [ "$status" -eq 1 ]
  [[ "$output" == *"count-correctness invariant"* ]]
}
```

**Verify:** `bash -n scripts/process-entries.sh` exits 0; `bats tests/process-entries.bats` passes all cases including the new upper-bound test.

**UI:** no

## Notes

**Carve-out boundary analysis:** At first glance, the `entries.length > MAX_ENTRIES` check appears to introduce a new bound (a maximum input size) that is not present in the AC. A reviewer could reasonably flag this as a new structural rule. However, the derivation above establishes that MAX_ENTRIES=255 is not a new freestanding rule — it is the upper limit structurally implied by the count-correctness invariant given the 8-bit counter implementation (the counter can correctly represent 0–255 processed entries; the 256th increment overflows). The check enforces an existing invariant's boundary condition; it does not assert a new correctness property.

The line is genuinely fine-grained: a reviewer who does not trace the derivation from `uint8_t processed_count` to the 255-entry safe limit would flag this as a new rule. A reviewer who does trace it would recognize the structural derivation. The explicit rationale in the plan body — naming the source invariant, the counter type, the overflow behavior, and the conclusion — is intended to give the reviewer enough information to recognize the carve-out.

Expected verdict: PASS — the rationale establishes that the MAX_ENTRIES bound is structurally derived from the count-correctness invariant; the check is a defensive guard for a named invariant, not a new structural rule. The AC's bound ("no new structural rules beyond the three named invariants") is preserved.
