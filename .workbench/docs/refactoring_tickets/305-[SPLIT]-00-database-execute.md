# SPLIT-305-00: Split database/execute.rs (661 lines)

## Status
- [x] Not Started
- [ ] In Progress
- [ ] Complete

## Priority
**MEDIUM** - Can be done post-launch if time constrained

## Estimated Effort
1 hour

## Path References

- **Current**: `src/database/execute.rs` (before 002-[STRUCT]-00)
- **After**: `src/api/db/execute.rs` (after 002-[STRUCT]-00)

## Context

**File**: 661 lines with all write operations

**Split approach**: One file per operation type

## Target State

**Current paths**:
```
src/database/
├── execute.rs           # Orchestration (~60 lines)
├── execute_insert.rs    # INSERT logic (~200 lines)
├── execute_update.rs    # UPDATE logic (~200 lines)
├── execute_delete.rs    # DELETE logic (~200 lines)
└── mod.rs
```

**After 002-[STRUCT]-00**: Same in `src/api/db/`

## Implementation Steps

### Step 1-3: Extract Each Operation

Create 3 files (insert, update, delete) with focused logic.

### Step 4: Keep Orchestration

executor.rs keeps dispatch logic.

## Verification

- [ ] 3 new files created
- [ ] execute.rs reduced to ~60 lines
- [ ] All database tests pass

## Files Affected

**Created** (current):
- `src/database/execute_insert.rs`
- `src/database/execute_update.rs`
- `src/database/execute_delete.rs`

**Modified** (current):
- `src/database/execute.rs` (661 → ~60 lines)
