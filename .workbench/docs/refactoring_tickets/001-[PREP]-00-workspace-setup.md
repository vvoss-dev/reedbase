# 001-[PREP]-00: Cargo Workspace Setup

**Category**: Preparation  
**Effort**: 30 minutes  
**Priority**: CRITICAL (Phase 0 - MUST DO FIRST!)

---

## Overview

Setup Cargo Workspace structure für Clean Room Rebuild:
- `current/` - Neuer Code (Clean Room Implementation)
- `last/` - Alter Code (Referenz, Tests, Benchmarks)

**User Decision**:
> "Cargo Workspace aber: reedbase/current (das neue), reedbase/last (das alte)"

---

## Why Workspace?

**Vorteile**:
- ✅ Beide Versionen parallel kompilierbar
- ✅ Alte Tests laufen weiter (`cargo test -p last`)
- ✅ Neue Tests unabhängig (`cargo test -p current`)
- ✅ Regression Testing: Vergleich current/ vs last/
- ✅ Benchmarks können beide Versionen vergleichen
- ✅ Cargo-Standard (Best Practice)

**Struktur**:
```
reedbase/
├── Cargo.toml              [workspace] root
├── current/                ← NEUER Code (wird aufgebaut)
│   ├── Cargo.toml          [package] name = "reedbase"
│   ├── src/
│   │   ├── lib.rs
│   │   ├── error.rs
│   │   └── core/
│   ├── tests/
│   └── benches/
├── last/                   ← ALTER Code (Referenz)
│   ├── Cargo.toml          [package] name = "reedbase-last"
│   ├── src/
│   ├── tests/
│   └── benches/
├── scripts/
│   ├── quality-check.sh
│   └── regression-verify.sh
└── .workbench/
```

---

## ✅ Qualitätssicherung + Regression Testing

### Pre-Implementation
- [x] Standard #0: Keine Funktionen (nur Setup)
- [x] Standard #3: N/A (keine Code-Files)
- [x] Standard #8: N/A (Workspace Setup)
- [x] **Regression: Alte Tests in src/ identifiziert** (werden zu last/)
- [x] **Regression: Backup-Strategie definiert** (mv src → last/src)

### During Implementation
- [ ] Standard #1: N/A (keine Kommentare in Setup)
- [ ] Standard #4: N/A (keine Funktionen)
- [ ] Standard #6: N/A (keine Funktionen)
- [ ] Standard #7: N/A (keine Namen zu vergeben)
- [x] **Regression: Alte Tests bleiben lauffähig** (in last/)
- [x] **Regression: Verzeichnisstruktur dokumentiert**

### Post-Implementation
- [ ] Standard #2: N/A (keine .rs Files)
- [ ] Standard #5: N/A (keine Tests hier)
- [ ] Standard #0: N/A (keine Funktionen)
- [x] **Regression: Alte Tests laufen** (`cargo test -p last`)
- [x] **Regression: Workspace kompiliert** (`cargo build --all`)

### Final Verification
```bash
# Workspace kompiliert beide Packages
cargo build --all
# ✅ Expected: Both packages compile

# Alte Tests laufen weiter (Baseline)
cargo test -p last
# ✅ Expected: All tests passing (establishes baseline)

# Neue Struktur existiert
ls -la current/src/
# ✅ Expected: Empty structure ready for Phase 1

# Scripts funktionieren mit neuer Struktur
./scripts/regression-verify.sh --help
# ✅ Expected: Script adapted to last/ and current/

git commit -m "[CLEAN-001] feat: setup Cargo Workspace (current/ + last/)

✅ Workspace structure created
✅ last/ contains old implementation (baseline)
✅ current/ ready for Clean Room rebuild
✅ Both packages compile independently
✅ Old tests passing: XX/XX (baseline established)

Phase 0 complete."
```

---

## Implementation Steps

### Step 1: Backup Current Implementation (5 min)

```bash
cd reedbase

# Check current state
ls -la
# Expected: src/, Cargo.toml, tests/, benches/, etc.

# Create workspace root Cargo.toml
cat > Cargo.toml.new << 'EOF'
[workspace]
members = [
    "current",
    "last",
]

resolver = "2"

[workspace.package]
version = "0.2.0-beta"
edition = "2021"
authors = ["Vivian Voss <ask@vvoss.dev>"]
license = "Apache-2.0"
repository = "https://github.com/vvoss-dev/reedbase"

[workspace.dependencies]
# Shared dependencies (will be used by both packages)
serde = { version = "1.0", features = ["derive"] }
tokio = { version = "1.0", features = ["full"] }
# ... (copy from current Cargo.toml if needed)
EOF

# Backup old Cargo.toml
mv Cargo.toml Cargo.toml.backup

# Move workspace root into place
mv Cargo.toml.new Cargo.toml

echo "✅ Step 1 complete: Workspace root Cargo.toml created"
```

### Step 2: Create `last/` Package (5 min)

```bash
# Create last/ directory
mkdir last

# Move current implementation to last/
mv src/ last/
mv Cargo.toml.backup last/Cargo.toml
[ -d tests ] && mv tests/ last/
[ -d benches ] && mv benches/ last/
[ -d examples ] && mv examples/ last/

# Update last/Cargo.toml package name
cd last
sed -i '' 's/name = "reedbase"/name = "reedbase-last"/' Cargo.toml

# Optional: Update description
sed -i '' 's/description = "/description = "ReedBase Last Version (Reference) - /' Cargo.toml

cd ..

echo "✅ Step 2 complete: last/ package created"
```

### Step 3: Create `current/` Package (10 min)

```bash
# Create current/ as new library
cargo new current --lib

cd current

# Create module structure
mkdir -p src/{core,api/{db,reedql},store/{btree,tables,indices},validate/{schema,rbks},process/{concurrent,locks},ops/{backup,versioning,metrics}}

# Create module files
touch src/core/mod.rs
touch src/api/mod.rs
touch src/api/db/mod.rs
touch src/api/reedql/mod.rs
touch src/store/mod.rs
touch src/store/btree/mod.rs
touch src/store/tables/mod.rs
touch src/store/indices/mod.rs
touch src/validate/mod.rs
touch src/validate/schema/mod.rs
touch src/validate/rbks/mod.rs
touch src/process/mod.rs
touch src/process/concurrent/mod.rs
touch src/process/locks/mod.rs
touch src/ops/mod.rs
touch src/ops/backup/mod.rs
touch src/ops/versioning/mod.rs
touch src/ops/metrics/mod.rs

# Create error.rs
touch src/error.rs

# Update lib.rs
cat > src/lib.rs << 'EOF'
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! ReedBase: CSV-based versioned database with Smart Indices and ReedQL.
//!
//! This is the v0.2.0-beta Clean Room rebuild.

pub mod core;
pub mod api;
pub mod store;
pub mod validate;
pub mod process;
pub mod ops;

pub mod error;

// Re-exports
pub use error::ReedError;

/// ReedBase version
pub const VERSION: &str = env!("CARGO_PKG_VERSION");
EOF

# Update Cargo.toml
cat > Cargo.toml << 'EOF'
[package]
name = "reedbase"
version.workspace = true
edition.workspace = true
authors.workspace = true
license.workspace = true
repository.workspace = true
description = "ReedBase: CSV-based versioned database with Smart Indices and ReedQL"

[dependencies]
# Core dependencies
serde = { workspace = true }
tokio = { workspace = true }

# Add other dependencies as needed during implementation

[dev-dependencies]
# Test dependencies
criterion = "0.5"

[[bench]]
name = "comparison"
harness = false
EOF

cd ..

echo "✅ Step 3 complete: current/ package created with structure"
```

### Step 4: Update Scripts for Workspace (5 min)

```bash
# Update regression-verify.sh
sed -i '' 's|last/src/|last/src/|g' scripts/regression-verify.sh
sed -i '' 's|src/|current/src/|g' scripts/regression-verify.sh

# Update quality-check.sh (if it references paths)
sed -i '' 's|src/|current/src/|g' scripts/quality-check.sh

echo "✅ Step 4 complete: Scripts updated for workspace structure"
```

### Step 5: Verify Setup (5 min)

```bash
# Verify workspace structure
ls -la
# Expected: Cargo.toml (workspace), current/, last/

# Build both packages
cargo build --all
# Expected: Both compile successfully

# Run old tests (establish baseline)
cargo test -p reedbase-last
# Expected: XX tests passing (baseline)

# Verify new package compiles (empty for now)
cargo test -p reedbase
# Expected: 0 tests, 0 failures (empty but valid)

# Check structure
tree current/src -L 2
# Expected: Module structure visible

tree last/src -L 2
# Expected: Old code structure visible

echo "✅ Step 5 complete: Workspace verified and functional"
```

---

## Verification Checklist

### Workspace Structure
- [ ] `Cargo.toml` (root) exists with `[workspace]`
- [ ] `current/` directory exists
- [ ] `current/Cargo.toml` has `name = "reedbase"`
- [ ] `last/` directory exists
- [ ] `last/Cargo.toml` has `name = "reedbase-last"`

### Compilation
- [ ] `cargo build --all` succeeds
- [ ] `cargo build -p reedbase` succeeds (current)
- [ ] `cargo build -p reedbase-last` succeeds (last)

### Tests
- [ ] `cargo test -p reedbase-last` runs and passes (baseline)
- [ ] `cargo test -p reedbase` runs (0 tests, but no errors)

### Structure
- [ ] `current/src/` has module structure (core/, api/, store/, etc.)
- [ ] `last/src/` has old code intact
- [ ] `scripts/` updated to reference current/ and last/

### Scripts
- [ ] `./scripts/quality-check.sh current/src/lib.rs` works
- [ ] `./scripts/regression-verify.sh` recognizes new structure

---

## Expected Baseline (from last/)

After this ticket, establish baseline metrics:

```bash
# Test count
cargo test -p reedbase-last 2>&1 | grep "test result"
# Example: test result: ok. 127 passed; 0 failed

# Function count
rg "^pub fn" last/src/ | wc -l
# Example: 284 public functions

# Documentation
rg "^///" last/src/ | wc -l
# Example: 1420 doc lines

# File sizes
find last/src -name "*.rs" -exec wc -l {} \; | sort -rn | head -10
# Example: Top 10 largest files identified
```

**Document these in**: `_workbench/baseline-metrics.txt`

---

## Commit Message

```bash
git add -A
git commit -m "[CLEAN-001] feat: setup Cargo Workspace (current/ + last/)

Created workspace structure for Clean Room rebuild:

Structure:
- Cargo.toml (root)     : Workspace with 2 members
- current/              : New implementation (Clean Room)
- last/                 : Old implementation (Reference, Tests)

Both packages compile independently:
- cargo build -p reedbase       (current, empty structure)
- cargo build -p reedbase-last  (last, full implementation)

Baseline established:
- Tests passing: XX/XX
- Public functions: YYY
- Documentation lines: ZZZZ

Scripts updated:
- regression-verify.sh adapted to current/ and last/
- quality-check.sh adapted to current/

Ready for Phase 1 (010-[CORE]-XX)."
```

---

## Next Steps

After this ticket:

1. **Phase 1**: Start with 010-[CORE]-01 (Core module structure)
2. **Baseline**: Keep `_workbench/baseline-metrics.txt` for reference
3. **Regression**: All future tickets compare current/ with last/

---

## Troubleshooting

### Issue: `cargo build --all` fails

**Solution**:
```bash
# Build individually to isolate issue
cargo build -p reedbase-last
cargo build -p reedbase

# Check workspace members
cargo metadata --format-version 1 | jq '.workspace_members'
```

### Issue: Tests fail in last/

**Problem**: Dependencies missing or versions incompatible

**Solution**:
```bash
cd last/
cargo update
cargo test
```

### Issue: Scripts don't find modules

**Problem**: Paths still reference old structure

**Solution**:
```bash
# Check script contents
grep "src-old" scripts/*.sh
grep "src/" scripts/*.sh

# Update to current/ and last/
sed -i '' 's|last/src/|last/src/|g' scripts/*.sh
sed -i '' 's|^src/|current/src/|g' scripts/*.sh
```

---

## Success Criteria

**This ticket is complete when**:
- ✅ Workspace compiles (`cargo build --all`)
- ✅ Both packages compile independently
- ✅ Old tests pass (baseline established)
- ✅ New package has empty structure ready
- ✅ Scripts adapted to new paths
- ✅ Baseline metrics documented
- ✅ Git committed with [CLEAN-001]

**Estimated Time**: 30 minutes  
**Blocking**: None (first ticket in Phase 0)  
**Enables**: All Phase 1-9 tickets (010-900)

---

**Note**: This workspace structure stays for entire Clean Room rebuild. After Phase 9 (verification), `last/` can be archived or removed, and `current/` becomes the only package.
