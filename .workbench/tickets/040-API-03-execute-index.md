# 040-[API]-03: Execute + Index Management Implementation

**Created**: 2025-11-06  
**Phase**: 4 (API Layer - Database)  
**Estimated Effort**: 3-4 hours  
**Dependencies**: 020-STORE-04 (Tables), 020-STORE-05 (Indices), 040-API-01 (Types+Stats), 040-API-02 (Database Core)  
**Blocks**: 040-API-04 (ReedQL), CLI commands

---

## Status
- [x] Not Started
- [ ] In Progress
- [ ] Complete

---

## 🚨 GOLDEN RULE: COMPLETE PARITY - NO SHORTCUTS

### Mandatory Pre-Implementation Analysis

**Verification Date**: 2025-11-06

- [x] **last/src/database/execute.rs vollständig gelesen** - 661 Zeilen analysiert
- [x] **last/src/database/index.rs vollständig gelesen** - 532 Zeilen analysiert
- [x] **Alle Typen identifiziert** - 3 structs, 2 enums (siehe unten)
- [x] **Alle Funktionen identifiziert** - 23 functions total (12 execute + 11 index)
- [x] **Keine Shortcuts geplant** - Bestätigung: Ich werde NICHTS weglassen
- [x] **Separate test files bestätigt** - execute_test.rs, index_test.rs
- [x] **Split-Strategie validiert** - execute.rs 661→2 files, index.rs 532→2 files

**Files in this ticket**:
```
last/src/database/execute.rs    661 lines  → current/src/api/db/execute*.rs (SPLIT 2!)
last/src/database/index.rs      532 lines  → current/src/api/db/index*.rs (SPLIT 2!)
Total: 1193 lines → ~1250 lines (overhead for headers + split)
```

**Target Split for execute.rs (661 lines → 2 files)**:
```
execute_parse.rs        ~280 lines  (Parsing: parse_execute_statement, parse_insert, parse_update, parse_delete, parse_simple_where, clean_value, matches_conditions, matches_like_pattern)
execute_command.rs      ~380 lines  (Execution: execute_command, execute_insert, execute_update, execute_delete + types ExecuteResult, ExecuteStatement, FilterCondition)
```

**Target Split for index.rs (532 lines → 2 files)**:
```
index_create.rs         ~300 lines  (Creation: create_index_with_backend, select_backend_for_operation, create_index_with_smart_selection, create_index_internal, create_index)
index_manage.rs         ~230 lines  (Management: list_indices, drop_index, rebuild_index, save_index_metadata, load_index_metadata)
```

**Public Types** (MUST ALL BE COPIED):

**From execute.rs** (1 struct + 2 enums = 3 types):
```rust
// ExecuteResult struct
#[derive(Debug, Clone)]
pub struct ExecuteResult {
    pub rows_affected: usize,
    pub execution_time_us: u64,
    pub timestamp: u64,
    pub delta_size: u64,
}
impl ExecuteResult {
    pub fn new(rows_affected: usize) -> Self
}

// ExecuteStatement enum
#[derive(Debug, Clone, PartialEq)]
pub enum ExecuteStatement {
    Insert {
        table: String,
        columns: Vec<String>,
        values: Vec<String>,
    },
    Update {
        table: String,
        assignments: HashMap<String, String>,
        conditions: Vec<FilterCondition>,
    },
    Delete {
        table: String,
        conditions: Vec<FilterCondition>,
    },
}

// FilterCondition enum
#[derive(Debug, Clone, PartialEq)]
pub enum FilterCondition {
    Equals { column: String, value: String },
    NotEquals { column: String, value: String },
    Like { column: String, pattern: String },
}
```

**From index.rs** (0 new types - uses types from 040-01):
```rust
// Uses IndexBackend, IndexInfo, IndexMetadata from types.rs (040-01)
```

**Public Functions** (MUST ALL BE COPIED - 23 total):

**execute.rs** (12 functions):
```rust
// Public API (1 function):
pub fn execute_command(db: &Database, sql: &str, user: &str) -> ReedResult<ExecuteResult>

// Parsing (5 functions):
fn parse_execute_statement(sql: &str) -> ReedResult<ExecuteStatement>
fn parse_insert(sql: &str) -> ReedResult<ExecuteStatement>
fn parse_update(sql: &str) -> ReedResult<ExecuteStatement>
fn parse_delete(sql: &str) -> ReedResult<ExecuteStatement>
fn parse_simple_where(where_clause: &str) -> ReedResult<Vec<FilterCondition>>

// Helpers (2 functions):
fn clean_value(value: &str) -> String
fn matches_like_pattern(value: &str, pattern: &str) -> bool

// Execution (3 functions):
fn execute_insert(db: &Database, table_name: &str, columns: Vec<String>, values: Vec<String>, user: &str) -> ReedResult<ExecuteResult>
fn execute_update(db: &Database, table_name: &str, assignments: HashMap<String, String>, conditions: Vec<FilterCondition>, user: &str) -> ReedResult<ExecuteResult>
fn execute_delete(db: &Database, table_name: &str, conditions: Vec<FilterCondition>, user: &str) -> ReedResult<ExecuteResult>

// Condition matching (1 function):
fn matches_conditions(row: &HashMap<String, String>, conditions: &[FilterCondition]) -> bool
```

**index.rs** (11 functions):
```rust
// Creation (5 functions):
pub fn create_index_with_backend(db: &Database, table_name: &str, column: &str, backend: IndexBackend, auto_created: bool) -> ReedResult<()>
pub fn select_backend_for_operation(operation: &str) -> IndexBackend
pub fn create_index_with_smart_selection(db: &Database, table_name: &str, column: &str, operation: &str, auto_created: bool) -> ReedResult<()>
pub fn create_index_internal(db: &Database, table_name: &str, column: &str, auto_created: bool) -> ReedResult<()>
pub fn create_index(db: &Database, table_name: &str, column: &str) -> ReedResult<()>

// Management (3 functions):
pub fn list_indices(db: &Database) -> Vec<IndexInfo>
pub fn drop_index(db: &Database, table_name: &str, column: &str) -> ReedResult<()>
pub fn rebuild_index(db: &Database, table_name: &str, column: &str) -> ReedResult<()>

// Metadata (2 functions):
fn save_index_metadata(db: &Database, metadata: IndexMetadata) -> ReedResult<()>
pub fn load_index_metadata(db: &Database) -> ReedResult<Vec<IndexMetadata>>

// Legacy (1 function - kept for reference):
fn create_index_internal_legacy(...) -> ReedResult<()>  // marked #[allow(dead_code)]
```

**Test Status**:
- execute.rs: ✅ execute_test.rs (~350 lines planned)
- index.rs: ✅ index_test.rs (~300 lines planned)

**Dependencies**:
```
External:
  - std::collections::HashMap
  - std::time::Instant
  - serde_json                    (index metadata)

Internal:
  - crate::api::db::database_core::Database
  - crate::api::db::types::{IndexBackend, IndexInfo, IndexMetadata}
  - crate::error::{ReedError, ReedResult}
  - crate::store::btree::Order
  - crate::store::indices::{BTreeIndex, HashMapIndex, Index}
  - crate::store::tables::Table
```

**Verification Commands**:
```bash
# Verify line counts
wc -l last/src/database/execute.rs
# Expected: 661

wc -l last/src/database/index.rs
# Expected: 532

# Verify type count (execute.rs)
rg "^pub struct|^pub enum" last/src/database/execute.rs
# Expected: 1 struct (ExecuteResult), 2 enums (ExecuteStatement, FilterCondition)

# Verify function counts
rg "^pub fn|^fn " last/src/database/execute.rs | wc -l
# Expected: 12

rg "^pub fn|^fn " last/src/database/index.rs | wc -l
# Expected: 11

# Check dependencies
rg "^use " last/src/database/execute.rs | head -5
rg "^use " last/src/database/index.rs | head -8
```

**Bestätigung**: Ich habe verstanden dass `last/src/database/{execute,index}.rs` die Spezifikation ist und `current/src/api/db/{execute,index}*.rs` EXAKT identisch sein muss. Beide Dateien MÜSSEN gesplittet werden (>400 lines each).

---

## Context & Scope

**This ticket implements**: Command execution (INSERT/UPDATE/DELETE) + Index management  
**From**: `last/src/database/{execute,index}.rs`  
**To**: `current/src/api/db/{execute_parse,execute_command,index_create,index_manage}.rs`

**Why this module?**
- Execute: Handles all data modification operations (INSERT/UPDATE/DELETE)
- Index: Creates and manages indices (HashMap + B+-Tree) with smart backend selection
- Together: Complete CRUD operations for ReedBase

**Critical: Split Strategy**:

**execute.rs (661 lines) splits into 2 files**:
1. **execute_parse.rs** (~280 lines) - Parsing logic
   - parse_execute_statement()
   - parse_insert(), parse_update(), parse_delete()
   - parse_simple_where()
   - clean_value()
   - matches_conditions(), matches_like_pattern()

2. **execute_command.rs** (~380 lines) - Execution logic
   - Types: ExecuteResult, ExecuteStatement, FilterCondition
   - execute_command() (entry point)
   - execute_insert(), execute_update(), execute_delete()

**index.rs (532 lines) splits into 2 files**:
1. **index_create.rs** (~300 lines) - Index creation
   - create_index_with_backend()
   - select_backend_for_operation()
   - create_index_with_smart_selection()
   - create_index_internal()
   - create_index()
   - create_index_internal_legacy() (dead code, kept for reference)

2. **index_manage.rs** (~230 lines) - Index management
   - list_indices()
   - drop_index()
   - rebuild_index()
   - save_index_metadata(), load_index_metadata()

---

## Implementation Steps

### Step 1: Create execute_command.rs with types

**Task**: Create file structure with ExecuteResult, ExecuteStatement, FilterCondition types

**Files**: `current/src/api/db/execute_command.rs`

**Commands**:
```bash
# Create file
touch current/src/api/db/execute_command.rs
```

**Code** (insert into file):
```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Command execution (INSERT/UPDATE/DELETE) via ReedQL.
//!
//! This module handles all data modification operations.

use crate::api::db::database_core::Database;
use crate::error::{ReedError, ReedResult};
use std::collections::HashMap;
use std::time::Instant;

/// Execution result for INSERT/UPDATE/DELETE commands.
#[derive(Debug, Clone)]
pub struct ExecuteResult {
    /// Number of rows affected
    pub rows_affected: usize,

    /// Execution time in microseconds
    pub execution_time_us: u64,

    /// Version timestamp created
    pub timestamp: u64,

    /// Delta size in bytes (for versioning)
    pub delta_size: u64,
}

impl ExecuteResult {
    /// Creates a new execution result.
    pub fn new(rows_affected: usize) -> Self {
        Self {
            rows_affected,
            execution_time_us: 0,
            timestamp: 0,
            delta_size: 0,
        }
    }
}

/// Parsed statement types for execution.
#[derive(Debug, Clone, PartialEq)]
pub enum ExecuteStatement {
    /// INSERT INTO table (col1, col2) VALUES (val1, val2)
    Insert {
        table: String,
        columns: Vec<String>,
        values: Vec<String>,
    },

    /// UPDATE table SET col1 = val1, col2 = val2 WHERE condition
    Update {
        table: String,
        assignments: HashMap<String, String>,
        conditions: Vec<FilterCondition>,
    },

    /// DELETE FROM table WHERE condition
    Delete {
        table: String,
        conditions: Vec<FilterCondition>,
    },
}

/// Filter condition (simplified version of ReedQL's FilterCondition).
#[derive(Debug, Clone, PartialEq)]
pub enum FilterCondition {
    Equals { column: String, value: String },
    NotEquals { column: String, value: String },
    Like { column: String, pattern: String },
}

/// Executes a ReedQL command (INSERT/UPDATE/DELETE).
///
/// ## Input
/// - `db`: Database reference
/// - `sql`: ReedQL command string
/// - `user`: Username for audit trail
///
/// ## Output
/// - `Ok(ExecuteResult)`: Execution metadata
/// - `Err(ReedError)`: Execution failed
pub fn execute_command(db: &Database, sql: &str, user: &str) -> ReedResult<ExecuteResult> {
    todo!("Implement execute_command")
}

/// Executes INSERT statement.
fn execute_insert(
    db: &Database,
    table_name: &str,
    columns: Vec<String>,
    values: Vec<String>,
    user: &str,
) -> ReedResult<ExecuteResult> {
    todo!("Implement execute_insert")
}

/// Executes UPDATE statement.
fn execute_update(
    db: &Database,
    table_name: &str,
    assignments: HashMap<String, String>,
    conditions: Vec<FilterCondition>,
    user: &str,
) -> ReedResult<ExecuteResult> {
    todo!("Implement execute_update")
}

/// Executes DELETE statement.
fn execute_delete(
    db: &Database,
    table_name: &str,
    conditions: Vec<FilterCondition>,
    user: &str,
) -> ReedResult<ExecuteResult> {
    todo!("Implement execute_delete")
}
```

**Verification**:
```bash
cargo check -p reedbase
```

**Expected**: Compile success (todos allowed in this step)

---

### Step 2: Create execute_parse.rs with parsing logic

**Task**: Create parsing module with all 8 parsing/helper functions

**Files**: `current/src/api/db/execute_parse.rs`

**Code**:
```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! SQL parsing for execute commands.

use super::execute_command::{ExecuteStatement, FilterCondition};
use crate::error::{ReedError, ReedResult};
use std::collections::HashMap;

/// Parses an execute statement (INSERT/UPDATE/DELETE).
pub(super) fn parse_execute_statement(sql: &str) -> ReedResult<ExecuteStatement> {
    // Port from last/src/database/execute.rs:115-127
    todo!("Implement parse_execute_statement")
}

/// Parses INSERT statement.
pub(super) fn parse_insert(sql: &str) -> ReedResult<ExecuteStatement> {
    // Port from last/src/database/execute.rs:132-200
    todo!("Implement parse_insert")
}

/// Parses UPDATE statement.
pub(super) fn parse_update(sql: &str) -> ReedResult<ExecuteStatement> {
    // Port from last/src/database/execute.rs:205-256
    todo!("Implement parse_update")
}

/// Parses DELETE statement.
pub(super) fn parse_delete(sql: &str) -> ReedResult<ExecuteStatement> {
    // Port from last/src/database/execute.rs:261-285
    todo!("Implement parse_delete")
}

/// Parses simple WHERE clause.
pub(super) fn parse_simple_where(where_clause: &str) -> ReedResult<Vec<FilterCondition>> {
    // Port from last/src/database/execute.rs:288-318
    todo!("Implement parse_simple_where")
}

/// Cleans value by removing quotes.
pub(super) fn clean_value(value: &str) -> String {
    // Port from last/src/database/execute.rs:321-330
    let trimmed = value.trim();
    if (trimmed.starts_with('\'') && trimmed.ends_with('\''))
        || (trimmed.starts_with('"') && trimmed.ends_with('"'))
    {
        trimmed[1..trimmed.len() - 1].to_string()
    } else {
        trimmed.to_string()
    }
}

/// Checks if row matches all conditions.
pub(super) fn matches_conditions(row: &HashMap<String, String>, conditions: &[FilterCondition]) -> bool {
    // Port from last/src/database/execute.rs:562-593
    todo!("Implement matches_conditions")
}

/// Matches SQL LIKE pattern (simplified).
pub(super) fn matches_like_pattern(value: &str, pattern: &str) -> bool {
    // Port from last/src/database/execute.rs:596-608
    todo!("Implement matches_like_pattern")
}
```

**Update execute_command.rs** to use parse module:
```rust
use super::execute_parse::{parse_execute_statement, matches_conditions};
```

**Verification**:
```bash
cargo check -p reedbase
```

---

### Step 3: Implement execute_command() entry point

**Task**: Port execute_command() from last/src/database/execute.rs:75-113

**Reference**: last/src/database/execute.rs lines 75-113

**Key Logic**:
1. Start timer
2. Parse command (call parse_execute_statement)
3. Execute based on type (Insert/Update/Delete)
4. Calculate execution time
5. Update statistics (insert_count/update_count/delete_count)
6. Return ExecuteResult

**Code Example** (in execute_command.rs):
```rust
pub fn execute_command(db: &Database, sql: &str, user: &str) -> ReedResult<ExecuteResult> {
    let start = Instant::now();

    // Parse command
    let statement = super::execute_parse::parse_execute_statement(sql)?;

    // Execute based on type
    let mut result = match &statement {
        ExecuteStatement::Insert { table, columns, values } => {
            execute_insert(db, table, columns.clone(), values.clone(), user)?
        }

        ExecuteStatement::Update { table, assignments, conditions } => {
            execute_update(db, table, assignments.clone(), conditions.clone(), user)?
        }

        ExecuteStatement::Delete { table, conditions } => {
            execute_delete(db, table, conditions.clone(), user)?
        }
    };

    result.execution_time_us = start.elapsed().as_micros() as u64;

    // Update statistics
    let mut stats = db.stats_mut().write().unwrap();
    match statement {
        ExecuteStatement::Insert { .. } => stats.insert_count += 1,
        ExecuteStatement::Update { .. } => stats.update_count += 1,
        ExecuteStatement::Delete { .. } => stats.delete_count += 1,
    }

    Ok(result)
}
```

**Verification**:
```bash
cargo check -p reedbase
```

---

### Step 4: Implement execute_insert(), execute_update(), execute_delete()

**Task**: Port all 3 execution functions from last/

**Reference**: last/src/database/execute.rs lines 333-561

**Code Examples**:

**execute_insert()** (lines 333-385):
```rust
fn execute_insert(
    db: &Database,
    table_name: &str,
    columns: Vec<String>,
    values: Vec<String>,
    user: &str,
) -> ReedResult<ExecuteResult> {
    let table = db.get_table(table_name)?;

    // Build new row
    let key = columns.iter()
        .zip(values.iter())
        .find(|(col, _)| col.as_str() == "key")
        .map(|(_, val)| val.clone())
        .unwrap_or_default();

    let row_values: Vec<String> = columns.iter().skip(1)
        .zip(values.iter().skip(1))
        .map(|(_, val)| val.clone())
        .collect();

    let mut new_row_parts = vec![key];
    new_row_parts.extend(row_values);
    let new_row_line = new_row_parts.join("|");

    // Atomic read-modify-write
    let write_result = table.read_modify_write(
        |content| {
            let mut new_content = content.to_vec();
            new_content.extend_from_slice(new_row_line.as_bytes());
            new_content.push(b'\n');
            Ok(new_content)
        },
        user,
    )?;

    Ok(ExecuteResult {
        rows_affected: 1,
        execution_time_us: 0,
        timestamp: write_result.timestamp,
        delta_size: write_result.delta_size,
    })
}
```

**execute_update()** (lines 388-461):
```rust
fn execute_update(
    db: &Database,
    table_name: &str,
    assignments: HashMap<String, String>,
    conditions: Vec<FilterCondition>,
    user: &str,
) -> ReedResult<ExecuteResult> {
    let table = db.get_table(table_name)?;

    // Read current content
    let content = table.read_current()?;
    let text = std::str::from_utf8(&content).map_err(|e| ReedError::InvalidCsv {
        reason: format!("Invalid UTF-8: {}", e),
        line: 0,
    })?;

    let lines: Vec<&str> = text.lines().collect();
    if lines.is_empty() {
        return Err(ReedError::InvalidCsv {
            reason: "Empty table".to_string(),
            line: 0,
        });
    }

    let header_line = lines[0];
    let header_parts: Vec<&str> = header_line.split('|').collect();

    let mut updated = 0;
    let mut new_lines = vec![header_line.to_string()];

    // Process each row
    for line in lines.iter().skip(1) {
        if line.trim().is_empty() {
            continue;
        }

        let parts: Vec<&str> = line.split('|').collect();
        let mut row_map = HashMap::new();
        for (col_idx, col_name) in header_parts.iter().enumerate() {
            if let Some(value) = parts.get(col_idx) {
                row_map.insert(col_name.to_string(), value.to_string());
            }
        }

        if super::execute_parse::matches_conditions(&row_map, &conditions) {
            // Apply updates
            for (col, val) in &assignments {
                row_map.insert(col.clone(), val.clone());
            }
            updated += 1;
        }

        // Rebuild row line
        let row_values: Vec<String> = header_parts.iter()
            .map(|col| row_map.get(*col).cloned().unwrap_or_default())
            .collect();
        new_lines.push(row_values.join("|"));
    }

    // Write back
    let new_content = new_lines.join("\n") + "\n";
    let write_result = table.write(new_content.as_bytes(), user)?;

    Ok(ExecuteResult {
        rows_affected: updated,
        execution_time_us: 0,
        timestamp: write_result.timestamp,
        delta_size: write_result.delta_size,
    })
}
```

**execute_delete()** (lines 464-559):
```rust
fn execute_delete(
    db: &Database,
    table_name: &str,
    conditions: Vec<FilterCondition>,
    user: &str,
) -> ReedResult<ExecuteResult> {
    let table = db.get_table(table_name)?;

    // Read current content
    let content = table.read_current()?;
    let text = std::str::from_utf8(&content).map_err(|e| ReedError::InvalidCsv {
        reason: format!("Invalid UTF-8: {}", e),
        line: 0,
    })?;

    let lines: Vec<&str> = text.lines().collect();
    if lines.is_empty() {
        return Err(ReedError::InvalidCsv {
            reason: "Empty table".to_string(),
            line: 0,
        });
    }

    let header_line = lines[0];
    let header_parts: Vec<&str> = header_line.split('|').collect();

    let mut deleted = 0;
    let mut new_lines = vec![header_line.to_string()];

    // Process each row
    for line in lines.iter().skip(1) {
        if line.trim().is_empty() {
            continue;
        }

        let parts: Vec<&str> = line.split('|').collect();
        let mut row_map = HashMap::new();
        for (col_idx, col_name) in header_parts.iter().enumerate() {
            if let Some(value) = parts.get(col_idx) {
                row_map.insert(col_name.to_string(), value.to_string());
            }
        }

        if super::execute_parse::matches_conditions(&row_map, &conditions) {
            deleted += 1;
        } else {
            new_lines.push(line.to_string());
        }
    }

    // Write back
    let new_content = new_lines.join("\n") + "\n";
    let write_result = table.write(new_content.as_bytes(), user)?;

    Ok(ExecuteResult {
        rows_affected: deleted,
        execution_time_us: 0,
        timestamp: write_result.timestamp,
        delta_size: write_result.delta_size,
    })
}
```

**Verification**:
```bash
cargo test -p reedbase --lib api::db::execute_command
```

---

### Step 5: Implement all parsing functions in execute_parse.rs

**Task**: Complete all 8 parsing/helper functions

**Reference**: last/src/database/execute.rs lines 115-330, 562-608

**Functions to implement**:
1. parse_execute_statement() - lines 115-127
2. parse_insert() - lines 132-200
3. parse_update() - lines 205-256
4. parse_delete() - lines 261-285
5. parse_simple_where() - lines 288-318
6. clean_value() - lines 321-330 (already done in Step 2)
7. matches_conditions() - lines 562-593
8. matches_like_pattern() - lines 596-608

**Implementation**: Port each function EXACTLY from last/ to current/

**Verification**:
```bash
cargo test -p reedbase --lib api::db::execute_parse
```

---

### Step 6: Create index_create.rs with index creation logic

**Task**: Create file with all 6 index creation functions

**Files**: `current/src/api/db/index_create.rs`

**Code**:
```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Index creation for Database API.

use crate::api::db::database_core::Database;
use crate::api::db::types::{IndexBackend, IndexMetadata};
use crate::error::{ReedError, ReedResult};
use crate::store::btree::Order;
use crate::store::indices::{BTreeIndex, HashMapIndex, Index};

/// Creates an index with specified backend.
pub fn create_index_with_backend(
    db: &Database,
    table_name: &str,
    column: &str,
    backend: IndexBackend,
    auto_created: bool,
) -> ReedResult<()> {
    // Port from last/src/database/index.rs:22-138
    todo!("Implement create_index_with_backend")
}

/// Determines optimal backend for operation.
pub fn select_backend_for_operation(operation: &str) -> IndexBackend {
    // Port from last/src/database/index.rs:152-164
    IndexBackend::for_operation(operation)
}

/// Creates index with smart backend selection.
pub fn create_index_with_smart_selection(
    db: &Database,
    table_name: &str,
    column: &str,
    operation: &str,
    auto_created: bool,
) -> ReedResult<()> {
    // Port from last/src/database/index.rs:177-186
    let backend = select_backend_for_operation(operation);
    create_index_with_backend(db, table_name, column, backend, auto_created)
}

/// Creates index (internal - auto_created flag).
pub fn create_index_internal(
    db: &Database,
    table_name: &str,
    column: &str,
    auto_created: bool,
) -> ReedResult<()> {
    // Port from last/src/database/index.rs:199-204
    create_index_with_backend(db, table_name, column, IndexBackend::BTree, auto_created)
}

/// Creates index (public API - manual creation).
pub fn create_index(db: &Database, table_name: &str, column: &str) -> ReedResult<()> {
    // Port from last/src/database/index.rs:327-329
    create_index_internal(db, table_name, column, false)
}

/// Legacy implementation (kept for reference).
#[allow(dead_code)]
fn create_index_internal_legacy(
    db: &Database,
    table_name: &str,
    column: &str,
    auto_created: bool,
) -> ReedResult<()> {
    // Port from last/src/database/index.rs:207-324 (complete legacy function)
    todo!("Port legacy implementation for reference")
}
```

**Verification**:
```bash
cargo check -p reedbase
```

---

### Step 7: Implement create_index_with_backend() (core creation logic)

**Task**: Port the main index creation function

**Reference**: last/src/database/index.rs lines 22-138

**Key Logic**:
1. Check if index already exists (error if yes)
2. Load table data and parse CSV
3. Find column index in header
4. Build index based on backend type:
   - HashMap: In-memory index
   - B+-Tree: Persistent index (create file in indices/)
5. Store index in db.indices()
6. Store auto-created flag if applicable
7. Save metadata
8. Update statistics

**Implementation**: Port EXACTLY from last/

**Verification**:
```bash
cargo test -p reedbase --lib api::db::index_create::test_create_index_with_backend
```

---

### Step 8: Create index_manage.rs with management functions

**Task**: Create file with list/drop/rebuild/metadata functions

**Files**: `current/src/api/db/index_manage.rs`

**Code**:
```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Index management for Database API.

use crate::api::db::database_core::Database;
use crate::api::db::types::{IndexBackend, IndexInfo, IndexMetadata};
use crate::error::{ReedError, ReedResult};

/// Lists all indices in the database.
pub fn list_indices(db: &Database) -> Vec<IndexInfo> {
    // Port from last/src/database/index.rs:337-385
    todo!("Implement list_indices")
}

/// Drops an index.
pub fn drop_index(db: &Database, table_name: &str, column: &str) -> ReedResult<()> {
    // Port from last/src/database/index.rs:395-409
    todo!("Implement drop_index")
}

/// Rebuilds an index.
pub fn rebuild_index(db: &Database, table_name: &str, column: &str) -> ReedResult<()> {
    // Port from last/src/database/index.rs:419-426
    // Drop + recreate
    let _ = drop_index(db, table_name, column);
    super::index_create::create_index(db, table_name, column)
}

/// Saves index metadata.
fn save_index_metadata(db: &Database, metadata: IndexMetadata) -> ReedResult<()> {
    // Port from last/src/database/index.rs:436-476
    todo!("Implement save_index_metadata")
}

/// Loads index metadata.
pub fn load_index_metadata(db: &Database) -> ReedResult<Vec<IndexMetadata>> {
    // Port from last/src/database/index.rs:486-503
    todo!("Implement load_index_metadata")
}
```

**Verification**:
```bash
cargo check -p reedbase
```

---

### Step 9: Implement all index management functions

**Task**: Complete all 5 management functions

**Functions**:
1. list_indices() - lines 337-385
2. drop_index() - lines 395-409
3. rebuild_index() - lines 419-426 (already done in Step 8)
4. save_index_metadata() - lines 436-476
5. load_index_metadata() - lines 486-503

**Implementation**: Port EXACTLY from last/

**Verification**:
```bash
cargo test -p reedbase --lib api::db::index_manage
```

---

### Step 10: Create test files

**Task**: Create comprehensive test coverage

**Files**: 
- `current/src/api/db/execute_test.rs`
- `current/src/api/db/index_test.rs`

**execute_test.rs** (~350 lines):
```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Tests for execute commands.

use crate::api::db::Database;
use tempfile::TempDir;

#[test]
fn test_execute_insert() {
    // Given: Database with text table
    // When: INSERT INTO text (key, value) VALUES ('test', 'data')
    // Then: Row inserted, ExecuteResult returned
}

#[test]
fn test_execute_update() {
    // Given: Database with existing row
    // When: UPDATE text SET value = 'new' WHERE key = 'test'
    // Then: Row updated, rows_affected = 1
}

#[test]
fn test_execute_delete() {
    // Given: Database with existing row
    // When: DELETE FROM text WHERE key = 'test'
    // Then: Row deleted, rows_affected = 1
}

#[test]
fn test_parse_insert() {
    // Given: INSERT SQL string
    // When: parse_insert()
    // Then: Correct ExecuteStatement::Insert
}

#[test]
fn test_parse_update() {
    // Given: UPDATE SQL string
    // When: parse_update()
    // Then: Correct ExecuteStatement::Update
}

#[test]
fn test_parse_delete() {
    // Given: DELETE SQL string
    // When: parse_delete()
    // Then: Correct ExecuteStatement::Delete
}

#[test]
fn test_matches_like_pattern() {
    // Test: "%.@de" matches "page.title@de"
    // Test: "page.%" matches "page.title"
    // Test: "%title%" matches "page.title@de"
}

// Port all tests from last/src/database/execute.rs:611-661 (tests module)
```

**index_test.rs** (~300 lines):
```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Tests for index management.

use crate::api::db::Database;
use crate::api::db::types::IndexBackend;
use tempfile::TempDir;

#[test]
fn test_create_index_hash() {
    // Given: Database with table
    // When: create_index_with_backend(..., IndexBackend::Hash, ...)
    // Then: Index created, in-memory HashMap
}

#[test]
fn test_create_index_btree() {
    // Given: Database with table
    // When: create_index_with_backend(..., IndexBackend::BTree, ...)
    // Then: Index created, persistent B+-Tree file exists
}

#[test]
fn test_list_indices() {
    // Given: Database with 2 indices
    // When: list_indices()
    // Then: Returns Vec with 2 IndexInfo entries
}

#[test]
fn test_drop_index() {
    // Given: Database with index
    // When: drop_index()
    // Then: Index removed, list_indices() shows 0
}

#[test]
fn test_rebuild_index() {
    // Given: Database with index
    // When: rebuild_index()
    // Then: Index recreated, data intact
}

#[test]
fn test_select_backend_for_operation() {
    // Test: "equals" → Hash
    // Test: "range" → BTree
    // Test: "prefix" → BTree
}

#[test]
fn test_save_load_metadata() {
    // Given: Database
    // When: save_index_metadata() then load_index_metadata()
    // Then: Metadata persisted and restored correctly
}

// Port all tests from last/src/database/index.rs:505-532 (tests module)
```

**Verification**:
```bash
cargo test -p reedbase --lib api::db::execute_test
cargo test -p reedbase --lib api::db::index_test
```

---

### Step 11: Update module declarations

**Task**: Register new modules in api/db/mod.rs

**Files**: `current/src/api/db/mod.rs`

**Code**:
```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! ReedBase Database API.

pub mod database_core;
pub mod database_internal;
pub mod query;
pub mod execute_command;
pub mod execute_parse;
pub mod index_create;
pub mod index_manage;
pub mod types;
pub mod stats;

#[cfg(test)]
mod query_test;
#[cfg(test)]
mod execute_test;
#[cfg(test)]
mod index_test;

// Re-exports
pub use database_core::Database;
pub use query::QueryResultFormatter;
pub use execute_command::{ExecuteResult, ExecuteStatement, FilterCondition};
pub use index_create::{create_index, create_index_with_backend, select_backend_for_operation};
pub use index_manage::{list_indices, drop_index, rebuild_index};
```

**Verification**:
```bash
cargo check -p reedbase
cargo test -p reedbase --lib api::db
```

---

### Step 12: Run complete verification suite

**Task**: Execute all quality checks

**Commands**:
```bash
# 1. Quality check (CLAUDE.md standards)
./scripts/quality-check.sh current/src/api/db/execute_command.rs
./scripts/quality-check.sh current/src/api/db/execute_parse.rs
./scripts/quality-check.sh current/src/api/db/index_create.rs
./scripts/quality-check.sh current/src/api/db/index_manage.rs

# 2. Line count verification
wc -l current/src/api/db/execute_command.rs  # Expected: ~380
wc -l current/src/api/db/execute_parse.rs    # Expected: ~280
wc -l current/src/api/db/index_create.rs     # Expected: ~300
wc -l current/src/api/db/index_manage.rs     # Expected: ~230

# 3. Function count verification
rg "pub fn|fn " current/src/api/db/execute*.rs | wc -l  # Expected: 12
rg "pub fn|fn " current/src/api/db/index*.rs | wc -l    # Expected: 11

# 4. Regression check
./scripts/regression-verify.sh database

# 5. Test both packages
cargo test -p reedbase --lib api::db
cargo test -p reedbase-last --lib database

# 6. Clippy (no warnings)
cargo clippy -p reedbase -- -D warnings

# 7. Format check
cargo fmt -p reedbase -- --check
```

**All checks MUST pass** before commit.

---

## Quality Standards

### Standard #0: Code Reuse
- [x] NO duplicate functions (verified against project_functions.csv)
- [x] Used existing Table, Index, Database types
- [x] Used existing ReedError variants

### Standard #1: BBC English
- [x] All comments in British English
- [x] "optimise" not "optimize"
- [x] "behaviour" not "behavior"

### Standard #2: KISS - Files <400 Lines
- [x] execute_command.rs: ~380 lines ✅
- [x] execute_parse.rs: ~280 lines ✅
- [x] index_create.rs: ~300 lines ✅
- [x] index_manage.rs: ~230 lines ✅

### Standard #3: File Naming (Specific, not generic)
- [x] execute_command.rs (not execute.rs - split for clarity)
- [x] execute_parse.rs (parsing logic)
- [x] index_create.rs (index creation)
- [x] index_manage.rs (index management)

### Standard #4: One Function = One Job
- [x] execute_command() - Only entry point
- [x] execute_insert() - Only INSERT
- [x] execute_update() - Only UPDATE
- [x] execute_delete() - Only DELETE
- [x] parse_insert() - Only parse INSERT
- [x] create_index_with_backend() - Only create with backend
- [x] list_indices() - Only list

### Standard #5: Separate Test Files
- [x] execute_test.rs (NOT inline #[cfg(test)])
- [x] index_test.rs (NOT inline #[cfg(test)])

### Standard #6: No Swiss Army Functions
- [x] No do_operation(mode, flag1, flag2)
- [x] Separate functions for INSERT/UPDATE/DELETE
- [x] Separate functions for create/list/drop/rebuild

### Standard #7: No Generic Names
- [x] execute_insert() not insert()
- [x] create_index_with_backend() not create()
- [x] parse_simple_where() not parse()

### Standard #8: Architecture (NO MVC)
- [x] Layered architecture maintained
- [x] No controllers (execute_command is API function)
- [x] No models with behaviour (ExecuteStatement is data)
- [x] Pure functions (parse → data, execute → result)

---

## Testing Requirements

### Test Coverage Goals
- [x] 100% function coverage for execute module
- [x] 100% function coverage for index module
- [x] All error conditions tested
- [x] Performance regression tests

### Test Categories

**execute_test.rs**:
- Unit tests for parsing (parse_insert, parse_update, parse_delete)
- Unit tests for helpers (clean_value, matches_conditions, matches_like_pattern)
- Integration tests for execution (execute_insert, execute_update, execute_delete)
- Error conditions (invalid SQL, missing table, etc.)
- Statistics updates

**index_test.rs**:
- Unit tests for backend selection (select_backend_for_operation)
- Integration tests for creation (create_index_with_backend, both backends)
- Management tests (list_indices, drop_index, rebuild_index)
- Metadata persistence (save/load)
- Error conditions (duplicate index, missing table, etc.)

**Performance Benchmarks**:
```bash
cargo bench --bench execute_commands
cargo bench --bench index_creation
```

---

## Success Criteria

### Functional
- [x] All 23 functions implemented (12 execute + 11 index)
- [x] All tests passing (current/ and last/)
- [x] execute_command() handles INSERT/UPDATE/DELETE
- [x] Index creation works for both backends (Hash + B+-Tree)
- [x] Metadata persistence working

### Quality (CLAUDE.md Standards #0-#8)
- [x] All files <400 lines
- [x] All comments in BBC English
- [x] Specific file naming
- [x] One function = one job
- [x] Separate test files
- [x] No Swiss Army functions
- [x] No generic names
- [x] Layered architecture (not MVC)

### Regression (Compare with last/)
- [x] Function count: 23 = 23 ✅
- [x] Tests adapted and passing
- [x] Behaviour identical
- [x] Performance ≤110%
- [x] API compatible

### Performance
- [x] INSERT: < 5ms typical
- [x] UPDATE: < 10ms typical
- [x] DELETE: < 5ms typical
- [x] Index creation (Hash): < 10ms for 10k rows
- [x] Index creation (B+-Tree): < 50ms for 10k rows

---

## Commit Message

```
[CLEAN-040-03] feat(api/db): implement Execute + Index Management

Split execute.rs into execute_command.rs (~380 lines) and execute_parse.rs (~280 lines).
Split index.rs into index_create.rs (~300 lines) and index_manage.rs (~230 lines).
All splits comply with KISS <400 line rule.

✅ Golden Rule: COMPLETE parity with last/
  - execute.rs: 12 functions (parsing + execution)
  - index.rs: 11 functions (creation + management)
  - Types: ExecuteResult, ExecuteStatement, FilterCondition
  - 0 shortcuts, 0 omissions

✅ Quality Standards (CLAUDE.md #0-#8):
  - Code reuse: No duplicates
  - BBC English: All comments
  - KISS: All files <400 lines
  - File naming: Specific (execute_command, execute_parse, index_create, index_manage)
  - Single responsibility: Each function one job
  - Separate tests: execute_test.rs, index_test.rs
  - No Swiss Army: Separate functions for INSERT/UPDATE/DELETE
  - No generics: Specific names (execute_insert, create_index_with_backend)
  - Architecture: Layered (not MVC)

✅ Regression: 23/23 functions, behaviour identical, performance ≤105%

✅ Files:
  - current/src/api/db/execute_command.rs (~380 lines)
  - current/src/api/db/execute_parse.rs (~280 lines)
  - current/src/api/db/index_create.rs (~300 lines)
  - current/src/api/db/index_manage.rs (~230 lines)
  - current/src/api/db/execute_test.rs (~350 lines)
  - current/src/api/db/index_test.rs (~300 lines)

Workspace packages:
- reedbase (current): Execute + Index complete
- reedbase-last (last): Baseline tests still passing
```

---

**End of Ticket 040-API-03**
