# 020-[STORE]-04: CSV Tables Implementation

**Created**: 2025-11-06  
**Phase**: 2 (Storage Layer)  
**Estimated Effort**: 2-3 hours  
**Dependencies**: None (standalone module)  
**Blocks**: Database layer, API layer

---

## Status
- [x] Not Started
- [ ] In Progress
- [ ] Complete

---

## 🚨 GOLDEN RULE: COMPLETE PARITY - NO SHORTCUTS

### Mandatory Pre-Implementation Analysis

**Verification Date**: 2025-11-06

- [x] **last/src/tables/ vollständig gelesen** - 4 Dateien analysiert
- [x] **Alle Typen identifiziert** - 4 structs (WriteResult, VersionInfo, CsvRow, TableStats)
- [x] **Alle Funktionen identifiziert** - 15 public functions (siehe unten)
- [x] **Keine Shortcuts geplant** - Bestätigung: Ich werde NICHTS weglassen
- [x] **Separate test files bestätigt** - csv_parser_test.rs, helpers_test.rs, table_test.rs
- [x] **Split-Strategie validiert** - table.rs 700 lines → 4 files <400 each

**Files in this ticket**:
```
last/src/tables/types.rs         68 lines  → current/src/store/tables/types.rs
last/src/tables/csv_parser.rs    98 lines  → current/src/store/tables/csv_parser.rs
last/src/tables/helpers.rs      199 lines  → current/src/store/tables/helpers.rs
last/src/tables/table.rs        700 lines  → current/src/store/tables/table*.rs (SPLIT 4!)
last/src/tables/mod.rs           61 lines  → current/src/store/tables/mod.rs
Total: 1126 lines → ~1150 lines (overhead for headers)
```

**Target Split for table.rs**:
```
table.rs              ~100 lines  (Core struct + paths)
table_read.rs         ~150 lines  (Read operations)
table_write.rs        ~250 lines  (Write + init operations)
table_version.rs      ~200 lines  (Versioning + rollback)
```

**Public Types** (MUST ALL BE COPIED):
```rust
// From types.rs (4 structs):
pub struct WriteResult {
    pub timestamp: u64,
    pub delta_size: u64,
    pub current_size: u64,
}

pub struct VersionInfo {
    pub timestamp: u64,
    pub action: String,
    pub user: String,
    pub delta_size: u64,
    pub message: Option<String>,
}

pub struct CsvRow {
    pub key: String,
    pub values: Vec<String>,
}

pub struct TableStats {
    pub name: String,
    pub current_size: u64,
    pub deltas_size: u64,
    pub version_count: usize,
    pub latest_version: u64,
    pub oldest_version: u64,
}
```

**Public Functions** (MUST ALL BE COPIED - 15 total):

**csv_parser.rs** (2 functions):
```rust
pub fn parse_csv(content: &[u8]) -> ReedResult<Vec<CsvRow>>
pub fn parse_csv_row(line: &str, line_num: usize) -> ReedResult<CsvRow>
```

**helpers.rs** (3 functions):
```rust
pub fn list_tables(base_path: &Path) -> ReedResult<Vec<String>>
pub fn table_exists(base_path: &Path, name: &str) -> bool
pub fn table_stats(base_path: &Path, name: &str) -> ReedResult<TableStats>
```

**table.rs - Table struct** (10 methods, split across 4 files):
```rust
// Core (table.rs):
pub fn new(base_path: &Path, name: &str) -> Self
pub fn current_path(&self) -> PathBuf
pub fn delta_path(&self, timestamp: u64) -> PathBuf
pub fn log_path(&self) -> PathBuf

// Read (table_read.rs):
pub fn exists(&self) -> bool
pub fn read_current(&self) -> ReedResult<Vec<u8>>
pub fn read_current_as_rows(&self) -> ReedResult<Vec<CsvRow>>

// Write (table_write.rs):
pub fn init(&self, initial_content: &[u8], user: &str) -> ReedResult<()>
pub fn write(&self, content: &[u8], user: &str) -> ReedResult<WriteResult>
pub fn read_modify_write<F>(&self, modify_fn: F, user: &str) -> ReedResult<WriteResult>
    where F: FnOnce(Vec<u8>) -> ReedResult<Vec<u8>>

// Version (table_version.rs):
pub fn list_versions(&self) -> ReedResult<Vec<VersionInfo>>
pub fn rollback(&self, timestamp: u64, user: &str) -> ReedResult<()>
pub fn delete(&self, confirm: bool) -> ReedResult<()>
```

**Test Status**:
- csv_parser.rs: ✅ csv_parser_test.rs (253 lines)
- helpers.rs: ✅ helpers_test.rs (247 lines)
- table.rs: ✅ table_test.rs (246 lines)

**Dependencies**:
```
External:
  - fs2::FileExt              (file locking)

Internal:
  - crate::error::{ReedError, ReedResult}
  - crate::registry::get_or_create_user_code  (user ID lookup)
  - super::csv_parser::parse_csv
  - super::types::{CsvRow, VersionInfo, WriteResult, TableStats}
```

**Verification Commands**:
```bash
# Verify line counts
wc -l last/src/tables/{types,csv_parser,helpers,table,mod}.rs
# Expected: 68, 98, 199, 700, 61

# Verify struct count
rg "^pub struct" last/src/tables/types.rs
# Expected: 4 structs

# Verify function counts
rg "^pub fn" last/src/tables/csv_parser.rs | wc -l
# Expected: 2

rg "^pub fn" last/src/tables/helpers.rs | wc -l
# Expected: 3

rg "^    pub fn" last/src/tables/table.rs | wc -l
# Expected: 13 methods

# Check dependencies
rg "^use " last/src/tables/table.rs | head -10
# Expected: fs2, crate::error, crate::registry, etc.
```

**Bestätigung**: Ich habe verstanden dass `last/src/tables/` die Spezifikation ist und `current/src/store/tables/` EXAKT identisch sein muss. table.rs MUSS gesplittet werden (700 lines → 4 files <400 each).

---

## Context & Scope

**This ticket implements**: Universal CSV table abstraction with versioning  
**From**: `last/src/tables/{types,csv_parser,helpers,table,mod}.rs`  
**To**: `current/src/store/tables/{types,csv_parser,helpers,table*.rs,mod.rs}`

**Why this module?**
- Core abstraction for ALL ReedBase tables (text, routes, meta, users)
- Provides versioning (Git-like history with binary deltas)
- Universal API: Same interface for all tables
- No dependencies on btree/ (standalone module)

**Critical: table.rs Split Strategy**:
```
table.rs (700 lines) splits into:

1. table.rs (~100 lines)
   - Table struct definition
   - new(), table_dir()
   - Path helpers: current_path(), delta_path(), log_path()

2. table_read.rs (~150 lines)
   - exists()
   - read_current()
   - read_current_as_rows()

3. table_write.rs (~250 lines)
   - init()
   - write()
   - read_modify_write()
   - Internal helper: create_delta()

4. table_version.rs (~200 lines)
   - list_versions()
   - rollback()
   - delete()
   - Internal helpers: parse_version_log(), append_version_log()
```

**What comes AFTER this ticket**:
- ✅ **Tables module COMPLETE** - Ready for use by database layer
- ➡️ **Next**: 020-[STORE]-05 (Smart Indices - uses tables for metadata)

**Dependency Graph**:
```
tables/ module:
  - No internal dependencies (standalone)
  - Uses: error (Phase 1), registry (external)
  - Used by: database/, api/ (later phases)
```

---

## Reference (Old Tickets)

**This ticket may reference**:
- Old analysis of tables/ module structure
- Versioning strategy documentation
- Delta compression decisions

**New ticket provides**:
- ✅ Golden Rule verification against actual last/src/ code
- ✅ table.rs split strategy (700 → ~700 across 4 files)
- ✅ QS-Matrix (16 checks)
- ✅ BBC English corrections
- ✅ Workspace structure
- ✅ Regression testing

---

## BBC English Corrections Required

**Issues found in last/src/tables/**:
```rust
// Comments use American English
"initialize" → "initialise"
"serialize" → "serialise"
"synchronized" → "synchronised"
```

**Action**: Fix ALL comments/docs to BBC English in current/

---

## Implementation Steps

### Step 1: Create File Structure (10 min)

**Create all files with copyright headers**:
```bash
cd current/src/store
mkdir -p tables

for file in types.rs csv_parser.rs helpers.rs table.rs table_read.rs table_write.rs table_version.rs mod.rs; do
  cat > tables/$file << 'EOF'
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

EOF
done
```

---

### Step 2: Implement types.rs (15 min)

**Reference**: `last/src/tables/types.rs` (68 lines - complete file)  
**Target**: `current/src/store/tables/types.rs`

**What to copy** (Golden Rule: EVERYTHING):
1. ✅ Complete file (68 lines, under 400 limit)
2. ✅ ALL 4 structs: WriteResult, VersionInfo, CsvRow, TableStats
3. ✅ ALL fields in each struct
4. ✅ Derive macros: Debug, Clone

**Changes**:
```rust
// No import changes needed (no internal dependencies)

// Fix BBC English in comments
```

**Verification**:
```bash
wc -l current/src/store/tables/types.rs
# Expected: ~68 lines

rg "^pub struct" current/src/store/tables/types.rs
# Expected: 4 structs

cargo check -p reedbase
```

---

### Step 3: Implement csv_parser.rs (20 min)

**Reference**: `last/src/tables/csv_parser.rs` (98 lines)  
**Target**: `current/src/store/tables/csv_parser.rs`

**What to copy**:
1. ✅ parse_csv() function
2. ✅ parse_csv_row() function
3. ✅ All error handling

**Changes**:
```rust
// Update imports
use crate::error::{ReedError, ReedResult};
use super::types::CsvRow;

// Fix BBC English
```

**Verification**:
```bash
wc -l current/src/store/tables/csv_parser.rs
# Expected: ~98 lines

rg "^pub fn" current/src/store/tables/csv_parser.rs
# Expected: 2 functions

cargo check -p reedbase
```

---

### Step 4: Implement helpers.rs (25 min)

**Reference**: `last/src/tables/helpers.rs` (199 lines)  
**Target**: `current/src/store/tables/helpers.rs`

**What to copy**:
1. ✅ list_tables() function
2. ✅ table_exists() function
3. ✅ table_stats() function
4. ✅ All internal helpers

**Changes**:
```rust
// Update imports
use crate::error::{ReedError, ReedResult};
use super::types::TableStats;

// Fix BBC English
```

**Verification**:
```bash
wc -l current/src/store/tables/helpers.rs
# Expected: ~199 lines

rg "^pub fn" current/src/store/tables/helpers.rs
# Expected: 3 functions

cargo check -p reedbase
```

---

### Step 5: Implement table.rs Core (30 min)

**Reference**: `last/src/tables/table.rs` lines 1-100 (approx)  
**Target**: `current/src/store/tables/table.rs` (~100 lines)

**What to extract**:
```rust
//! Universal table abstraction for ReedBase.

use crate::error::{ReedError, ReedResult};
use super::types::{CsvRow, VersionInfo, WriteResult};
use std::path::{Path, PathBuf};

/// Universal table abstraction.
pub struct Table {
    base_path: PathBuf,
    name: String,
}

impl Table {
    /// Creates new table reference.
    pub fn new(base_path: &Path, name: &str) -> Self {
        // Copy from last/
    }
    
    /// Gets path to table directory.
    fn table_dir(&self) -> PathBuf {
        // Copy from last/
    }
    
    /// Gets path to current.csv.
    pub fn current_path(&self) -> PathBuf {
        // Copy from last/
    }
    
    /// Gets path to delta file.
    pub fn delta_path(&self, timestamp: u64) -> PathBuf {
        // Copy from last/
    }
    
    /// Gets path to version.log.
    pub fn log_path(&self) -> PathBuf {
        // Copy from last/
    }
}
```

**Verification**:
```bash
wc -l current/src/store/tables/table.rs
# Expected: ~100 lines

rg "^    pub fn (new|current_path|delta_path|log_path)" current/src/store/tables/table.rs
# Expected: 4 methods

cargo check -p reedbase
```

---

### Step 6: Implement table_read.rs (30 min)

**Reference**: `last/src/tables/table.rs` read methods  
**Target**: `current/src/store/tables/table_read.rs` (~150 lines)

**What to extract**:
```rust
//! Table read operations.

use super::table::Table;
use super::types::CsvRow;
use super::csv_parser::parse_csv;
use crate::error::{ReedError, ReedResult};
use std::fs;

impl Table {
    /// Check if table exists.
    pub fn exists(&self) -> bool {
        // Copy from last/
    }
    
    /// Read current.csv as raw bytes.
    pub fn read_current(&self) -> ReedResult<Vec<u8>> {
        // Copy from last/
    }
    
    /// Read current.csv as parsed rows.
    pub fn read_current_as_rows(&self) -> ReedResult<Vec<CsvRow>> {
        // Copy from last/
    }
}
```

**Verification**:
```bash
wc -l current/src/store/tables/table_read.rs
# Expected: ~150 lines

cargo check -p reedbase
```

---

### Step 7: Implement table_write.rs (45 min)

**Reference**: `last/src/tables/table.rs` write methods  
**Target**: `current/src/store/tables/table_write.rs` (~250 lines)

**What to extract**:
```rust
//! Table write operations.

use super::table::Table;
use super::types::WriteResult;
use crate::error::{ReedError, ReedResult};
use crate::registry::get_or_create_user_code;
use fs2::FileExt;
use std::fs::{self, File, OpenOptions};
use std::io::Write;

impl Table {
    /// Initialise new table.
    pub fn init(&self, initial_content: &[u8], user: &str) -> ReedResult<()> {
        // Copy from last/
    }
    
    /// Write new version.
    pub fn write(&self, content: &[u8], user: &str) -> ReedResult<WriteResult> {
        // Copy from last/
    }
    
    /// Read-modify-write transaction.
    pub fn read_modify_write<F>(&self, modify_fn: F, user: &str) -> ReedResult<WriteResult>
    where
        F: FnOnce(Vec<u8>) -> ReedResult<Vec<u8>>,
    {
        // Copy from last/
    }
}

// Internal helper
fn create_delta(old: &[u8], new: &[u8]) -> ReedResult<Vec<u8>> {
    // Copy from last/
}
```

**Verification**:
```bash
wc -l current/src/store/tables/table_write.rs
# Expected: ~250 lines

cargo check -p reedbase
```

---

### Step 8: Implement table_version.rs (45 min)

**Reference**: `last/src/tables/table.rs` version methods  
**Target**: `current/src/store/tables/table_version.rs` (~200 lines)

**What to extract**:
```rust
//! Table version management.

use super::table::Table;
use super::types::VersionInfo;
use crate::error::{ReedError, ReedResult};
use std::fs;
use std::io::{BufRead, BufReader};

impl Table {
    /// List all versions.
    pub fn list_versions(&self) -> ReedResult<Vec<VersionInfo>> {
        // Copy from last/
    }
    
    /// Rollback to specific version.
    pub fn rollback(&self, timestamp: u64, user: &str) -> ReedResult<()> {
        // Copy from last/
    }
    
    /// Delete table completely.
    pub fn delete(&self, confirm: bool) -> ReedResult<()> {
        // Copy from last/
    }
}

// Internal helpers
fn parse_version_log(path: &Path) -> ReedResult<Vec<VersionInfo>> {
    // Copy from last/
}

fn append_version_log(path: &Path, entry: &VersionInfo) -> ReedResult<()> {
    // Copy from last/
}
```

**Verification**:
```bash
wc -l current/src/store/tables/table_version.rs
# Expected: ~200 lines

cargo check -p reedbase
```

---

### Step 9: Update mod.rs (15 min)

**Target**: `current/src/store/tables/mod.rs`

**Add modules**:
```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Universal table API for ReedBase.

pub mod types;
pub mod csv_parser;
pub mod helpers;
pub mod table;
mod table_read;
mod table_write;
mod table_version;

// Re-exports
pub use types::{CsvRow, TableStats, VersionInfo, WriteResult};
pub use csv_parser::{parse_csv, parse_csv_row};
pub use helpers::{list_tables, table_exists, table_stats};
pub use table::Table;
```

---

### Step 10: Adapt Tests (45 min)

**Reference**: `last/src/tables/*_test.rs`  
**Target**: `current/tests/store/tables/`

```bash
mkdir -p current/tests/store/tables

# Create test files
touch current/tests/store/tables/csv_parser_test.rs
touch current/tests/store/tables/helpers_test.rs
touch current/tests/store/tables/table_test.rs
```

**Adapt tests**:
- Update imports: `use reedbase::store::tables::...`
- Fix paths to test data if needed
- Verify all tests pass

---

### Step 11: Quality Verification (15 min)

```bash
# Run quality check on all files
for file in types.rs csv_parser.rs helpers.rs table.rs table_read.rs table_write.rs table_version.rs; do
  echo "Checking $file..."
  ./scripts/quality-check.sh current/src/store/tables/$file
done

# Run regression verification
./scripts/regression-verify.sh tables
```

---

### Step 12: Final Verification (15 min)

```bash
# Verify split successful (all files <400 lines)
echo "=== File Size Verification ==="
for file in types.rs csv_parser.rs helpers.rs table.rs table_read.rs table_write.rs table_version.rs; do
  lines=$(wc -l < current/src/store/tables/$file)
  if [ $lines -le 400 ]; then
    echo "✅ $file: $lines lines (under limit)"
  else
    echo "❌ $file: $lines lines (EXCEEDS LIMIT!)"
  fi
done

# Verify all functions present
echo ""
echo "=== Function Count Verification ==="
echo "csv_parser functions:"
rg "^pub fn" current/src/store/tables/csv_parser.rs | wc -l
echo "Expected: 2"

echo "helpers functions:"
rg "^pub fn" current/src/store/tables/helpers.rs | wc -l
echo "Expected: 3"

echo "Table methods:"
rg "^    pub fn" current/src/store/tables/table*.rs | wc -l
echo "Expected: 13 methods"

# Final test run
echo ""
echo "=== Final Test Run ==="
cargo test -p reedbase --lib store::tables
cargo test -p reedbase-last --lib tables
```

---

## ✅ Quality Assurance Matrix (MANDATORY)

### Pre-Implementation

- [x] **Golden Rule: last/ analysed completely**
  - [x] 4 source files validated (types, csv_parser, helpers, table)
  - [x] 15 public functions + 4 structs identified
  - [x] Split strategy: table.rs 700 → 4 files <400 each

- [x] **Standard #0: Code Reuse**
  - [x] Uses error types from Phase 1 ✅
  - [x] Uses registry::get_or_create_user_code ✅

- [x] **Standard #3: File Naming**
  - [x] Specific names: table_read, table_write, table_version ✅

- [x] **Standard #8: Architecture**
  - [x] Layered structure: store/tables/ ✅

### During Implementation

- [ ] **Standard #1: BBC English**
  - [ ] All comments fixed (initialise, serialise, synchronise)

- [ ] **Standard #4: Single Responsibility**
  - [ ] table.rs: Core struct + paths only ✅
  - [ ] table_read.rs: Read operations only ✅
  - [ ] table_write.rs: Write operations only ✅
  - [ ] table_version.rs: Version management only ✅

### Post-Implementation

- [ ] **Standard #2: File Size <400 Lines**
  - [ ] types.rs: 68 lines ✅
  - [ ] csv_parser.rs: 98 lines ✅
  - [ ] helpers.rs: 199 lines ✅
  - [ ] table.rs: ~100 lines ✅
  - [ ] table_read.rs: ~150 lines ✅
  - [ ] table_write.rs: ~250 lines ✅
  - [ ] table_version.rs: ~200 lines ✅

- [ ] **Standard #5: Separate Test Files**
  - [ ] csv_parser_test.rs in tests/ ✅
  - [ ] helpers_test.rs in tests/ ✅
  - [ ] table_test.rs in tests/ ✅

- [ ] **Regression: All Tests Passing**
  - [ ] `cargo test -p reedbase --lib store::tables` ✅
  - [ ] `cargo test -p reedbase-last --lib tables` ✅

---

## Success Criteria

### Functionality
- ✅ All 4 types implemented (WriteResult, VersionInfo, CsvRow, TableStats)
- ✅ All 15 functions/methods present
- ✅ table.rs split successful (700 → ~700 across 4 files)
- ✅ Versioning logic complete
- ✅ Tables module COMPLETE

### Quality
- ✅ All files <400 lines (split successful)
- ✅ BBC English everywhere (initialise, serialise, synchronise)
- ✅ Specific file names (table_read, table_write, not operations)
- ✅ Single responsibility per file
- ✅ No duplicates

### Regression
- ✅ All tests passing (csv_parser, helpers, table)
- ✅ Baseline unchanged (last/ tests still green)
- ✅ Behaviour identical (versioning works same way)

---

## Commit Message Template

```
[CLEAN-020-04] feat(store): implement CSV Tables with versioning

Phase 2 - Storage Layer - Ticket 4/6

✅ Golden Rule: Complete parity with last/src/tables/
✅ QS-Matrix: 16/16 checks passing (table.rs split successful!)
✅ Regression tests: X/X passing
✅ Behaviour: Identical to last/

Implementation:
- types.rs: 4 structs (WriteResult, VersionInfo, CsvRow, TableStats) - 68 lines
- csv_parser.rs: 2 functions (parse_csv, parse_csv_row) - 98 lines
- helpers.rs: 3 functions (list_tables, table_exists, table_stats) - 199 lines
- table.rs split (700 → ~700 lines across 4 files):
  - table.rs: Core struct + paths (~100 lines)
  - table_read.rs: exists, read_current, read_current_as_rows (~150 lines)
  - table_write.rs: init, write, read_modify_write (~250 lines)
  - table_version.rs: list_versions, rollback, delete (~200 lines)

Quality:
- KISS Standard #2: ALL files <400 lines ✅
- BBC English: All comments corrected (initialise, serialise, synchronise) ✅
- Specific names: table_read, table_write, table_version ✅
- Single responsibility: Each file ONE operation type ✅

Tables module COMPLETE:
- Universal API for all ReedBase tables
- Versioning with binary deltas (XZ compressed)
- Read/write/rollback operations
- Ready for use by database layer

Workspace packages:
- reedbase (current): Tables complete, X tests passing
- reedbase-last (last): Baseline unchanged, X tests passing
```

---

## Next Steps

**After this ticket**:
- ✅ **Tables module 100% COMPLETE** (universal table abstraction ready)
- ➡️ **Next**: 020-[STORE]-05 (Smart Indices - uses tables for metadata)

**Unblocked by this ticket**:
- Database layer can now manage tables
- API layer can read/write tables
- Versioning system available system-wide

---

**Validation Date**: 2025-11-06  
**Validated Against**: last/src/tables/{types,csv_parser,helpers,table,mod}.rs  
**Estimated Time**: 2-3 hours  
**Complexity**: Medium (split required, versioning logic, file I/O)
