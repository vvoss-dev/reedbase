# 901-[WORKSPACE]-00: Flatten Workspace Structure

**Category**: Cleanup / Post-Rebuild  
**Effort**: 15 minutes  
**Priority**: FINAL STEP (after Phase 9 complete)

---

## Overview

After Clean Room rebuild is complete (Phase 9), promote `current/` to root and remove workspace structure.

**Purpose**: Return to normal single-package structure for v0.2.0-beta release.

---

## Status
- [ ] Not Started
- [ ] In Progress  
- [ ] Complete

---

## Context

**During Rebuild** (Phase 0-9):
```
reedbase/
├── Cargo.toml              [workspace] with 2 members
├── current/                ← New implementation (reedbase v0.2.0-beta)
│   ├── Cargo.toml          [package] name = "reedbase"
│   └── src/
└── last/                   ← Old implementation (reedbase-last v0.1.0)
    ├── Cargo.toml          [package] name = "reedbase-last"
    └── src/                Reference for regression testing
```

**After This Ticket**:
```
reedbase/
├── Cargo.toml              [package] name = "reedbase" (from current/)
├── src/                    ← Promoted from current/src/
├── benches/
├── tests/
└── .workbench/             (kept for documentation)
```

---

## Dependencies

**MUST complete BEFORE running this ticket**:
- ✅ **Phase 9 (900-[VERIFY]-XX)**: All verification tickets passed
- ✅ **900-[LAUNCH]-00**: Final commit and squash complete
- ✅ **All tests passing**: `cargo test -p reedbase --all`
- ✅ **100% CLAUDE.md compliance**: All 8 standards verified
- ✅ **Regression tests**: 0 regressions vs `last/`

**DO NOT run if**:
- ❌ Any Phase 1-9 tickets incomplete
- ❌ Any tests failing
- ❌ Quality checks not passing

---

## Why Flatten?

### ✅ Reasons

1. **Normal Package Structure**
   - Standard Rust project layout
   - Easier for contributors to understand
   - No confusion about which package to work in

2. **Simpler Build Commands**
   ```bash
   # Before (workspace)
   cargo test -p reedbase
   cargo build -p reedbase
   
   # After (single package)
   cargo test
   cargo build
   ```

3. **Clean Release**
   - No `last/` reference code in public repo
   - No workspace complexity for users
   - Standard crates.io structure

4. **Workspace No Longer Needed**
   - `last/` served its purpose (regression testing during rebuild)
   - Clean Room rebuild complete
   - All functionality now in `current/` with better architecture

---

## Implementation Steps

### Step 1: Verify Readiness (CRITICAL!)

```bash
cd /Users/byvoss/Workbench/Unternehmen/ByVoss/Projekte/ReedCMS/reedbase

# 1. Verify Phase 9 complete
cat .workbench/progress.txt
# Expected: "Phase 9: ✅ DONE"

# 2. Verify all tests pass
cargo test -p reedbase --all
# Expected: All tests passing

# 3. Verify quality checks
./scripts/quality-check.sh current/src/lib.rs
# Expected: ✅ ALL CHECKS PASSED

# 4. Verify no regressions
./scripts/regression-verify.sh core
# Expected: ✅ REGRESSION CHECK PASSED

# 5. Check git status
git status
# Expected: Working tree clean
```

**⚠️ STOP if any check fails! Do NOT proceed.**

---

### Step 2: Create Backup

```bash
# Create backup BEFORE any destructive operations
cd /Users/byvoss/Workbench/Unternehmen/ByVoss/Projekte/ReedCMS

# Full backup
cp -r reedbase reedbase-pre-flatten-backup

# Verify backup
ls -la reedbase-pre-flatten-backup/current/
ls -la reedbase-pre-flatten-backup/last/

echo "✅ Backup created: reedbase-pre-flatten-backup"
```

---

### Step 3: Promote current/ to Root

```bash
cd /Users/byvoss/Workbench/Unternehmen/ByVoss/Projekte/ReedCMS/reedbase

# 1. Move current/src/ to root
mv current/src ./

# 2. Move current/Cargo.toml to root (replace workspace)
mv Cargo.toml Cargo.toml.workspace.bak
mv current/Cargo.toml ./

# 3. Move other current/ content if exists
[ -d current/benches ] && mv current/benches ./
[ -d current/tests ] && mv current/tests ./
[ -d current/examples ] && mv current/examples ./

# 4. Remove now-empty current/ directory
rmdir current/

echo "✅ current/ promoted to root"
```

---

### Step 4: Remove Workspace Remnants

```bash
# 1. Remove last/ (no longer needed)
rm -rf last/

# 2. Remove workspace backup
rm -f Cargo.toml.workspace.bak

# 3. Keep .workbench/ (contains documentation)
# Do NOT delete .workbench/

echo "✅ Workspace structure removed"
```

---

### Step 5: Update Cargo.toml

The promoted `current/Cargo.toml` already has correct structure, but verify:

```bash
cat Cargo.toml
```

Expected content:
```toml
[package]
name = "reedbase"
version = "0.2.0-beta"
edition = "2024"
authors = ["Vivian Voss <ask@vvoss.dev>"]
license = "Apache-2.0"
repository = "https://github.com/vvoss-dev/reedbase"
description = "A serious database built on 'just CSV files' – with versioning, transactions, and a custom query language that makes it surprisingly fast."

[dependencies]
# ... (alphabetically sorted)

[dev-dependencies]
# ...
```

**No `workspace = true` references should remain!**

If workspace references exist:
```bash
# Replace workspace references with actual values
sed -i '' 's/version.workspace = true/version = "0.2.0-beta"/' Cargo.toml
sed -i '' 's/edition.workspace = true/edition = "2024"/' Cargo.toml
sed -i '' 's/authors.workspace = true/authors = ["Vivian Voss <ask@vvoss.dev>"]/' Cargo.toml
sed -i '' 's/license.workspace = true/license = "Apache-2.0"/' Cargo.toml
sed -i '' 's/repository.workspace = true/repository = "https:\/\/github.com\/vvoss-dev\/reedbase"/' Cargo.toml
sed -i '' 's/\.workspace = true//g' Cargo.toml
```

---

### Step 6: Update Scripts

```bash
# Scripts should work with normal paths now (no current/ prefix needed)

# Update regression-verify.sh if needed
sed -i '' 's/current\/src\//src\//g' scripts/regression-verify.sh
sed -i '' 's/last\/src\//src\//g' scripts/regression-verify.sh

# Update quality-check.sh
sed -i '' 's/current\/src\//src\//g' scripts/quality-check.sh

echo "✅ Scripts updated for single-package structure"
```

---

### Step 7: Verify New Structure

```bash
# 1. Check directory structure
ls -la
# Expected: src/, Cargo.toml, benches/, tests/, .workbench/
# NOT expected: current/, last/, Cargo.toml.workspace.bak

# 2. Build package
cargo build --release
# Expected: Compiles successfully

# 3. Run tests
cargo test --lib
# Expected: All tests passing

# 4. Run quality check
./scripts/quality-check.sh src/lib.rs
# Expected: ✅ ALL CHECKS PASSED

# 5. Check workspace commands NO LONGER WORK
cargo test -p reedbase 2>&1 | grep "not a member"
# Expected: Error (proves workspace is gone)

echo "✅ Verification complete"
```

---

### Step 8: Update Documentation

Update references in documentation files:

```bash
# 1. Update SESSION_HANDOVER.md
cat > .workbench/docs/SESSION_HANDOVER.md << 'EOF'
# Session Handover for ReedBase v0.2.0-beta

**Date**: $(date +%Y-%m-%d)  
**Status**: ✅ Clean Room Rebuild Complete  
**Phase**: Post-Phase 9 (Workspace Flattened)

---

## Project Status

**Clean Room rebuild complete!**

Structure has been flattened from workspace to single package:
- current/ → src/ (promoted)
- last/ removed (baseline no longer needed)
- Workspace structure removed

Standard Rust project layout restored.

---

## Next Steps

Ready for v0.2.0-beta release:
1. Final testing
2. Create release tag
3. Publish to crates.io
4. Announce publicly

---
EOF

# 2. Update CLAUDE.md Quick Start (if needed)
# Remove workspace-specific commands

echo "✅ Documentation updated"
```

---

### Step 9: Git Commit

```bash
git add -A

git commit -m "[CLEAN-901] chore: flatten workspace structure for v0.2.0-beta

Clean Room rebuild complete (Phase 0-9). Workspace no longer needed.

Changes:
- current/ → root (src/, Cargo.toml promoted)
- last/ removed (baseline served its purpose)
- Workspace structure removed
- Single package structure restored

Structure before:
- Cargo.toml [workspace] with current/ and last/
- current/ (reedbase v0.2.0-beta)
- last/ (reedbase-last v0.1.0 reference)

Structure after:
- Cargo.toml [package] reedbase v0.2.0-beta
- src/ (from current/src/)
- Standard Rust project layout

Verified:
✅ All tests passing
✅ Quality checks passing
✅ Build successful
✅ No workspace commands work (confirms cleanup)

Ready for v0.2.0-beta release."

git push origin main
```

---

## Verification Checklist

**Structure**:
- [ ] `current/` directory does NOT exist
- [ ] `last/` directory does NOT exist
- [ ] `src/` exists at root
- [ ] `Cargo.toml` at root is a [package], NOT [workspace]
- [ ] `.workbench/` still exists (documentation)

**Build & Test**:
- [ ] `cargo build --release` succeeds
- [ ] `cargo test --lib` all passing
- [ ] `cargo bench` works (if benchmarks exist)
- [ ] `./scripts/quality-check.sh src/lib.rs` passes

**Cleanup**:
- [ ] No `workspace = true` references in Cargo.toml
- [ ] Scripts use `src/` not `current/src/`
- [ ] No `Cargo.toml.workspace.bak` file
- [ ] `cargo test -p reedbase` fails with "not a member" error

**Git**:
- [ ] Committed with [CLEAN-901]
- [ ] Pushed to main
- [ ] Working tree clean

---

## Rollback Plan

If something goes wrong:

```bash
cd /Users/byvoss/Workbench/Unternehmen/ByVoss/Projekte/ReedCMS

# 1. Remove broken state
rm -rf reedbase

# 2. Restore backup
cp -r reedbase-pre-flatten-backup reedbase

# 3. Verify restored state
cd reedbase
cargo build -p reedbase

# 4. Reset git if pushed
git reset --hard HEAD~1
git push --force origin main
```

---

## Success Criteria

**This ticket is complete when**:
- ✅ Workspace structure removed
- ✅ `current/` promoted to root
- ✅ `last/` removed
- ✅ Standard Rust project layout
- ✅ All tests passing
- ✅ Quality checks passing
- ✅ Git committed with [CLEAN-901]
- ✅ Ready for v0.2.0-beta release

---

## Next Steps

After this ticket:
1. **Create release tag**: `git tag v0.2.0-beta`
2. **Publish to crates.io**: `cargo publish`
3. **Create GitHub release**: Document features, upload binaries
4. **Announce**: Blog post, social media, etc.

---

## Notes

**Why keep .workbench/?**
- Contains valuable documentation
- Planning tickets (reference for future)
- Baseline metrics (comparison)
- Process logs (audit trail)
- Not shipped in crates.io package

**Backup Location**:
- `../reedbase-pre-flatten-backup/` - Full workspace backup

**Recovery Time**: < 2 minutes (just restore backup)

---

**Estimated Time**: 15 minutes  
**Blocking**: Phase 0-9 complete (all 900-[VERIFY]-XX tickets)  
**Enables**: v0.2.0-beta release process
