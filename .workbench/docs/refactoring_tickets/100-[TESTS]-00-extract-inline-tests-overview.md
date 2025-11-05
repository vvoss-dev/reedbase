# TESTS-100-00: Extract Inline Tests - Overview

## Status
- [x] Not Started
- [ ] In Progress
- [ ] Complete

## Priority
**HIGH** - Violates CLAUDE.md mandatory standard #5

## Estimated Effort
2-3 hours total (17 files, ~10 minutes each)

## Context
CLAUDE.md requires:
> **5. Testing**: Separate test files as `{name}_test.rs` - **never inline `#[cfg(test)]` modules**

Currently **17 files** have inline test modules that must be extracted.

## Current State
Files with inline `#[cfg(test)] mod tests`:
1. `src/database/types.rs` (570 lines)
2. `src/database/execute.rs` (661 lines)
3. `src/database/query.rs` (387 lines)
4. `src/database/index.rs` (532 lines)
5. `src/database/stats.rs` (200 lines)
6. `src/reedql/types.rs` (483 lines)
7. `src/reedql/executor.rs` (697 lines)
8. `src/merge/types.rs` (200 lines)
9. `src/conflict/types.rs` (404 lines)
10. `src/schema/types.rs` (306 lines)
11. `src/btree/page.rs` (669 lines)
12. `src/btree/types.rs` (150 lines)
13. `src/version/rebuild.rs` (200 lines)
14. `src/concurrent/types.rs` (100 lines)
15. `src/reedql/parser.rs` (730 lines) - if has inline tests
16. `src/database/database.rs` (526 lines) - if has inline tests
17. Additional files discovered during execution

## Target State
- All inline test modules moved to separate `{name}_test.rs` files
- Original files contain only production code
- Test files follow naming convention: `src/module/{name}_test.rs`
- All tests still pass

## Breaking Changes
**None** - Tests are not public API

## Dependencies
- **FIX-001-00**: Must complete first (tests must pass before refactoring)

## Sub-Tickets
Each file gets its own ticket for tracking:
- `TESTS-101-00-database-types.md`
- `TESTS-102-00-database-execute.md`
- `TESTS-103-00-database-query.md`
- `TESTS-104-00-database-index.md`
- `TESTS-105-00-database-stats.md`
- `TESTS-106-00-reedql-types.md`
- `TESTS-107-00-reedql-executor.md`
- `TESTS-108-00-merge-types.md`
- `TESTS-109-00-conflict-types.md`
- `TESTS-110-00-schema-types.md`
- `TESTS-111-00-btree-page.md`
- `TESTS-112-00-btree-types.md`
- `TESTS-113-00-version-rebuild.md`
- `TESTS-114-00-concurrent-types.md`
- `TESTS-115-00-remaining-files.md` (catch-all for any discovered during work)

## Implementation Pattern

For each file, follow this process:

1. **Extract tests**
   ```bash
   # Find the #[cfg(test)] mod tests block
   # Copy entire block to new {name}_test.rs file
   ```

2. **Update test file structure**
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

3. **Remove from original file**
   - Delete entire `#[cfg(test)] mod tests { ... }` block
   - Ensure no test code remains

4. **Update module**
   - Add to `mod.rs`: `mod {name}_test;` (with `#[cfg(test)]`)

5. **Verify**
   ```bash
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
