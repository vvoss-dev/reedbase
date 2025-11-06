# 030-[VALIDATE]-02: Registry System (User/Action Dictionaries)

**Created**: 2025-11-06  
**Phase**: 3 (Validation Layer)  
**Estimated Effort**: 2-3 hours  
**Dependencies**: 020-[STORE]-04 (Tables - for dictionary storage)  
**Blocks**: Database layer, Logging system

---

## Status
- [x] Not Started
- [ ] In Progress
- [ ] Complete

---

## 🚨 GOLDEN RULE: COMPLETE PARITY - NO SHORTCUTS

### Mandatory Pre-Implementation Analysis

**Verification Date**: 2025-11-06

- [x] **last/src/registry/ vollständig gelesen** - 3 Dateien analysiert
- [x] **Alle Typen identifiziert** - 0 structs (pure functions module)
- [x] **Alle Funktionen identifiziert** - 8 public functions (siehe unten)
- [x] **Keine Shortcuts geplant** - Bestätigung: Ich werde NICHTS weglassen
- [x] **Separate test files bestätigt** - dictionary_test.rs, init_test.rs
- [x] **Split-Strategie validiert** - dictionary.rs 473 lines → 2 files <400 each

**Files in this ticket**:
```
last/src/registry/dictionary.rs     473 lines  → current/src/validate/registry/dictionary*.rs (SPLIT 2!)
last/src/registry/init.rs           227 lines  → current/src/validate/registry/init.rs
last/src/registry/mod.rs             43 lines  → current/src/validate/registry/mod.rs
Total: 743 lines → ~760 lines (overhead for headers)
```

**Target Split for dictionary.rs**:
```
dictionary_actions.rs    ~200 lines  (Action code ↔ name mapping)
dictionary_users.rs      ~280 lines  (User code ↔ name mapping + persistence)
```

**Public Types** (MUST ALL BE COPIED):
```rust
// No public structs - pure function module
// Uses internal static DICTIONARIES with RwLock
```

**Public Functions** (MUST ALL BE COPIED - 8 total):

**dictionary.rs** (6 functions - will split across files):
```rust
// Action dictionary (→ dictionary_actions.rs):
pub fn get_action_name(code: u8) -> ReedResult<String>
pub fn get_action_code(name: &str) -> ReedResult<u8>

// User dictionary (→ dictionary_users.rs):
pub fn get_username(code: u32) -> ReedResult<String>
pub fn get_or_create_user_code(username: &str) -> ReedResult<u32>

// Shared (→ both files need):
pub fn reload_dictionaries() -> ReedResult<()>
pub fn set_base_path(path: PathBuf)
```

**init.rs** (2 functions):
```rust
pub fn init_registry(base_path: &Path) -> ReedResult<()>
pub fn validate_dictionaries(base_path: &Path) -> ReedResult<()>
```

**Test Files** (separate files, as per Standard #5):
```
dictionary_test.rs     202 lines
init_test.rs           156 lines
```

**Dependencies**:
```
Internal (from Phase 1-2):
  - crate::error::{ReedError, ReedResult}
  - crate::store::tables::Table                 (from 020-04)

External:
  - once_cell::sync::Lazy                       (for static dictionaries)
  - parking_lot::RwLock                         (for thread-safe access)
  - std::collections::HashMap                   (for code ↔ name mapping)
  - std::path::PathBuf                          (for base path storage)
```

**Dependency Analysis**:
```
Level 0: mod.rs (re-exports)
Level 1: dictionary_actions.rs (only std + error)
Level 2: dictionary_users.rs (uses tables from 020-04)
Level 3: init.rs (uses dictionary functions)
```

**Verification Commands**:
```bash
# Verify line counts
wc -l last/src/registry/{dictionary,init,mod}.rs
# Expected: 473, 227, 43

# Verify function count
rg "^pub fn" last/src/registry/dictionary.rs | wc -l
# Expected: 6 functions

rg "^pub fn" last/src/registry/init.rs | wc -l
# Expected: 2 functions

# Check dependencies
rg "^use crate::" last/src/registry/dictionary.rs
# Expected: error, tables
```

**Bestätigung**: Ich habe verstanden dass `last/src/registry/` die Spezifikation ist und `current/src/validate/registry/` EXAKT identisch sein muss. dictionary.rs MUSS gesplittet werden (473 lines → 2 files <400 each).

---

## Context & Scope

**This ticket implements**: User/Action dictionaries for encoded logs  
**From**: `last/src/registry/{dictionary,init,mod}.rs`  
**To**: `current/src/validate/registry/` (with dictionary split into 2 files)

**Why this module?**
- **Encoded logs**: Integer codes instead of strings (space savings)
- **Action codes**: 1 byte per action (create, update, delete, etc.)
- **User codes**: 4 bytes per user (vs ~20 bytes for username)
- **Persistent mapping**: Codes never change, even if names change
- **Thread-safe**: RwLock for concurrent read access

**Critical: dictionary.rs Split Strategy**:
```
dictionary.rs (473 lines) splits into:

1. dictionary_actions.rs (~200 lines)
   - Static ACTION_CODES HashMap
   - Static ACTION_NAMES HashMap
   - get_action_name(code: u8) -> ReedResult<String>
   - get_action_code(name: &str) -> ReedResult<u8>
   - Internal: load_action_dictionary()

2. dictionary_users.rs (~280 lines)
   - Static USER_CODES HashMap (RwLock)
   - Static USER_NAMES HashMap (RwLock)
   - Static BASE_PATH (RwLock<Option<PathBuf>>)
   - get_username(code: u32) -> ReedResult<String>
   - get_or_create_user_code(username: &str) -> ReedResult<u32>
   - reload_dictionaries() -> ReedResult<()>
   - set_base_path(path: PathBuf)
   - Internal: load_user_dictionary(), save_user_dictionary()
```

**What comes AFTER this ticket**:
- ✅ **Registry module COMPLETE** - Ready for use by logging system
- ✅ **Phase 3 (Validation Layer) COMPLETE** - All validation modules done
- ➡️ **Next**: Phase 4 (API Layer) - database, reedql

**Dependency Graph** (validated 2025-11-06):
```
Level 0:
└─ mod.rs (re-exports) ✅

Level 1 (only std):
└─ dictionary_actions.rs → error ✅

Level 2 (uses tables from 020-04):
└─ dictionary_users.rs → error, tables::Table (020-04) ✅

Level 3 (uses dictionary):
└─ init.rs → dictionary_actions, dictionary_users ✅
```

---

## Reference (Old Tickets)

**This ticket may reference**:
- Old analysis of registry/ module structure
- Dictionary persistence strategy
- Code allocation logic

**New ticket provides**:
- ✅ Golden Rule verification against actual last/src/ code
- ✅ dictionary.rs split strategy (473 → ~480 across 2 files)
- ✅ Complete dependency analysis (Level 0-3)
- ✅ QS-Matrix (16 checks)
- ✅ BBC English corrections
- ✅ Workspace structure
- ✅ Regression testing

---

## BBC English Corrections Required

**Issues found in last/src/registry/**:
```rust
// Comments use American English
"initialize" → "initialise"
"synchronized" → "synchronised"
```

**Action**: Fix ALL comments/docs to BBC English in current/

---

## Implementation Steps

### Step 1: Create File Structure (10 min)

**Create all files with copyright headers**:
```bash
cd current/src/validate
mkdir -p registry

for file in dictionary_actions.rs dictionary_users.rs init.rs mod.rs; do
  cat > registry/$file << 'EOF'
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

EOF
done
```

---

### Step 2: Implement dictionary_actions.rs (30 min)

**Reference**: `last/src/registry/dictionary.rs` lines 1-200 (approx)  
**Target**: `current/src/validate/registry/dictionary_actions.rs` (~200 lines)

**What to extract**:
```rust
//! Action code dictionary (1 byte per action).

use crate::error::{ReedError, ReedResult};
use once_cell::sync::Lazy;
use std::collections::HashMap;

/// Action codes (action name → u8 code).
static ACTION_CODES: Lazy<HashMap<String, u8>> = Lazy::new(|| {
    let mut map = HashMap::new();
    map.insert("create".to_string(), 1);
    map.insert("update".to_string(), 2);
    map.insert("delete".to_string(), 3);
    // ... copy ALL from last/
    map
});

/// Action names (u8 code → action name).
static ACTION_NAMES: Lazy<HashMap<u8, String>> = Lazy::new(|| {
    ACTION_CODES.iter().map(|(k, v)| (*v, k.clone())).collect()
});

/// Get action name from code.
pub fn get_action_name(code: u8) -> ReedResult<String> {
    // Copy from last/ (lines ~218-256)
}

/// Get action code from name.
pub fn get_action_code(name: &str) -> ReedResult<u8> {
    // Copy from last/ (lines ~257-294)
}
```

**Verification**:
```bash
wc -l current/src/validate/registry/dictionary_actions.rs
# Expected: ~200 lines

rg "^pub fn" current/src/validate/registry/dictionary_actions.rs
# Expected: 2 functions

cargo check -p reedbase
```

---

### Step 3: Implement dictionary_users.rs (45 min)

**Reference**: `last/src/registry/dictionary.rs` lines 200-473 (approx)  
**Target**: `current/src/validate/registry/dictionary_users.rs` (~280 lines)

**What to extract**:
```rust
//! User code dictionary (4 bytes per user, persistent).

use crate::error::{ReedError, ReedResult};
use crate::store::tables::Table;  // From 020-04
use once_cell::sync::Lazy;
use parking_lot::RwLock;
use std::collections::HashMap;
use std::path::PathBuf;

/// User codes (username → u32 code).
static USER_CODES: Lazy<RwLock<HashMap<String, u32>>> = Lazy::new(|| {
    RwLock::new(HashMap::new())
});

/// User names (u32 code → username).
static USER_NAMES: Lazy<RwLock<HashMap<u32, String>>> = Lazy::new(|| {
    RwLock::new(HashMap::new())
});

/// Base path for dictionary storage.
static BASE_PATH: Lazy<RwLock<Option<PathBuf>>> = Lazy::new(|| {
    RwLock::new(None)
});

/// Get username from code.
pub fn get_username(code: u32) -> ReedResult<String> {
    // Copy from last/ (lines ~295-334)
}

/// Get or create user code.
pub fn get_or_create_user_code(username: &str) -> ReedResult<u32> {
    // Copy from last/ (lines ~335-430)
}

/// Reload dictionaries from disk.
pub fn reload_dictionaries() -> ReedResult<()> {
    // Copy from last/ (lines ~431-442)
}

/// Set base path for dictionary storage.
pub fn set_base_path(path: PathBuf) {
    // Copy from last/ (lines ~443-end)
}

// Internal helpers
fn load_user_dictionary(base_path: &Path) -> ReedResult<()> {
    // Copy from last/
}

fn save_user_dictionary(base_path: &Path) -> ReedResult<()> {
    // Copy from last/
}
```

**Verification**:
```bash
wc -l current/src/validate/registry/dictionary_users.rs
# Expected: ~280 lines

rg "^pub fn" current/src/validate/registry/dictionary_users.rs
# Expected: 4 functions

cargo check -p reedbase
```

---

### Step 4: Implement init.rs (30 min)

**Reference**: `last/src/registry/init.rs` (227 lines)  
**Target**: `current/src/validate/registry/init.rs`

**What to copy** (Golden Rule: EVERYTHING):
1. ✅ init_registry() function
2. ✅ validate_dictionaries() function
3. ✅ All internal helpers

**Changes**:
```rust
// Update imports
use crate::error::{ReedError, ReedResult};
use crate::store::tables::Table;  // From 020-04
use super::dictionary_actions::{get_action_name, get_action_code};
use super::dictionary_users::{reload_dictionaries, set_base_path};

// Fix BBC English
```

**Verification**:
```bash
wc -l current/src/validate/registry/init.rs
# Expected: ~227 lines

rg "^pub fn" current/src/validate/registry/init.rs
# Expected: 2 functions

cargo check -p reedbase
```

---

### Step 5: Update mod.rs (15 min)

**Target**: `current/src/validate/registry/mod.rs`

**Add modules**:
```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Registry system for encoded logs (user/action dictionaries).

pub mod dictionary_actions;
pub mod dictionary_users;
pub mod init;

// Re-exports
pub use dictionary_actions::{get_action_code, get_action_name};
pub use dictionary_users::{
    get_or_create_user_code, get_username, reload_dictionaries, set_base_path,
};
pub use init::{init_registry, validate_dictionaries};
```

---

### Step 6: Adapt Tests (40 min)

**Reference**: `last/src/registry/{dictionary,init}_test.rs`  
**Target**: `current/tests/validate/registry/`

```bash
mkdir -p current/tests/validate/registry

# Create test files
touch current/tests/validate/registry/dictionary_test.rs
touch current/tests/validate/registry/init_test.rs
```

**Adapt tests**:
- Update imports: `use reedbase::validate::registry::...`
- Update paths to test data if needed
- Verify all tests pass

---

### Step 7: Quality Verification (15 min)

```bash
# Run quality check on all files
for file in dictionary_actions.rs dictionary_users.rs init.rs; do
  echo "Checking $file..."
  ./scripts/quality-check.sh current/src/validate/registry/$file
done

# Run regression verification
./scripts/regression-verify.sh registry
```

---

### Step 8: Final Verification (15 min)

```bash
# Verify split successful (all files <400 lines)
echo "=== File Size Verification ==="
for file in dictionary_actions.rs dictionary_users.rs init.rs; do
  lines=$(wc -l < current/src/validate/registry/$file)
  if [ $lines -le 400 ]; then
    echo "✅ $file: $lines lines (under limit)"
  else
    echo "❌ $file: $lines lines (EXCEEDS LIMIT!)"
  fi
done

# Verify all functions present
echo ""
echo "=== Function Count Verification ==="
rg "^pub fn" current/src/validate/registry/*.rs | wc -l
echo "Expected: 8 functions"

# Final test run
echo ""
echo "=== Final Test Run ==="
cargo test -p reedbase --lib validate::registry
cargo test -p reedbase-last --lib registry
```

---

## ✅ Quality Assurance Matrix (MANDATORY)

### Pre-Implementation

- [x] **Golden Rule: last/ analysed completely**
  - [x] 3 source files validated
  - [x] 8 public functions identified
  - [x] Split strategy: dictionary.rs 473 → 2 files <400 each

- [x] **Standard #0: Code Reuse**
  - [x] Uses Table from 020-04 (dictionary_users.rs) ✅
  - [x] Uses error types from Phase 1 ✅

- [x] **Standard #3: File Naming**
  - [x] Specific names: dictionary_actions, dictionary_users (not dictionary_utils) ✅

- [x] **Standard #8: Architecture**
  - [x] Layered structure: validate/registry/ ✅
  - [x] No MVC patterns ✅

### During Implementation

- [ ] **Standard #1: BBC English**
  - [ ] All comments fixed (initialise, synchronise)

- [ ] **Standard #4: Single Responsibility**
  - [ ] dictionary_actions.rs: Action codes only ✅
  - [ ] dictionary_users.rs: User codes + persistence only ✅
  - [ ] init.rs: Initialisation only ✅

### Post-Implementation

- [ ] **Standard #2: File Size <400 Lines**
  - [ ] dictionary_actions.rs: ~200 lines ✅
  - [ ] dictionary_users.rs: ~280 lines ✅
  - [ ] init.rs: 227 lines ✅

- [ ] **Standard #5: Separate Test Files**
  - [ ] dictionary_test.rs in tests/ ✅
  - [ ] init_test.rs in tests/ ✅

- [ ] **Standard #6: No Swiss Army Functions**
  - [ ] get_or_create_user_code() does ONE thing (get or create) ✅

- [ ] **Regression: All Tests Passing**
  - [ ] `cargo test -p reedbase --lib validate::registry` ✅
  - [ ] `cargo test -p reedbase-last --lib registry` ✅

---

## Success Criteria

### Functionality
- ✅ All 8 functions present
- ✅ dictionary.rs split successful (473 → ~480 across 2 files)
- ✅ Action dictionary (1 byte codes)
- ✅ User dictionary (4 byte codes, persistent)
- ✅ Registry module COMPLETE

### Quality
- ✅ All files <400 lines (split successful)
- ✅ BBC English everywhere (initialise, synchronise)
- ✅ Specific file names (dictionary_actions, dictionary_users)
- ✅ Single responsibility per file
- ✅ No duplicates

### Regression
- ✅ All tests passing (dictionary, init)
- ✅ Baseline unchanged (last/ tests still green)
- ✅ Behaviour identical (same code allocation)

### Performance
- ✅ Action lookup < 1μs (static HashMap)
- ✅ User lookup < 1μs (RwLock read)
- ✅ User creation < 10μs (RwLock write + persist)

---

## Commit Message Template

```
[CLEAN-030-02] feat(validate): implement Registry system

Phase 3 - Validation Layer - Ticket 2/2

✅ Golden Rule: Complete parity with last/src/registry/
✅ QS-Matrix: 16/16 checks passing (dictionary.rs split successful!)
✅ Regression tests: X/X passing
✅ Behaviour: Identical to last/

Implementation:
- dictionary.rs split (473 → ~480 lines across 2 files):
  - dictionary_actions.rs: Action code mapping (~200 lines)
  - dictionary_users.rs: User code mapping + persistence (~280 lines)
- init.rs: Registry initialisation (227 lines)

Quality:
- KISS Standard #2: ALL files <400 lines ✅
- BBC English: All comments corrected (initialise, synchronise) ✅
- Specific names: dictionary_actions, dictionary_users ✅
- Single responsibility: Each file ONE dictionary type ✅

Registry module COMPLETE:
- Action codes: 1 byte per action (vs ~10 bytes string)
- User codes: 4 bytes per user (vs ~20 bytes username)
- Persistent mapping: Codes never change
- Thread-safe: RwLock for concurrent access
- Ready for use by logging system

Phase 3 (Validation Layer) COMPLETE:
- 030-01: Schema (RBKS v2 + column validation) ✅
- 030-02: Registry (user/action dictionaries) ✅

Dependencies:
- Uses Table from 020-04 (dictionary_users.rs) ✅

Workspace packages:
- reedbase (current): Registry complete, X tests passing
- reedbase-last (last): Baseline unchanged, X tests passing
```

---

## Next Steps

**After this ticket**:
- ✅ **Registry module 100% COMPLETE** (encoded log dictionaries ready)
- ✅ **Phase 3 (Validation Layer) 100% COMPLETE** - All validation modules done:
  - 030-01: Schema ✅
  - 030-02: Registry ✅
- ➡️ **Next**: Phase 4 (API Layer) - database, reedql, query execution

**Unblocked by this ticket**:
- Logging system can use encoded logs (space savings)
- Version logs can use 1+4 bytes instead of ~30 bytes per entry
- Audit logs have human-readable mapping

---

**Validation Date**: 2025-11-06  
**Validated Against**: last/src/registry/ (3 files)  
**Estimated Time**: 2-3 hours  
**Complexity**: Medium (split required, thread-safe statics, persistence)
