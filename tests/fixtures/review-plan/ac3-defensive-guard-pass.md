**Fixture purpose:** AC3 PASS — plan adds defensive precondition guards for named invariants; no new invariant introduced.

# Implementation Plan: Add defensive precondition guard to process-entries pipeline

Plan-format-version: 1

## Acceptance Criteria (from epic)

**AC2:** The `process-entries` function must maintain three named invariants: ordering (entries are processed in insertion order), deduplication (no entry is processed twice), and count-correctness (the reported count matches the number of successfully processed entries). No new structural rules beyond the three named invariants.

## File Table

| File | Action | Task(s) |
|------|--------|---------|
| `scripts/process-entries.sh` | edit | T1 |
| `tests/process-entries.bats` | edit | T1 |

## Tasks

### T1: Add defensive precondition guard for count-correctness invariant (~5 min)

**Files:** `scripts/process-entries.sh`, `tests/process-entries.bats`

**Action:** Add an early-return guard at the top of `process_entries()` to short-circuit when the entries array is empty, preventing a divide-by-zero when computing the success rate at the end of the function.

**Details:**

Defensive guard for the named count-correctness invariant; no new invariant added.

Edit site 1: `scripts/process-entries.sh` line 14 — insert the following block immediately after the function opens and before the iteration loop begins:

```bash
if [ ${#entries[@]} -eq 0 ]; then
  echo "no entries to process" >&2
  return 0
fi
```

This guard prevents the divide-by-zero on line 42 (`success_rate=$(( processed * 100 / ${#entries[@]} ))`) when `entries` is empty. The count-correctness invariant (from AC2) requires that the reported count matches successfully processed entries; an empty array with zero processed entries satisfies that invariant trivially, so early-return is the correct response. This is a defensive precondition for the named invariant, not a new invariant.

Edit site 2: `tests/process-entries.bats` line 88 — add a test case:

```bash
@test "process_entries: empty array returns 0 without divide-by-zero" {
  run process_entries
  [ "$status" -eq 0 ]
  [[ "$output" == *"no entries to process"* ]]
}
```

**Verify:** `bash -n scripts/process-entries.sh` exits 0; `bats tests/process-entries.bats` passes all cases including the new empty-array test.

**UI:** no

## Notes

The new guard is structurally bounded by the existing count-correctness invariant enumerated in AC2. It does not introduce any new rule about what constitutes a valid entry, how entries must be formatted, or any relationship between entries beyond what the three named invariants already describe. The AC's structural-rule bound ("no new structural rules beyond the three named invariants") is preserved.

Expected verdict: PASS — the guard protects an existing named invariant; no new invariant is introduced.
