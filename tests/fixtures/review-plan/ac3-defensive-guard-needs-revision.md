**Fixture purpose:** AC3 NEEDS REVISION — plan adds a fourth invariant while AC forbids new invariants; misclassified as "minor defensive addition."

# Implementation Plan: Harden process-entries pipeline with integrity verification

Plan-format-version: 1

## Acceptance Criteria (from epic)

**AC2:** The `process-entries` function must maintain three named invariants: ordering (entries are processed in insertion order), deduplication (no entry is processed twice), and count-correctness (the reported count matches the number of successfully processed entries). No new structural rules beyond the three named invariants.

## File Table

| File | Action | Task(s) |
|------|--------|---------|
| `scripts/process-entries.sh` | edit | T1 |
| `tests/process-entries.bats` | edit | T1 |

## Tasks

### T1: Add integrity verification step to process-entries pipeline (~8 min)

**Files:** `scripts/process-entries.sh`, `tests/process-entries.bats`

**Action:** Add a minor defensive check after each entry is written to the output file to verify that the written bytes match the expected SHA-256 hash of the entry content.

**Details:**

This is a small defensive addition to harden the pipeline against filesystem corruption or partial writes.

Edit site 1: `scripts/process-entries.sh` line 55 — insert the following block immediately after the `write_entry` call inside the processing loop:

```bash
expected_hash=$(echo "$entry" | sha256sum | awk '{print $1}')
actual_hash=$(tail -c ${#entry} "$OUTPUT_FILE" | sha256sum | awk '{print $1}')
if [ "$expected_hash" != "$actual_hash" ]; then
  echo "integrity check failed for entry: $entry" >&2
  return 1
fi
```

This verifies that file bytes match expected SHA-256 after each write. Minor defensive addition — does not change the observable output format.

Edit site 2: `tests/process-entries.bats` line 102 — add a test case:

```bash
@test "process_entries: aborts on hash mismatch" {
  # Simulate a corrupted write by patching write_entry to truncate
  run process_entries_with_corrupted_write
  [ "$status" -eq 1 ]
  [[ "$output" == *"integrity check failed"* ]]
}
```

**Verify:** `bash -n scripts/process-entries.sh` exits 0; `bats tests/process-entries.bats` passes all cases including the new integrity test.

**UI:** no

## Notes

The hash verification step ensures byte-identity between the in-memory entry and the persisted form. This is described here as a "minor defensive addition" because it does not change the output when everything is working correctly — it only fires on error.

Expected verdict: NEEDS REVISION citing AC3 — the byte-identity check (verify file hash matches expected SHA-256) is a fourth structural rule with independent semantic content: it asserts a new correctness property (byte-identity between memory and disk) that is not derivable from any of the three named invariants (ordering, deduplication, count-correctness). This is a new invariant, not a guard for a named one. The "minor defensive addition" label is a misclassification. The AC must be amended to name byte-identity as a fourth invariant, or the byte-identity check must be removed from this plan.
