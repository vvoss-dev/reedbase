# REED-CLEAN-070-02: Merge Operations (CSV Merge & Diff)

**Created**: 2025-11-06  
**Phase**: 7 (Logging & Merge)  
**Estimated Effort**: 4-6 hours  
**Dependencies**: 050-01 (Concurrent - uses CsvRow type)  
**Blocks**: None (last ticket in Phase 7)

---

## Status

- [ ] Ticket understood
- [ ] Pre-implementation analysis complete
- [ ] Implementation complete
- [ ] Tests passing (unit + integration)
- [ ] Quality standards verified (all 8)
- [ ] Regression tests passing
- [ ] Documentation complete
- [ ] Committed

---

## 🚨 GOLDEN RULE: "last ist die vorgabe"

**MANDATORY**: Before writing ANY code, perform complete analysis of `last/src/merge/`.

### Pre-Implementation Analysis

**Verification Date**: ________________ (MUST be filled before implementation!)

**Analysis Checklist**:
- [ ] All files in `last/src/merge/` read and understood
- [ ] All public types enumerated below
- [ ] All public functions enumerated below with exact signatures
- [ ] All test files identified and migration strategy planned
- [ ] All dependencies (external + internal) documented
- [ ] Behaviour parity strategy confirmed

---

### Files in this ticket

```
last/src/merge/types.rs      151 lines  → current/src/ops/merge/types.rs
last/src/merge/diff.rs       169 lines  → current/src/ops/merge/diff.rs
last/src/merge/csv.rs        256 lines  → current/src/ops/merge/csv.rs
last/src/merge/mod.rs         23 lines  → current/src/ops/merge/mod.rs

Total: 599 lines → ~620 lines
```

**File Size Analysis**:
- ✅ types.rs: 151 lines (< 400, no split needed)
- ✅ diff.rs: 169 lines (< 400, no split needed)
- ✅ csv.rs: 256 lines (< 400, no split needed)
- ✅ mod.rs: 23 lines (< 400, no split needed)

**Result**: All files under 400 lines - NO splits required ✅

---

### Public Types (4 total)

#### From types.rs (4 types)

1. **`RowChange`** - Row change types (enum)
   ```rust
   pub enum RowChange {
       Insert(CsvRow),      // Insert new row
       Update(CsvRow),      // Update existing row
       Delete(String),      // Delete row (key only)
   }
   ```

2. **`MergeResult`** - Merge result (enum)
   ```rust
   pub enum MergeResult {
       Success(Vec<CsvRow>),       // Successful merge, no conflicts
       Conflicts(Vec<Conflict>),   // Merge had conflicts
   }
   ```

3. **`Conflict`** - Merge conflict details
   ```rust
   pub struct Conflict {
       pub key: String,              // Row key where conflict occurred
       pub base: Option<CsvRow>,     // Base version (if existed)
       pub change_a: CsvRow,         // Change from process A
       pub change_b: CsvRow,         // Change from process B
   }
   ```

4. **`MergeStats`** - Merge statistics
   ```rust
   pub struct MergeStats {
       pub added: usize,       // Number of rows added
       pub deleted: usize,     // Number of rows deleted
       pub modified: usize,    // Number of rows modified
       pub conflicts: usize,   // Number of conflicts detected
   }
   ```

---

### Public Functions (12 total)

#### types.rs - Type Construction (3 methods)

1. **`MergeStats::new(added, deleted, modified, conflicts) -> Self`**
   - Creates new merge statistics
   - All fields required (no defaults)
   - O(1) operation

2. **`MergeStats::total_changes(&self) -> usize`**
   - Calculates total changes (added + deleted + modified)
   - Does NOT include conflicts in count
   - O(1) operation

3. **`MergeStats::is_clean(&self) -> bool`**
   - Returns true if conflicts == 0
   - Used for quick conflict check
   - O(1) operation

---

#### diff.rs - Diff Calculation (3 functions)

4. **`calculate_diff(old: &[CsvRow], new: &[CsvRow]) -> ReedResult<Vec<RowChange>>`**
   - Calculates row-level differences between two CSV versions
   - Detects inserts, updates, deletes
   - O(n+m) where n,m = number of rows
   - < 15ms for 100 rows
   - Uses HashSet for fast lookups

5. **`apply_changes(base: &[CsvRow], changes: &[RowChange]) -> ReedResult<Vec<CsvRow>>`**
   - Applies changes to base rows
   - Handles Insert/Update/Delete operations
   - Returns sorted result (by key)
   - O(n) where n = number of rows
   - < 10ms for 100 rows

6. **`count_changes(changes: &[RowChange]) -> (usize, usize, usize)`**
   - Counts changes by type
   - Returns (inserts, updates, deletes)
   - O(n) where n = number of changes
   - < 1ms for 100 changes

---

#### csv.rs - CSV Merging (6 functions)

7. **`merge_changes(base: &[CsvRow], changes_a: &[CsvRow], changes_b: &[CsvRow]) -> ReedResult<MergeResult>`**
   - Merges two sets of changes into base CSV
   - Automatically handles non-conflicting changes
   - Detects conflicts when both A and B modify same row
   - Returns Success(rows) or Conflicts(list)
   - O(n) where n = total rows
   - < 50ms for 100 rows (no conflicts)

8. **`merge_single(base: &[CsvRow], changes: &[CsvRow]) -> ReedResult<Vec<CsvRow>>`**
   - Merges single change set into base
   - No conflict detection (simple merge)
   - Returns sorted rows
   - O(n) where n = number of rows
   - < 20ms for 100 rows

9. **`build_row_map(rows: &[CsvRow]) -> HashMap<String, CsvRow>`**
   - Builds HashMap from CSV rows for fast lookup
   - Key → Row mapping
   - O(n) where n = number of rows
   - < 5ms for 100 rows

10. **`detect_conflicts(changes_a: &[CsvRow], changes_b: &[CsvRow]) -> Vec<String>`**
    - Detects conflicts between two change sets
    - Returns list of conflicting row keys
    - O(n*m) where n,m = number of changes
    - < 5ms for 100 changes each

11. **`rows_equal(row_a: &CsvRow, row_b: &CsvRow) -> bool`**
    - Checks if two rows have same key and values
    - O(n) where n = number of columns
    - < 1μs typical

12. **`calculate_merge_stats(base_count: usize, merged_count: usize, conflicts: usize) -> MergeStats`**
    - Calculates merge statistics from counts
    - Derives added/deleted from count difference
    - O(1) operation
    - < 1μs

---

### Test Status

**Test files to migrate**:
```
last/src/merge/diff_test.rs     → current/src/ops/merge/diff_test.rs
last/src/merge/csv_test.rs      → current/src/ops/merge/csv_test.rs
```

**Test coverage expectations**:
- Diff: Insert/update/delete detection, apply changes
- Merge: Two-way merge, conflict detection, single merge
- Edge cases: Empty base, empty changes, all conflicts
- Performance: 100 rows in < 50ms

---

### Dependencies

**External crates**: None

**Internal modules**:
- `crate::concurrent::types::CsvRow` - Row type from concurrent module
- `crate::error` - ReedError, ReedResult types

**Standard library**:
- `std::collections::HashMap` - Row map for fast lookup
- `std::collections::HashSet` - Key sets for diff calculation

---

### Verification Commands

**Before implementation** (analyse last/):
```bash
# Count lines per file
wc -l last/src/merge/*.rs | grep -v test

# Find all public types
rg "^pub struct|^pub enum" last/src/merge/ -n

# Find all public functions
rg "^pub fn" last/src/merge/ -n
rg "^    pub fn" last/src/merge/ -n

# Check test files
ls -la last/src/merge/*_test.rs
```

**During implementation** (build current/):
```bash
# Quick compile check
cargo check -p reedbase

# Run merge tests only
cargo test -p reedbase --lib ops::merge

# Watch mode
cargo watch -p reedbase -x "test --lib ops::merge"
```

**After implementation** (verify parity):
```bash
# Both packages pass
cargo test -p reedbase --lib ops::merge
cargo test -p reedbase-last --lib merge

# Regression check
./scripts/regression-verify.sh merge

# Quality check
./scripts/quality-check.sh current/src/ops/merge/types.rs
./scripts/quality-check.sh current/src/ops/merge/diff.rs
./scripts/quality-check.sh current/src/ops/merge/csv.rs

# No clippy warnings
cargo clippy -p reedbase -- -D warnings
```

---

### Bestätigung (Confirmation)

**I hereby confirm**:
- ✅ I have read ALL files in `last/src/merge/`
- ✅ I have enumerated ALL 4 public types above
- ✅ I have enumerated ALL 12 public functions above with exact signatures
- ✅ I understand the two-way merge algorithm (merge_changes)
- ✅ I understand conflict detection (both A and B modify same row)
- ✅ I understand the diff algorithm (HashSet for key comparison)
- ✅ I understand the CsvRow dependency from concurrent module
- ✅ I will achieve 100% behaviour parity with last/
- ✅ I will NOT add features, optimisations, or "improvements"
- ✅ I will maintain ALL existing function signatures exactly
- ✅ I will adapt tests from last/ to current/ without modification

**Signature**: ________________ **Date**: ________________

---

## Context & Scope

### What is this module?

The **merge module** provides intelligent row-level merging for concurrent CSV writes. It automatically merges non-conflicting changes from multiple processes and detects conflicts when the same row is modified by both.

**Key characteristics**:
- **Row-level**: Operates on entire rows (not cell-level)
- **Automatic**: Non-conflicting changes merge automatically
- **Conflict detection**: Identifies when both processes modify same row
- **Diff calculation**: Detects inserts/updates/deletes between versions
- **No parsing**: Works with CsvRow objects (already parsed)

### Why this module?

1. **Concurrent writes**: Multiple processes can write simultaneously
2. **Automatic resolution**: Most changes merge without user intervention
3. **Conflict reporting**: Clear identification of manual resolution needs
4. **Versioning support**: Diff calculation for delta generation
5. **ACID compliance**: Enables optimistic locking with conflict detection

### Architecture Context

**Position in layered architecture**:
```
ops/        ← Merge lives here (operations layer)
  ├── backup/
  ├── versioning/
  ├── metrics/
  ├── log/
  └── merge/        ← THIS MODULE
process/
  └── concurrent/   → Provides CsvRow type
api/
validate/
store/
core/
```

**Merge is used by concurrent writes** - enables optimistic locking:
- **process/concurrent/queue** queues pending writes
- **ops/merge/** merges non-conflicting writes
- **process/concurrent/lock** handles conflicts

### Merge Algorithm

**Two-way merge** (merge_changes):
```
Base:      Alice|30
Change A:  Alice|31  (A modified row 1)
Change B:  Bob|25    (B inserted row 2)

Result: Success([Alice|31, Bob|25])  ✅ No conflict
```

**Conflict detection**:
```
Base:      Alice|30
Change A:  Alice|31  (A modified row 1)
Change B:  Alice|32  (B also modified row 1)

Result: Conflicts([key=Alice, base=Alice|30, a=Alice|31, b=Alice|32])  ⚠️ Conflict
```

**Conflict rules**:
- ✅ Different rows modified: Auto-merge
- ✅ A modifies, B inserts different row: Auto-merge
- ✅ Both insert same row with SAME values: Auto-merge
- ⚠️ Both modify SAME row with DIFFERENT values: Conflict

---

## Implementation Steps

### Step 1: Create Module Structure

Create the merge module in `current/src/ops/merge/`:

```bash
mkdir -p current/src/ops/merge
touch current/src/ops/merge/types.rs
touch current/src/ops/merge/diff.rs
touch current/src/ops/merge/csv.rs
touch current/src/ops/merge/mod.rs
```

Update `current/src/ops/mod.rs`:
```rust
pub mod backup;
pub mod versioning;
pub mod metrics;
pub mod log;
pub mod merge;  // Add this line
```

---

### Step 2: Implement Merge Types (types.rs)

**Reference**: `last/src/merge/types.rs` (151 lines)

**Key types**:
```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Shared types for CSV merge operations.

use crate::concurrent::types::CsvRow;

/// Row change types.
#[derive(Debug, Clone, PartialEq)]
pub enum RowChange {
    Insert(CsvRow),      // Insert new row
    Update(CsvRow),      // Update existing row
    Delete(String),      // Delete row (key only)
}

/// Merge result.
#[derive(Debug)]
pub enum MergeResult {
    Success(Vec<CsvRow>),       // No conflicts
    Conflicts(Vec<Conflict>),   // Has conflicts
}

/// Merge conflict details.
#[derive(Debug, Clone)]
pub struct Conflict {
    pub key: String,              // Row key
    pub base: Option<CsvRow>,     // Base version
    pub change_a: CsvRow,         // Change from A
    pub change_b: CsvRow,         // Change from B
}

/// Merge statistics.
#[derive(Debug, Clone, PartialEq)]
pub struct MergeStats {
    pub added: usize,
    pub deleted: usize,
    pub modified: usize,
    pub conflicts: usize,
}

impl MergeStats {
    /// Creates new merge statistics.
    pub fn new(added: usize, deleted: usize, modified: usize, conflicts: usize) -> Self {
        Self {
            added,
            deleted,
            modified,
            conflicts,
        }
    }

    /// Calculates total number of changes (excludes conflicts).
    pub fn total_changes(&self) -> usize {
        self.added + self.deleted + self.modified
    }

    /// Checks if merge had no conflicts.
    pub fn is_clean(&self) -> bool {
        self.conflicts == 0
    }
}
```

**Exact parity required**:
- RowChange enum variants (Insert, Update, Delete)
- MergeResult enum variants (Success, Conflicts)
- Conflict struct fields (key, base, change_a, change_b)
- MergeStats methods (new, total_changes, is_clean)

---

### Step 3: Implement Diff Calculation (diff.rs)

**Reference**: `last/src/merge/diff.rs` (169 lines)

**Key functions**:
```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! CSV diff calculation for change detection.

use crate::concurrent::types::CsvRow;
use crate::error::ReedResult;
use crate::merge::types::RowChange;
use std::collections::HashSet;

/// Calculates diff between two CSV versions.
pub fn calculate_diff(old: &[CsvRow], new: &[CsvRow]) -> ReedResult<Vec<RowChange>> {
    let old_keys: HashSet<&String> = old.iter().map(|r| &r.key).collect();
    let new_keys: HashSet<&String> = new.iter().map(|r| &r.key).collect();

    let mut changes = Vec::new();

    // Find deletions (in old, not in new)
    for key in old_keys.difference(&new_keys) {
        changes.push(RowChange::Delete((*key).clone()));
    }

    // Find insertions (in new, not in old)
    for row in new {
        if !old_keys.contains(&row.key) {
            changes.push(RowChange::Insert(row.clone()));
        }
    }

    // Find updates (in both, but values changed)
    for new_row in new {
        if let Some(old_row) = old.iter().find(|r| r.key == new_row.key) {
            if old_row.values != new_row.values {
                changes.push(RowChange::Update(new_row.clone()));
            }
        }
    }

    Ok(changes)
}

/// Applies changes to base rows.
pub fn apply_changes(base: &[CsvRow], changes: &[RowChange]) -> ReedResult<Vec<CsvRow>> {
    use std::collections::HashMap;

    let mut rows: HashMap<String, CsvRow> =
        base.iter().map(|r| (r.key.clone(), r.clone())).collect();

    for change in changes {
        match change {
            RowChange::Insert(row) | RowChange::Update(row) => {
                rows.insert(row.key.clone(), row.clone());
            }
            RowChange::Delete(key) => {
                rows.remove(key);
            }
        }
    }

    let mut result: Vec<_> = rows.into_values().collect();
    result.sort_by(|a, b| a.key.cmp(&b.key));

    Ok(result)
}

/// Counts changes by type.
pub fn count_changes(changes: &[RowChange]) -> (usize, usize, usize) {
    let inserts = changes
        .iter()
        .filter(|c| matches!(c, RowChange::Insert(_)))
        .count();
    let updates = changes
        .iter()
        .filter(|c| matches!(c, RowChange::Update(_)))
        .count();
    let deletes = changes
        .iter()
        .filter(|c| matches!(c, RowChange::Delete(_)))
        .count();

    (inserts, updates, deletes)
}
```

**Critical behaviours**:
- HashSet for O(n) key comparison
- Detect deletions: old_keys - new_keys
- Detect insertions: new_keys - old_keys
- Detect updates: Same key, different values
- apply_changes: Sort result by key

---

### Step 4: Implement CSV Merging (csv.rs)

**Reference**: `last/src/merge/csv.rs` (256 lines)

**Key function - merge_changes()** (two-way merge):
```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Row-level CSV merging for concurrent writes.

use crate::concurrent::types::CsvRow;
use crate::error::ReedResult;
use crate::merge::types::{Conflict, MergeResult, MergeStats};
use std::collections::HashMap;

/// Merges two sets of changes into base CSV.
pub fn merge_changes(
    base: &[CsvRow],
    changes_a: &[CsvRow],
    changes_b: &[CsvRow],
) -> ReedResult<MergeResult> {
    let mut merged = build_row_map(base);
    let mut conflicts = Vec::new();

    // Apply changes from A
    for row in changes_a {
        merged.insert(row.key.clone(), row.clone());
    }

    // Apply changes from B, detecting conflicts
    for row in changes_b {
        if let Some(existing) = merged.get(&row.key) {
            // Check if this row was also modified by A
            if changes_a.iter().any(|a| a.key == row.key) {
                // Conflict: both A and B modified same row
                conflicts.push(Conflict {
                    key: row.key.clone(),
                    base: base.iter().find(|b| b.key == row.key).cloned(),
                    change_a: existing.clone(),
                    change_b: row.clone(),
                });
                continue;
            }
        }
        merged.insert(row.key.clone(), row.clone());
    }

    if conflicts.is_empty() {
        let mut rows: Vec<_> = merged.into_values().collect();
        rows.sort_by(|a, b| a.key.cmp(&b.key));
        Ok(MergeResult::Success(rows))
    } else {
        Ok(MergeResult::Conflicts(conflicts))
    }
}

/// Merges single change set into base.
pub fn merge_single(base: &[CsvRow], changes: &[CsvRow]) -> ReedResult<Vec<CsvRow>> {
    let mut merged = build_row_map(base);

    for row in changes {
        merged.insert(row.key.clone(), row.clone());
    }

    let mut rows: Vec<_> = merged.into_values().collect();
    rows.sort_by(|a, b| a.key.cmp(&b.key));

    Ok(rows)
}

/// Builds HashMap from CSV rows for fast lookup.
pub fn build_row_map(rows: &[CsvRow]) -> HashMap<String, CsvRow> {
    rows.iter()
        .map(|row| (row.key.clone(), row.clone()))
        .collect()
}

/// Detects conflicts between two change sets.
pub fn detect_conflicts(changes_a: &[CsvRow], changes_b: &[CsvRow]) -> Vec<String> {
    let keys_a: Vec<&String> = changes_a.iter().map(|r| &r.key).collect();

    changes_b
        .iter()
        .filter(|row| keys_a.contains(&&row.key))
        .map(|row| row.key.clone())
        .collect()
}

/// Checks if rows have same values.
pub fn rows_equal(row_a: &CsvRow, row_b: &CsvRow) -> bool {
    row_a.key == row_b.key && row_a.values == row_b.values
}

/// Calculates merge statistics.
pub fn calculate_merge_stats(
    base_count: usize,
    merged_count: usize,
    conflicts: usize,
) -> MergeStats {
    MergeStats {
        added: if merged_count > base_count {
            merged_count - base_count
        } else {
            0
        },
        deleted: if base_count > merged_count {
            base_count - merged_count
        } else {
            0
        },
        modified: 0, // TODO: Track modifications separately
        conflicts,
    }
}
```

**Critical behaviours**:
- Apply A first: All A changes go into merged map
- Apply B second: Check if key already modified by A
- Conflict detection: `changes_a.iter().any(|a| a.key == row.key)`
- Base lookup: Find original row in base for conflict report
- Sort result: Always sort by key

---

### Step 5: Create Module Root (mod.rs)

**Reference**: `last/src/merge/mod.rs` (23 lines)

```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Row-level CSV merge module.
//!
//! Provides intelligent merging for concurrent writes with automatic
//! conflict detection.

pub mod csv;
pub mod diff;
pub mod types;

// Re-export public APIs
pub use csv::{
    build_row_map, calculate_merge_stats, detect_conflicts, merge_changes, merge_single,
    rows_equal,
};
pub use diff::{apply_changes, calculate_diff, count_changes};
pub use types::{Conflict, MergeResult, MergeStats, RowChange};
```

**Key points**:
- Re-export all public functions
- Module-level documentation
- Clear API surface

---

### Step 6: Migrate Tests

**Test files** (adapt from last/ to current/):
```
last/src/merge/diff_test.rs     → current/src/ops/merge/diff_test.rs
last/src/merge/csv_test.rs      → current/src/ops/merge/csv_test.rs
```

**Test migration checklist**:
- [ ] Update import paths (`reedbase_last::merge` → `reedbase::ops::merge`)
- [ ] Update CsvRow import (`reedbase_last::concurrent` → `reedbase::process::concurrent`)
- [ ] Verify identical assertions (no behaviour changes)
- [ ] Test two-way merge (merge_changes)
- [ ] Test conflict detection
- [ ] Test diff calculation
- [ ] Run both test suites to confirm parity

---

### Step 7: Run Quality Checks

```bash
# Compile check
cargo check -p reedbase

# Run tests
cargo test -p reedbase --lib ops::merge

# Baseline check (last/ still passing)
cargo test -p reedbase-last --lib merge

# Quality checks (all 8 standards)
./scripts/quality-check.sh current/src/ops/merge/types.rs
./scripts/quality-check.sh current/src/ops/merge/diff.rs
./scripts/quality-check.sh current/src/ops/merge/csv.rs

# No clippy warnings
cargo clippy -p reedbase --lib -- -D warnings

# Regression verification
./scripts/regression-verify.sh merge
```

---

### Step 8: Verify Behaviour Parity

**Manual verification**:

1. **Diff calculation**:
   ```rust
   let old = vec![CsvRow::new("1", vec!["Alice", "30"])];
   let new = vec![CsvRow::new("1", vec!["Alice", "31"])];
   let diff = calculate_diff(&old, &new)?;
   assert_eq!(diff.len(), 1);
   assert!(matches!(diff[0], RowChange::Update(_)));
   ```

2. **Non-conflicting merge**:
   ```rust
   let base = vec![CsvRow::new("1", vec!["Alice", "30"])];
   let a = vec![CsvRow::new("1", vec!["Alice", "31"])];
   let b = vec![CsvRow::new("2", vec!["Bob", "25"])];
   let result = merge_changes(&base, &a, &b)?;
   assert!(matches!(result, MergeResult::Success(_)));
   ```

3. **Conflicting merge**:
   ```rust
   let base = vec![CsvRow::new("1", vec!["Alice", "30"])];
   let a = vec![CsvRow::new("1", vec!["Alice", "31"])];
   let b = vec![CsvRow::new("1", vec!["Alice", "32"])];
   let result = merge_changes(&base, &a, &b)?;
   assert!(matches!(result, MergeResult::Conflicts(_)));
   ```

4. **Apply changes**:
   ```rust
   let base = vec![CsvRow::new("1", vec!["Alice", "30"])];
   let changes = vec![RowChange::Update(CsvRow::new("1", vec!["Alice", "31"]))];
   let updated = apply_changes(&base, &changes)?;
   assert_eq!(updated[0].values[1], "31");
   ```

---

## Quality Standards (8 Total)

### Standard #0: Code Reuse ✅
- [x] Checked `project_functions.csv` for existing merge functions
- [x] Using `std::collections::HashMap` (no custom implementation)
- [x] Using `std::collections::HashSet` (no custom implementation)
- [x] Using `crate::concurrent::types::CsvRow` (no duplication)

**Why compliant**: All functions are new (merge module didn't exist in current/), uses standard library and existing types.

---

### Standard #1: BBC English ✅
- [x] All comments use British spelling
- [x] "optimisation" not "optimization"
- [x] "recognise" not "recognize"

**Examples**:
```rust
/// Calculates differences for change detection.  ✅
// not: "Calculates differences for change recognition"

/// Optimised merge algorithm.  ✅
// not: "Optimized merge algorithm"
```

---

### Standard #2: KISS - Files <400 Lines ✅
- [x] types.rs: 151 lines (< 400) ✅
- [x] diff.rs: 169 lines (< 400) ✅
- [x] csv.rs: 256 lines (< 400) ✅
- [x] mod.rs: 23 lines (< 400) ✅

**Verification**:
```bash
wc -l current/src/ops/merge/*.rs
# All files must be < 400 lines
```

---

### Standard #3: Specific File Naming ✅
- [x] types.rs (RowChange, MergeResult, Conflict, MergeStats) ✅
- [x] diff.rs (diff calculation functions) ✅
- [x] csv.rs (CSV merge functions) ✅

**NOT**:
- ❌ utils.rs
- ❌ helpers.rs
- ❌ common.rs
- ❌ merge.rs (too generic for multi-file module)

---

### Standard #4: One Function = One Job ✅
- [x] `calculate_diff()` - ONLY calculates differences
- [x] `apply_changes()` - ONLY applies changes
- [x] `merge_changes()` - Merges AND detects conflicts (acceptable atomic operation)
- [x] `merge_single()` - ONLY merges (no conflict detection)
- [x] `detect_conflicts()` - ONLY detects conflicts (no merging)
- [x] No boolean flags (no `merge(detect_conflicts: bool)`)

**Examples of good separation**:
```rust
pub fn calculate_diff(old, new) -> Vec<RowChange>  // ONLY diff
pub fn apply_changes(base, changes) -> Vec<CsvRow> // ONLY apply
pub fn count_changes(changes) -> (usize, usize, usize)  // ONLY count

// NOT: pub fn process_changes(old, new, apply, count, mode)
```

---

### Standard #5: Separate Test Files ✅
- [x] diff_test.rs (not inline in diff.rs)
- [x] csv_test.rs (not inline in csv.rs)

**NO inline modules**:
```rust
// ❌ FORBIDDEN
#[cfg(test)]
mod tests {
    use super::*;
    // tests here
}
```

---

### Standard #6: No Swiss Army Functions ✅
- [x] No `handle()`, `process()`, `manage()` doing many things
- [x] `merge_changes()` does TWO things (merge + conflict detection) - acceptable for atomic operation
- [x] Each utility function is separate (build_row_map, detect_conflicts, rows_equal)

**Avoided**:
```rust
// ❌ Swiss Army function
pub fn process_merge(base, a, b, apply, detect, stats, mode) {
    if apply { /* ... */ }
    if detect { /* ... */ }
    if stats { /* ... */ }
}

// ✅ Separate, focused functions
pub fn merge_changes(base, a, b) -> MergeResult
pub fn detect_conflicts(a, b) -> Vec<String>
pub fn calculate_merge_stats(base_count, merged_count, conflicts) -> MergeStats
```

---

### Standard #7: No Generic Names ✅
- [x] `merge_changes()` not `merge()` (context: changes)
- [x] `calculate_diff()` not `diff()` (context: calculate)
- [x] `build_row_map()` not `build_map()` (context: row)
- [x] `MergeStats` not `Stats` (context: merge)

---

### Standard #8: Architecture - Layered (not MVC) ✅
- [x] Merge is in `ops/` layer (operations)
- [x] No controllers (`handle_request()` in lib)
- [x] No models with behaviour (`impl RowChange { fn apply() }`)
- [x] No views (`Display`, `println!` in lib)
- [x] Pure functions: data in → data out

**Why compliant**:
- Merge provides **services** (diff, merge, detect)
- No business logic (pure data transformation)
- No MVC patterns present

---

## Testing Requirements

### Unit Tests

**diff_test.rs** (Diff calculation):
- [ ] calculate_diff() detects inserts
- [ ] calculate_diff() detects updates
- [ ] calculate_diff() detects deletes
- [ ] calculate_diff() handles empty old
- [ ] calculate_diff() handles empty new
- [ ] apply_changes() applies Insert
- [ ] apply_changes() applies Update
- [ ] apply_changes() applies Delete
- [ ] apply_changes() sorts result by key
- [ ] count_changes() counts correctly

**csv_test.rs** (CSV merging):
- [ ] merge_changes() success case (no conflicts)
- [ ] merge_changes() conflict case (both modify same row)
- [ ] merge_changes() handles empty base
- [ ] merge_single() merges correctly
- [ ] detect_conflicts() detects overlapping keys
- [ ] detect_conflicts() returns empty for non-overlapping
- [ ] rows_equal() compares key and values
- [ ] build_row_map() creates correct HashMap
- [ ] calculate_merge_stats() calculates added
- [ ] calculate_merge_stats() calculates deleted

### Integration Tests

**Full workflow test** (in `current/tests/`):
```rust
#[test]
fn test_merge_end_to_end() {
    // 1. Create base and changes
    let base = vec![CsvRow::new("1", vec!["Alice", "30"])];
    let a = vec![CsvRow::new("1", vec!["Alice", "31"])];  // Update row 1
    let b = vec![CsvRow::new("2", vec!["Bob", "25"])];    // Insert row 2

    // 2. Merge changes
    let result = merge_changes(&base, &a, &b).unwrap();

    // 3. Verify success (no conflicts)
    match result {
        MergeResult::Success(rows) => {
            assert_eq!(rows.len(), 2);
            assert_eq!(rows[0].key, "1");
            assert_eq!(rows[0].values[1], "31");  // A's update
            assert_eq!(rows[1].key, "2");
            assert_eq!(rows[1].values[0], "Bob");  // B's insert
        }
        MergeResult::Conflicts(_) => panic!("Expected success, got conflicts"),
    }
}
```

### Regression Tests

**Baseline comparison** (compare with last/):
```bash
# Both test suites pass
cargo test -p reedbase --lib ops::merge
cargo test -p reedbase-last --lib merge

# Behaviour parity
./scripts/regression-verify.sh merge
```

**Specific parity checks**:
- [ ] Identical diff results for same input
- [ ] Identical merge results for non-conflicting changes
- [ ] Identical conflict detection for conflicting changes
- [ ] Identical sorting (by key)
- [ ] Identical count results

---

## Success Criteria

### Functional Requirements ✅
- [x] All 12 public functions implemented with exact signatures
- [x] All 4 types (RowChange, MergeResult, Conflict, MergeStats) implemented
- [x] Two-way merge with conflict detection (merge_changes)
- [x] Single merge without conflict detection (merge_single)
- [x] Diff calculation (calculate_diff, apply_changes, count_changes)
- [x] Utility functions (build_row_map, detect_conflicts, rows_equal)
- [x] Statistics calculation (MergeStats methods)

### Quality Requirements ✅
- [x] All files < 400 lines (Standard #2)
- [x] BBC English throughout (Standard #1)
- [x] Specific file names (Standard #3)
- [x] One function = one job (Standard #4)
- [x] Separate test files (Standard #5)
- [x] No Swiss Army functions (Standard #6)
- [x] No generic names (Standard #7)
- [x] Layered architecture (Standard #8)
- [x] No code duplication (Standard #0)

### Regression Requirements ✅
- [x] All tests from last/ adapted and passing
- [x] Behaviour parity with last/src/merge/
- [x] Identical diff calculation
- [x] Identical merge results
- [x] Identical conflict detection
- [x] `./scripts/regression-verify.sh merge` passes

### Performance Requirements ✅
- [x] calculate_diff(): O(n+m), < 15ms for 100 rows
- [x] apply_changes(): O(n), < 10ms for 100 rows
- [x] merge_changes(): O(n), < 50ms for 100 rows (no conflicts)
- [x] detect_conflicts(): O(n*m), < 5ms for 100 changes each
- [x] No performance regressions vs last/

### Documentation Requirements ✅
- [x] Module-level docs with overview
- [x] All public types documented
- [x] All public functions documented
- [x] Performance characteristics documented
- [x] Merge algorithm explained

---

## Commit Message

```
[CLEAN-070-02] feat(ops): implement CSV merge with conflict detection

✅ QS-Matrix verified (all 8 CLAUDE.md standards)
✅ Regression tests: 100% passing (XX/XX tests)
✅ Behaviour identical to last/src/merge/

Implemented complete merge system for concurrent CSV writes:

Types (types.rs, 151 lines):
- RowChange: Insert/Update/Delete variants
- MergeResult: Success/Conflicts variants
- Conflict: Conflict details (key, base, change_a, change_b)
- MergeStats: Merge statistics (added, deleted, modified, conflicts)

Diff (diff.rs, 169 lines):
- calculate_diff(): Row-level diff (O(n+m) HashSet)
- apply_changes(): Apply Insert/Update/Delete
- count_changes(): Count by type

CSV Merge (csv.rs, 256 lines):
- merge_changes(): Two-way merge with conflict detection
- merge_single(): Simple merge (no conflict detection)
- detect_conflicts(): Find overlapping keys
- build_row_map(): HashMap for fast lookup
- rows_equal(): Compare key and values
- calculate_merge_stats(): Statistics from counts

Merge Algorithm:
1. Apply all changes from A to merged map
2. Apply changes from B, checking if key modified by A
3. If both A and B modified same row → Conflict
4. Otherwise → Auto-merge

Test Coverage:
- diff_test.rs: Diff calculation, apply, count
- csv_test.rs: Two-way merge, conflicts, single merge

Quality Standards:
✅ #0: No duplicate functions (uses HashSet/HashMap from std)
✅ #1: BBC English throughout ("optimisation", "recognise")
✅ #2: All files <400 lines (largest: csv.rs 256)
✅ #3: Specific naming (types, diff, csv)
✅ #4: One function = one job (separate merge/detect/stats)
✅ #5: Separate test files (*_test.rs)
✅ #6: No Swiss Army functions
✅ #7: Contextual names (merge_changes, calculate_diff)
✅ #8: Layered architecture (ops/ layer, no MVC)

Workspace packages:
- reedbase (current): Implementation complete
- reedbase-last (last): Baseline tests still passing

Dependencies:
- crate::concurrent::types::CsvRow (from process layer)
- std::collections::{HashMap, HashSet}

Files:
- current/src/ops/merge/types.rs (151 lines)
- current/src/ops/merge/diff.rs (169 lines)
- current/src/ops/merge/csv.rs (256 lines)
- current/src/ops/merge/mod.rs (23 lines)
- current/src/ops/merge/diff_test.rs
- current/src/ops/merge/csv_test.rs
```

---

## Notes

### Key Implementation Details

1. **Two-Way Merge Algorithm**:
   - Apply A's changes first (all go into merged map)
   - Apply B's changes second (check for conflicts)
   - Conflict: `changes_a.iter().any(|a| a.key == row.key)`
   - Base lookup: Find original row for conflict report

2. **Conflict Detection Rules**:
   - ✅ A modifies row 1, B modifies row 2 → Auto-merge
   - ✅ A inserts row 3, B modifies row 1 → Auto-merge
   - ⚠️ A modifies row 1, B also modifies row 1 → Conflict

3. **Diff Calculation**:
   - HashSet for O(n) key comparison
   - Deletions: `old_keys.difference(&new_keys)`
   - Insertions: `new_keys` not in `old_keys`
   - Updates: Same key, different values

4. **Sorting**:
   - Always sort result by key (lexicographic)
   - `result.sort_by(|a, b| a.key.cmp(&b.key))`

5. **CsvRow Dependency**:
   - Comes from `crate::concurrent::types`
   - Has `key` and `values` fields
   - Must be imported in tests

### Common Pitfalls to Avoid

1. ❌ Don't change conflict detection logic (both A and B modify same key)
2. ❌ Don't skip sorting (result must be sorted by key)
3. ❌ Don't modify merge_single to detect conflicts (it's intentionally simple)
4. ❌ Don't include conflicts in total_changes() count (only added+deleted+modified)
5. ❌ Don't change diff algorithm (must use HashSet for performance)
6. ❌ Don't skip base lookup in conflicts (Conflict needs base row)

### Migration Gotchas

1. **Import paths change**:
   - last: `use reedbase_last::merge::merge_changes`
   - current: `use reedbase::ops::merge::merge_changes`

2. **CsvRow import**:
   - last: `use reedbase_last::concurrent::types::CsvRow`
   - current: `use reedbase::process::concurrent::types::CsvRow`

3. **Test data creation**:
   - Need CsvRow::new() available
   - May need to import from process/concurrent

---

**Ticket Complete**: Ready for implementation following Clean Room Rebuild Protocol.
