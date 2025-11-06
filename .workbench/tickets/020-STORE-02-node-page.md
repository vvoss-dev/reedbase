# 020-[STORE]-02: B-Tree Nodes & Pages (node + page)

**Created**: 2025-11-06  
**Phase**: 2 (Storage Layer)  
**Estimated Effort**: 2-2.5 hours  
**Dependencies**: 020-[STORE]-01 complete (types, wal)  
**Blocks**: 020-[STORE]-03 (tree needs node + page)

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
- [x] **Alle Typen identifiziert** - 4 structs (siehe unten)
- [x] **Alle Funktionen identifiziert** - 20 functions (siehe unten)
- [x] **Alle Trait-Impls identifiziert** - Diverse (siehe unten)
- [x] **Keine Shortcuts geplant** - Bestätigung: Ich werde NICHTS weglassen

**Files in this ticket**:
```
last/src/btree/node.rs      593 lines  → current/src/store/btree/node.rs
last/src/btree/page.rs      669 lines  → current/src/store/btree/page.rs (SPLIT!)
Total: 1262 lines
```

**Public Types** (MUST ALL BE COPIED):
```rust
// From node.rs (2 structs):
pub struct InternalNode<K> {
    pub keys: Vec<K>,
    pub children: Vec<PageId>,
}

pub struct LeafNode<K, V> {
    pub keys: Vec<K>,
    pub values: Vec<V>,
    pub next: Option<PageId>,
}

// From page.rs (2 structs):
pub struct PageHeader {
    pub magic: u32,
    pub node_type: NodeType,
    pub page_id: PageId,
    pub checksum: u32,
    // ... all fields
}

pub struct Page {
    pub header: PageHeader,
    pub data: Vec<u8>,
}
```

**Public Functions** (MUST ALL BE COPIED):
```rust
// From node.rs - InternalNode (6 methods):
pub fn new() -> Self
pub fn find_child(&self, key: &K) -> usize
pub fn insert_key(&mut self, key: K, child: PageId) -> ReedResult<()>
pub fn split(&mut self) -> ReedResult<(K, Self)>
pub fn is_underflow(&self, order: Order) -> bool
pub fn is_overflow(&self, order: Order) -> bool

// From node.rs - LeafNode (6 methods):
pub fn new() -> Self
pub fn find_value(&self, key: &K) -> Option<V>
pub fn insert(&mut self, key: K, value: V) -> ReedResult<()>
pub fn split(&mut self) -> ReedResult<(K, Self)>
pub fn is_underflow(&self, order: Order) -> bool
pub fn is_overflow(&self, order: Order) -> bool

// From page.rs (8 methods):
pub fn new_internal(_page_id: PageId) -> Self
pub fn new_leaf(_page_id: PageId) -> Self
pub fn read_from(mmap: &Mmap, page_id: PageId) -> ReedResult<Self>
pub fn read_from_bytes(bytes: &[u8], page_id: PageId) -> ReedResult<Self>
pub fn write_to(&self, mmap: &mut MmapMut, page_id: PageId) -> ReedResult<()>
pub fn validate(&self) -> ReedResult<()>
pub fn set_data(&mut self, data: Vec<u8>)
pub fn get_data(&self) -> &[u8]

Total: 20 public functions
```

**Test Status**:
- node.rs: ❌ No inline tests
- page.rs: ✅ Has inline tests (lines 554-end, must extract to page_test.rs)

**Dependencies**:
```
node.rs imports:
  - crate::btree::types::{Order, PageId}
  - crate::error::{ReedError, ReedResult}

page.rs imports:
  - crate::btree::types::{NodeType, PageId, BTREE_MAGIC}
  - crate::error::{ReedError, ReedResult}
  - memmap2::{Mmap, MmapMut}
  - std::io
```

**Verification Commands**:
```bash
# Verify line counts
wc -l last/src/btree/node.rs last/src/btree/page.rs
# Expected: 593 node.rs, 669 page.rs

# Verify public API
rg "^pub struct" last/src/btree/node.rs last/src/btree/page.rs
# Expected: 4 structs

# Verify functions
rg "    pub fn" last/src/btree/{node,page}.rs | wc -l
# Expected: 20 functions

# Verify inline tests
rg "#\[cfg\(test\)\]" last/src/btree/node.rs
# Expected: Not found

rg "#\[cfg\(test\)\]" last/src/btree/page.rs
# Expected: Found at line 554
```

**Bestätigung**: Ich habe verstanden dass `last/src/btree/{node,page}.rs` die Spezifikation ist und `current/src/store/btree/{node,page}.rs` EXAKT identisch sein muss.

---

## Context & Scope

**This ticket implements**: B-Tree node structures and page management  
**From**: `last/src/btree/node.rs`, `last/src/btree/page.rs`  
**To**: `current/src/store/btree/node.rs`, `current/src/store/btree/page.rs`

**Why these two together?**
- Both are Level 1 dependencies (only import types from 020-[STORE]-01)
- node.rs defines in-memory node structures
- page.rs defines on-disk page format and serialization
- Both needed before tree.rs can be implemented
- Splitting page.rs (669 lines) required per KISS Standard #2

**Critical Split Decision**:
- Old ticket 304-[SPLIT]-00 suggests: page.rs → page.rs + page_serialize.rs
- Analysis: Serialization is tightly coupled with Page struct
- **Decision**: Keep together for now (cohesive unit), document exception like wal.rs

**What comes AFTER this ticket**:
- ✋ **STOP**: Cannot implement tree.rs without node + page!
- ✋ **MUST WAIT**: This ticket must be 100% complete first
- ✅ **THEN**: 020-[STORE]-03 can implement tree.rs (which imports node, page)

**Dependency Graph** (validated 2025-11-06):
```
Level 0 (complete):
├─ types.rs  ✅ (020-[STORE]-01)
└─ wal.rs    ✅ (020-[STORE]-01)

Level 1 (this ticket):
├─ node.rs   → types ✅
└─ page.rs   → types ✅

Level 2 (blocked):
├─ tree.rs   → types, node, page, wal (BLOCKED until this ticket done)
└─ iter.rs   → types, node, page (BLOCKED until this ticket done)
```

---

## Reference (Old Tickets)

**This ticket combines/supersedes**:
- `111-[TESTS]-00-extract-btree-page.md` - Test extraction for page.rs
- `304-[SPLIT]-00-btree-page.md` - Split strategy for page.rs (669 lines)

**Old tickets provided**:
- ✅ Test extraction strategy for page.rs
- ✅ Split suggestion: page.rs + page_serialize.rs
- ✅ Understanding that page.rs exceeds 400 line limit

**New ticket adds**:
- ✅ Golden Rule verification against actual last/src/ code
- ✅ QS-Matrix (16 checks)
- ✅ BBC English corrections
- ✅ Workspace structure (current/ + last/)
- ✅ Regression testing against last/
- ✅ Decision: Keep page.rs together (document exception)

---

## BBC English Corrections Required

**Issues found in last/src/btree/node.rs**:
```rust
// Comments use American English
"optimize" → "optimise"
```

**Issues found in last/src/btree/page.rs**:
```rust
// Comments use American English
"serialize" → "serialise"
"deserialize" → "deserialise"
"optimize" → "optimise"

// ✅ Exception: memmap2 crate names
Mmap, MmapMut  // OK (external crate)
```

**Action**: Fix ALL comments/docs to BBC English in current/

**Verification**:
```bash
# Find American spellings
rg -i "(optimize|serialize|deserialize)" last/src/btree/{node,page}.rs | grep -v "fn \|struct \|impl "
```

---

## Implementation Steps

### Step 1: Implement node.rs (45 min)

**Reference**: `last/src/btree/node.rs` (593 lines)  
**Target**: `current/src/store/btree/node.rs`

**What to copy** (Golden Rule: EVERYTHING):

1. ✅ File header documentation (lines 1-15)
2. ✅ ALL imports (lines 16-35)
3. ✅ InternalNode<K> struct + ALL 6 methods (lines 57-280)
4. ✅ LeafNode<K, V> struct + ALL 6 methods (lines 324-590)
5. ✅ ALL trait impls (Debug, Clone, etc.)
6. ❌ No inline tests to extract (node.rs has none)

**Changes required**:
```rust
// Update imports
use crate::error::{ReedError, ReedResult};
use super::types::{Order, PageId};

// Fix BBC English in comments
// OLD: "Optimize node access..."
// NEW: "Optimise node access..."
```

**Implementation**:
```bash
# Copy complete file
cp last/src/btree/node.rs current/src/store/btree/node.rs

# Manually fix:
# 1. Copyright header
# 2. Import paths (crate::btree:: → super::)
# 3. BBC English comments
```

**Verification**:
```bash
# Line count should match (~593 lines)
wc -l current/src/store/btree/node.rs
# Expected: ~593 lines (exceeds 400 - document exception)

# All 12 functions present
rg "    pub fn" current/src/store/btree/node.rs | wc -l
# Expected: 12 functions

# Compilation
cargo check -p reedbase
```

---

### Step 2: Implement page.rs (45 min)

**Reference**: `last/src/btree/page.rs` (669 lines)  
**Target**: `current/src/store/btree/page.rs`

**What to copy** (Golden Rule: EVERYTHING except tests):

1. ✅ File header documentation (lines 1-20)
2. ✅ ALL imports (lines 21-40)
3. ✅ Constants (PAGE_SIZE, etc.)
4. ✅ PageHeader struct (lines 73-220)
5. ✅ Page struct + ALL 8 methods (lines 222-550)
6. ✅ ALL helper functions
7. ❌ **SKIP inline tests** (lines 554-end) → Extract to page_test.rs in Step 3

**Changes required**:
```rust
// Update imports
use crate::error::{ReedError, ReedResult};
use super::types::{NodeType, PageId, BTREE_MAGIC};

// Fix BBC English in comments
// OLD: "Serialize page to disk..."
// NEW: "Serialise page to disk..."

// OLD: "Deserialize from bytes..."
// NEW: "Deserialise from bytes..."
```

**Implementation**:
```bash
# Copy file excluding inline tests
head -n 553 last/src/btree/page.rs > current/src/store/btree/page.rs

# Manually fix:
# 1. Copyright header
# 2. Import paths
# 3. BBC English comments
```

**Verification**:
```bash
# Line count (~553 lines without tests)
wc -l current/src/store/btree/page.rs
# Expected: ~553 lines (exceeds 400 - document exception)

# All 8 functions present
rg "    pub fn" current/src/store/btree/page.rs | wc -l
# Expected: 8 functions

# Compilation
cargo check -p reedbase
```

---

### Step 3: Extract page.rs Tests (20 min)

**Reference**: Old ticket `111-[TESTS]-00` + `last/src/btree/page.rs` lines 554-end  
**Target**: `current/src/store/btree/page_test.rs`

**What to extract**:
```rust
// Lines 554-669 from last/src/btree/page.rs
#[cfg(test)]
mod tests {
    use super::*;
    
    // ALL tests
}
```

**Create**: `current/src/store/btree/page_test.rs`

```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Tests for B-Tree page management.

use super::*;

#[cfg(test)]
mod tests {
    use super::*;
    
    // Copy ALL tests from last/src/btree/page.rs lines 556-669
}
```

**Verification**:
```bash
# Count tests
rg "#\[test\]" last/src/btree/page.rs | wc -l
rg "#\[test\]" current/src/store/btree/page_test.rs | wc -l
# Expected: Equal

# Run tests
cargo test -p reedbase --lib store::btree::page
# Expected: All passing
```

---

### Step 4: Update mod.rs (10 min)

**Target**: `current/src/store/btree/mod.rs`

**Add to existing mod.rs**:
```rust
mod node;
mod page;

#[cfg(test)]
#[path = "page_test.rs"]
mod page_test;

// Add to re-exports
pub use node::{InternalNode, LeafNode};
pub use page::{Page, PageHeader};
```

**Verification**:
```bash
cargo check -p reedbase
```

---

### Step 5: Integration Testing (15 min)

**Run ALL checks**:

```bash
# 1. Compilation
cargo check -p reedbase
# Expected: No errors

# 2. Run page tests
cargo test -p reedbase --lib store::btree::page
# Expected: All tests passing

# 3. Verify baseline still works
cargo test -p reedbase-last --lib btree::page
cargo test -p reedbase-last --lib btree::node
# Expected: Baseline tests still passing

# 4. No warnings
cargo clippy -p reedbase -- -D warnings

# 5. Line count verification
wc -l current/src/store/btree/{node,page}.rs
# Expected: ~593 node.rs, ~553 page.rs (both exceed 400)
```

**Known Issues**: Both files exceed 400 line limit (see below)

---

## ✅ Quality Assurance Matrix (MANDATORY)

### Pre-Implementation

- [x] **Golden Rule: last/ analysed completely**
  - [x] node.rs read: 593 lines, 12 functions, 2 structs
  - [x] page.rs read: 669 lines, 8 functions, 2 structs
  - [x] All trait impls verified
  - [x] Dependencies verified: Only types imported
  - [x] Test status: page has inline tests, node has none

- [x] **Standard #0: Code Reuse**
  - [x] Uses `crate::error::{ReedError, ReedResult}` ✅
  - [x] Uses `super::types::{Order, PageId, NodeType}` ✅
  
- [x] **Standard #3: File Naming**
  - [x] Specific names: node.rs (node structures), page.rs (page management)

- [x] **Standard #8: Architecture**
  - [x] Layered structure: store/btree/
  - [x] Pure data structures + operations

### During Implementation

- [ ] **Standard #1: BBC English**
  - [ ] All comments fixed: "optimise", "serialise", "deserialise"

- [ ] **Standard #4: Single Responsibility**
  - [ ] node.rs: Node structures + operations ✅
  - [ ] page.rs: Page format + serialization ✅

- [ ] **Standard #6: No Swiss Army Functions**
  - [ ] Each function single purpose ✅

- [ ] **Standard #7: Specific Names**
  - [ ] Functions: `find_child()`, `read_from()` - specific ✅
  - [ ] Types: `InternalNode`, `LeafNode`, `Page` - clear ✅

- [ ] **Regression: Behaviour Verification**
  - [ ] Tests adapted from last/src/btree/page.rs

### Post-Implementation

- [ ] **Standard #2: File Size <400 Lines**
  - [ ] node.rs: 593 lines ❌ (exceeds - see Known Issues)
  - [ ] page.rs: 553 lines ❌ (exceeds - see Known Issues)
  - [ ] page_test.rs: ~115 lines ✅

- [ ] **Standard #5: Separate Test Files**
  - [ ] page_test.rs created ✅
  - [ ] No inline tests in page.rs ✅
  - [ ] node.rs has no tests (OK - might be covered by tree tests)

- [ ] **Regression: All Tests Passing**
  - [ ] `cargo test -p reedbase --lib store::btree` ✅
  - [ ] `cargo test -p reedbase-last --lib btree` ✅

---

## Known Issues & Decisions

### Issue 1: node.rs Exceeds 400 Line Limit

**Problem**: node.rs is 593 lines (violates Standard #2)

**Analysis**:
- InternalNode: ~220 lines (struct + 6 methods)
- LeafNode: ~270 lines (struct + 6 methods)
- Both are tightly coupled node types

**Options**:
A. Accept as-is (node types are cohesive)
B. Split into node_internal.rs + node_leaf.rs
C. Extract helpers

**Decision**: **Option A** - Accept for now
- InternalNode and LeafNode are fundamental paired types
- Splitting would reduce cohesion (both represent B-Tree nodes)
- Methods are focused (6 each, all <50 lines)
- Document exception in MIGRATION.md

### Issue 2: page.rs Exceeds 400 Line Limit

**Problem**: page.rs is 553 lines (without tests, violates Standard #2)

**Analysis**:
- PageHeader struct: ~150 lines
- Page struct + methods: ~400 lines
- Serialization is integral to Page

**Options**:
A. Accept as-is (cohesive page management)
B. Split into page.rs + page_serialize.rs (old ticket 304 suggestion)
C. Extract PageHeader to separate file

**Decision**: **Option A** - Accept for now
- Page struct and serialization are tightly coupled
- Splitting would create artificial boundaries
- All methods are focused (<100 lines each)
- Document exception in MIGRATION.md

**Note**: Similar pattern to wal.rs (581 lines) from 020-[STORE]-01

### Documentation

```markdown
# MIGRATION.md

## Known Exceptions to CLAUDE.md Standards

### node.rs: 593 lines (exceeds 400 line limit)

**Reason**: InternalNode and LeafNode are paired fundamental types.
- InternalNode: 220 lines (struct + 6 methods)
- LeafNode: 270 lines (struct + 6 methods)
- Splitting would reduce cohesion of node operations.

**Future**: Monitor - if either grows beyond 400 lines individually, split then.

### page.rs: 553 lines (exceeds 400 line limit)

**Reason**: Page struct and serialization are tightly coupled.
- PageHeader: 150 lines
- Page operations: 400 lines (8 methods, all <100 lines each)
- Serialization integral to page format.

**Future**: Consider extracting PageHeader if page grows beyond 600 lines.
```

---

## Success Criteria

### Functionality
- ✅ All types from last/ present: InternalNode, LeafNode, Page, PageHeader
- ✅ All 20 functions from last/ present
- ✅ All trait impls present
- ✅ Page tests extracted and passing

### Quality
- ✅ BBC English everywhere
- ✅ Separate test file (page_test.rs)
- ✅ Specific file names
- ✅ Single responsibility
- ❌ node.rs + page.rs exceed 400 lines (documented exceptions)
- ✅ No duplicates, uses types from 020-[STORE]-01

### Regression
- ✅ All page tests passing in current/
- ✅ Baseline tests still passing in last/
- ✅ Behaviour identical

### Dependencies
- ✅ Level 1 complete (imports types only)
- ✅ Ready for Level 2 (tree.rs can now import node + page)

---

## Commit Message Template

```
[CLEAN-020-02] feat(store): implement B-Tree nodes & pages

Phase 2 - Storage Layer - Ticket 2/4

✅ Golden Rule: Complete parity with last/src/btree/
✅ QS-Matrix: 14/16 checks passing (node + page exceed line limits - documented)
✅ Regression tests: X/X passing
✅ Behaviour: Identical to last/

Implementation:
- node.rs: InternalNode, LeafNode (593 lines)
  - InternalNode: 6 methods (find_child, insert_key, split, is_underflow, is_overflow, new)
  - LeafNode: 6 methods (find_value, insert, split, is_underflow, is_overflow, new)
- page.rs: Page, PageHeader (553 lines)
  - 8 methods: new_internal, new_leaf, read_from, read_from_bytes, write_to, validate, set_data, get_data
- page_test.rs: Extracted inline tests (X tests)

Quality:
- BBC English: All comments corrected ✅
- Separate tests: page_test.rs ✅
- Specific names: node.rs, page.rs ✅
- No duplicates: Uses types from 020-01 ✅

Known exceptions:
- node.rs=593 lines: Paired node types (Internal + Leaf), documented in MIGRATION.md
- page.rs=553 lines: Page struct + serialization cohesive, documented in MIGRATION.md

Dependencies satisfied:
- Level 1 complete (imports types only)
- Blocks 020-[STORE]-03: tree.rs can now import node + page

Workspace packages:
- reedbase (current): B-Tree nodes & pages complete, X tests passing
- reedbase-last (last): Baseline unchanged, all tests still passing
```

---

## Next Steps

**After this ticket is complete and committed**:

1. ✅ Verify: `cargo test -p reedbase --lib store::btree`
2. ✅ Commit with message above
3. ➡️ **Start 020-[STORE]-03**: Implement tree.rs + iter.rs (Level 2)
   - Can now import types, node, page, wal
   - Must split tree.rs (782 lines) into 5 files

**DO NOT START**:
- ❌ CSV tables (different module)
- ❌ Indices (different module)
- ❌ ANY non-btree code

**Strict ordering**:
```
020-01 (types+wal) → 020-02 (node+page) → 020-03 (tree+iter)
     COMPLETE           COMPLETE              BLOCKED
```

---

**Validation Date**: 2025-11-06  
**Validated Against**: last/src/btree/{node,page}.rs  
**Estimated Time**: 2-2.5 hours  
**Complexity**: Medium (large files, test extraction, line limit exceptions)
