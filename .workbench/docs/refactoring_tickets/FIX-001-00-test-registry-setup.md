# FIX-001-00: Fix Test Registry Setup

## Status
- [x] Not Started
- [ ] In Progress
- [ ] Complete

## Priority
**CRITICAL** - Blocks all other refactoring (tests must pass first)

## Estimated Effort
30 minutes

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
- `src/tables/table_test.rs` calls `init_registry()` but dictionaries not found
- `src/backup/tests.rs` has similar issues
- 27 tests failing: backup (6), database (2), log (3), tables (16)

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

1. **Investigate registry initialization**
   ```bash
   cd reedbase
   cargo test --lib tables::table_test::tests::test_table_new -- --nocapture
   ```
   - Check if `init_registry()` creates directories
   - Verify dictionary files are written
   - Check path resolution

2. **Fix registry test setup**
   - Ensure `registry/init.rs` creates all required files
   - Add better error messages for missing dictionaries
   - Consider test-specific registry initialization helper

3. **Options**:
   **Option A**: Fix `init_registry()` to be more robust
   **Option B**: Create `init_registry_for_tests()` helper
   **Option C**: Mock registry in tests (avoid filesystem)

4. **Verify fix**
   ```bash
   cargo test --lib
   # Should show: test result: ok. 656 passed; 0 failed
   ```

5. **Clean up**
   - Ensure temp directories are removed after tests
   - Add comments explaining test setup

## Verification
- [ ] All 656 library tests pass
- [ ] No warnings about missing dictionaries
- [ ] Temp directories cleaned up after tests
- [ ] Can run tests multiple times without issues

## Files Affected
- `src/registry/init.rs` (likely needs robustness improvements)
- `src/tables/table_test.rs` (test setup)
- `src/backup/tests.rs` (test setup)
- Possibly: `src/registry/dictionary.rs` (error handling)

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
