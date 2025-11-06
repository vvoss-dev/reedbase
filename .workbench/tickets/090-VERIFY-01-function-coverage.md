# REED-CLEAN-090-01: Function Coverage Verification

**Created**: 2025-11-06  
**Phase**: 9 (Verification & Documentation)  
**Estimated Effort**: 1-2 hours  
**Dependencies**: All phases 1-8 complete  
**Blocks**: v0.2.0-beta release

---

## Status

- [ ] Ticket understood
- [ ] Function comparison complete
- [ ] Missing functions documented
- [ ] MIGRATION.md created
- [ ] Intentional omissions justified
- [ ] 100% coverage confirmed
- [ ] Committed

---

## 🚨 CRITICAL: This is Verification, Not Implementation

**Purpose**: Verify that ALL functions from `last/` are present in `current/`, or explicitly documented as intentionally omitted.

**NO NEW CODE** - This ticket only verifies and documents.

---

## Verification Steps

### Step 1: Extract Function Lists

```bash
# Extract all public functions from current/
rg "^pub fn" current/src/ --no-heading > .workbench/verification/current-functions.txt
rg "^    pub fn" current/src/ --no-heading >> .workbench/verification/current-functions.txt

# Extract all public functions from last/
rg "^pub fn" last/src/ --no-heading > .workbench/verification/last-functions.txt
rg "^    pub fn" last/src/ --no-heading >> .workbench/verification/last-functions.txt

# Sort both files
sort .workbench/verification/current-functions.txt -o .workbench/verification/current-functions-sorted.txt
sort .workbench/verification/last-functions.txt -o .workbench/verification/last-functions-sorted.txt

# Compare
diff .workbench/verification/last-functions-sorted.txt .workbench/verification/current-functions-sorted.txt > .workbench/verification/function-diff.txt
```

---

### Step 2: Analyze Differences

**Expected differences** (acceptable):
- ✅ Path changes: `last/src/btree/` → `current/src/store/btree/`
- ✅ Module renames: `last/src/concurrent/` → `current/src/process/concurrent/`
- ✅ File splits: `types.rs` → `types_core.rs` + `types_index.rs`

**Unacceptable differences**:
- ❌ Missing public functions (not in current/)
- ❌ Changed function signatures
- ❌ Removed functionality

---

### Step 3: Document Findings

**Create `.workbench/verification/FUNCTION-COVERAGE-REPORT.md`**:

```markdown
# Function Coverage Report

**Date**: 2025-11-06  
**Verified By**: Claude  
**Status**: [PASS/FAIL]

## Summary

- **Total functions in last/**: XXX
- **Total functions in current/**: XXX
- **Missing functions**: X
- **Renamed/Moved functions**: XX
- **Intentionally omitted**: X

## Missing Functions

(Empty if all present)

| Function | Last Location | Reason Missing |
|----------|---------------|----------------|
| example_fn | last/src/x.rs:42 | [Document reason] |

## Renamed/Moved Functions

| Last Location | Current Location | Notes |
|---------------|------------------|-------|
| last/src/btree/insert.rs:52 | current/src/store/btree/insert.rs:48 | Path change only |

## Intentionally Omitted Functions

| Function | Last Location | Reason for Omission | Documented In |
|----------|---------------|---------------------|---------------|
| deprecated_fn | last/src/x.rs:100 | Deprecated in v0.1, replaced by new_fn | MIGRATION.md:42 |

## Verification Commands

bash
# Verify specific function exists
rg "pub fn function_name" current/src/

# Verify signature matches
diff <(rg "pub fn function_name" last/src/) <(rg "pub fn function_name" current/src/)


## Conclusion

[PASS/FAIL] - All functions accounted for.
```

---

### Step 4: Create MIGRATION.md

**Create `current/MIGRATION.md`**:

```markdown
# Migration Guide: v0.1.x → v0.2.0-beta

**Clean Room Rebuild**: ReedBase v0.2.0-beta is a complete rewrite following strict quality standards (CLAUDE.md compliance).

---

## Breaking Changes

### Module Structure

Old (v0.1.x):
\`\`\`
src/
├── btree/
├── concurrent/
├── database/
└── reedql/
\`\`\`

New (v0.2.0-beta):
\`\`\`
src/
├── core/          (paths, validation)
├── store/         (btree, tables, indices)
├── validate/      (schema, rbks)
├── process/       (concurrent, locks)
├── api/           (db, reedql)
├── ops/           (backup, versioning, metrics, log, merge)
└── bin/           (CLI)
\`\`\`

### Import Path Changes

| Old | New |
|-----|-----|
| `use reedbase::Database` | `use reedbase::api::db::Database` |
| `use reedbase::btree::BTree` | `use reedbase::store::btree::BTree` |
| `use reedbase::concurrent::CsvRow` | `use reedbase::process::concurrent::types::CsvRow` |

### Renamed Functions

(List any renamed functions)

| Old | New | Reason |
|-----|-----|--------|
| `example_old()` | `example_new()` | More descriptive name |

### Removed Functions

(List any intentionally removed functions)

| Function | Replacement | Migration Path |
|----------|-------------|----------------|
| `deprecated_fn()` | `new_fn()` | Use `new_fn()` with equivalent parameters |

---

## File Splits

Some large files (>400 lines) were split for KISS compliance:

| Old File | New Files | Notes |
|----------|-----------|-------|
| `database/types.rs` (570 lines) | `api/db/types_core.rs` + `api/db/types_index.rs` | Logical separation |

---

## New Features in v0.2.0-beta

- ✅ Complete metrics system (`ops/metrics/`)
- ✅ Git-like versioning (`ops/versioning/`)
- ✅ Automated backups (`ops/backup/`)
- ✅ Encoded logging with CRC32 (`ops/log/`)
- ✅ Intelligent CSV merge (`ops/merge/`)
- ✅ Complete CLI tool (`bin/`)

---

## Quality Improvements

- ✅ **100% CLAUDE.md Compliance**: All 8 standards enforced
- ✅ **No files >400 lines**: KISS principle strictly followed
- ✅ **No duplicate code**: Zero redundancy
- ✅ **Layered architecture**: Clean separation of concerns
- ✅ **Comprehensive tests**: Separate test files for all modules
- ✅ **BBC English**: All comments in British English

---

## Upgrade Checklist

- [ ] Update import paths
- [ ] Replace renamed functions
- [ ] Replace removed functions with equivalents
- [ ] Test with new module structure
- [ ] Update dependencies if needed
- [ ] Run full test suite

---

## Need Help?

See:
- `ARCHITECTURE.md` - Complete system architecture
- `CLAUDE.md` - Quality standards and guidelines
- GitHub Issues - Report migration problems
```

---

### Step 5: Verify Coverage

**Checklist**:
- [ ] All `pub fn` from last/ present in current/
- [ ] All `pub struct` from last/ present in current/
- [ ] All `pub enum` from last/ present in current/
- [ ] All `pub trait` from last/ present in current/
- [ ] All missing items documented in MIGRATION.md
- [ ] All intentional omissions justified

---

## Success Criteria

### Coverage Requirements ✅
- [x] 100% of public API migrated or documented
- [x] 0 undocumented missing functions
- [x] All breaking changes listed in MIGRATION.md
- [x] All file splits documented
- [x] All renames documented

### Documentation Requirements ✅
- [x] FUNCTION-COVERAGE-REPORT.md created
- [x] MIGRATION.md created with upgrade guide
- [x] Breaking changes clearly listed
- [x] Migration paths provided for all changes

---

## Commit Message

```
[CLEAN-090-01] docs: verify function coverage and create migration guide

✅ Function Coverage: 100% verified
✅ Missing functions: 0 (all accounted for)
✅ Breaking changes: Documented in MIGRATION.md

Verification Results:
- Total functions in last/: XXX
- Total functions in current/: XXX
- Path changes: XX (documented)
- Intentional omissions: 0

Documentation:
- Created FUNCTION-COVERAGE-REPORT.md
- Created MIGRATION.md with complete upgrade guide
- Documented all breaking changes
- Provided migration paths for all changes

Files:
- .workbench/verification/FUNCTION-COVERAGE-REPORT.md
- current/MIGRATION.md
```

---

## Notes

### What to Look For

**Normal differences** (acceptable):
- Path changes due to new structure
- File splits for KISS compliance
- Module renames for clarity

**Red flags** (investigate):
- Missing public functions
- Changed signatures without documentation
- Removed functionality without replacement

### Common Issues

1. **Helper functions**: Internal helpers may not need migration if functionality covered by new implementation
2. **Test-only functions**: Functions only used in tests may be in test files now
3. **Deprecated functions**: Should be documented as intentionally omitted

---

**Ticket Complete**: Verification only, no implementation.
