# 100-[TESTS]-00: Extract Inline Tests - Overview

## Status
- [x] Not Started
- [ ] In Progress
- [ ] Complete

## Priority
**HIGH** - Violates CLAUDE.md mandatory standard #5

## Estimated Effort
2-3 hours total (17 files, ~10 minutes each)

## Path References

**⚠️ IMPORTANT**: This ticket references paths in the NEW structure.

**Current location** (before 002-[STRUCT]-00):
- `src/database/` → Code is HERE now
- `src/reedql/` → Code is HERE now
- `src/btree/` → Code is HERE now
- etc.

**Target location** (after 002-[STRUCT]-00):
- `src/api/db/` → Code will move HERE
- `src/api/reedql/` → Code will move HERE
- `src/store/btree/` → Code will move HERE
- etc.

**When executing this ticket**:
- If 002-[STRUCT]-00 NOT done yet: Use `src/database/`, `src/btree/`, etc.
- If 002-[STRUCT]-00 IS done: Use `src/api/db/`, `src/store/btree/`, etc.

## Context
CLAUDE.md requires:
> **5. Testing**: Separate test files as `{name}_test.rs` - **never inline `#[cfg(test)]` modules**

Currently **17 files** have inline test modules that must be extracted.

## Current State

Files with inline `#[cfg(test)] mod tests`:

1. **database/types.rs** (570 lines)
   - Current: `src/database/types.rs`
   - After 002: `src/api/db/types.rs`

2. **database/execute.rs** (661 lines)
   - Current: `src/database/execute.rs`
   - After 002: `src/api/db/execute.rs`

3. **database/query.rs** (387 lines)
   - Current: `src/database/query.rs`
   - After 002: `src/api/db/query.rs`

4. **database/index.rs** (532 lines)
   - Current: `src/database/index.rs`
   - After 002: `src/api/db/index.rs`

5. **database/stats.rs** (200 lines)
   - Current: `src/database/stats.rs`
   - After 002: `src/api/db/stats.rs`

6. **reedql/types.rs** (483 lines)
   - Current: `src/reedql/types.rs`
   - After 002: `src/api/reedql/types.rs`

7. **reedql/executor.rs** (697 lines)
   - Current: `src/reedql/executor.rs`
   - After 002: `src/api/reedql/executor.rs`

8. **merge/types.rs** (200 lines)
   - Current: `src/merge/types.rs`
   - After 002: `src/process/merge/types.rs`

9. **conflict/types.rs** (404 lines)
   - Current: `src/conflict/types.rs`
   - After 002: `src/process/conflict/types.rs`

10. **schema/types.rs** (306 lines)
    - Current: `src/schema/types.rs`
    - After 002: `src/validate/schema/types.rs`

11. **btree/page.rs** (669 lines)
    - Current: `src/btree/page.rs`
    - After 002: `src/store/btree/page.rs`

12. **btree/types.rs** (150 lines)
    - Current: `src/btree/types.rs`
    - After 002: `src/store/btree/types.rs`

13. **version/rebuild.rs** (200 lines)
    - Current: `src/version/rebuild.rs`
    - After 002: `src/process/version/rebuild.rs`

14. **concurrent/types.rs** (100 lines)
    - Current: `src/concurrent/types.rs`
    - After 002: `src/process/locks/types.rs`

15. **reedql/parser.rs** (730 lines) - if has inline tests
    - Current: `src/reedql/parser.rs`
    - After 002: `src/api/reedql/parser.rs`

16. **database/database.rs** (526 lines) - if has inline tests
    - Current: `src/database/database.rs`
    - After 002: `src/api/db/database.rs`

17. Additional files discovered during execution

## Target State
- All inline test modules moved to separate `{name}_test.rs` files
- Original files contain only production code
- Test files follow naming convention: `{name}_test.rs` next to source file
- All tests still pass

## Breaking Changes
**None** - Tests are not public API

## Dependencies
- **001-[PREP]-00**: Must complete first (tests must pass before refactoring)

## Sub-Tickets
Each file gets its own ticket for tracking:
- `101-[TESTS]-00-database-types.md`
- `102-[TESTS]-00-database-execute.md`
- `103-[TESTS]-00-database-query.md`
- `104-[TESTS]-00-database-index.md`
- `105-[TESTS]-00-database-stats.md`
- `106-[TESTS]-00-reedql-types.md`
- `107-[TESTS]-00-reedql-executor.md`
- `108-[TESTS]-00-merge-types.md`
- `109-[TESTS]-00-conflict-types.md`
- `110-[TESTS]-00-schema-types.md`
- `111-[TESTS]-00-btree-page.md`
- `112-[TESTS]-00-btree-types.md`
- `113-[TESTS]-00-version-rebuild.md`
- `114-[TESTS]-00-concurrent-types.md`
- `115-[TESTS]-00-remaining-files.md` (catch-all)

## Implementation Pattern

For each file, follow this process:

### Step 1: Find the file
```bash
# If 002-[STRUCT]-00 NOT done yet:
cd src/database  # (or btree, reedql, etc.)

# If 002-[STRUCT]-00 IS done:
cd src/api/db    # (or store/btree, api/reedql, etc.)
```

### Step 2: Extract tests
```bash
# Find the #[cfg(test)] mod tests block
# Copy entire block to new {name}_test.rs file
```

### Step 3: Update test file structure
```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Tests for {module_name}.

#[cfg(test)]
mod tests {
    use super::super::*;  // Import from parent module
    // ... test code ...
}
```

### Step 4: Remove from original file
- Delete entire `#[cfg(test)] mod tests { ... }` block
- Ensure no test code remains

### Step 5: Update module
- Add to `mod.rs`: `mod {name}_test;` (with `#[cfg(test)]`)

### Step 6: Verify
```bash
# Test the specific module
cargo test --lib {module}::{name}_test
```

## Verification
- [ ] All 17 files processed
- [ ] No inline test modules remain (`grep -r "#[cfg(test)].*mod tests" src/`)
- [ ] All tests still pass (`cargo test --lib`)
- [ ] Test coverage unchanged
- [ ] Each test file has copyright header

## Files Affected
- 17 source files (remove inline tests)
- 17 new test files (add `{name}_test.rs`)
- 17 `mod.rs` files (add test module declarations)

## Notes

**Automation Possibility**: Could write a script to automate extraction, but manual is safer to avoid breaking anything.

**Order**: Process in dependency order (leaf modules first, core modules last) to minimize issues.

**Remember**: Adjust paths based on whether 002-[STRUCT]-00 has been executed or not!
