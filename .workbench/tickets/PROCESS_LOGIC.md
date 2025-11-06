# Ticket Creation Process Logic

**⚠️ CRITICAL: Read this BEFORE creating EVERY new ticket**

This document contains the validated process logic for creating Clean Room tickets from the old ticket system.

---

## Mantra (Read Aloud Before Each Ticket)

> "I will validate every assumption against last/src/ code.  
> I will check all dependencies are resolved.  
> I will preserve all analysis from old tickets.  
> I will add Golden Rule, QS-Matrix, BBC English, Regression.  
> I will update all paths to workspace structure.  
> I will verify nothing is lost."

---

## The Problem We're Solving

**Yesterday's Mistake**:
- ✅ Created workspace structure (`current/`, `last/`)
- ✅ Defined new folder hierarchy (`store/btree/` instead of `btree/`)
- ❌ Did NOT update tickets to match new structure
- ❌ Tried to reinvent tickets without preserving old analysis

**What We Have**:
- **Old tickets** (`.workbench/docs/refactoring_tickets/`): Hours of validated dependency analysis, implementation steps
- **Old code** (`last/src/`): The reference implementation
- **New structure** (`current/src/`): Empty target with new folder layout

**What We Need**:
- **New tickets** (`.workbench/tickets/`): Old analysis + workspace updates + quality rules

---

## Ticket Creation Process (9 Steps)

### Step 1: Select Old Ticket

**Source**: `.workbench/docs/refactoring_tickets/XXX-[TYPE]-YY-*.md`

**Priority order** (from old ticket dependencies):
1. Tests extraction (100-[TESTS]-XX)
2. Structural splits (300-[SPLIT]-XX)
3. Renames (200-[RENAME]-XX)
4. Function analysis (250-[FUNC]-XX)

**Action**: Read complete old ticket, understand scope

---

### Step 2: Validate Against last/src/

**⚠️ MANDATORY: Never trust old ticket blindly - VERIFY EVERYTHING**

For each claim in old ticket, check against `last/src/`:

#### Line Counts
```bash
# Old ticket says: "tree.rs is 782 lines"
# Verify:
wc -l last/src/btree/tree.rs
# If different: Update ticket with actual count
```

#### File Existence
```bash
# Old ticket references: "src/btree/tree.rs"
# Verify:
ls last/src/btree/tree.rs
# If missing: Investigate - file renamed? moved? deleted?
```

#### Public API
```bash
# Old ticket lists functions
# Verify:
rg "^    pub fn \w+" last/src/btree/tree.rs -o | sort
# Compare: Are all functions listed? Any missing? Any extra?
```

#### Dependencies
```bash
# Old ticket shows dependency graph
# Verify:
rg "^use crate::" last/src/btree/tree.rs
# Check: Does tree.rs really import page.rs, wal.rs, node.rs?
```

#### Type Definitions
```bash
# Old ticket lists structs/enums
# Verify:
rg "^pub (struct|enum|type)" last/src/btree/tree.rs
# Compare: All types present? Names correct?
```

**Rule**: If **ANY** discrepancy found:
1. Update ticket with **actual** values from last/src/
2. Document discrepancy in "Validation Notes" section
3. Never blindly copy old ticket content

---

### Step 3: Analyze Dependencies (Critical!)

**Why**: Wrong dependency order = stuck in middle = cannot compile

**Process**:

```bash
# For each file in ticket scope, check what it imports
rg "^use crate::" last/src/module/file.rs

# Example output:
# use crate::btree::types::{Order, PageId};
# use crate::btree::node::InternalNode;
```

**Build dependency graph**:

```
Level 0 (no internal dependencies):
├─ types.rs     imports: (none)
└─ wal.rs       imports: (none)

Level 1 (only Level 0):
├─ node.rs      imports: types
└─ page.rs      imports: types

Level 2 (Level 0 + 1):
├─ tree.rs      imports: types, node, page, wal
└─ iter.rs      imports: types, node, page
```

**Ticket ordering rule**:
- Ticket A must come BEFORE Ticket B if B imports anything from A
- Never create ticket for tree.rs before tickets for types, node, page, wal
- Verify old ticket order respects this (it usually does, but check!)

**If old order is wrong**:
- Reorder tickets in new system
- Document reordering in ticket: "Reordered: Original was XXX, moved to YYY due to dependency Z"

---

### Step 4: Map Paths (Old → New)

**Old path format**: `src/module/file.rs`  
**New path format**: `last/src/module/file.rs` (reference) + `current/src/layer/module/file.rs` (target)

**Mapping rules**:

| Old Path | last/ Path | current/ Path | Layer |
|----------|------------|---------------|-------|
| `src/btree/` | `last/src/btree/` | `current/src/store/btree/` | Storage |
| `src/schema/` | `last/src/schema/` | `current/src/validate/schema/` | Validation |
| `src/database/` | `last/src/database/` | `current/src/api/db/` | API |
| `src/reedql/` | `last/src/reedql/` | `current/src/api/reedql/` | API |
| `src/concurrent/` | `last/src/concurrent/` | `current/src/process/concurrent/` | Process |
| `src/backup/` | `last/src/backup/` | `current/src/ops/backup/` | Operations |
| `src/version/` | `last/src/version/` | `current/src/ops/version/` | Operations |
| `src/metrics/` | `last/src/metrics/` | `current/src/ops/metrics/` | Operations |

**Update all paths in**:
- File references: "Edit `src/btree/tree.rs`" → "Edit `current/src/store/btree/tree.rs`"
- Commands: `wc -l src/btree/tree.rs` → `wc -l last/src/btree/tree.rs`
- Imports: `use crate::btree::` → `use crate::store::btree::`

---

### Step 5: Update Commands (Workspace-Aware)

**Old commands**: Single package, no `-p` flag  
**New commands**: Workspace with two packages, MUST specify `-p reedbase` or `-p reedbase-last`

**Command mapping**:

| Old Command | New Command (current/) | New Command (last/) |
|-------------|----------------------|-------------------|
| `cargo test` | `cargo test -p reedbase` | `cargo test -p reedbase-last` |
| `cargo check` | `cargo check -p reedbase` | `cargo check -p reedbase-last` |
| `cargo build` | `cargo build -p reedbase` | `cargo build -p reedbase-last` |
| `cargo test --lib module` | `cargo test -p reedbase --lib module` | `cargo test -p reedbase-last --lib module` |
| `cargo clippy` | `cargo clippy -p reedbase` | N/A (baseline) |

**Examples**:

```bash
# ❌ OLD (wrong in workspace)
cargo test --lib btree

# ✅ NEW (workspace-aware)
cargo test -p reedbase --lib store::btree
cargo test -p reedbase-last --lib btree  # Baseline verification
```

**Update all commands in**:
- Implementation Steps
- Verification sections
- Test commands

---

### Step 6: Add Golden Rule Section

**Insert at top** (after Status, before Context):

```markdown
---

## 🚨 GOLDEN RULE: COMPLETE PARITY - NO SHORTCUTS

### Mandatory Pre-Implementation Analysis

- [ ] **last/src/module/ vollständig gelesen** - Alle X Dateien analysiert
- [ ] **Alle Typen identifiziert** - [Complete list from Step 2]
- [ ] **Alle Funktionen identifiziert** - [Complete list from Step 2]
- [ ] **Alle Trait-Impls identifiziert** - [Complete list from Step 2]
- [ ] **Keine Shortcuts geplant** - Bestätigung: Ich werde NICHTS weglassen

**Function Count**: X public functions identified in last/src/module/
**Type Count**: Y public types identified
**Line Count**: Z lines total

**Verification Commands**:
```bash
# List all public functions
rg "^    pub fn \w+" last/src/module/*.rs -o | sort

# List all public types
rg "^pub (struct|enum|type)" last/src/module/*.rs

# Count lines
wc -l last/src/module/*.rs
```

**Bestätigung**: Ich habe verstanden dass `last/src/module/` die Spezifikation ist und `current/src/layer/module/` EXAKT identisch sein muss.

---
```

**CRITICAL**: Lists must be **complete and verified** against last/src/ in Step 2

---

### Step 7: Add QS-Matrix Section

**Insert before Implementation Steps**:

```markdown
---

## ✅ Quality Assurance Matrix (MANDATORY)

### Pre-Implementation

- [ ] **Golden Rule: last/ analysiert completely**
  - [ ] All X files read: [list files]
  - [ ] All Y types listed: [list types]
  - [ ] All Z functions counted: [number] public functions
  - [ ] All trait impls listed: [list traits]
  - [ ] Dependencies verified: [dependency graph]

- [ ] **Standard #0: Code Reuse**
  - [ ] No duplicate path functions (use `core::paths`)
  - [ ] No duplicate error types (use `crate::error`)
  - [ ] Checked: `grep "function_name" .workbench/analysis/050-all-functions.txt`
  
- [ ] **Standard #3: File Naming**
  - [ ] All filenames specific: [list]
  - [ ] No generic names: NO helpers.rs, NO utils.rs

- [ ] **Standard #8: Architecture**
  - [ ] Layered structure confirmed: [layer]/[module]/
  - [ ] No MVC patterns planned
  - [ ] Pure functions planned (data in → data out)

### During Implementation

- [ ] **Standard #1: BBC English**
  - [ ] All comments in BBC English
  - [ ] All docstrings in BBC English
  - [ ] American spellings documented where necessary (serde::Serialize, etc.)

- [ ] **Standard #4: Single Responsibility**
  - [ ] Each file has ONE clear purpose
  - [ ] Functions <100 lines
  - [ ] Parameters <5
  - [ ] No boolean flags in parameters

- [ ] **Standard #6: No Swiss Army Functions**
  - [ ] No `handle()`, `process()`, `manage()` functions
  - [ ] No complex mode switching with flags

- [ ] **Standard #7: Specific Names**
  - [ ] Function names specific: `find_leaf()`, not `find()`
  - [ ] Variable names contextual: `root_page_id`, not `id`
  - [ ] Type names clear: `InternalNode`, not `Node`

- [ ] **Regression: Behaviour Verification**
  - [ ] Tests adapted from last/src/
  - [ ] ALL test categories included
  - [ ] New regression tests added

### Post-Implementation

- [ ] **Standard #2: File Size <400 Lines**
  - [ ] [list all files with line counts]
  - [ ] If >400 lines: Document split plan or justification

- [ ] **Standard #5: Separate Test Files**
  - [ ] [list]_test.rs exists
  - [ ] No inline `#[cfg(test)]` modules

- [ ] **Standard #0: No Duplicates (Final Check)**
  - [ ] No duplicate functions created
  - [ ] All core utilities used from `core/`

- [ ] **Regression: All Tests Passing**
  - [ ] `cargo test -p reedbase --lib module` ✅
  - [ ] `cargo test -p reedbase-last --lib module` ✅ (baseline)
  - [ ] Test count: current >= last

### Final Verification

```bash
# Quality check
for file in current/src/layer/module/*.rs; do
  ./scripts/quality-check.sh "$file"
done

# Compare APIs
rg "^pub (fn|struct|enum|type)" last/src/module/*.rs | sort > /tmp/last_api.txt
rg "^pub (fn|struct|enum|type)" current/src/layer/module/*.rs | sort > /tmp/current_api.txt
diff /tmp/last_api.txt /tmp/current_api.txt
# Expected: Only path differences, no missing items

# Test count
last_tests=$(rg "#\[test\]" last/src/module/*test.rs | wc -l)
current_tests=$(rg "#\[test\]" current/src/layer/module/*test.rs | wc -l)
echo "Tests: last=$last_tests, current=$current_tests"
# Expected: current >= last

# No warnings
cargo clippy -p reedbase -- -D warnings
```

---
```

---

### Step 8: Add BBC English & Regression Sections

**Insert after QS-Matrix, before Implementation Steps**:

```markdown
---

## BBC English Corrections Required

**Issues found in last/src/module/** (verified in Step 2):

```rust
// ❌ American English in comments (fix in current/)
"initialize"  → "initialise"
"optimize"    → "optimise"  
"analyze"     → "analyse"
"serialized"  → "serialised"
"color"       → "colour"
"behavior"    → "behaviour"

// ✅ Exception: Code identifiers from ecosystem
impl Serialize for Type { ... }  // OK (from serde)
fn optimize() { ... }             // If from external trait
```

**Verification**:
```bash
# Find American spellings in comments
rg -i "(initialize|optimize|analyze|color|behavior)" last/src/module/*.rs
```

**Action**: Fix ALL comments/docs to BBC English in current/

---

## Regression Testing Strategy

### Baseline (last/)

**Tests that must keep passing**:
```bash
# Run baseline tests
cargo test -p reedbase-last --lib module

# Count baseline tests
rg "#\[test\]" last/src/module/*test.rs | wc -l
# Result: X tests
```

### Migration (current/)

**Tests to adapt**:
1. ✅ Copy ALL tests from last/src/module/*test.rs
2. ✅ Update imports: `use reedbase_last::` → `use reedbase::`
3. ✅ Update paths: module-relative
4. ✅ Add regression tests comparing current/ output with last/

**New tests to add**:
- Regression: Verify output identical to last/
- Performance: Verify within 110% of last/ speed
- Quality: Verify all QS-Matrix items

**Verification**:
```bash
# Both must pass
cargo test -p reedbase-last --lib module      # Baseline
cargo test -p reedbase --lib layer::module   # New implementation

# Test count must be equal or greater
```

---
```

---

### Step 9: Preserve & Enhance Implementation Steps

**From old ticket**:
- ✅ Keep ALL implementation steps (hours of work already done!)
- ✅ Keep dependency analysis
- ✅ Keep split strategies (if file >400 lines)

**Update in each step**:
1. **Paths**: `src/module/file.rs` → `current/src/layer/module/file.rs` + `last/src/module/file.rs`
2. **Commands**: Add `-p reedbase` to all cargo commands
3. **Verification**: Add baseline check: `cargo test -p reedbase-last`

**Example old step**:
```markdown
### Step 3: Extract Search Operations

1. Create tree_search.rs
```rust
// Implementation
```

2. Test:
```bash
cargo test --lib btree::tree_search
```
```

**Enhanced new step**:
```markdown
### Step 3: Extract Search Operations (30 min)

**Reference**: `last/src/btree/tree.rs` lines 150-300  
**Target**: `current/src/store/btree/tree_search.rs`

**What to copy from last/**:
1. ✅ `get()` - Single key lookup (lines 150-180)
2. ✅ `range()` - Range queries (lines 181-220)
3. ✅ `find_leaf()` - Helper (lines 221-250)
4. ✅ ALL search-related functions

**Changes required**:
- Update imports: `use crate::btree::` → `use crate::store::btree::`
- Fix BBC English in comments
- Update error handling to use `ReedError` from `crate::error`

**Create**: `current/src/store/btree/tree_search.rs`
```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! B+-Tree search operations.
//!
//! Single-key lookups, range queries, and full scans.

use crate::error::{ReedError, ReedResult};
use super::tree::BPlusTree;

impl<K, V> BPlusTree<K, V> {
    /// [Copy implementation from last/src/btree/tree.rs lines 150-180]
}
```

**Verification**:
```bash
# Check compilation
cargo check -p reedbase

# Test search operations
cargo test -p reedbase --lib store::btree::tree_search

# Verify baseline still works
cargo test -p reedbase-last --lib btree

# Compare function signatures
rg "pub fn (get|range)" last/src/btree/tree.rs
rg "pub fn (get|range)" current/src/store/btree/tree_search.rs
# Expected: Identical signatures (except paths)
```

**QS-Matrix checkpoint**:
- [ ] Standard #1: BBC English in all comments ✅
- [ ] Standard #4: Each function <100 lines ✅
- [ ] Standard #7: Specific names (get, range, not search) ✅
```

---

## Validation Checklist (Before Saving Ticket)

Before saving new ticket to `.workbench/tickets/`, verify:

- [ ] **Step 2 complete**: All claims validated against last/src/
- [ ] **Step 3 complete**: Dependencies analyzed, order correct
- [ ] **Step 4 complete**: All paths updated (old → new)
- [ ] **Step 5 complete**: All commands updated (workspace-aware)
- [ ] **Step 6 complete**: Golden Rule section added with VERIFIED lists
- [ ] **Step 7 complete**: QS-Matrix section added (all 16 checks)
- [ ] **Step 8 complete**: BBC English + Regression sections added
- [ ] **Step 9 complete**: Implementation steps preserved & enhanced
- [ ] **No placeholders**: All [TODO], [FILL], [CHECK] removed
- [ ] **No assumptions**: Everything verified against actual code

---

## Common Pitfalls to Avoid

### Pitfall 1: Trusting Old Ticket Blindly

**Wrong**:
```markdown
Old ticket says: "tree.rs is 782 lines"
New ticket: [copies] "tree.rs is 782 lines"
```

**Right**:
```bash
# Verify first!
wc -l last/src/btree/tree.rs
# Result: 782 lines ✅ (or different - update!)

New ticket: "tree.rs is 782 lines (verified 2025-11-06)"
```

### Pitfall 2: Wrong Dependency Order

**Wrong**: Create ticket for tree.rs before page.rs (tree.rs imports page!)

**Right**: Check dependencies first, order tickets correctly

### Pitfall 3: Missing Workspace Commands

**Wrong**:
```bash
cargo test --lib btree
```

**Right**:
```bash
cargo test -p reedbase --lib store::btree
cargo test -p reedbase-last --lib btree  # Also verify baseline
```

### Pitfall 4: Incomplete Golden Rule

**Wrong**:
```markdown
- [ ] All functions identified: [some functions]
```

**Right**:
```markdown
- [ ] All functions identified: get(), range(), find_leaf(), insert(), delete() [5 functions - COMPLETE list verified]

Verification:
```bash
rg "pub fn \w+" last/src/module/file.rs -o | sort
# Output: [exact list above]
```
```

### Pitfall 5: Generic Ticket Content

**Wrong**: Copy-paste template without filling details

**Right**: Every ticket has:
- Specific file names from last/src/
- Exact line counts
- Complete function lists
- Verified dependency graph

---

## Summary: The 9-Step Process

1. ✅ Select old ticket
2. ✅ **Validate against last/src/** (line counts, APIs, dependencies)
3. ✅ Analyze dependencies (build graph, check order)
4. ✅ Map paths (old → last/ + current/)
5. ✅ Update commands (workspace-aware)
6. ✅ Add Golden Rule (with VERIFIED lists)
7. ✅ Add QS-Matrix (16 checks)
8. ✅ Add BBC English + Regression
9. ✅ Preserve & enhance implementation steps

**Time per ticket**: 30-60 minutes (depending on complexity)  
**Quality**: Consistent, verified, complete

---

## CLAUDE.md Integration

**Add to CLAUDE.md** (Essential Documentation section):

```markdown
### Ticket Creation Process

**⚠️ MANDATORY**: Before creating ANY ticket in `.workbench/tickets/`, read:

```bash
cat .workbench/tickets/PROCESS_LOGIC.md
```

This file contains the validated 9-step process for creating Clean Room tickets with complete parity, quality checks, and workspace structure.

**Key principle**: Never trust assumptions - always verify against `last/src/` code.
```

---

**Last Updated**: 2025-11-06  
**Version**: 1.0  
**Status**: Active - Read before EVERY ticket creation
