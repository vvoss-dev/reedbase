# SPLIT-306-00: Extract Formatters from mod.rs

## Status
- [x] Not Started
- [ ] In Progress
- [ ] Complete

## Priority
**LOW** - Nice to have, not blocking

## Estimated Effort
30 minutes

## Path References

- **Current**: `src/bin/formatters/mod.rs` (before 002-[STRUCT]-00)
- **After**: `src/api/cli/formatters/mod.rs` (after 002-[STRUCT]-00)

## Context

**File**: formatters/mod.rs likely has implementation code

**Split approach**: Extract each formatter to its own file

## Target State

**Current paths**:
```
src/bin/formatters/
├── mod.rs              # Exports only (~20 lines)
├── table_formatter.rs  # Table output
├── json_formatter.rs   # JSON output
├── csv_formatter.rs    # CSV output
└── ...
```

## Implementation Steps

Extract formatter implementations from mod.rs to dedicated files.

## Verification

- [ ] mod.rs is <30 lines (exports only)
- [ ] Each formatter in own file
- [ ] CLI tests pass

## Files Affected

**Created** (current): Multiple `*_formatter.rs` files
**Modified** (current): `src/bin/formatters/mod.rs`
