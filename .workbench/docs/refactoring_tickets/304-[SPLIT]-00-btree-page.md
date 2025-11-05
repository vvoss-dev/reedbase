# SPLIT-304-00: Split btree/page.rs (669 lines)

## Status
- [x] Not Started
- [ ] In Progress
- [ ] Complete

## Priority
**HIGH** - Related to btree/tree.rs split

## Estimated Effort
1 hour

## Path References

- **Current**: `src/btree/page.rs` (before 002-[STRUCT]-00)
- **After**: `src/store/btree/page.rs` (after 002-[STRUCT]-00)

## Context

**File**: 669 lines with page operations + serialization mixed

**Split approach**: Separate operations from serialization

## Target State

**Current paths**:
```
src/btree/
├── page.rs              # Page struct + operations (~350 lines)
├── page_serialize.rs    # Serialization/deserialization (~300 lines)
└── mod.rs
```

**After 002-[STRUCT]-00**: Same in `src/store/btree/`

## Implementation Steps

### Step 1: Keep in page.rs

- Page struct definition
- Page operations (insert, delete, search)
- Page splitting/merging logic

### Step 2: Extract to page_serialize.rs

- Serialize to bytes
- Deserialize from bytes
- Checksum calculation
- Compression/decompression

## Verification

- [ ] 1 new file created (page_serialize.rs)
- [ ] page.rs reduced to ~350 lines
- [ ] All btree tests pass

## Files Affected

**Created** (current):
- `src/btree/page_serialize.rs` (~300 lines)

**Modified** (current):
- `src/btree/page.rs` (669 → ~350 lines)
