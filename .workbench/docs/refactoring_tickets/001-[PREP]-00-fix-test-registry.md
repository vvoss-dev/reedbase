# 001-[PREP]-00: Fix Test Registry Setup

## Status
- [x] Not Started
- [ ] In Progress
- [ ] Complete

## Priority
**CRITICAL** - Blocks all other refactoring (tests must pass first)

## Estimated Effort
30 minutes

## Path References

**⚠️ DUAL PATH NOTATION**:
- **Current**: `src/tables/` (before 002-[STRUCT]-00)
- **After**: `src/store/tables/` (after 002-[STRUCT]-00)

Use current paths if structure not yet reorganized.

## Context
27 tests are failing due to registry initialization issues:
```
called `Result::unwrap()` on an `Err` value: IoError { 
  operation: "read_actions_dict", 
  reason: "No such file or directory (os error 2)" 
}
```

Tests initialize registry but fail to find dictionary files. This must be fixed before any refactoring.

## Current State
- **tables/table_test.rs** calls `init_registry()` but dictionaries not found
  - Current: `src/tables/table_test.rs`
  - After: `src/store/tables/table_test.rs`
  
- **backup/tests.rs** has similar issues
  - Current: `src/backup/tests.rs`
  - After: `src/ops/backup/tests.rs`

- 27 tests failing:
  - backup (6 tests)
  - database/execute (2 tests)
  - log (3 tests)  
  - tables (16 tests)

**Failing tests**:
- `backup::tests::test_*` (6 tests)
- `database::execute::tests::test_matches_like_pattern`
- `database::types::tests::test_index_metadata_record_usage`
- `log::decoder_test::tests::test_decode_multiple_entries`
- `log::validator_test::tests::test_*` (3 tests)
- `tables::*_test::tests::test_*` (16 tests)

## Target State
- All 656 tests pass
- Registry initialization reliable in all test contexts
- Temp directories properly cleaned up

## Breaking Changes
**None** - Internal test fixture improvements only

## Dependencies
None - this is the foundation

## Implementation Steps

### Step 1: Investigate registry initialization

```bash
cd reedbase

# Run failing test to see error
cargo test --lib tables::table_test::tests::test_table_new -- --nocapture

# Check registry init code
# Current: src/registry/init.rs
# After: src/store/registry/init.rs (if 002 done)
```

Check:
- Does `init_registry()` create all directories?
- Are dictionary files written?
- Is path resolution correct?

### Step 2: Fix registry test setup

Options to investigate:
- **Option A**: Fix `registry/init.rs` to be more robust
- **Option B**: Create `init_registry_for_tests()` helper
- **Option C**: Mock registry in tests (avoid filesystem)

### Step 3: Verify fix

```bash
# Run all tests
cargo test --lib

# Should show: test result: ok. 656 passed; 0 failed
```

### Step 4: Clean up
- Ensure temp directories are removed after tests
- Add comments explaining test setup

## Verification
- [ ] All 656 library tests pass
- [ ] No warnings about missing dictionaries
- [ ] Temp directories cleaned up after tests
- [ ] Can run tests multiple times without issues

## Files Affected

**Current paths** (before 002-[STRUCT]-00):
- `src/registry/init.rs` (likely needs robustness improvements)
- `src/tables/table_test.rs` (test setup)
- `src/backup/tests.rs` (test setup)
- Possibly: `src/registry/dictionary.rs` (error handling)

**After paths** (after 002-[STRUCT]-00):
- `src/store/registry/init.rs`
- `src/store/tables/table_test.rs`
- `src/ops/backup/tests.rs`
- `src/store/registry/dictionary.rs`

## Notes

**Root Cause**: Tests create temp directories but registry code may not handle missing parent directories correctly.

**Quick Check**:
```bash
# Does this work?
cd /tmp
mkdir test_registry
cd test_registry
# Run init_registry() with this as base_path
# Does it create registry/ subdirectory?
# Does it write actions.dict and users.dict?
```

If `init_registry()` assumes parent directories exist, that's the bug.
