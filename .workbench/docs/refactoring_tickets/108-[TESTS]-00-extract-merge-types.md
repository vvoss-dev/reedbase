# TESTS-108-00: Extract Tests from merge/types

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

- **Current**: `src/merge/types.rs` (before 002-[STRUCT]-00)
- **After**: `src/process/merge/types.rs` (after 002-[STRUCT]-00)

Use current path if folder reorganisation not yet done.

## Context

**File**: merge/types (200 lines)  
**Violation**: Has inline `#[cfg(test)] mod tests`  
**Required**: Extract to `merge/types_test.rs`

## Implementation

### Step 1: Locate Test Module

```bash
# Find the test module
rg "#\[cfg\(test\)\]" src/merge/types.rs -A1 | grep "mod tests"
```

### Step 2: Extract Tests

```bash
# 1. Copy test module to new file
# Use current or after path depending on 002-[STRUCT]-00 status

# Current path:
cat src/merge/types.rs | awk '/#\[cfg\(test\)\]/,/^}$/ {print}' > src/merge/types_test.rs

# OR after 002-[STRUCT]-00:
# cat src/process/merge/types.rs | awk '/#\[cfg\(test\)\]/,/^}$/ {print}' > src/process/merge/types_test.rs
```

### Step 3: Update Test File Header

```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Tests for merge/types.

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
mod types_test;
```

### Step 6: Verify

```bash
# Run tests for this module specifically
cargo test --lib merge::

# Verify no inline tests remain
rg "#\[cfg\(test\)\].*mod tests" src/merge/types.rs
# Should return nothing

# Run full test suite
cargo test --lib
```

## Verification

- [ ] Test file created: `src/merge/types_test.rs`
- [ ] Copyright header added
- [ ] Inline tests removed from `src/merge/types.rs`
- [ ] mod.rs updated with test module reference
- [ ] All tests still pass (`cargo test --lib`)
- [ ] No inline `mod tests` remains in original file

## Files Affected

**Created** (current paths):
- `src/merge/types_test.rs`

**Modified** (current paths):
- `src/merge/types.rs` (remove inline tests)
- `src/merge/mod.rs` (add test module reference)

**After 002-[STRUCT]-00**:
- `src/process/merge/types_test.rs`
- `src/process/merge/types.rs`
- `src/process/merge/mod.rs`

## Notes

**Test Structure**: Maintain exact same test structure, just move location.

**Imports**: Use `use super::*;` to import from parent module.

**No changes to test logic** - pure extraction.
