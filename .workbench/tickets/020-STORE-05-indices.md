# 020-[STORE]-05: Smart Indices Implementation

**Created**: 2025-11-06  
**Phase**: 2 (Storage Layer)  
**Estimated Effort**: 3-4 hours  
**Dependencies**: 020-[STORE]-03 (B-Tree), 020-[STORE]-04 (Tables)  
**Blocks**: Database layer, Query layer

---

## Status
- [x] Not Started
- [ ] In Progress
- [ ] Complete

---

## 🚨 GOLDEN RULE: COMPLETE PARITY - NO SHORTCUTS

### Mandatory Pre-Implementation Analysis

**Verification Date**: 2025-11-06

- [x] **last/src/indices/ vollständig gelesen** - 9 Dateien analysiert
- [x] **Alle Typen identifiziert** - 3 structs + 1 trait (siehe unten)
- [x] **Alle Funktionen identifiziert** - ~64 public functions (siehe unten)
- [x] **Keine Shortcuts geplant** - Bestätigung: Ich werde NICHTS weglassen
- [x] **Separate test files bestätigt** - builder_tests.rs, indices_test.rs
- [x] **Line counts validiert** - Alle Dateien unter 400 Zeilen ✅

**Files in this ticket**:
```
last/src/indices/types.rs           123 lines  → current/src/store/indices/types.rs
last/src/indices/index_trait.rs     112 lines  → current/src/store/indices/index_trait.rs
last/src/indices/namespace.rs       157 lines  → current/src/store/indices/namespace.rs
last/src/indices/modifier.rs        115 lines  → current/src/store/indices/modifier.rs
last/src/indices/hierarchy.rs       183 lines  → current/src/store/indices/hierarchy.rs
last/src/indices/hashmap_index.rs   328 lines  → current/src/store/indices/hashmap_index.rs
last/src/indices/btree_index.rs     343 lines  → current/src/store/indices/btree_index.rs
last/src/indices/builder.rs         365 lines  → current/src/store/indices/builder.rs
last/src/indices/manager.rs         310 lines  → current/src/store/indices/manager.rs
last/src/indices/mod.rs              77 lines  → current/src/store/indices/mod.rs
Total: 2113 lines (all files under 400 limit ✅)
```

**Public Types** (MUST ALL BE COPIED):
```rust
// From types.rs (3 structs):
pub struct KeyIndex {
    pub row_id: usize,
    pub key: String,
    pub namespace: String,
    pub modifiers: Modifiers,
    pub hierarchy: Vec<String>,
}

pub struct Modifiers {
    pub language: Option<String>,
    pub environment: Option<String>,
    pub season: Option<String>,
    pub variant: Option<String>,
    pub custom: Vec<(String, String)>,
}

pub struct QueryFilter {
    pub namespace: Option<String>,
    pub language: Option<String>,
    pub environment: Option<String>,
    pub season: Option<String>,
    pub variant: Option<String>,
    pub hierarchy: Option<Vec<String>>,
}

// From index_trait.rs (1 trait):
pub trait Index<K, V>: Send + Sync + Debug {
    fn get(&self, key: &K) -> ReedResult<Option<V>>;
    fn insert(&mut self, key: K, value: V) -> ReedResult<()>;
    fn delete(&mut self, key: &K) -> ReedResult<()>;
    fn range(&self, start: &K, end: &K) -> ReedResult<Vec<(K, V)>>;
    fn scan(&self) -> ReedResult<Vec<(K, V)>>;
    fn len(&self) -> usize;
    fn is_empty(&self) -> bool;
}

// From manager.rs:
pub struct IndexManager { ... }
pub struct IndexStats { ... }

// From builder.rs:
pub struct IndexBuilder { ... }
pub struct IndexConfig { ... }
pub enum IndexBackend { HashMap, BTree }

// From namespace.rs:
pub struct NamespaceIndex { ... }

// From modifier.rs:
pub struct ModifierIndex { ... }

// From hierarchy.rs:
pub struct HierarchyTrie { ... }

// From hashmap_index.rs:
pub struct HashMapIndex<K, V> { ... }

// From btree_index.rs:
pub struct BTreeIndex<K, V> { ... }
```

**Public Functions** (~64 total, validated against last/src/):

**index_trait.rs** (trait methods - 7):
- `get()`, `insert()`, `delete()`, `range()`, `scan()`, `len()`, `is_empty()`

**namespace.rs** (NamespaceIndex - ~8 methods):
- `new()`, `insert()`, `query()`, `list_namespaces()`, `stats()`, etc.

**modifier.rs** (ModifierIndex - ~8 methods):
- `new()`, `insert()`, `query_language()`, `query_environment()`, `query_season()`, etc.

**hierarchy.rs** (HierarchyTrie - ~10 methods):
- `new()`, `insert()`, `query()`, `query_prefix()`, `query_wildcard()`, etc.

**hashmap_index.rs** (HashMapIndex<K,V> - implements Index trait + ~3 extra):
- All Index trait methods + `new()`, `with_capacity()`, `clear()`

**btree_index.rs** (BTreeIndex<K,V> - implements Index trait + ~3 extra):
- All Index trait methods + `new()`, `from_btree()`, `clear()`

**builder.rs** (IndexBuilder - ~8 methods):
- `new()`, `with_config()`, `build()`, `build_from_table()`, `add_key()`, etc.

**manager.rs** (IndexManager - ~10 methods):
- `new()`, `build()`, `query()`, `rebuild()`, `stats()`, `clear()`, etc.

**Test Files** (separate files, as per Standard #5):
```
builder_tests.rs      334 lines
indices_test.rs       481 lines
```

**Dependencies**:
```
Internal (from Phase 1-2):
  - crate::error::{ReedError, ReedResult}
  - crate::btree::{BPlusTree, Index as BTreeIndexTrait, Order}  (from 020-03)
  - crate::tables::Table                                         (from 020-04)
  - crate::schema::rbks                                          (external - schema layer)

External:
  - std::collections::{HashMap, HashSet}
```

**Dependency Analysis**:
```
Level 0: types.rs, index_trait.rs (no deps)
Level 1: namespace.rs, modifier.rs, hierarchy.rs (only types)
Level 2: hashmap_index.rs, btree_index.rs (uses btree from 020-03, implements Index trait)
Level 3: builder.rs (uses all Level 1+2)
Level 4: manager.rs (uses builder, all indices)
```

**Verification Commands**:
```bash
# Verify line counts
wc -l last/src/indices/*.rs
# Expected: All <400 lines

# Verify struct/trait count
rg "^pub (struct|trait|enum)" last/src/indices/types.rs
# Expected: 3 structs

rg "^pub trait" last/src/indices/index_trait.rs
# Expected: 1 trait

# Verify function count
rg "^    pub fn" last/src/indices/*.rs | wc -l
# Expected: ~64 functions

# Check dependencies
rg "^use crate::" last/src/indices/manager.rs
# Expected: error, btree, tables, schema, indices::*
```

**Bestätigung**: Ich habe verstanden dass `last/src/indices/` die Spezifikation ist und `current/src/store/indices/` EXAKT identisch sein muss. ALLE 9 Dateien unter 400 Zeilen - kein Split nötig ✅

---

## Context & Scope

**This ticket implements**: Smart Indices for 100-1000x faster queries  
**From**: `last/src/indices/{types,index_trait,namespace,modifier,hierarchy,hashmap_index,btree_index,builder,manager,mod}.rs`  
**To**: `current/src/store/indices/` (same structure)

**Why this module?**
- O(1) lookups for filtered queries (language, environment, namespace)
- O(d) hierarchical wildcard queries (e.g., `page.header.*`)
- Index build < 50ms for 10,000 keys
- Memory efficient: ~150 bytes/key
- Enables fast filtering WITHOUT full table scans

**Architecture**:
```
┌─────────────────────────────────────────┐
│ IndexManager                            │
│ - Coordinates all indices               │
│ - Set intersection for combined queries │
└────────────┬────────────────────────────┘
             │
      ┌──────┴──────┬──────────┬───────────┐
      ▼             ▼          ▼           ▼
┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
│Namespace │  │Modifier  │  │Hierarchy │  │Builder   │
│Index     │  │Index     │  │Trie      │  │          │
│O(1)      │  │O(1)      │  │O(d)      │  │          │
└──────────┘  └──────────┘  └──────────┘  └──────────┘
      │             │          │
      │             │          │
      └─────────────┴──────────┘
                │
      ┌─────────┴──────────┐
      ▼                    ▼
┌──────────┐         ┌──────────┐
│HashMap   │         │BTree     │
│Index     │         │Index     │
│(default) │         │(sorted)  │
└──────────┘         └──────────┘
```

**What comes AFTER this ticket**:
- ✅ **Indices module COMPLETE** - Ready for use by database layer
- ➡️ **Phase 2 COMPLETE** - All storage modules done
- ➡️ **Phase 3**: API/Query layers (use indices for fast queries)

**Dependency Graph** (validated 2025-11-06):
```
Level 0 (no deps):
├─ types.rs ✅
└─ index_trait.rs ✅

Level 1 (only types):
├─ namespace.rs → types ✅
├─ modifier.rs → types ✅
└─ hierarchy.rs → types ✅

Level 2 (uses btree from 020-03):
├─ hashmap_index.rs → index_trait ✅
└─ btree_index.rs → index_trait, btree::BPlusTree (020-03) ✅

Level 3 (uses all):
└─ builder.rs → types, namespace, modifier, hierarchy, hashmap/btree indices ✅

Level 4 (top-level):
└─ manager.rs → builder, tables::Table (020-04), schema::rbks ✅
```

---

## Reference (Old Tickets)

**This ticket may reference**:
- Old analysis of indices/ module structure
- Performance benchmarks for index lookups
- Query optimization strategies

**New ticket provides**:
- ✅ Golden Rule verification against actual last/src/ code
- ✅ Complete dependency analysis (Level 0-4)
- ✅ QS-Matrix (16 checks)
- ✅ BBC English corrections
- ✅ Workspace structure
- ✅ Regression testing

---

## BBC English Corrections Required

**Issues found in last/src/indices/**:
```rust
// Comments use American English
"optimize" → "optimise"
"initialize" → "initialise"
"serialize" → "serialise"
```

**Action**: Fix ALL comments/docs to BBC English in current/

---

## Implementation Steps

### Step 1: Create File Structure (10 min)

**Create all files with copyright headers**:
```bash
cd current/src/store
mkdir -p indices

for file in types.rs index_trait.rs namespace.rs modifier.rs hierarchy.rs hashmap_index.rs btree_index.rs builder.rs manager.rs mod.rs; do
  cat > indices/$file << 'EOF'
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

EOF
done
```

---

### Step 2: Implement types.rs (20 min)

**Reference**: `last/src/indices/types.rs` (123 lines)  
**Target**: `current/src/store/indices/types.rs`

**What to copy** (Golden Rule: EVERYTHING):
1. ✅ All 3 structs: KeyIndex, Modifiers, QueryFilter
2. ✅ All fields in each struct
3. ✅ All impl blocks (methods on structs)
4. ✅ Derive macros: Debug, Clone, Default, etc.

**Changes**:
```rust
// No import changes needed (no internal dependencies)

// Fix BBC English in comments
```

**Verification**:
```bash
wc -l current/src/store/indices/types.rs
# Expected: ~123 lines

rg "^pub struct" current/src/store/indices/types.rs
# Expected: 3 structs

cargo check -p reedbase
```

---

### Step 3: Implement index_trait.rs (20 min)

**Reference**: `last/src/indices/index_trait.rs` (112 lines)  
**Target**: `current/src/store/indices/index_trait.rs`

**What to copy**:
1. ✅ Index<K, V> trait definition
2. ✅ All 7 trait methods
3. ✅ Trait bounds: Send + Sync + Debug

**Changes**:
```rust
// Update imports
use crate::error::{ReedError, ReedResult};

// Fix BBC English
```

**Verification**:
```bash
wc -l current/src/store/indices/index_trait.rs
# Expected: ~112 lines

rg "^pub trait Index" current/src/store/indices/index_trait.rs
# Expected: 1 trait

cargo check -p reedbase
```

---

### Step 4: Implement namespace.rs (25 min)

**Reference**: `last/src/indices/namespace.rs` (157 lines)  
**Target**: `current/src/store/indices/namespace.rs`

**What to copy**:
1. ✅ NamespaceIndex struct
2. ✅ All methods (~8 methods)
3. ✅ Internal HashMap storage

**Changes**:
```rust
// Update imports
use crate::error::{ReedError, ReedResult};
use super::types::KeyIndex;

// Fix BBC English
```

**Verification**:
```bash
wc -l current/src/store/indices/namespace.rs
# Expected: ~157 lines

cargo check -p reedbase
```

---

### Step 5: Implement modifier.rs (25 min)

**Reference**: `last/src/indices/modifier.rs` (115 lines)  
**Target**: `current/src/store/indices/modifier.rs`

**What to copy**:
1. ✅ ModifierIndex struct
2. ✅ All methods (~8 methods: query_language, query_environment, etc.)
3. ✅ Internal HashMap storage for each modifier type

**Changes**:
```rust
// Update imports
use crate::error::{ReedError, ReedResult};
use super::types::{KeyIndex, Modifiers};

// Fix BBC English
```

**Verification**:
```bash
wc -l current/src/store/indices/modifier.rs
# Expected: ~115 lines

cargo check -p reedbase
```

---

### Step 6: Implement hierarchy.rs (30 min)

**Reference**: `last/src/indices/hierarchy.rs` (183 lines)  
**Target**: `current/src/store/indices/hierarchy.rs`

**What to copy**:
1. ✅ HierarchyTrie struct
2. ✅ All methods (~10 methods: query, query_prefix, query_wildcard, etc.)
3. ✅ Internal trie structure (tree-like HashMap)

**Changes**:
```rust
// Update imports
use crate::error::{ReedError, ReedResult};
use super::types::KeyIndex;

// Fix BBC English
```

**Verification**:
```bash
wc -l current/src/store/indices/hierarchy.rs
# Expected: ~183 lines

cargo check -p reedbase
```

---

### Step 7: Implement hashmap_index.rs (35 min)

**Reference**: `last/src/indices/hashmap_index.rs` (328 lines)  
**Target**: `current/src/store/indices/hashmap_index.rs`

**What to copy**:
1. ✅ HashMapIndex<K, V> struct
2. ✅ impl Index<K, V> trait (all 7 methods)
3. ✅ Additional methods (new, with_capacity, clear)
4. ✅ Internal HashMap storage

**Changes**:
```rust
// Update imports
use crate::error::{ReedError, ReedResult};
use super::index_trait::Index;

// Fix BBC English
```

**Verification**:
```bash
wc -l current/src/store/indices/hashmap_index.rs
# Expected: ~328 lines

rg "impl.*Index.*for HashMapIndex" current/src/store/indices/hashmap_index.rs
# Expected: Index trait impl found

cargo check -p reedbase
```

---

### Step 8: Implement btree_index.rs (35 min)

**Reference**: `last/src/indices/btree_index.rs` (343 lines)  
**Target**: `current/src/store/indices/btree_index.rs`

**What to copy**:
1. ✅ BTreeIndex<K, V> struct
2. ✅ impl Index<K, V> trait (all 7 methods)
3. ✅ Additional methods (new, from_btree, clear)
4. ✅ Uses BPlusTree from 020-03

**Changes**:
```rust
// Update imports
use crate::error::{ReedError, ReedResult};
use crate::store::btree::BPlusTree;  // From 020-03
use super::index_trait::Index;

// Fix BBC English
```

**Verification**:
```bash
wc -l current/src/store/indices/btree_index.rs
# Expected: ~343 lines

rg "impl.*Index.*for BTreeIndex" current/src/store/indices/btree_index.rs
# Expected: Index trait impl found

cargo check -p reedbase
```

---

### Step 9: Implement builder.rs (40 min)

**Reference**: `last/src/indices/builder.rs` (365 lines)  
**Target**: `current/src/store/indices/builder.rs`

**What to copy**:
1. ✅ IndexBuilder struct
2. ✅ IndexConfig struct
3. ✅ IndexBackend enum (HashMap, BTree)
4. ✅ All methods (~8 methods: build, build_from_table, add_key, etc.)

**Changes**:
```rust
// Update imports
use crate::error::{ReedError, ReedResult};
use super::types::{KeyIndex, Modifiers};
use super::{NamespaceIndex, ModifierIndex, HierarchyTrie};
use super::{HashMapIndex, BTreeIndex};

// Fix BBC English
```

**Verification**:
```bash
wc -l current/src/store/indices/builder.rs
# Expected: ~365 lines

rg "^pub (struct|enum)" current/src/store/indices/builder.rs
# Expected: 3 types (IndexBuilder, IndexConfig, IndexBackend)

cargo check -p reedbase
```

---

### Step 10: Implement manager.rs (40 min)

**Reference**: `last/src/indices/manager.rs` (310 lines)  
**Target**: `current/src/store/indices/manager.rs`

**What to copy**:
1. ✅ IndexManager struct
2. ✅ IndexStats struct
3. ✅ All methods (~10 methods: build, query, rebuild, stats, etc.)
4. ✅ Set intersection logic for combined queries

**Changes**:
```rust
// Update imports
use crate::error::{ReedError, ReedResult};
use crate::store::tables::Table;  // From 020-04
use crate::schema::rbks;          // External - schema layer
use super::builder::IndexBuilder;
use super::{NamespaceIndex, ModifierIndex, HierarchyTrie};
use super::types::{KeyIndex, QueryFilter};

// Fix BBC English
```

**Verification**:
```bash
wc -l current/src/store/indices/manager.rs
# Expected: ~310 lines

rg "^pub struct" current/src/store/indices/manager.rs
# Expected: 2 structs (IndexManager, IndexStats)

cargo check -p reedbase
```

---

### Step 11: Update mod.rs (15 min)

**Target**: `current/src/store/indices/mod.rs`

**Add modules**:
```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Smart Indices for 100-1000x faster queries.

pub mod types;
pub mod index_trait;
pub mod namespace;
pub mod modifier;
pub mod hierarchy;
pub mod hashmap_index;
pub mod btree_index;
pub mod builder;
pub mod manager;

// Re-exports
pub use types::{KeyIndex, Modifiers, QueryFilter};
pub use index_trait::Index;
pub use namespace::NamespaceIndex;
pub use modifier::ModifierIndex;
pub use hierarchy::HierarchyTrie;
pub use hashmap_index::HashMapIndex;
pub use btree_index::BTreeIndex;
pub use builder::{IndexBackend, IndexBuilder, IndexConfig};
pub use manager::{IndexManager, IndexStats};
```

---

### Step 12: Adapt Tests (45 min)

**Reference**: `last/src/indices/{builder_tests,indices_test}.rs`  
**Target**: `current/tests/store/indices/`

```bash
mkdir -p current/tests/store/indices

# Create test files
touch current/tests/store/indices/builder_test.rs
touch current/tests/store/indices/indices_test.rs
```

**Adapt tests**:
- Update imports: `use reedbase::store::indices::...`
- Update paths: `use reedbase::store::tables::Table`
- Fix test data paths if needed
- Verify all tests pass

---

### Step 13: Quality Verification (20 min)

```bash
# Run quality check on all files
for file in types.rs index_trait.rs namespace.rs modifier.rs hierarchy.rs hashmap_index.rs btree_index.rs builder.rs manager.rs; do
  echo "Checking $file..."
  ./scripts/quality-check.sh current/src/store/indices/$file
done

# Run regression verification
./scripts/regression-verify.sh indices
```

---

### Step 14: Final Verification (20 min)

```bash
# Verify all files <400 lines
echo "=== File Size Verification ==="
for file in types.rs index_trait.rs namespace.rs modifier.rs hierarchy.rs hashmap_index.rs btree_index.rs builder.rs manager.rs; do
  lines=$(wc -l < current/src/store/indices/$file)
  if [ $lines -le 400 ]; then
    echo "✅ $file: $lines lines (under limit)"
  else
    echo "❌ $file: $lines lines (EXCEEDS LIMIT!)"
  fi
done

# Verify all functions present
echo ""
echo "=== Function Count Verification ==="
rg "^    pub fn" current/src/store/indices/*.rs | wc -l
echo "Expected: ~64 functions"

# Verify trait impl
echo ""
echo "=== Trait Implementation Verification ==="
rg "impl.*Index.*for (HashMap|BTree)Index" current/src/store/indices/
# Expected: 2 Index trait implementations

# Final test run
echo ""
echo "=== Final Test Run ==="
cargo test -p reedbase --lib store::indices
cargo test -p reedbase-last --lib indices
```

---

## ✅ Quality Assurance Matrix (MANDATORY)

### Pre-Implementation

- [x] **Golden Rule: last/ analysed completely**
  - [x] 9 source files validated (all under 400 lines ✅)
  - [x] ~64 public functions + 4 types identified
  - [x] Dependency graph: Level 0-4 validated

- [x] **Standard #0: Code Reuse**
  - [x] Uses BPlusTree from 020-03 (btree_index.rs) ✅
  - [x] Uses Table from 020-04 (manager.rs) ✅
  - [x] Uses error types from Phase 1 ✅

- [x] **Standard #3: File Naming**
  - [x] Specific names: namespace, modifier, hierarchy (not helpers, utils) ✅

- [x] **Standard #8: Architecture**
  - [x] Layered structure: store/indices/ ✅

### During Implementation

- [ ] **Standard #1: BBC English**
  - [ ] All comments fixed (optimise, initialise, serialise)

- [ ] **Standard #4: Single Responsibility**
  - [ ] namespace.rs: Namespace lookup only ✅
  - [ ] modifier.rs: Modifier lookup only ✅
  - [ ] hierarchy.rs: Hierarchical trie only ✅
  - [ ] manager.rs: Index coordination only ✅

### Post-Implementation

- [ ] **Standard #2: File Size <400 Lines**
  - [ ] types.rs: 123 lines ✅
  - [ ] index_trait.rs: 112 lines ✅
  - [ ] namespace.rs: 157 lines ✅
  - [ ] modifier.rs: 115 lines ✅
  - [ ] hierarchy.rs: 183 lines ✅
  - [ ] hashmap_index.rs: 328 lines ✅
  - [ ] btree_index.rs: 343 lines ✅
  - [ ] builder.rs: 365 lines ✅
  - [ ] manager.rs: 310 lines ✅

- [ ] **Standard #5: Separate Test Files**
  - [ ] builder_test.rs in tests/ ✅
  - [ ] indices_test.rs in tests/ ✅

- [ ] **Standard #6: No Swiss Army Functions**
  - [ ] query() does ONE thing (filter by criteria) ✅
  - [ ] build() does ONE thing (build indices) ✅

- [ ] **Regression: All Tests Passing**
  - [ ] `cargo test -p reedbase --lib store::indices` ✅
  - [ ] `cargo test -p reedbase-last --lib indices` ✅

---

## Success Criteria

### Functionality
- ✅ All 9 files implemented (all under 400 lines)
- ✅ All ~64 functions/methods present
- ✅ Index trait implemented by HashMapIndex and BTreeIndex
- ✅ Manager coordinates all indices with set intersection
- ✅ Indices module COMPLETE

### Quality
- ✅ All files <400 lines (no split needed!)
- ✅ BBC English everywhere (optimise, initialise, serialise)
- ✅ Specific file names (namespace, modifier, not helpers)
- ✅ Single responsibility per file
- ✅ No duplicates

### Regression
- ✅ All tests passing (builder, indices)
- ✅ Baseline unchanged (last/ tests still green)
- ✅ Behaviour identical (same query results)

### Performance
- ✅ Single index lookup < 1μs (O(1))
- ✅ Hierarchy query < 10μs (O(d))
- ✅ Combined query < 50μs (3 filters + intersection)

---

## Commit Message Template

```
[CLEAN-020-05] feat(store): implement Smart Indices for fast queries

Phase 2 - Storage Layer - Ticket 5/6

✅ Golden Rule: Complete parity with last/src/indices/
✅ QS-Matrix: 16/16 checks passing (all files <400 lines!)
✅ Regression tests: X/X passing
✅ Behaviour: Identical to last/

Implementation:
- types.rs: 3 structs (KeyIndex, Modifiers, QueryFilter) - 123 lines
- index_trait.rs: Index<K,V> trait (7 methods) - 112 lines
- namespace.rs: O(1) namespace lookup (NamespaceIndex) - 157 lines
- modifier.rs: O(1) modifier lookup (ModifierIndex) - 115 lines
- hierarchy.rs: O(d) hierarchical trie (HierarchyTrie) - 183 lines
- hashmap_index.rs: HashMap backend (implements Index trait) - 328 lines
- btree_index.rs: B-Tree backend (implements Index trait) - 343 lines
- builder.rs: Index construction (IndexBuilder) - 365 lines
- manager.rs: Index coordination (IndexManager) - 310 lines

Quality:
- KISS Standard #2: ALL files <400 lines ✅
- BBC English: All comments corrected (optimise, initialise, serialise) ✅
- Specific names: namespace, modifier, hierarchy (not helpers) ✅
- Single responsibility: Each file ONE index type ✅

Indices module COMPLETE:
- O(1) lookups for filtered queries (namespace, language, environment)
- O(d) hierarchical wildcard queries (e.g., page.header.*)
- Set intersection for combined queries
- 100-1000x faster than full table scans
- Ready for use by database/query layers

Dependencies:
- Uses BPlusTree from 020-03 (btree_index.rs) ✅
- Uses Table from 020-04 (manager.rs) ✅

Workspace packages:
- reedbase (current): Indices complete, X tests passing
- reedbase-last (last): Baseline unchanged, X tests passing
```

---

## Next Steps

**After this ticket**:
- ✅ **Indices module 100% COMPLETE** (fast query indices ready)
- ✅ **Phase 2 (Storage Layer) COMPLETE** - All store/ modules done:
  - 020-01: types + wal ✅
  - 020-02: node + page ✅
  - 020-03: tree + iter ✅
  - 020-04: tables ✅
  - 020-05: indices ✅
  - 020-06: TBD (identify remaining modules if any)

**Unblocked by this ticket**:
- Database layer can use indices for fast queries
- Query planner can optimise with index selection
- API layer can filter results efficiently

---

**Validation Date**: 2025-11-06  
**Validated Against**: last/src/indices/ (9 files)  
**Estimated Time**: 3-4 hours  
**Complexity**: Medium-High (many files, trait impl, set operations)
