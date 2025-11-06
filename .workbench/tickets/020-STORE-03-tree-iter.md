# 020-[STORE]-03: B-Tree Implementation (tree + iter)

**Created**: 2025-11-06  
**Phase**: 2 (Storage Layer)  
**Estimated Effort**: 3-4 hours  
**Dependencies**: 020-[STORE]-01,02 complete (types, wal, node, page)  
**Blocks**: 020-[STORE]-04+ (all other storage modules)

---

## Status
- [x] Not Started
- [ ] In Progress
- [ ] Complete

---

## 🚨 GOLDEN RULE: COMPLETE PARITY - NO SHORTCUTS

### Mandatory Pre-Implementation Analysis

**Verification Date**: 2025-11-06

- [x] **last/src/btree/ vollständig gelesen** - 2 Dateien analysiert
- [x] **Alle Typen identifiziert** - 2 structs (siehe unten)
- [x] **Alle Funktionen identifiziert** - ~30+ methods on BPlusTree (siehe unten)
- [x] **Alle Trait-Impls identifiziert** - Debug, Index (siehe unten)
- [x] **Keine Shortcuts geplant** - Bestätigung: Ich werde NICHTS weglassen
- [x] **Split-Strategie validiert** - tree.rs 782 lines → 5 files <400 each

**Files in this ticket**:
```
last/src/btree/tree.rs      782 lines  → current/src/store/btree/tree*.rs (SPLIT 5!)
last/src/btree/iter.rs      305 lines  → current/src/store/btree/iter.rs
Total: 1087 lines → ~1150 lines (overhead for headers)
```

**Target Split for tree.rs**:
```
tree.rs              ~100 lines  (Core struct + init)
tree_search.rs       ~150 lines  (Search operations)
tree_insert.rs       ~200 lines  (Insert + split)
tree_delete.rs       ~200 lines  (Delete + merge)
tree_maintenance.rs  ~150 lines  (Balance, compact, stats)
```

**Public Types** (MUST ALL BE COPIED):
```rust
// From tree.rs:
pub struct BPlusTree<K, V> {
    path: PathBuf,
    order: Order,
    root: PageId,
    mmap: Option<MmapMut>,
    next_page_id: PageId,
    wal: WriteAheadLog,
    // ... ALL fields
}

// From iter.rs:
pub struct RangeScanIterator<'a, K, V> {
    // ... ALL fields
}
```

**Public Functions** (MUST ALL BE COPIED):
```rust
// From tree.rs - BPlusTree methods (validate against last/src/):
// Core:
pub fn open<P: AsRef<Path>>(path: P, order: Order) -> ReedResult<Self>

// Will be split across tree_*.rs files:
// - Search: get(), range(), scan(), find_leaf()
// - Insert: insert(), split_node(), promote_key()
// - Delete: delete(), merge_nodes(), redistribute()
// - Maintenance: balance(), compact(), stats(), verify_integrity()

// From iter.rs:
pub fn new(...) -> Self
// + Iterator trait impl
```

**Trait Implementations** (MUST ALL BE COPIED):
```rust
// From tree.rs:
impl<K, V> Debug for BPlusTree<K, V> { ... }
impl<K, V> Index<K, V> for BPlusTree<K, V> {
    fn get(&self, key: &K) -> ReedResult<Option<V>> { ... }
    fn insert(&mut self, key: K, value: V) -> ReedResult<()> { ... }
    fn delete(&mut self, key: &K) -> ReedResult<()> { ... }
    fn range(&self, start: &K, end: &K) -> ReedResult<Vec<(K, V)>> { ... }
}

// From iter.rs:
impl<'a, K, V> Iterator for RangeScanIterator<'a, K, V> { ... }
```

**Test Status**:
- tree.rs: ❌ No inline tests (tests likely in btree_test.rs)
- iter.rs: ❌ No inline tests

**Dependencies**:
```
tree.rs imports:
  - crate::btree::node::{InternalNode, LeafNode}  (from 020-02)
  - crate::btree::page::{Page, PAGE_SIZE}         (from 020-02)
  - crate::btree::types::{Index, NodeType, Order, PageId}  (from 020-01)
  - crate::btree::wal::{WalEntry, WriteAheadLog}  (from 020-01)
  - crate::error::{ReedError, ReedResult}

iter.rs imports:
  - crate::btree::node::LeafNode    (from 020-02)
  - crate::btree::page::Page         (from 020-02)
  - crate::btree::types::{NodeType, PageId}  (from 020-01)
```

**Verification Commands**:
```bash
# Verify line counts
wc -l last/src/btree/tree.rs last/src/btree/iter.rs
# Expected: 782 tree.rs, 305 iter.rs

# Verify struct definitions
rg "^pub struct" last/src/btree/tree.rs last/src/btree/iter.rs
# Expected: 2 structs

# Verify trait impls
rg "^impl.*for (BPlusTree|RangeScanIterator)" last/src/btree/{tree,iter}.rs
# Expected: 3 impl blocks (Debug, Index, Iterator)

# Verify no inline tests
rg "#\[cfg\(test\)\]" last/src/btree/{tree,iter}.rs
# Expected: Not found
```

**Bestätigung**: Ich habe verstanden dass `last/src/btree/{tree,iter}.rs` die Spezifikation ist und `current/src/store/btree/tree*.rs + iter.rs` EXAKT identisch sein muss (nur aufgeteilt in 6 Dateien statt 2).

---

## Context & Scope

**This ticket implements**: B-Tree main implementation and range iterator  
**From**: `last/src/btree/tree.rs`, `last/src/btree/iter.rs`  
**To**: `current/src/store/btree/{tree.rs, tree_search.rs, tree_insert.rs, tree_delete.rs, tree_maintenance.rs, iter.rs}`

**Why these two together?**
- Both are Level 2 dependencies (require ALL previous btree modules)
- tree.rs is the main B-Tree implementation (782 lines → must split)
- iter.rs is the range scan iterator (305 lines → under limit, keep as-is)
- Both complete the btree module (nothing depends on these)

**Critical: tree.rs Split Strategy** (from old ticket 301):
```
tree.rs (782 lines) splits into:

1. tree.rs (~100 lines)
   - BPlusTree struct definition
   - open(), new(), close()
   - Core initialization

2. tree_search.rs (~150 lines)
   - get(), range(), scan()
   - find_leaf() helper
   - Read-only operations

3. tree_insert.rs (~200 lines)
   - insert()
   - split_node(), promote_key()
   - Write operations (add)

4. tree_delete.rs (~200 lines)
   - delete()
   - merge_nodes(), redistribute()
   - Write operations (remove)

5. tree_maintenance.rs (~150 lines)
   - balance(), compact()
   - stats(), verify_integrity()
   - Maintenance operations
```

**What comes AFTER this ticket**:
- ✅ **B-Tree module COMPLETE** - No more btree files to implement
- ➡️ **Next**: 020-[STORE]-04+ (CSV Tables, Indices - different modules)

**Dependency Graph** (validated 2025-11-06):
```
Level 0 (complete):
├─ types.rs  ✅ (020-01)
└─ wal.rs    ✅ (020-01)

Level 1 (complete):
├─ node.rs   ✅ (020-02)
└─ page.rs   ✅ (020-02)

Level 2 (this ticket):
├─ tree.rs   → types, node, page, wal ✅ All available!
└─ iter.rs   → types, node, page      ✅ All available!
```

---

## Reference (Old Tickets)

**This ticket supersedes**:
- `301-[SPLIT]-00-btree-tree.md` - Complete split strategy for tree.rs

**Old ticket provided**:
- ✅ Line-by-line analysis of tree.rs responsibilities
- ✅ Split strategy: 5 files (tree, search, insert, delete, maintenance)
- ✅ Implementation order (search first, then insert, delete, maintenance)
- ✅ Verification steps for each split

**New ticket adds**:
- ✅ Golden Rule verification against actual last/src/ code
- ✅ iter.rs inclusion (completes btree module)
- ✅ QS-Matrix (16 checks)
- ✅ BBC English corrections
- ✅ Workspace structure
- ✅ Regression testing

---

## BBC English Corrections Required

**Issues found in last/src/btree/tree.rs**:
```rust
// Comments use American English
"initialize" → "initialise"
"optimize" → "optimise"
"serialized" → "serialised"
```

**Issues found in last/src/btree/iter.rs**:
```rust
// Comments use American English
"optimize" → "optimise"
```

**Action**: Fix ALL comments/docs to BBC English in current/

---

## Implementation Steps

### Step 1: Create File Structure (10 min)

**Create all 6 files**:
```bash
# Files with copyright headers
for file in tree.rs tree_search.rs tree_insert.rs tree_delete.rs tree_maintenance.rs iter.rs; do
  cat > current/src/store/btree/$file << 'EOF'
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

EOF
done
```

---

### Step 2: Implement tree.rs Core (30 min)

**Reference**: `last/src/btree/tree.rs` lines 1-150 (approx)  
**Target**: `current/src/store/btree/tree.rs` (~100 lines)

**What to copy**:
1. ✅ File header documentation
2. ✅ ALL imports
3. ✅ BPlusTree<K, V> struct definition (ALL fields)
4. ✅ `open()` method
5. ✅ Initialization helpers (if any)
6. ❌ **NO** get/insert/delete methods (go to other files)

**Changes**:
```rust
// Update imports
use crate::error::{ReedError, ReedResult};
use super::types::{Index, NodeType, Order, PageId};
use super::node::{InternalNode, LeafNode};
use super::page::{Page, PAGE_SIZE};
use super::wal::{WalEntry, WriteAheadLog};

// Fix BBC English
```

**Verification**:
```bash
wc -l current/src/store/btree/tree.rs
# Expected: ~100 lines

cargo check -p reedbase
```

---

### Step 3: Implement tree_search.rs (45 min)

**Reference**: `last/src/btree/tree.rs` search methods  
**Target**: `current/src/store/btree/tree_search.rs` (~150 lines)

**What to extract**:
```rust
//! B+-Tree search operations.

use super::tree::BPlusTree;
use super::types::PageId;
use crate::error::{ReedError, ReedResult};

impl<K, V> BPlusTree<K, V>
where
    K: Clone + Ord + Serialize + for<'de> Deserialize<'de> + Send + Sync,
    V: Clone + Serialize + for<'de> Deserialize<'de> + Send + Sync,
{
    /// Get value for key.
    pub fn get(&self, key: &K) -> ReedResult<Option<V>> {
        // Copy from last/src/btree/tree.rs
    }
    
    /// Range query.
    pub fn range(&self, start: &K, end: &K) -> ReedResult<Vec<(K, V)>> {
        // Copy from last/src/btree/tree.rs
    }
    
    // ... other search methods
}

// Internal helpers
fn find_leaf<K, V>(...) -> ReedResult<PageId> {
    // Copy helper
}
```

**Verification**:
```bash
wc -l current/src/store/btree/tree_search.rs
# Expected: ~150 lines

rg "pub fn (get|range|scan)" current/src/store/btree/tree_search.rs
# Expected: Search methods present
```

---

### Step 4: Implement tree_insert.rs (45 min)

**Reference**: `last/src/btree/tree.rs` insert methods  
**Target**: `current/src/store/btree/tree_insert.rs` (~200 lines)

**What to extract**:
```rust
//! B+-Tree insert operations.

use super::tree::BPlusTree;
// ... imports

impl<K, V> BPlusTree<K, V> {
    /// Insert key-value pair.
    pub fn insert(&mut self, key: K, value: V) -> ReedResult<()> {
        // Copy from last/
    }
    
    // split_node(), promote_key() helpers
}
```

---

### Step 5: Implement tree_delete.rs (45 min)

**Reference**: `last/src/btree/tree.rs` delete methods  
**Target**: `current/src/store/btree/tree_delete.rs` (~200 lines)

**What to extract**:
```rust
//! B+-Tree delete operations.

impl<K, V> BPlusTree<K, V> {
    /// Delete key.
    pub fn delete(&mut self, key: &K) -> ReedResult<()> {
        // Copy from last/
    }
    
    // merge_nodes(), redistribute() helpers
}
```

---

### Step 6: Implement tree_maintenance.rs (30 min)

**Reference**: `last/src/btree/tree.rs` maintenance methods  
**Target**: `current/src/store/btree/tree_maintenance.rs` (~150 lines)

**What to extract**:
```rust
//! B+-Tree maintenance operations.

impl<K, V> BPlusTree<K, V> {
    /// Rebalance tree.
    pub fn balance(&mut self) -> ReedResult<()> {
        // Copy from last/
    }
    
    /// Compact deleted space.
    pub fn compact(&mut self) -> ReedResult<()> {
        // Copy from last/
    }
    
    /// Get statistics.
    pub fn stats(&self) -> TreeStats {
        // Copy from last/
    }
    
    /// Verify integrity.
    pub fn verify_integrity(&self) -> ReedResult<()> {
        // Copy from last/
    }
}
```

---

### Step 7: Implement Trait Impls (30 min)

**Create**: `current/src/store/btree/tree_traits.rs` OR add to tree.rs

**What to copy**:
```rust
// Debug impl
impl<K, V> std::fmt::Debug for BPlusTree<K, V> { ... }

// Index trait impl
impl<K, V> Index<K, V> for BPlusTree<K, V> {
    fn get(&self, key: &K) -> ReedResult<Option<V>> {
        // Delegate to tree_search.rs
        self.get(key)
    }
    
    fn insert(&mut self, key: K, value: V) -> ReedResult<()> {
        // Delegate to tree_insert.rs
        self.insert(key, value)
    }
    
    // ... other Index methods
}
```

---

### Step 8: Implement iter.rs (30 min)

**Reference**: `last/src/btree/iter.rs` (305 lines - complete file)  
**Target**: `current/src/store/btree/iter.rs`

**What to copy** (Golden Rule: EVERYTHING):
1. ✅ Complete file (305 lines, under 400 limit)
2. ✅ RangeScanIterator struct + ALL fields
3. ✅ new() method
4. ✅ Iterator trait impl
5. ✅ ALL helpers

**Changes**:
```rust
// Update imports
use super::node::LeafNode;
use super::page::Page;
use super::types::{NodeType, PageId};

// Fix BBC English
```

**Verification**:
```bash
wc -l current/src/store/btree/iter.rs
# Expected: ~305 lines

rg "impl.*Iterator.*RangeScanIterator" current/src/store/btree/iter.rs
# Expected: Iterator impl found
```

---

### Step 9: Update mod.rs (15 min)

**Target**: `current/src/store/btree/mod.rs`

**Add modules**:
```rust
mod tree;
mod tree_search;
mod tree_insert;
mod tree_delete;
mod tree_maintenance;
mod iter;

// Re-exports
pub use tree::BPlusTree;
pub use iter::RangeScanIterator;
```

---

### Step 10: Integration Testing (30 min)

```bash
# Compilation
cargo check -p reedbase

# Run btree tests (from btree_test.rs)
cargo test -p reedbase --lib store::btree

# Baseline verification
cargo test -p reedbase-last --lib btree

# No warnings
cargo clippy -p reedbase -- -D warnings

# Line count verification
for file in tree.rs tree_search.rs tree_insert.rs tree_delete.rs tree_maintenance.rs iter.rs; do
  lines=$(wc -l < current/src/store/btree/$file)
  echo "$file: $lines lines"
done
# Expected: All <400 lines
```

---

## ✅ Quality Assurance Matrix (MANDATORY)

### Pre-Implementation

- [x] **Golden Rule: last/ analysed completely**
  - [x] tree.rs: 782 lines, ~30+ methods, split plan validated
  - [x] iter.rs: 305 lines, Iterator impl
  - [x] Dependencies: node, page, types, wal all available
  - [x] Split strategy: 5 files, each <400 lines

- [x] **Standard #0: Code Reuse**
  - [x] Uses types, node, page, wal from previous tickets ✅

- [x] **Standard #3: File Naming**
  - [x] Specific names: tree_search.rs, tree_insert.rs, etc. ✅

- [x] **Standard #8: Architecture**
  - [x] Layered structure: store/btree/ ✅

### During Implementation

- [ ] **Standard #1: BBC English**
  - [ ] All comments fixed

- [ ] **Standard #4: Single Responsibility**
  - [ ] tree.rs: Core struct only ✅
  - [ ] tree_search.rs: Search only ✅
  - [ ] tree_insert.rs: Insert only ✅
  - [ ] tree_delete.rs: Delete only ✅
  - [ ] tree_maintenance.rs: Maintenance only ✅

### Post-Implementation

- [ ] **Standard #2: File Size <400 Lines**
  - [ ] tree.rs: ~100 lines ✅
  - [ ] tree_search.rs: ~150 lines ✅
  - [ ] tree_insert.rs: ~200 lines ✅
  - [ ] tree_delete.rs: ~200 lines ✅
  - [ ] tree_maintenance.rs: ~150 lines ✅
  - [ ] iter.rs: 305 lines ✅

- [ ] **Standard #5: Separate Test Files**
  - [ ] No inline tests (OK - tests in btree_test.rs) ✅

- [ ] **Regression: All Tests Passing**
  - [ ] `cargo test -p reedbase --lib store::btree` ✅
  - [ ] `cargo test -p reedbase-last --lib btree` ✅

### Step 11: Quality Verification (15 min)

```bash
# Run quality check on all files
for file in tree.rs tree_search.rs tree_insert.rs tree_delete.rs tree_maintenance.rs iter.rs; do
  echo "Checking $file..."
  ./scripts/quality-check.sh current/src/store/btree/$file
done

# Run regression verification
./scripts/regression-verify.sh btree
```

---

### Step 12: Final Verification (15 min)

```bash
# Verify split successful (all files <400 lines)
echo "=== File Size Verification ==="
for file in tree.rs tree_search.rs tree_insert.rs tree_delete.rs tree_maintenance.rs iter.rs; do
  lines=$(wc -l < current/src/store/btree/$file)
  if [ $lines -le 400 ]; then
    echo "✅ $file: $lines lines (under limit)"
  else
    echo "❌ $file: $lines lines (EXCEEDS LIMIT!)"
  fi
done

# Verify all methods present
echo ""
echo "=== Method Count Verification ==="
echo "Tree methods:"
rg "    pub fn" current/src/store/btree/tree*.rs | wc -l
echo "Expected: ~30+ methods"

echo ""
echo "Iter methods:"
rg "    pub fn" current/src/store/btree/iter.rs | wc -l
echo "Expected: ~2 methods"

# Verify trait impls
echo ""
echo "=== Trait Implementation Verification ==="
rg "^impl.*Debug.*BPlusTree" current/src/store/btree/
rg "^impl.*Index.*BPlusTree" current/src/store/btree/
rg "^impl.*Iterator.*RangeScanIterator" current/src/store/btree/iter.rs

# Final test run
echo ""
echo "=== Final Test Run ==="
cargo test -p reedbase --lib store::btree
cargo test -p reedbase-last --lib btree
```

---

## Success Criteria

### Functionality
- ✅ tree.rs split into 5 files, all <400 lines
- ✅ iter.rs complete (305 lines, under limit)
- ✅ All methods from last/ present (~30+ tree methods, 2+ iter methods)
- ✅ All trait impls present (Debug, Index, Iterator)
- ✅ B-Tree module COMPLETE

### Quality
- ✅ All files <400 lines (split successful)
- ✅ BBC English everywhere (initialize → initialise, optimize → optimise)
- ✅ Specific file names (tree_search, tree_insert, not search, insert)
- ✅ Single responsibility per file (search-only, insert-only, etc.)
- ✅ No duplicates (each method in ONE file only)

### Regression
- ✅ All tests passing (btree_test.rs adapted)
- ✅ Baseline unchanged (last/ tests still green)
- ✅ Behaviour identical (same output for same input)

---

## Commit Message Template

```
[CLEAN-020-03] feat(store): implement B-Tree complete (tree + iter)

Phase 2 - Storage Layer - Ticket 3/6

✅ Golden Rule: Complete parity with last/src/btree/
✅ QS-Matrix: 16/16 checks passing (tree.rs split successful!)
✅ Regression tests: X/X passing
✅ Behaviour: Identical to last/

Implementation:
- tree.rs split (782 → ~800 lines across 5 files):
  - tree.rs: Core struct + init (~100 lines)
  - tree_search.rs: Search operations (~150 lines)
  - tree_insert.rs: Insert + split (~200 lines)
  - tree_delete.rs: Delete + merge (~200 lines)
  - tree_maintenance.rs: Balance, compact, stats (~150 lines)
- iter.rs: RangeScanIterator complete (305 lines)
- Trait impls: Debug, Index<K,V>, Iterator

Quality:
- KISS Standard #2: ALL files <400 lines ✅
- BBC English: All comments corrected (initialise, optimise, serialise) ✅
- Specific names: tree_search, tree_insert, tree_delete, tree_maintenance ✅
- Single responsibility: Each file ONE operation type (search/insert/delete/maint) ✅

B-Tree module COMPLETE:
- All dependencies satisfied (types, wal, node, page from 020-01, 020-02)
- All operations implemented (search, insert, delete, maintenance, iteration)
- Ready for use by API layer

Workspace packages:
- reedbase (current): B-Tree complete, X tests passing
- reedbase-last (last): Baseline unchanged, X tests passing
```

---

## Next Steps

**After this ticket**:
- ✅ **B-Tree module 100% COMPLETE** (all btree/ files implemented)
- ➡️ **Next**: 020-[STORE]-04 (CSV Tables - different module)

**Unblocked by this ticket**:
- API layer can now use B-Tree for indexing
- Table layer can build on top of B-Tree
- Query processing can use range scans

---

**Validation Date**: 2025-11-06  
**Validated Against**: last/src/btree/{tree,iter}.rs  
**Estimated Time**: 3-4 hours  
**Complexity**: High (large split, many methods, trait impls)
