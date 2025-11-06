# 030-[VALIDATE]-01: Schema Validation System

**Created**: 2025-11-06  
**Phase**: 3 (Validation Layer)  
**Estimated Effort**: 3-4 hours  
**Dependencies**: 020-[STORE]-04 (Tables - for schema storage)  
**Blocks**: Database layer, API layer

---

## Status
- [x] Not Started
- [ ] In Progress
- [ ] Complete

---

## 🚨 GOLDEN RULE: COMPLETE PARITY - NO SHORTCUTS

### Mandatory Pre-Implementation Analysis

**Verification Date**: 2025-11-06

- [x] **last/src/schema/ vollständig gelesen** - 5 Dateien analysiert
- [x] **Alle Typen identifiziert** - 2 structs (Schema, ColumnDef)
- [x] **Alle Funktionen identifiziert** - 14 public functions (siehe unten)
- [x] **Keine Shortcuts geplant** - Bestätigung: Ich werde NICHTS weglassen
- [x] **Separate test files bestätigt** - loader_test.rs, rbks_test.rs, validation_test.rs
- [x] **Split-Strategie validiert** - rbks.rs 647 lines → 2 files <400 each

**Files in this ticket**:
```
last/src/schema/types.rs        306 lines  → current/src/validate/schema/types.rs
last/src/schema/loader.rs       142 lines  → current/src/validate/schema/loader.rs
last/src/schema/validation.rs   270 lines  → current/src/validate/schema/validation.rs
last/src/schema/rbks.rs         647 lines  → current/src/validate/schema/rbks*.rs (SPLIT 2!)
last/src/schema/mod.rs          110 lines  → current/src/validate/schema/mod.rs
Total: 1475 lines → ~1500 lines (overhead for headers)
```

**Target Split for rbks.rs**:
```
rbks_types.rs         ~150 lines  (ParsedKey, Modifiers structs + constants)
rbks_validate.rs      ~250 lines  (validate_key, parse_key functions)
rbks_normalize.rs     ~250 lines  (normalize_key, fallback_chain functions)
```

**Public Types** (MUST ALL BE COPIED):
```rust
// From types.rs (2 structs):
pub struct Schema {
    pub version: String,
    pub strict: bool,
    pub columns: Vec<ColumnDef>,
}

pub struct ColumnDef {
    pub name: String,
    pub column_type: String,
    pub required: bool,
    pub unique: bool,
    pub primary_key: bool,
    pub min: Option<i64>,
    pub max: Option<i64>,
    pub min_length: Option<usize>,
    pub max_length: Option<usize>,
    pub pattern: Option<String>,
}

// From rbks.rs (2 structs + constants):
pub struct ParsedKey {
    pub base: String,
    pub modifiers: Modifiers,
    pub hierarchy: Vec<String>,
}

pub struct Modifiers {
    pub language: Option<String>,
    pub environment: Option<String>,
    pub season: Option<String>,
    pub variant: Option<String>,
    pub custom: Vec<String>,
}

pub const KNOWN_LANGUAGES: &[&str] = &["de", "en", "fr", "es", "it", ...];
pub const KNOWN_ENVIRONMENTS: &[&str] = &["dev", "prod", "staging", "test"];
pub const KNOWN_SEASONS: &[&str] = &["christmas", "easter", "summer", "winter"];
pub const KNOWN_VARIANTS: &[&str] = &["mobile", "desktop", "tablet"];
pub const RBKS_V2_PATTERN: &str = r"^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+(<[a-z0-9,]+>)?$";
```

**Public Functions** (MUST ALL BE COPIED - 14 total):

**loader.rs** (5 functions):
```rust
pub fn load_schema(base_path: &Path, table_name: &str) -> ReedResult<Schema>
pub fn save_schema(base_path: &Path, table_name: &str, schema: &Schema) -> ReedResult<()>
pub fn delete_schema(base_path: &Path, table_name: &str) -> ReedResult<()>
pub fn schema_exists(base_path: &Path, table_name: &str) -> bool
pub fn create_default_schema(table_name: &str) -> Schema
```

**rbks.rs** (3 functions - will split across files):
```rust
pub fn validate_key(key: &str) -> ReedResult<()>
pub fn parse_key(key: &str) -> ReedResult<ParsedKey>
pub fn normalize_key(raw: &str) -> ReedResult<String>
```

**validation.rs** (3 functions):
```rust
pub fn validate_row(row: &CsvRow, schema: &Schema) -> ReedResult<()>
pub fn validate_rows(rows: &[CsvRow], schema: &Schema) -> ReedResult<()>
pub fn validate_uniqueness(rows: &[CsvRow], schema: &Schema) -> ReedResult<()>
```

**ParsedKey methods** (3 methods):
```rust
impl ParsedKey {
    pub fn depth(&self) -> usize
    pub fn namespace(&self) -> &str
    pub fn fallback_chain(&self) -> Vec<String>
}
```

**Test Files** (separate files, as per Standard #5):
```
loader_test.rs         275 lines
rbks_test.rs           546 lines
validation_test.rs     474 lines
```

**Dependencies**:
```
Internal (from Phase 1-2):
  - crate::error::{ReedError, ReedResult}
  - crate::store::tables::Table                 (from 020-04)

External:
  - once_cell::sync::Lazy                       (for static regexes)
  - regex::Regex                                (for RBKS pattern matching)
  - serde::{Serialize, Deserialize}             (for TOML schema files)
  - toml                                        (for schema serialization)
```

**Dependency Analysis**:
```
Level 0: types.rs (no deps)
Level 1: rbks_types.rs (only std)
Level 2: rbks_validate.rs (uses rbks_types)
Level 3: rbks_normalize.rs (uses rbks_types, rbks_validate)
Level 4: loader.rs (uses types, tables from 020-04)
Level 5: validation.rs (uses types, rbks_validate)
```

**Verification Commands**:
```bash
# Verify line counts
wc -l last/src/schema/{types,loader,validation,rbks,mod}.rs
# Expected: 306, 142, 270, 647, 110

# Verify struct count
rg "^pub struct" last/src/schema/types.rs
# Expected: 2 structs

rg "^pub struct" last/src/schema/rbks.rs
# Expected: 2 structs

# Verify function count
rg "^pub fn" last/src/schema/{loader,validation}.rs | wc -l
# Expected: 8 functions

rg "^pub fn" last/src/schema/rbks.rs | wc -l
# Expected: 3 functions

# Check dependencies
rg "^use crate::" last/src/schema/loader.rs
# Expected: error, tables
```

**Bestätigung**: Ich habe verstanden dass `last/src/schema/` die Spezifikation ist und `current/src/validate/schema/` EXAKT identisch sein muss. rbks.rs MUSS gesplittet werden (647 lines → 3 files <400 each).

---

## Context & Scope

**This ticket implements**: Schema validation (RBKS v2 + column schemas)  
**From**: `last/src/schema/{types,loader,validation,rbks,mod}.rs`  
**To**: `current/src/validate/schema/` (with rbks split into 3 files)

**Why this module?**
- **RBKS v2**: Enforces structured key format for reliable queries
- **Column schemas**: Type-safe data with TOML-based schemas
- **Early validation**: Catch errors at write time (< 30μs overhead)
- **Enables indices**: Structured keys enable O(1) lookups

**Critical: rbks.rs Split Strategy**:
```
rbks.rs (647 lines) splits into:

1. rbks_types.rs (~150 lines)
   - ParsedKey struct
   - Modifiers struct
   - Constants: KNOWN_LANGUAGES, KNOWN_ENVIRONMENTS, KNOWN_SEASONS, KNOWN_VARIANTS
   - RBKS_V2_PATTERN regex
   - ParsedKey impl methods (depth, namespace, fallback_chain)

2. rbks_validate.rs (~250 lines)
   - validate_key() function
   - parse_key() function
   - Internal helpers: validate_modifiers(), validate_hierarchy()

3. rbks_normalize.rs (~250 lines)
   - normalize_key() function
   - Internal helpers: normalize_hierarchy(), normalize_modifiers()
   - Deduplication logic
```

**What comes AFTER this ticket**:
- ✅ **Schema module COMPLETE** - Ready for use by database layer
- ➡️ **Next**: 030-[VALIDATE]-02 (Registry - user/action dictionaries)

**Dependency Graph** (validated 2025-11-06):
```
Level 0 (no deps):
└─ types.rs ✅

Level 1 (only std):
└─ rbks_types.rs ✅

Level 2 (uses rbks_types):
└─ rbks_validate.rs → rbks_types ✅

Level 3 (uses rbks_types + rbks_validate):
└─ rbks_normalize.rs → rbks_types, rbks_validate ✅

Level 4 (uses types + tables from 020-04):
└─ loader.rs → types, tables::Table (020-04) ✅

Level 5 (uses types + rbks_validate):
└─ validation.rs → types, rbks_validate ✅
```

---

## Reference (Old Tickets)

**This ticket may reference**:
- Old analysis of schema/ module structure
- RBKS v2 specification document
- Column validation requirements

**New ticket provides**:
- ✅ Golden Rule verification against actual last/src/ code
- ✅ rbks.rs split strategy (647 → ~650 across 3 files)
- ✅ Complete dependency analysis (Level 0-5)
- ✅ QS-Matrix (16 checks)
- ✅ BBC English corrections
- ✅ Workspace structure
- ✅ Regression testing

---

## BBC English Corrections Required

**Issues found in last/src/schema/**:
```rust
// Comments use American English
"optimize" → "optimise"
"initialize" → "initialise"
"serialize" → "serialise"
"normalized" → "normalised"
```

**Action**: Fix ALL comments/docs to BBC English in current/

---

## Implementation Steps

### Step 1: Create File Structure (10 min)

**Create all files with copyright headers**:
```bash
cd current/src
mkdir -p validate/schema

for file in types.rs loader.rs validation.rs rbks_types.rs rbks_validate.rs rbks_normalize.rs mod.rs; do
  cat > validate/schema/$file << 'EOF'
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

EOF
done
```

---

### Step 2: Implement types.rs (25 min)

**Reference**: `last/src/schema/types.rs` (306 lines)  
**Target**: `current/src/validate/schema/types.rs`

**What to copy** (Golden Rule: EVERYTHING):
1. ✅ Schema struct (all 3 fields)
2. ✅ ColumnDef struct (all 10 fields)
3. ✅ All impl blocks for both structs
4. ✅ Derive macros: Debug, Clone, Serialize, Deserialize

**Changes**:
```rust
// Update imports
use serde::{Deserialize, Serialize};

// Fix BBC English in comments
```

**Verification**:
```bash
wc -l current/src/validate/schema/types.rs
# Expected: ~306 lines

rg "^pub struct" current/src/validate/schema/types.rs
# Expected: 2 structs

cargo check -p reedbase
```

---

### Step 3: Implement rbks_types.rs (30 min)

**Reference**: `last/src/schema/rbks.rs` lines 1-200 (approx)  
**Target**: `current/src/validate/schema/rbks_types.rs` (~150 lines)

**What to extract**:
```rust
//! RBKS v2 types and constants.

use once_cell::sync::Lazy;
use regex::Regex;

/// Parsed key with modifiers.
pub struct ParsedKey {
    pub base: String,
    pub modifiers: Modifiers,
    pub hierarchy: Vec<String>,
}

/// Key modifiers (language, environment, etc.).
pub struct Modifiers {
    pub language: Option<String>,
    pub environment: Option<String>,
    pub season: Option<String>,
    pub variant: Option<String>,
    pub custom: Vec<String>,
}

/// Known language codes (ISO 639-1).
pub const KNOWN_LANGUAGES: &[&str] = &[
    "de", "en", "fr", "es", "it", // ... (copy ALL from last/)
];

/// Known environments.
pub const KNOWN_ENVIRONMENTS: &[&str] = &["dev", "prod", "staging", "test"];

/// Known seasons.
pub const KNOWN_SEASONS: &[&str] = &["christmas", "easter", "summer", "winter"];

/// Known variants.
pub const KNOWN_VARIANTS: &[&str] = &["mobile", "desktop", "tablet"];

/// RBKS v2 pattern regex.
pub static RBKS_V2_PATTERN: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r"^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+(<[a-z0-9,]+>)?$").unwrap()
});

impl ParsedKey {
    /// Get hierarchy depth.
    pub fn depth(&self) -> usize {
        // Copy from last/
    }
    
    /// Get namespace (first segment).
    pub fn namespace(&self) -> &str {
        // Copy from last/
    }
    
    /// Generate fallback chain.
    pub fn fallback_chain(&self) -> Vec<String> {
        // Copy from last/
    }
}
```

**Verification**:
```bash
wc -l current/src/validate/schema/rbks_types.rs
# Expected: ~150 lines

rg "^pub (struct|const|static)" current/src/validate/schema/rbks_types.rs
# Expected: 2 structs, 4 constants, 1 static

cargo check -p reedbase
```

---

### Step 4: Implement rbks_validate.rs (40 min)

**Reference**: `last/src/schema/rbks.rs` lines 200-450 (approx)  
**Target**: `current/src/validate/schema/rbks_validate.rs` (~250 lines)

**What to extract**:
```rust
//! RBKS v2 validation functions.

use crate::error::{ReedError, ReedResult};
use super::rbks_types::{ParsedKey, Modifiers, RBKS_V2_PATTERN, KNOWN_LANGUAGES, ...};

/// Validate key format.
pub fn validate_key(key: &str) -> ReedResult<()> {
    // Copy from last/ (lines ~310-400)
}

/// Parse key into components.
pub fn parse_key(key: &str) -> ReedResult<ParsedKey> {
    // Copy from last/ (lines ~405-600)
}

// Internal helpers
fn validate_modifiers(modifiers: &Modifiers) -> ReedResult<()> {
    // Copy from last/
}

fn validate_hierarchy(hierarchy: &[String]) -> ReedResult<()> {
    // Copy from last/
}
```

**Verification**:
```bash
wc -l current/src/validate/schema/rbks_validate.rs
# Expected: ~250 lines

rg "^pub fn" current/src/validate/schema/rbks_validate.rs
# Expected: 2 functions

cargo check -p reedbase
```

---

### Step 5: Implement rbks_normalize.rs (40 min)

**Reference**: `last/src/schema/rbks.rs` lines 450-647 (approx)  
**Target**: `current/src/validate/schema/rbks_normalize.rs` (~250 lines)

**What to extract**:
```rust
//! RBKS v2 normalisation functions.

use crate::error::{ReedError, ReedResult};
use super::rbks_types::{ParsedKey, Modifiers};
use super::rbks_validate::parse_key;

/// Normalise malformed key.
pub fn normalize_key(raw: &str) -> ReedResult<String> {
    // Copy from last/ (lines ~605-647)
}

// Internal helpers
fn normalize_hierarchy(raw: &str) -> String {
    // Copy from last/
}

fn normalize_modifiers(raw: &[String]) -> Vec<String> {
    // Copy from last/ (deduplication + sorting)
}
```

**Verification**:
```bash
wc -l current/src/validate/schema/rbks_normalize.rs
# Expected: ~250 lines

rg "^pub fn" current/src/validate/schema/rbks_normalize.rs
# Expected: 1 function

cargo check -p reedbase
```

---

### Step 6: Implement loader.rs (30 min)

**Reference**: `last/src/schema/loader.rs` (142 lines)  
**Target**: `current/src/validate/schema/loader.rs`

**What to copy**:
1. ✅ All 5 functions
2. ✅ Schema file paths (`.reedbase/schemas/{table}.toml`)
3. ✅ TOML serialization logic

**Changes**:
```rust
// Update imports
use crate::error::{ReedError, ReedResult};
use crate::store::tables::Table;  // From 020-04
use super::types::Schema;

// Fix BBC English
```

**Verification**:
```bash
wc -l current/src/validate/schema/loader.rs
# Expected: ~142 lines

rg "^pub fn" current/src/validate/schema/loader.rs
# Expected: 5 functions

cargo check -p reedbase
```

---

### Step 7: Implement validation.rs (35 min)

**Reference**: `last/src/schema/validation.rs` (270 lines)  
**Target**: `current/src/validate/schema/validation.rs`

**What to copy**:
1. ✅ validate_row() function
2. ✅ validate_rows() function
3. ✅ validate_uniqueness() function
4. ✅ All type validation logic (string, integer, boolean, etc.)

**Changes**:
```rust
// Update imports
use crate::error::{ReedError, ReedResult};
use super::types::{Schema, ColumnDef};
use super::rbks_validate::validate_key;

// Fix BBC English
```

**Verification**:
```bash
wc -l current/src/validate/schema/validation.rs
# Expected: ~270 lines

rg "^pub fn" current/src/validate/schema/validation.rs
# Expected: 3 functions

cargo check -p reedbase
```

---

### Step 8: Update mod.rs (20 min)

**Target**: `current/src/validate/schema/mod.rs`

**Add modules**:
```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Schema validation module for ReedBase.

pub mod types;
pub mod loader;
pub mod validation;
pub mod rbks_types;
pub mod rbks_validate;
pub mod rbks_normalize;

// Re-exports
pub use types::{ColumnDef, Schema};
pub use loader::{
    create_default_schema, delete_schema, load_schema, save_schema, schema_exists,
};
pub use validation::{validate_row, validate_rows, validate_uniqueness};
pub use rbks_types::{
    Modifiers, ParsedKey, KNOWN_ENVIRONMENTS, KNOWN_LANGUAGES, KNOWN_SEASONS, KNOWN_VARIANTS,
    RBKS_V2_PATTERN,
};
pub use rbks_validate::{parse_key, validate_key};
pub use rbks_normalize::normalize_key;
```

---

### Step 9: Adapt Tests (50 min)

**Reference**: `last/src/schema/{loader,rbks,validation}_test.rs`  
**Target**: `current/tests/validate/schema/`

```bash
mkdir -p current/tests/validate/schema

# Create test files
touch current/tests/validate/schema/loader_test.rs
touch current/tests/validate/schema/rbks_test.rs
touch current/tests/validate/schema/validation_test.rs
```

**Adapt tests**:
- Update imports: `use reedbase::validate::schema::...`
- Update paths to test data if needed
- Verify all tests pass

---

### Step 10: Quality Verification (20 min)

```bash
# Run quality check on all files
for file in types.rs rbks_types.rs rbks_validate.rs rbks_normalize.rs loader.rs validation.rs; do
  echo "Checking $file..."
  ./scripts/quality-check.sh current/src/validate/schema/$file
done

# Run regression verification
./scripts/regression-verify.sh schema
```

---

### Step 11: Final Verification (20 min)

```bash
# Verify split successful (all files <400 lines)
echo "=== File Size Verification ==="
for file in types.rs rbks_types.rs rbks_validate.rs rbks_normalize.rs loader.rs validation.rs; do
  lines=$(wc -l < current/src/validate/schema/$file)
  if [ $lines -le 400 ]; then
    echo "✅ $file: $lines lines (under limit)"
  else
    echo "❌ $file: $lines lines (EXCEEDS LIMIT!)"
  fi
done

# Verify all functions present
echo ""
echo "=== Function Count Verification ==="
rg "^pub fn" current/src/validate/schema/*.rs | wc -l
echo "Expected: 14 functions"

# Final test run
echo ""
echo "=== Final Test Run ==="
cargo test -p reedbase --lib validate::schema
cargo test -p reedbase-last --lib schema
```

---

## ✅ Quality Assurance Matrix (MANDATORY)

### Pre-Implementation

- [x] **Golden Rule: last/ analysed completely**
  - [x] 5 source files validated
  - [x] 14 public functions + 4 types identified
  - [x] Split strategy: rbks.rs 647 → 3 files <400 each

- [x] **Standard #0: Code Reuse**
  - [x] Uses Table from 020-04 (loader.rs) ✅
  - [x] Uses error types from Phase 1 ✅

- [x] **Standard #3: File Naming**
  - [x] Specific names: rbks_validate, rbks_normalize (not rbks_utils) ✅

- [x] **Standard #8: Architecture**
  - [x] Layered structure: validate/schema/ ✅

### During Implementation

- [ ] **Standard #1: BBC English**
  - [ ] All comments fixed (optimise, initialise, normalise)

- [ ] **Standard #4: Single Responsibility**
  - [ ] rbks_types.rs: Types + constants only ✅
  - [ ] rbks_validate.rs: Validation only ✅
  - [ ] rbks_normalize.rs: Normalisation only ✅
  - [ ] loader.rs: Schema I/O only ✅
  - [ ] validation.rs: Column validation only ✅

### Post-Implementation

- [ ] **Standard #2: File Size <400 Lines**
  - [ ] types.rs: 306 lines ✅
  - [ ] loader.rs: 142 lines ✅
  - [ ] validation.rs: 270 lines ✅
  - [ ] rbks_types.rs: ~150 lines ✅
  - [ ] rbks_validate.rs: ~250 lines ✅
  - [ ] rbks_normalize.rs: ~250 lines ✅

- [ ] **Standard #5: Separate Test Files**
  - [ ] loader_test.rs in tests/ ✅
  - [ ] rbks_test.rs in tests/ ✅
  - [ ] validation_test.rs in tests/ ✅

- [ ] **Regression: All Tests Passing**
  - [ ] `cargo test -p reedbase --lib validate::schema` ✅
  - [ ] `cargo test -p reedbase-last --lib schema` ✅

---

## Success Criteria

### Functionality
- ✅ All 4 types implemented (Schema, ColumnDef, ParsedKey, Modifiers)
- ✅ All 14 functions present
- ✅ rbks.rs split successful (647 → ~650 across 3 files)
- ✅ Schema validation COMPLETE (RBKS v2 + column schemas)

### Quality
- ✅ All files <400 lines (split successful)
- ✅ BBC English everywhere (optimise, initialise, normalise)
- ✅ Specific file names (rbks_validate, rbks_normalize)
- ✅ Single responsibility per file
- ✅ No duplicates

### Regression
- ✅ All tests passing (loader, rbks, validation)
- ✅ Baseline unchanged (last/ tests still green)
- ✅ Behaviour identical (same validation results)

### Performance
- ✅ Key validation < 20μs
- ✅ Row validation < 1ms
- ✅ Schema load < 5ms

---

## Commit Message Template

```
[CLEAN-030-01] feat(validate): implement Schema validation system

Phase 3 - Validation Layer - Ticket 1/2

✅ Golden Rule: Complete parity with last/src/schema/
✅ QS-Matrix: 16/16 checks passing (rbks.rs split successful!)
✅ Regression tests: X/X passing
✅ Behaviour: Identical to last/

Implementation:
- types.rs: Schema + ColumnDef structs (306 lines)
- loader.rs: Schema I/O operations (142 lines)
- validation.rs: Column validation (270 lines)
- rbks.rs split (647 → ~650 lines across 3 files):
  - rbks_types.rs: ParsedKey + Modifiers + constants (~150 lines)
  - rbks_validate.rs: validate_key + parse_key (~250 lines)
  - rbks_normalize.rs: normalize_key (~250 lines)

Quality:
- KISS Standard #2: ALL files <400 lines ✅
- BBC English: All comments corrected (optimise, normalise) ✅
- Specific names: rbks_validate, rbks_normalize ✅
- Single responsibility: Each file ONE operation type ✅

Schema module COMPLETE:
- RBKS v2 key validation (structured format enforcement)
- Column validation (type + constraint checking)
- TOML-based schemas with < 30μs validation overhead
- Ready for use by database/API layers

Dependencies:
- Uses Table from 020-04 (loader.rs) ✅

Workspace packages:
- reedbase (current): Schema complete, X tests passing
- reedbase-last (last): Baseline unchanged, X tests passing
```

---

## Next Steps

**After this ticket**:
- ✅ **Schema module 100% COMPLETE** (RBKS v2 + column validation ready)
- ➡️ **Next**: 030-[VALIDATE]-02 (Registry - user/action dictionaries)

**Unblocked by this ticket**:
- Database layer can validate keys before storage
- API layer can enforce column constraints
- Indices can rely on structured key format

---

**Validation Date**: 2025-11-06  
**Validated Against**: last/src/schema/ (5 files)  
**Estimated Time**: 3-4 hours  
**Complexity**: Medium-High (split required, regex logic, TOML handling)
