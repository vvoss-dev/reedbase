# SPLIT-303-00: Split reedql/executor.rs (697 lines)

## Status
- [x] Not Started
- [ ] In Progress
- [ ] Complete

## Priority
**HIGH** - Pairs with parser split

## Estimated Effort
1 hour

## Path References

- **Current**: `src/reedql/executor.rs` (before 002-[STRUCT]-00)
- **After**: `src/api/reedql/executor.rs` (after 002-[STRUCT]-00)

## Context

**File**: 697 lines containing ALL query execution logic

**Split approach**: Separate read operations from write operations

## Target State

**Current paths**:
```
src/reedql/
├── executor.rs           # Core executor struct (~50 lines)
├── executor_select.rs    # SELECT execution (~300 lines)
├── executor_mutations.rs # INSERT/UPDATE/DELETE (~300 lines)
└── mod.rs
```

**After 002-[STRUCT]-00**: Same in `src/api/reedql/`

## Implementation Steps

### Step 1: Extract SELECT Executor

```rust
// executor_select.rs
use super::executor::Executor;

impl Executor {
    pub fn execute_select(&self, stmt: &SelectStmt) -> Result<QueryResults> { ... }
    pub fn execute_query(&self, query: &str) -> Result<QueryResults> { ... }
}
```

### Step 2: Extract Mutations Executor

```rust
// executor_mutations.rs
use super::executor::Executor;

impl Executor {
    pub fn execute_insert(&mut self, stmt: &InsertStmt) -> Result<()> { ... }
    pub fn execute_update(&mut self, stmt: &UpdateStmt) -> Result<usize> { ... }
    pub fn execute_delete(&mut self, stmt: &DeleteStmt) -> Result<usize> { ... }
}
```

### Step 3: Core Executor

Keep in `executor.rs`:
- Executor struct definition
- new(), open(), close()
- Orchestration logic

## Verification

- [ ] 2 new files created
- [ ] executor.rs reduced to ~50 lines
- [ ] All tests pass
- [ ] Public API unchanged

## Files Affected

**Created** (current):
- `src/reedql/executor_select.rs`
- `src/reedql/executor_mutations.rs`

**Modified** (current):
- `src/reedql/executor.rs` (697 → ~50 lines)
- `src/reedql/mod.rs`
