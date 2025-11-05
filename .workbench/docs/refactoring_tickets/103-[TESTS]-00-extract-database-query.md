# TESTS-103-00: Extract Tests from database/query

## Status
- [x] Not Started
- [ ] In Progress
- [ ] Complete

## Priority
**HIGH** - CLAUDE.md Standard #5 compliance (MANDATORY)

## Estimated Effort
10 minutes

## Parent Ticket
100-[TESTS]-00: Extract Inline Tests - Overview

## Path References

- **Current**: `src/database/query.rs` (before 002-[STRUCT]-00)
- **After**: `src/api/db/query.rs` (after 002-[STRUCT]-00)

Use current path if folder reorganisation not yet done.

## Context

**File**: database/query (387 lines)  
**Violation**: Has inline `#[cfg(test)] mod tests`  
**Required**: Extract to `database/query_test.rs`

## Implementation

### Step 1: Locate Test Module

```bash
# Find the test module
rg "#\[cfg\(test\)\]" src/database/query.rs -A1 | grep "mod tests"
```

### Step 2: Extract Tests

```bash
# 1. Copy test module to new file
# Use current or after path depending on 002-[STRUCT]-00 status

# Current path:
cat src/database/query.rs | awk '/#\[cfg\(test\)\]/,/^}$/ {print}' > src/database/query_test.rs

# OR after 002-[STRUCT]-00:
# cat src/api/db/query.rs | awk '/#\[cfg\(test\)\]/,/^}$/ {print}' > src/api/db/query_test.rs
```

### Step 3: Update Test File Header

```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Tests for database/query.

use super::*; // Import from parent module

#[cfg(test)]
mod tests {
    use super::*;
    
    // ... existing tests ...
}
```

### Step 4: Remove from Original File

```bash
# Remove inline test module from original file
# Use your editor or sed to delete the #[cfg(test)] mod tests block
```

### Step 5: Update mod.rs

```rust
// In the module's mod.rs, add:
#[cfg(test)]
mod query_test;
```

### Step 6: Verify

```bash
# Run tests for this module specifically
cargo test --lib database::

# Verify no inline tests remain
rg "#\[cfg\(test\)\].*mod tests" src/database/query.rs
# Should return nothing

# Run full test suite
cargo test --lib
```

## Verification

- [ ] Test file created: `src/database/query_test.rs`
- [ ] Copyright header added
- [ ] Inline tests removed from `src/database/query.rs`
- [ ] mod.rs updated with test module reference
- [ ] All tests still pass (`cargo test --lib`)
- [ ] No inline `mod tests` remains in original file

## Files Affected

**Created** (current paths):
- `src/database/query_test.rs`

**Modified** (current paths):
- `src/database/query.rs` (remove inline tests)
- `src/database/mod.rs` (add test module reference)

**After 002-[STRUCT]-00**:
- `src/api/db/query_test.rs`
- `src/api/db/query.rs`
- `src/api/db/mod.rs`

## Notes

**Test Structure**: Maintain exact same test structure, just move location.

**Imports**: Use `use super::*;` to import from parent module.

**No changes to test logic** - pure extraction.
