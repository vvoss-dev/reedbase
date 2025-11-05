# 050-[REUSE]-00: Architecture & Redundancy Audit

**Category**: Code Quality / DRY Principle / Architecture  
**Effort**: 4-6 hours  
**Priority**: CRITICAL (Foundation for v0.2.0-beta)

---

## Overview

**Comprehensive audit to achieve 100% redundancy-free code before v0.2.0-beta release.**

This addresses:
1. **CLAUDE.md Standard #0**: Code Reuse - NEVER Duplicate Existing Functions
2. **Architecture clarity**: Identify "default functions" that need proper scope
3. **Anti-pattern detection**: Ensure NO MVC patterns (ReedBase has its own architecture)

---

## User Requirements (Exact)

> "das sogar soweit herunterbrechen, dass default functions - also die keinem scope bisher zugeordnet sind - aber für die immer gleichen effizienten default prozessen notwendig sind in einem separaten scope unterbringen"

**Translation**: Break down to the level where default functions (not yet assigned to any scope, but necessary for always-efficient default processes) are housed in a separate scope.

> "wirklich redundanzfreier code würde ja mein anspruch bevor ich das release"

**Translation**: Truly redundancy-free code is my requirement before I release.

> "KEIN MVC!"

**Translation**: NO MVC architecture!

---

## ReedBase Architecture (Current State)

### Current Module Structure (19 modules)

```
src/
├── backup/          # Backup creation, restoration, listing
├── bin/             # CLI entry point + commands
├── btree/           # B-Tree implementation (storage engine)
├── concurrent/      # Locks, queues (thread safety)
├── conflict/        # Conflict resolution logic
├── database/        # High-level DB operations (execute, query, stats)
├── error.rs         # Error types (ReedError)
├── functions/       # Aggregations, transformations, computed, cache
├── indices/         # B-Tree index, HashMap index, hierarchy, namespace
├── lib.rs           # Library entry point
├── log/             # Encoder, decoder, validator (WAL)
├── merge/           # CSV merge, diff algorithms
├── metrics/         # Metrics collection, aggregation, storage
├── reedql/          # Query language (parser, executor, analyzer, planner)
├── registry/        # Dictionary, initialisation
├── schema/          # RBKS validation, schema loading
├── tables/          # CSV parser, table structures, helpers
└── version/         # Delta tracking, rebuild, versioning
```

### What is ReedBase's Architecture? (NOT MVC!)

**ReedBase Architecture Principles**:
- **Layered**: Storage → Data → Query → API
- **Functional domains**: Each module = one responsibility
- **No controllers**: Direct function calls, no request/response objects
- **No models**: Tables are data, not classes with behaviour
- **No views**: Pure data out (CSV, JSON)

---

## Phase 1: Default Functions Identification (2h)

### Goal: Find "Orphaned" Utility Functions

**Definition of "Default Function"**:
- Used by multiple modules
- No clear ownership (which module should own it?)
- General-purpose (not domain-specific)
- Efficient standard processes (path handling, string manipulation, etc.)

### Step 1.1: Find Functions Without Clear Scope (1h)

```bash
# Find all public functions
rg "^\s*pub\s+fn\s+(\w+)" src/ \
  --type rust \
  --line-number \
  > _workbench/analysis/050-all-functions.txt

# Categorise by module
awk -F: '{print $1}' _workbench/analysis/050-all-functions.txt \
  | sed 's|src/||' \
  | cut -d'/' -f1 \
  | sort | uniq -c | sort -rn \
  > _workbench/analysis/050-functions-per-module.txt
```

**Expected Output**:
```
42 database        # Many functions - is this too broad?
38 reedql          # Query language - OK
35 indices         # Index operations - OK
12 tables          # Table operations - OK
8  functions       # Aggregations/transformations - check if truly distinct
5  error.rs        # Error constructors - OK
...
```

### Step 1.2: Identify Candidates for "Core/Utils" Module (1h)

**Manual Review**: For each module, ask:

1. **Are there generic helpers?**
   - Example: `tables/helpers.rs` (51 lines)
   - Question: Are these table-specific OR general utilities?

2. **Are there shared path operations?**
   ```bash
   # Find path manipulation
   rg "PathBuf|\.join\(|format!\(.*\.reed" src/ --type rust -l
   ```
   - If scattered: Need `core/paths.rs`

3. **Are there shared string operations?**
   ```bash
   # Find string utilities
   rg "fn.*str.*->.*String|fn.*String.*->.*str" src/ --type rust
   ```
   - If scattered: Need `core/strings.rs`

4. **Are there shared validation patterns?**
   ```bash
   # Find validation functions
   rg "fn validate_|fn is_valid_" src/ --type rust
   ```
   - If scattered: Need `core/validation.rs`

**Document in**: `_workbench/analysis/050-default-functions-candidates.md`

**Template**:
```markdown
## Candidate: Path Operations

### Current Locations (Scattered)
- `tables/helpers.rs:42` - `get_table_path()`
- `backup/create.rs:18` - `get_backup_dir()`
- `database/query.rs:89` - `resolve_db_path()`

### Analysis
- All 3 construct paths to .reedbase/ directories
- 80% duplicate logic (format!("{}/.reedbase/{}", base, file))
- NOT domain-specific (path operations are generic)

### Recommendation
- **Create**: `src/core/paths.rs`
- **Functions**: 
  - `pub fn db_path(base: &Path) -> PathBuf`
  - `pub fn table_path(base: &Path, table: &str) -> PathBuf`
  - `pub fn backup_dir(base: &Path) -> PathBuf`
- **Refactor**: Replace scattered logic with core::paths calls
- **Estimated effort**: 1 hour
```

---

## Phase 2: Redundancy Detection (2h)

### Step 2.1: Find Exact Duplicates (0.5h)

```bash
# Create checksums of function bodies (detect identical code)
for file in $(find src -name "*.rs" -type f); do
  echo "=== $file ==="
  # Extract function bodies, hash them
  rg "^\s*pub\s+fn\s+" "$file" -A 50 --no-line-number \
    | awk '/^pub fn/,/^}$/' \
    | md5sum
done > _workbench/analysis/050-function-hashes.txt

# Find duplicate hashes (identical implementations)
cat _workbench/analysis/050-function-hashes.txt \
  | sort \
  | uniq -d \
  > _workbench/analysis/050-exact-duplicates.txt
```

### Step 2.2: Find Near-Duplicates (Semantic Analysis) (1h)

**Manual inspection for common patterns**:

#### Pattern A: CSV Parsing
```bash
# Find manual CSV parsing (should use tables/csv_parser.rs)
rg "\.split\('\|'\)|\.split\(\"\\|" src/ \
  --type rust \
  -C 3 \
  > _workbench/analysis/050-manual-csv-parsing.txt

# Expected: 0 occurrences (all should use csv_parser)
```

**If found**: Create consolidation ticket.

#### Pattern B: Error Conversion
```bash
# Find manual error construction (should use From traits)
rg "ReedError::\w+\s*\{" src/ \
  --type rust \
  -C 2 \
  > _workbench/analysis/050-manual-error-construction.txt

# Check: Are these repetitive? Should be From<X> for ReedError?
```

#### Pattern C: Path Construction
```bash
# Find .reedbase path construction
rg "\.reedbase|format!\(.*reedbase" src/ \
  --type rust \
  -l \
  > _workbench/analysis/050-path-construction-files.txt

# Count occurrences per file
for file in $(cat _workbench/analysis/050-path-construction-files.txt); do
  count=$(rg "\.reedbase" "$file" -c)
  echo "$count $file"
done | sort -rn > _workbench/analysis/050-path-construction-frequency.txt
```

**If >5 files**: Centralise in `core/paths.rs`

#### Pattern D: Validation Logic
```bash
# Find validation patterns
rg "if.*\.is_empty\(\)|if.*\.len\(\) ==|if.*\.starts_with" src/ \
  --type rust \
  -C 2 \
  > _workbench/analysis/050-validation-patterns.txt

# Manual review: Are validations duplicated?
```

### Step 2.3: Find "God Functions" (Swiss Army Knives) (0.5h)

```bash
# Find functions >100 lines
rg "^\s*pub\s+fn\s+(\w+)" src/ --type rust -A 100 \
  | awk '/^pub fn/ {name=$0; lines=0} {lines++} /^}$/ {if (lines > 100) print name " (" lines " lines)"}' \
  > _workbench/analysis/050-long-functions.txt

# Find functions with >5 parameters
rg "pub fn \w+\([^)]*,[^)]*,[^)]*,[^)]*,[^)]*," src/ --type rust \
  > _workbench/analysis/050-complex-signatures.txt
```

**Analysis**: Do these functions do too many things? Should they be split?

---

## Phase 3: Architecture Analysis (1h)

### Step 3.1: Detect MVC Anti-Patterns (0.5h)

**Check for MVC violations**:

```bash
# 1. Controllers (request/response pattern)
rg "struct.*Request|struct.*Response|fn handle_" src/ --type rust
# Expected: Minimal (only in bin/commands for CLI)

# 2. Models with behaviour (classes with methods)
rg "impl \w+ \{" src/ --type rust -A 5 \
  | rg "pub fn \w+\(&self" \
  > _workbench/analysis/050-impl-methods.txt
# Review: Are these data structures with logic? Or pure data?

# 3. Views (templating, formatting)
rg "format!|println!|write!" src/ --type rust -l \
  | grep -v "bin/" \
  | grep -v "test" \
  > _workbench/analysis/050-output-in-lib.txt
# Expected: 0 (output should be in bin/ only, lib is pure data)
```

**Document violations** in `_workbench/analysis/050-mvc-violations.md`

### Step 3.2: Identify Module Boundaries (0.5h)

**Review current modules** and ask:

1. **Is the module cohesive?** (Single responsibility)
   - ❌ Example: `database/` has execute, query, stats, types - too broad?
   - ✅ Example: `backup/` has create, list, restore - cohesive

2. **Are there circular dependencies?**
   ```bash
   # Check for use crate:: patterns
   rg "use crate::" src/ --type rust \
     | cut -d: -f1,3 \
     | sort \
     > _workbench/analysis/050-module-dependencies.txt
   
   # Look for cycles (A uses B, B uses A)
   ```

3. **Are there "God modules"?** (Too many functions)
   - Check `_workbench/analysis/050-functions-per-module.txt`
   - If >50 functions: Likely too broad

**Proposed Refactoring**:
```markdown
## Current: database/ (42 functions)

Proposal: Split into:
- `query/` - Query execution (SELECT, WHERE, JOIN)
- `mutation/` - Data modification (INSERT, UPDATE, DELETE)
- `stats/` - Statistics and analytics

Rationale: database/ is doing 3 distinct jobs
```

---

## Phase 4: Proposed "Core" Module (1h)

### Step 4.1: Design Core Module Structure

Based on Phase 1 findings, create:

```
src/core/
├── mod.rs           # Module exports
├── paths.rs         # Path construction (db_path, table_path, etc.)
├── validation.rs    # Common validators (is_valid_key, etc.)
├── strings.rs       # String utilities (if needed)
└── types.rs         # Core types used everywhere (if needed)
```

### Step 4.2: Define Core Functions

**Example: `src/core/paths.rs`**
```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Core path utilities for ReedBase.
//!
//! Centralised path construction to eliminate scattered
//! format!() calls across the codebase.

use std::path::{Path, PathBuf};

/// Returns the .reedbase directory path.
pub fn db_dir(base: &Path) -> PathBuf {
    base.join(".reedbase")
}

/// Returns the path to a specific table file.
pub fn table_path(base: &Path, table: &str) -> PathBuf {
    db_dir(base).join(format!("{}.csv", table))
}

/// Returns the backup directory path.
pub fn backup_dir(base: &Path) -> PathBuf {
    db_dir(base).join("backups")
}

/// Returns the WAL (Write-Ahead Log) directory path.
pub fn wal_dir(base: &Path) -> PathBuf {
    db_dir(base).join("wal")
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::PathBuf;

    #[test]
    fn test_db_dir() {
        let base = PathBuf::from("/tmp/test");
        assert_eq!(db_dir(&base), PathBuf::from("/tmp/test/.reedbase"));
    }

    #[test]
    fn test_table_path() {
        let base = PathBuf::from("/tmp/test");
        assert_eq!(
            table_path(&base, "users"),
            PathBuf::from("/tmp/test/.reedbase/users.csv")
        );
    }
}
```

**Example: `src/core/validation.rs`**
```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Core validation utilities.

use crate::error::ReedError;

/// Validates that a key is not empty and contains only valid characters.
///
/// Valid characters: lowercase, dots, @, digits
pub fn validate_key(key: &str) -> Result<(), ReedError> {
    if key.is_empty() {
        return Err(ReedError::InvalidKey {
            key: key.to_string(),
            reason: "Key cannot be empty".to_string(),
        });
    }

    if !key.chars().all(|c| {
        c.is_lowercase() || c == '.' || c == '@' || c.is_numeric()
    }) {
        return Err(ReedError::InvalidKey {
            key: key.to_string(),
            reason: "Key must be lowercase with dots/@ only".to_string(),
        });
    }

    Ok(())
}

/// Validates that a table name is valid.
pub fn validate_table_name(name: &str) -> Result<(), ReedError> {
    if name.is_empty() || name.len() > 64 {
        return Err(ReedError::InvalidTableName {
            name: name.to_string(),
        });
    }

    if !name.chars().all(|c| c.is_alphanumeric() || c == '_') {
        return Err(ReedError::InvalidTableName {
            name: name.to_string(),
        });
    }

    Ok(())
}
```

---

## Sub-Tickets to Create

Based on findings:

### Architecture Sub-Tickets
```
051-[REUSE]-01-create-core-module.md         # Create src/core/
052-[REUSE]-02-centralise-path-operations.md # Move to core/paths.rs
053-[REUSE]-03-centralise-validation.md      # Move to core/validation.rs
```

### Redundancy Elimination Sub-Tickets
```
054-[REUSE]-04-eliminate-csv-parsing-dups.md
055-[REUSE]-05-eliminate-error-construction-dups.md
056-[REUSE]-06-consolidate-table-helpers.md
...
```

### Module Refactoring Sub-Tickets (if needed)
```
057-[REUSE]-07-split-database-module.md      # Split into query/mutation/stats
058-[REUSE]-08-resolve-circular-deps.md      # Fix circular dependencies
```

---

## Verification

### ✅ Success Criteria

1. **Zero code duplication**
   - No exact duplicate functions
   - No near-duplicate logic (>80% similar)

2. **Core module exists**
   - `src/core/` with paths, validation, etc.
   - All scattered utilities centralised

3. **NO MVC patterns**
   - No controllers in lib code
   - No models with behaviour (pure data only)
   - No views in lib (output in bin/ only)

4. **Clear module boundaries**
   - Each module = one responsibility
   - No circular dependencies
   - No "God modules" (>50 functions)

5. **Architecture documented**
   - `ARCHITECTURE.md` explaining ReedBase's layered design
   - Module responsibilities documented
   - Core module purpose clear

---

## Output Files

```
_workbench/analysis/
├── 050-all-functions.txt                    # All public functions
├── 050-functions-per-module.txt             # Function count by module
├── 050-default-functions-candidates.md      # Candidates for core/
├── 050-function-hashes.txt                  # Function body checksums
├── 050-exact-duplicates.txt                 # Identical implementations
├── 050-manual-csv-parsing.txt               # CSV parsing outside csv_parser
├── 050-manual-error-construction.txt        # Error construction patterns
├── 050-path-construction-files.txt          # Files with path logic
├── 050-path-construction-frequency.txt      # Path logic frequency
├── 050-validation-patterns.txt              # Validation logic patterns
├── 050-long-functions.txt                   # Functions >100 lines
├── 050-complex-signatures.txt               # Functions >5 parameters
├── 050-mvc-violations.md                    # MVC anti-patterns found
├── 050-module-dependencies.txt              # Module import graph
└── 050-consolidation-plan.md                # Action plan with sub-tickets
```

---

## Expected Results

### Minimum (Critical Only)
- ✅ Exact duplicates eliminated
- ✅ Core module created
- ✅ Path operations centralised
- ⚠️ Some near-duplicates may remain

**Effort**: 6-8 hours

### Recommended (100% Redundancy-Free) ⭐
- ✅ All of Minimum
- ✅ All near-duplicates eliminated
- ✅ Validation centralised
- ✅ No MVC patterns
- ✅ Clear module boundaries

**Effort**: 10-15 hours

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Breaking changes | MEDIUM | HIGH | Comprehensive tests after each consolidation |
| Over-abstraction | LOW | MEDIUM | Only centralise if ≥3 usages |
| Time overrun | MEDIUM | MEDIUM | Prioritise exact duplicates first |
| Architectural disagreement | LOW | HIGH | Document rationale in ARCHITECTURE.md |

---

## Notes

### When to Create Core Module

**Create `src/core/` if**:
- ✅ ≥5 files have scattered path operations
- ✅ ≥3 files have duplicate validation
- ✅ Clear "default functions" identified

**Don't create if**:
- ❌ Only 1-2 files have utilities
- ❌ "Utilities" are actually domain-specific
- ❌ Abstraction adds complexity > benefit

### NO MVC Means

- ❌ No `handle_request()` functions in lib
- ❌ No `struct UserModel { ... } impl UserModel { fn save() }`
- ❌ No templating/formatting in lib code
- ✅ Pure functions: data in → data out
- ✅ CLI layer handles I/O (bin/)
- ✅ Lib layer handles logic (src/)

---

**Estimated Total Effort**: 4-6h (audit) + 6-15h (consolidation) = **10-21 hours**  
**Priority**: CRITICAL (Foundation for v0.2.0-beta)  
**Blocking**: None (but blocks all other refactoring)

---

**Next Steps After 050**:
1. Review `_workbench/analysis/050-consolidation-plan.md`
2. Decide: Minimum (6-8h) vs Recommended (10-15h)
3. Execute sub-tickets 051-05X
4. Proceed with other refactoring tickets (001, 002, etc.)
