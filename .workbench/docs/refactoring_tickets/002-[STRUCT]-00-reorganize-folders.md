# STRUCT-050-00: Reorganize Folder Structure

## Status
- [x] Not Started
- [ ] In Progress
- [ ] Complete

## Priority
**HIGH** - Better structure improves developer experience significantly

## Estimated Effort
2-3 hours (moving files + updating ALL imports across codebase)

## Context
Current flat structure makes it unclear what modules do and how they relate.
Decision made to reorganize into 5 clear top-level categories for KISS developer experience.

## Current State (Flat)
```
src/
├── backup/
├── bin/
├── btree/
├── concurrent/
├── conflict/
├── database/
├── functions/
├── indices/
├── log/
├── merge/
├── metrics/
├── reedql/
├── registry/
├── schema/
├── tables/
├── version/
├── error.rs
└── lib.rs
```

**Problems**:
- ❌ All modules on same level (no hierarchy)
- ❌ Relationships unclear (btree vs indices vs tables?)
- ❌ Intent unclear (is reedql an API or internal parser?)
- ❌ No grouping by purpose

## Target State (Hierarchical)

```
src/
├── api/                    # External interfaces
│   ├── db/                # Database API (renamed from database/)
│   ├── reedql/            # Query language (moved from root)
│   └── cli/               # CLI commands (moved from bin/)
│
├── store/                  # Storage layer
│   ├── tables/            # Table operations (moved from root)
│   ├── btree/             # B+-Tree engine (moved from root)
│   ├── indices/           # Index management (moved from root)
│   └── registry/          # Dictionary system (moved from root)
│
├── validate/               # Data validation
│   ├── schema/            # RBKS validation (moved from root)
│   └── functions/         # Computed functions (moved from root)
│
├── process/                # Process coordination
│   ├── locks/             # Concurrency locks (renamed from concurrent/)
│   ├── conflict/          # Conflict resolution (moved from root)
│   ├── merge/             # CSV merging (moved from root)
│   └── version/           # Delta versioning (moved from root)
│
├── ops/                    # Operations
│   ├── backup/            # Backup & restore (moved from root)
│   ├── metrics/           # Observability (moved from root)
│   └── log/               # Change logs (moved from root)
│
├── error.rs
└── lib.rs
```

## Benefits

**Developer Experience**:
- ✅ Clear entry points: "I want to use API → go to `api/`"
- ✅ Intent-based navigation: "I need storage → go to `store/`"
- ✅ Logical grouping: Related modules together
- ✅ Scalable: Easy to add new modules to right category

**Code Organization**:
- ✅ 5 top-level categories vs 16 flat modules
- ✅ Clear separation of concerns
- ✅ Future-proof (e.g., `api/rest/` later)

## Breaking Changes

**Import changes** - All imports need updating:

```rust
// Before:
use crate::database::Database;
use crate::reedql::parse;
use crate::concurrent::Lock;

// After:
use crate::api::db::Database;
use crate::api::reedql::parse;
use crate::process::locks::Lock;
```

**Public API preserved** - External users unaffected:

```rust
// lib.rs re-exports maintain public API
pub use api::db::Database;
pub use api::reedql::*;
// External code still works:
use reedbase::Database;  // ✓ Still works
```

## Dependencies
- **Should complete AFTER**: FIX-001 (tests must pass first)
- **Can do BEFORE or AFTER**: TESTS-100, RENAME-200, SPLIT-300

**Recommendation**: Do this FIRST (after FIX-001), then other refactorings work with clean structure.

## Implementation Steps

### Step 1: Create New Directory Structure

```bash
cd src

# Create top-level categories
mkdir -p api/db api/reedql api/cli
mkdir -p store/tables store/btree store/indices store/registry
mkdir -p validate/schema validate/functions
mkdir -p process/locks process/conflict process/merge process/version
mkdir -p ops/backup ops/metrics ops/log
```

### Step 2: Move Modules (one category at a time)

#### 2.1 API Layer
```bash
# database/ → api/db/
git mv database/ api/db/

# reedql/ → api/reedql/
git mv reedql/ api/reedql/

# bin/ → api/cli/
git mv bin/ api/cli/
```

#### 2.2 Storage Layer
```bash
git mv tables/ store/tables/
git mv btree/ store/btree/
git mv indices/ store/indices/
git mv registry/ store/registry/
```

#### 2.3 Validation Layer
```bash
git mv schema/ validate/schema/
git mv functions/ validate/functions/
```

#### 2.4 Process Layer
```bash
git mv concurrent/ process/locks/  # Also rename concurrent → locks
git mv conflict/ process/conflict/
git mv merge/ process/merge/
git mv version/ process/version/
```

#### 2.5 Operations Layer
```bash
git mv backup/ ops/backup/
git mv metrics/ ops/metrics/
git mv log/ ops/log/
```

### Step 3: Update lib.rs

```rust
// src/lib.rs

// API layer
pub mod api {
    pub mod db;
    pub mod reedql;
    pub mod cli;
}

// Storage layer
pub mod store {
    pub mod tables;
    pub mod btree;
    pub mod indices;
    pub mod registry;
}

// Validation layer
pub mod validate {
    pub mod schema;
    pub mod functions;
}

// Process coordination
pub mod process {
    pub mod locks;
    pub mod conflict;
    pub mod merge;
    pub mod version;
}

// Operations
pub mod ops {
    pub mod backup;
    pub mod metrics;
    pub mod log;
}

pub mod error;

// Re-export commonly used types for backward compatibility
pub use api::db::{Database, DatabaseStats};
pub use api::reedql::{QueryResult, ReedQLError};
pub use error::{ReedError, ReedResult};
pub use store::btree::BPlusTree;
pub use validate::schema::RBKSValidator;
// ... other public exports
```

### Step 4: Update Internal Imports (CRITICAL - Most time consuming!)

**⚠️ This is the main effort of this ticket! Every import must be updated.**

#### 4.1 Find All Import Occurrences

```bash
cd reedbase

# Create analysis report
cat > /tmp/import_analysis.sh << 'SCRIPT'
#!/bin/bash
echo "=== Import Analysis for Folder Restructure ==="
echo ""

# Check each old module path
for module in database reedql bin concurrent conflict merge version \
              schema functions tables btree indices registry \
              backup metrics log; do
  count=$(grep -r "use crate::${module}::" src/ --include="*.rs" 2>/dev/null | wc -l)
  if [ "$count" -gt 0 ]; then
    echo "${module}: $count occurrences"
    grep -r "use crate::${module}::" src/ --include="*.rs" -l 2>/dev/null | head -5
    echo ""
  fi
done

echo "Total files to update:"
grep -r "use crate::" src/ --include="*.rs" -l | wc -l
SCRIPT

chmod +x /tmp/import_analysis.sh
/tmp/import_analysis.sh
```

This will show you:
- How many imports per old module
- Which files need updating
- Total scope of work

#### 4.2 Import Mapping Reference

**Use this mapping for replacements:**

| Old Import | New Import | Category |
|------------|------------|----------|
| `use crate::database::` | `use crate::api::db::` | API |
| `use crate::reedql::` | `use crate::api::reedql::` | API |
| `use crate::bin::` | `use crate::api::cli::` | API |
| `use crate::tables::` | `use crate::store::tables::` | Storage |
| `use crate::btree::` | `use crate::store::btree::` | Storage |
| `use crate::indices::` | `use crate::store::indices::` | Storage |
| `use crate::registry::` | `use crate::store::registry::` | Storage |
| `use crate::schema::` | `use crate::validate::schema::` | Validation |
| `use crate::functions::` | `use crate::validate::functions::` | Validation |
| `use crate::concurrent::` | `use crate::process::locks::` | Process |
| `use crate::conflict::` | `use crate::process::conflict::` | Process |
| `use crate::merge::` | `use crate::process::merge::` | Process |
| `use crate::version::` | `use crate::process::version::` | Process |
| `use crate::backup::` | `use crate::ops::backup::` | Ops |
| `use crate::metrics::` | `use crate::ops::metrics::` | Ops |
| `use crate::log::` | `use crate::ops::log::` | Ops |

#### 4.3 Automated Replacement (Careful!)

```bash
# Replace all imports across codebase
# DO THIS CATEGORY BY CATEGORY, TEST AFTER EACH!

# API layer
find src -name "*.rs" -type f -exec sed -i '' 's/use crate::database::/use crate::api::db::/g' {} \;
find src -name "*.rs" -type f -exec sed -i '' 's/use crate::reedql::/use crate::api::reedql::/g' {} \;
find src -name "*.rs" -type f -exec sed -i '' 's/use crate::bin::/use crate::api::cli::/g' {} \;

# TEST NOW!
cargo check
# Fix any issues before continuing

# Storage layer
find src -name "*.rs" -type f -exec sed -i '' 's/use crate::tables::/use crate::store::tables::/g' {} \;
find src -name "*.rs" -type f -exec sed -i '' 's/use crate::btree::/use crate::store::btree::/g' {} \;
find src -name "*.rs" -type f -exec sed -i '' 's/use crate::indices::/use crate::store::indices::/g' {} \;
find src -name "*.rs" -type f -exec sed -i '' 's/use crate::registry::/use crate::store::registry::/g' {} \;

# TEST NOW!
cargo check

# Validation layer
find src -name "*.rs" -type f -exec sed -i '' 's/use crate::schema::/use crate::validate::schema::/g' {} \;
find src -name "*.rs" -type f -exec sed -i '' 's/use crate::functions::/use crate::validate::functions::/g' {} \;

# TEST NOW!
cargo check

# Process layer
find src -name "*.rs" -type f -exec sed -i '' 's/use crate::concurrent::/use crate::process::locks::/g' {} \;
find src -name "*.rs" -type f -exec sed -i '' 's/use crate::conflict::/use crate::process::conflict::/g' {} \;
find src -name "*.rs" -type f -exec sed -i '' 's/use crate::merge::/use crate::process::merge::/g' {} \;
find src -name "*.rs" -type f -exec sed -i '' 's/use crate::version::/use crate::process::version::/g' {} \;

# TEST NOW!
cargo check

# Operations layer
find src -name "*.rs" -type f -exec sed -i '' 's/use crate::backup::/use crate::ops::backup::/g' {} \;
find src -name "*.rs" -type f -exec sed -i '' 's/use crate::metrics::/use crate::ops::metrics::/g' {} \;
find src -name "*.rs" -type f -exec sed -i '' 's/use crate::log::/use crate::ops::log::/g' {} \;

# FINAL TEST
cargo check
```

#### 4.4 Manual Review Required

**Some imports need manual attention:**

1. **Relative imports** (within same module):
   ```rust
   // If you're in api/db/types.rs:
   use super::Database;     // Still correct (same module)
   use crate::api::db::Query;  // Explicit path
   ```

2. **Re-exports** might break:
   ```rust
   // Check all pub use statements
   grep -r "pub use" src/ --include="*.rs"
   ```

3. **Path-based strings** (if any):
   ```rust
   // Check for hardcoded module paths in strings
   grep -r '"database::' src/ --include="*.rs"
   grep -r '"reedql::' src/ --include="*.rs"
   ```

#### 4.5 Test Each Layer

After updating each category:

```bash
# Compile check
cargo check

# Run tests for that category
cargo test --lib api::       # After API updates
cargo test --lib store::     # After storage updates
cargo test --lib validate::  # After validation updates
cargo test --lib process::   # After process updates
cargo test --lib ops::       # After ops updates

# Full test suite
cargo test --lib
```

**Example updates in one file:**
```rust
// Before:
use crate::database::Database;
use crate::concurrent::Lock;
use crate::btree::BPlusTree;

// After:
use crate::api::db::Database;
use crate::process::locks::Lock;
use crate::store::btree::BPlusTree;
```

**Can use find-replace** (carefully!):
```bash
# Example: Update database → api::db
find src -name "*.rs" -exec sed -i '' 's/use crate::database::/use crate::api::db::/g' {} \;

# But verify each change manually!
```

### Step 5: Update mod.rs Files

Each moved module's `mod.rs` needs path updates if it imports siblings:

```rust
// api/db/mod.rs - if it imports reedql
// Before:
use crate::reedql::parse;

// After:
use crate::api::reedql::parse;
```

### Step 6: Update Cargo.toml

```toml
# If we have explicit module paths, update them:
[[bin]]
name = "reedbase"
path = "src/api/cli/reedbase.rs"  # was: src/bin/reedbase.rs
```

### Step 7: Update Tests

Integration tests in `.workbench/tests/` need import updates:

```rust
// Before:
use reedbase::database::Database;

// After:
use reedbase::api::db::Database;
// OR (if re-exported in lib.rs):
use reedbase::Database;  // Preferred - shorter
```

### Step 8: Verify

```bash
# Check compilation
cargo check

# Run tests
cargo test --lib

# Check for any remaining old imports
grep -r "use crate::database::" src/ --include="*.rs"
grep -r "use crate::concurrent::" src/ --include="*.rs"
# Should return nothing

# Verify public API unchanged
cargo doc --no-deps --open
# Check that public types are still exported
```

## Verification
- [ ] All modules moved to new locations
- [ ] `concurrent/` renamed to `process/locks/`
- [ ] `database/` renamed to `api/db/`
- [ ] `bin/` moved to `api/cli/`
- [ ] All internal imports updated
- [ ] lib.rs updated with new module structure
- [ ] All tests pass (`cargo test --lib`)
- [ ] Documentation builds (`cargo doc`)
- [ ] Public API preserved (external code still works)
- [ ] No old imports remain (`grep` check passes)

## Files Affected

**Moved**: 16 directories → 5 top-level + 16 subdirectories
**Modified**: Every `.rs` file with imports (~126 files)
**Critical**: `lib.rs`, `Cargo.toml`, integration tests

## Rollback Plan

If something breaks:

```bash
# Git makes this easy - just revert
git log --oneline | head -5
git revert <commit-hash>

# Or if not committed yet:
git reset --hard HEAD

# Restore from backup snapshot
cp -r ../../_workbench/Archive/ReedBase/pre-refactoring-2025-11-05-snapshot/src/ .
```

## Notes

**Why do this EARLY?**
- Other refactorings (SPLIT-300) will create new files
- Better to have clean structure first
- Import updates easier with fewer files

**Why do this AFTER FIX-001?**
- Tests must pass before structural changes
- Easier to verify nothing broke if tests work before

**Automation possibility**:
Could write a script to automate import updates, but manual is safer for first time.

**Time breakdown**:
- Create directories: 5 min
- Move modules: 10 min
- Update lib.rs: 10 min
- Update imports: 30 min (most time-consuming)
- Verify & test: 10 min
- **Total: ~1 hour**

## Decision Rationale

**Why `process/` over `sync/` or `coord/`?**
- `sync/` implies P2P synchronization (misleading)
- `coord/` less clear than `process/`
- `process/` clearly indicates "process coordination"

**Why `store/` over `storage/`?**
- Shorter (5 vs 7 chars)
- Same meaning

**Why `validate/` over `validation/`?**
- Shorter (8 vs 10 chars)
- Verb form (more active)

**Why `ops/` over `operations/` or `management/`?**
- Standard abbreviation
- Clear and concise

**Why `api/db/` over `api/database/`?**
- Shorter (2 vs 8 chars)
- Common abbreviation
- `db` is standard in industry
