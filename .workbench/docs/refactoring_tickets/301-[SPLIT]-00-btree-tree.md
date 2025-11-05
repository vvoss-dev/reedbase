# SPLIT-301-00: Split btree/tree.rs (782 lines)

## Status
- [x] Not Started
- [ ] In Progress  
- [ ] Complete

## Priority
**CRITICAL** - Largest file, most complex module, highest refactoring impact

## Estimated Effort
2 hours

## Path References

**⚠️ DUAL PATH NOTATION**:
- **Current**: `src/btree/tree.rs` (before 002-[STRUCT]-00)
- **After**: `src/store/btree/tree.rs` (after 002-[STRUCT]-00)

Use current path if folder reorganisation not yet complete.

## Context
**File location**: `src/btree/tree.rs` (current) or `src/store/btree/tree.rs` (after 002)

This file is **782 lines** containing ALL B+-Tree operations:
- Tree struct + initialization
- Search operations (get, range)
- Insert operations (with node splitting)
- Delete operations (with node merging)  
- Maintenance operations (balance, compact, stats)
- Internal helpers

This violates KISS principle - one file should have one clear responsibility.

## Current State

**File**: `src/btree/tree.rs` (current) or `src/store/btree/tree.rs` (after 002) - 782 lines

**Responsibilities** (identified by analyzing code):
1. **Core struct** (~50 lines)
   - `BPlusTree` struct definition
   - `new()`, `open()`, `close()`
   - Configuration

2. **Search operations** (~150 lines)
   - `get()` - Single key lookup
   - `range()` - Range queries
   - `scan()` - Full scans
   - Helper: `find_leaf()`

3. **Insert operations** (~200 lines)
   - `insert()` - Add key-value pair
   - `split_node()` - Node splitting logic
   - `promote_key()` - Key promotion to parent
   - Helpers for insertion

4. **Delete operations** (~200 lines)
   - `delete()` - Remove key
   - `merge_nodes()` - Node merging
   - `redistribute()` - Rebalance after delete
   - Helpers for deletion

5. **Maintenance** (~150 lines)
   - `balance()` - Rebalance tree
   - `compact()` - Remove deleted space
   - `stats()` - Tree statistics
   - `verify_integrity()` - Consistency checks

6. **Internal helpers** (~32 lines)
   - Path tracking
   - Node utilities
   - Common helpers

## Target State

**Current paths** (before 002-[STRUCT]-00):
```
src/btree/
├── tree.rs              # Core struct + initialization (~100 lines)
├── tree_search.rs       # Search operations (~150 lines)
├── tree_insert.rs       # Insert + split (~200 lines)
├── tree_delete.rs       # Delete + merge (~200 lines)
├── tree_maintenance.rs  # Balance, compact, stats (~150 lines)
├── mod.rs               # Public API exports
└── ... (other btree files)
```

**After 002-[STRUCT]-00** (relocated to store/):
```
src/store/btree/
├── tree.rs              # Core struct + initialization (~100 lines)
├── tree_search.rs       # Search operations (~150 lines)
├── tree_insert.rs       # Insert + split (~200 lines)
├── tree_delete.rs       # Delete + merge (~200 lines)
├── tree_maintenance.rs  # Balance, compact, stats (~150 lines)
├── mod.rs               # Public API exports
└── ... (other btree files)
```

**Benefits**:
- Each file < 200 lines
- Clear single responsibility
- Easier to test operations independently
- Easier to review and understand
- Better documentation per operation type

## Breaking Changes
**None** - All changes internal to `btree` module

Public API remains unchanged:
```rust
// Still works exactly the same
use reedbase::btree::BPlusTree;

let tree = BPlusTree::new(path, order)?;
tree.insert(key, value)?;
let result = tree.get(key)?;
```

## Dependencies
- **001-[PREP]-00**: Tests must pass
- **111-[TESTS]-00**: btree/page.rs inline tests extracted first

## Implementation Steps

**Note**: All commands use current path (`src/btree/`) or after-002 path (`src/store/btree/`) depending on when this ticket is executed.

### Step 1: Analyze and Mark Boundaries

1. **Read through tree.rs completely** (in current or after-002 location)
   - Mark line ranges for each responsibility
   - Identify dependencies between functions
   - Note which functions call which

2. **Create dependency map**
   ```
   insert() → calls → split_node(), promote_key()
   delete() → calls → merge_nodes(), redistribute()
   get() → calls → find_leaf()
   ```

### Step 2: Extract Search Operations (Easiest First)

1. **Create tree_search.rs** (in `src/btree/` or `src/store/btree/`)
   ```rust
   // Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
   // SPDX-License-Identifier: Apache-2.0
   
   //! B+-Tree search operations.
   //!
   //! Single-key lookups, range queries, and full scans.
   
   use super::tree::BPlusTree;
   use super::types::*;
   use crate::ReedResult;
   
   impl BPlusTree {
       /// Search for a key in the tree.
       pub fn get(&self, key: &[u8]) -> ReedResult<Option<Vec<u8>>> {
           // Move get() implementation here
       }
       
       /// Range query between start and end keys.
       pub fn range(&self, start: &[u8], end: &[u8]) -> ReedResult<Vec<(Vec<u8>, Vec<u8>)>> {
           // Move range() implementation here
       }
       
       // ... other search operations
   }
   
   // Internal helpers
   fn find_leaf(tree: &BPlusTree, key: &[u8]) -> ReedResult<NodeId> {
       // Move helper here
   }
   ```

2. **Remove from tree.rs**
   - Cut search operations from tree.rs
   - Leave imports intact for now

3. **Update mod.rs**
   ```rust
   mod tree;
   mod tree_search;  // New
   // ... other modules
   
   pub use tree::BPlusTree;
   ```

4. **Test**
   ```bash
   cargo test --lib btree::tree_search
   cargo test --lib btree::
   ```

### Step 3: Extract Insert Operations

1. **Create tree_insert.rs** (in `src/btree/` or `src/store/btree/`)
   ```rust
   // Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
   // SPDX-License-Identifier: Apache-2.0
   
   //! B+-Tree insertion operations.
   //!
   //! Handles key insertion and node splitting logic.
   
   use super::tree::BPlusTree;
   // ... implementation
   ```

2. **Move functions**:
   - `insert()`
   - `split_node()`
   - `promote_key()`
   - Related helpers

3. **Test**
   ```bash
   cargo test --lib btree::tree_insert
   ```

### Step 4: Extract Delete Operations

1. **Create tree_delete.rs** (in `src/btree/` or `src/store/btree/`)
2. **Move functions**:
   - `delete()`
   - `merge_nodes()`
   - `redistribute()`
3. **Test**

### Step 5: Extract Maintenance Operations

1. **Create tree_maintenance.rs** (in `src/btree/` or `src/store/btree/`)
2. **Move functions**:
   - `balance()`
   - `compact()`
   - `stats()`
   - `verify_integrity()`
3. **Test**

### Step 6: Clean Up Core tree.rs

1. **Keep in tree.rs**:
   - `BPlusTree` struct definition
   - `new()`, `open()`, `close()`
   - Essential initialization logic
   - Should be ~100 lines now

2. **Verify structure**:
   ```
   tree.rs:        100 lines (core)
   tree_search.rs: 150 lines (read ops)
   tree_insert.rs: 200 lines (write + split)
   tree_delete.rs: 200 lines (delete + merge)
   tree_maintenance.rs: 150 lines (maintenance)
   Total: 800 lines (18 lines overhead for headers)
   ```

### Step 7: Final Verification

```bash
# Full test suite
cargo test --lib btree::

# Check public API unchanged
cargo check

# Integration tests
cargo test --test '*'

# Run benchmarks
cargo bench --bench btree
```

## Verification
- [ ] All 5 new files created with copyright headers
- [ ] tree.rs reduced to ~100 lines (core only)
- [ ] All btree tests pass
- [ ] Public API unchanged (external code still works)
- [ ] No code duplication between files
- [ ] Each file has clear single responsibility
- [ ] File-level documentation explains purpose
- [ ] mod.rs exports are correct

## Files Affected

**Created** (current paths before 002):
- `src/btree/tree_search.rs` (~150 lines)
- `src/btree/tree_insert.rs` (~200 lines)
- `src/btree/tree_delete.rs` (~200 lines)
- `src/btree/tree_maintenance.rs` (~150 lines)

**Modified** (current paths before 002):
- `src/btree/tree.rs` (782 → ~100 lines)
- `src/btree/mod.rs` (add new module declarations)

**After 002-[STRUCT]-00** (all in `src/store/btree/`):
- `src/store/btree/tree_search.rs`
- `src/store/btree/tree_insert.rs`
- `src/store/btree/tree_delete.rs`
- `src/store/btree/tree_maintenance.rs`
- `src/store/btree/tree.rs` (reduced)
- `src/store/btree/mod.rs` (updated)

**Unchanged** (public API):
- External imports: `use reedbase::btree::BPlusTree` still works
- Method calls: `tree.insert()`, `tree.get()` still work

## Notes

**Why This Order?**
1. Search first - read-only, safest to extract
2. Insert next - most complex write operation
3. Delete next - pairs with insert conceptually
4. Maintenance last - uses other operations

**Shared Helpers**:
If helpers are used across files, keep in `tree.rs` or create `tree_helpers.rs`.

**Testing Strategy**:
- Unit tests can now target specific operation types
- `tree_search_test.rs` focuses only on search
- `tree_insert_test.rs` focuses only on insert
- Better test organization

**Alternative Structure** (if helpers are complex):
```
btree/
├── tree/
│   ├── mod.rs          # Core struct
│   ├── search.rs
│   ├── insert.rs
│   ├── delete.rs
│   ├── maintenance.rs
│   └── helpers.rs      # Shared utilities
└── btree/mod.rs        # Re-exports tree::BPlusTree
```

But **flat structure is simpler** for now (KISS).
