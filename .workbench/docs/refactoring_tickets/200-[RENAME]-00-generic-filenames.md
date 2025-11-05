# RENAME-200-00: Rename Generic Filenames

## Status
- [x] Not Started
- [ ] In Progress
- [ ] Complete

## Priority
**HIGH** - Violates CLAUDE.md mandatory standard #7

## Estimated Effort
30 minutes

## Path References

**⚠️ DUAL PATH NOTATION**:
- **Current**: `src/tables/` (before 002-[STRUCT]-00)
- **After**: `src/store/tables/` (after 002-[STRUCT]-00)

Use current paths if structure not yet reorganised.

## Context
CLAUDE.md requires:
> **7. Avoid**: Generic names like `handler.rs`, `middleware.rs`, `utils.rs`

Found **2 violations**:
1. **Current**: `src/tables/helpers.rs` → **After 002**: `src/store/tables/helpers.rs`
2. **Current**: `src/indices/builder_tests.rs` → **After 002**: `src/store/indices/builder_tests.rs`

## Current State

### File 1: `helpers.rs` (200 lines)
- **Current**: `src/tables/helpers.rs`
- **After 002**: `src/store/tables/helpers.rs`
**Functions**:
- `list_tables()` - List all tables in database
- `table_exists()` - Check if table exists
- `table_stats()` - Get table statistics

**Better name**: `table_operations.rs` or `table_discovery.rs` or `table_info.rs`

**Recommendation**: `table_operations.rs` (clearest about what it does)

### File 2: `builder_tests.rs` (334 lines)
- **Current**: `src/indices/builder_tests.rs`
- **After 002**: `src/store/indices/builder_tests.rs`
**Issue**: Naming convention inconsistency
- All other test files: `{name}_test.rs`
- This file: `{name}_tests.rs` (plural)

**Better name**: `builder_test.rs` (match convention)

## Target State

**Current paths** (before 002-[STRUCT]-00):
```
src/tables/
├── table_operations.rs     # Renamed from helpers.rs
├── table_operations_test.rs # Already exists as helpers_test.rs, rename too
└── ...

src/indices/
├── builder_test.rs         # Renamed from builder_tests.rs
└── ...
```

**After 002-[STRUCT]-00** (relocated to store/):
```
src/store/tables/
├── table_operations.rs
├── table_operations_test.rs
└── ...

src/store/indices/
├── builder_test.rs
└── ...
```

## Breaking Changes
**Import changes only** - Internal module structure

Affected imports in:
- Any file that imports `crate::tables::helpers` → `crate::tables::table_operations`
- Any file that imports `crate::indices::builder_tests` (unlikely, it's tests)

## Dependencies
- **FIX-001-00**: Tests must pass first
- **TESTS-100-00**: Should complete inline test extraction first (cleaner to rename after)

## Implementation Steps

### Step 1: Rename `tables/helpers.rs`

**Note**: Use current path (`src/tables/`) or after-002 path (`src/store/tables/`) depending on whether 002-[STRUCT]-00 is complete.

1. **Rename file**
   ```bash
   # Current path (before 002):
   cd src/tables
   git mv helpers.rs table_operations.rs
   git mv helpers_test.rs table_operations_test.rs
   
   # OR after 002-[STRUCT]-00:
   cd src/store/tables
   git mv helpers.rs table_operations.rs
   git mv helpers_test.rs table_operations_test.rs
   ```

2. **Update `tables/mod.rs` or `store/tables/mod.rs`**
   ```rust
   // Change:
   pub mod helpers;
   // To:
   pub mod table_operations;
   ```

3. **Update re-exports in `tables/mod.rs`**
   ```rust
   // Change:
   pub use helpers::{list_tables, table_exists, table_stats};
   // To:
   pub use table_operations::{list_tables, table_exists, table_stats};
   ```

4. **Find and replace imports**
   ```bash
   # Search for imports (use appropriate base path)
   grep -r "use.*tables::helpers" src/
   grep -r "use.*helpers::" src/tables/  # OR src/store/tables/
   
   # Replace with table_operations
   ```

5. **Update test file**
   ```rust
   // In table_operations_test.rs:
   // Change:
   use super::super::*;
   // Ensure imports work from renamed module
   ```

### Step 2: Rename `indices/builder_tests.rs`

1. **Rename file**
   ```bash
   # Current path (before 002):
   cd src/indices
   git mv builder_tests.rs builder_test.rs
   
   # OR after 002-[STRUCT]-00:
   cd src/store/indices
   git mv builder_tests.rs builder_test.rs
   ```

2. **Update `indices/mod.rs` or `store/indices/mod.rs`**
   ```rust
   // Change:
   #[cfg(test)]
   mod builder_tests;
   // To:
   #[cfg(test)]
   mod builder_test;
   ```

3. **No import changes needed** (it's a test file, not imported externally)

### Step 3: Verify

```bash
# Compile check
cargo check

# Run tests
cargo test --lib tables::table_operations
cargo test --lib indices::builder_test

# Full test suite
cargo test --lib
```

## Verification
- [ ] `tables/helpers.rs` renamed to `table_operations.rs`
- [ ] `tables/helpers_test.rs` renamed to `table_operations_test.rs`
- [ ] `indices/builder_tests.rs` renamed to `builder_test.rs`
- [ ] All imports updated
- [ ] All tests pass
- [ ] No references to old names remain
- [ ] Copyright headers intact

## Files Affected

**Direct changes** (current paths before 002-[STRUCT]-00):
- `src/tables/helpers.rs` → `src/tables/table_operations.rs`
- `src/tables/helpers_test.rs` → `src/tables/table_operations_test.rs`
- `src/indices/builder_tests.rs` → `src/indices/builder_test.rs`
- `src/tables/mod.rs` (update module declarations)
- `src/indices/mod.rs` (update module declarations)

**After 002-[STRUCT]-00** (relocated to store/):
- `src/store/tables/helpers.rs` → `src/store/tables/table_operations.rs`
- `src/store/tables/helpers_test.rs` → `src/store/tables/table_operations_test.rs`
- `src/store/indices/builder_tests.rs` → `src/store/indices/builder_test.rs`
- `src/store/tables/mod.rs` (update module declarations)
- `src/store/indices/mod.rs` (update module declarations)

**Potential import updates**:
- Any file importing `tables::helpers` (search needed)
- Any file importing helper functions directly

## Notes
**Why "table_operations.rs" over "table_info.rs"**:
- More accurate: file contains both read (`list_tables`, `table_exists`) AND analysis (`table_stats`)
- "info" suggests read-only, but stats involve computation
- "operations" is clearer about functionality scope

**Alternative names considered**:
- `table_discovery.rs` - too narrow (doesn't include stats)
- `table_utils.rs` - still too generic (violates same rule)
- `table_metadata.rs` - misleading (not about CSV metadata)
- `table_operations.rs` - ✅ **clear and specific**
