# SPLIT-302-00: Split reedql/parser.rs (730 lines)

## Status
- [x] Not Started
- [ ] In Progress
- [ ] Complete

## Priority
**CRITICAL** - Second largest file, clear split boundaries

## Estimated Effort
1.5 hours

## Path References

- **Current**: `src/reedql/parser.rs` (before 002-[STRUCT]-00)
- **After**: `src/api/reedql/parser.rs` (after 002-[STRUCT]-00)

## Context

**File**: 730 lines containing ALL SQL parsing logic

**Responsibilities**:
1. SELECT parsing
2. INSERT/UPDATE/DELETE parsing  
3. CREATE/DROP parsing
4. Expression parsing
5. Common parsing utilities

## Target State

**Current paths** (before 002):
```
src/reedql/
├── parser.rs              # Core parser struct (~80 lines)
├── parser_select.rs       # SELECT parsing (~200 lines)
├── parser_mutations.rs    # INSERT/UPDATE/DELETE (~200 lines)
├── parser_ddl.rs          # CREATE/DROP (~150 lines)
├── parser_expressions.rs  # Expressions (~100 lines)
└── mod.rs
```

**After 002-[STRUCT]-00**:
```
src/api/reedql/
├── parser.rs
├── parser_select.rs
├── parser_mutations.rs
├── parser_ddl.rs
├── parser_expressions.rs
└── mod.rs
```

## Implementation Steps

### Step 1: Analyze Structure

```bash
# Find main parsing functions
rg "pub fn parse_" src/reedql/parser.rs --no-heading | head -20

# Identify SELECT-related
rg "SELECT|select|query" src/reedql/parser.rs -c

# Identify mutation-related
rg "INSERT|UPDATE|DELETE" src/reedql/parser.rs -c
```

### Step 2: Extract SELECT Parser

Create `parser_select.rs`:
```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! SELECT statement parsing.

use super::parser::Parser;
use super::types::*;

impl Parser {
    pub fn parse_select(&mut self) -> Result<SelectStmt> {
        // Move SELECT parsing here
    }
    
    pub fn parse_from(&mut self) -> Result<FromClause> {
        // Move FROM parsing here
    }
    
    pub fn parse_where(&mut self) -> Result<WhereClause> {
        // Move WHERE parsing here
    }
}
```

### Step 3: Extract Mutations Parser

Create `parser_mutations.rs`:
```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! INSERT/UPDATE/DELETE statement parsing.

use super::parser::Parser;
use super::types::*;

impl Parser {
    pub fn parse_insert(&mut self) -> Result<InsertStmt> { ... }
    pub fn parse_update(&mut self) -> Result<UpdateStmt> { ... }
    pub fn parse_delete(&mut self) -> Result<DeleteStmt> { ... }
}
```

### Step 4: Extract DDL Parser

Create `parser_ddl.rs`:
```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Data Definition Language (CREATE/DROP) parsing.

use super::parser::Parser;
use super::types::*;

impl Parser {
    pub fn parse_create_table(&mut self) -> Result<CreateTableStmt> { ... }
    pub fn parse_drop_table(&mut self) -> Result<DropTableStmt> { ... }
}
```

### Step 5: Extract Expression Parser

Create `parser_expressions.rs`:
```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Expression and literal parsing.

use super::parser::Parser;
use super::types::*;

impl Parser {
    pub fn parse_expression(&mut self) -> Result<Expression> { ... }
    pub fn parse_literal(&mut self) -> Result<Literal> { ... }
}
```

### Step 6: Update mod.rs

```rust
mod parser;
mod parser_select;      // New
mod parser_mutations;   // New
mod parser_ddl;         // New
mod parser_expressions; // New

pub use parser::Parser;
```

### Step 7: Verify

```bash
cargo test --lib reedql::parser
cargo test --lib reedql::
cargo check
```

## Verification

- [ ] All 4 new files created with copyright headers
- [ ] parser.rs reduced to ~80 lines (core only)
- [ ] All ReedQL tests pass
- [ ] Public API unchanged
- [ ] mod.rs updated correctly

## Files Affected

**Created** (current):
- `src/reedql/parser_select.rs` (~200 lines)
- `src/reedql/parser_mutations.rs` (~200 lines)
- `src/reedql/parser_ddl.rs` (~150 lines)
- `src/reedql/parser_expressions.rs` (~100 lines)

**Modified** (current):
- `src/reedql/parser.rs` (730 → ~80 lines)
- `src/reedql/mod.rs`

**After 002-[STRUCT]-00** (all in `src/api/reedql/`)

## Dependencies

- 001-[PREP]-00: Tests must pass first
- 115-[TESTS]-00: Extract parser.rs inline tests

## Notes

**Natural boundaries**: SQL grammar provides clear separation
- SELECT = queries
- INSERT/UPDATE/DELETE = mutations  
- CREATE/DROP = DDL
- Expressions = shared utilities
