# SPLIT-300-00: Split Large Files - Overview

## Status
- [x] Not Started
- [ ] In Progress
- [ ] Complete

## Priority
**HIGH** - Violates KISS principle (files >600 lines too complex)

## Estimated Effort
4-5 hours total (6 files)

## Path References

**⚠️ DUAL PATH NOTATION**:
- Paths shown as **Current** (before 002-[STRUCT]-00) → **After 002** (after folder reorganisation)
- Use current paths if 002-[STRUCT]-00 not yet complete

## Context
CLAUDE.md requires:
> **2. Principle**: KISS (Keep It Simple, Stupid)
> **3. File Naming**: One file = one clear responsibility

Files over 600 lines are candidates for splitting. We have **6 files**:

| File | Lines | Current Path | After 002 Path | Split Priority |
|------|-------|--------------|----------------|----------------|
| `tree.rs` | 782 | `src/btree/` | `src/store/btree/` | **CRITICAL** |
| `parser.rs` | 730 | `src/reedql/` | `src/api/reedql/` | **CRITICAL** |
| `executor.rs` | 697 | `src/reedql/` | `src/api/reedql/` | **HIGH** |
| `page.rs` | 669 | `src/btree/` | `src/store/btree/` | **HIGH** |
| `execute.rs` | 661 | `src/database/` | `src/api/db/` | **MEDIUM** |
| `formatters/mod.rs` | 177 | `src/bin/` | `src/api/cli/formatters/` | **LOW** |

## Target State
Each file split into focused modules with single responsibility:
- No file >400 lines
- Clear separation of concerns
- Improved testability
- Better documentation

## Breaking Changes
**Internal only** - All changes are within module boundaries, public APIs unchanged

## Dependencies
- **FIX-001-00**: Tests must pass
- **TESTS-100-00**: Inline tests extracted (cleaner to split after)
- **RENAME-200-00**: Generic names fixed

## Sub-Tickets

### Critical Priority (do first)
- `301-[SPLIT]-00-btree-tree.md` - Split 782-line B+-Tree (`src/btree/tree.rs` → `src/store/btree/`)
- `302-[SPLIT]-00-reedql-parser.md` - Split 730-line parser (`src/reedql/parser.rs` → `src/api/reedql/`)

### High Priority
- `303-[SPLIT]-00-reedql-executor.md` - Split executor (`src/reedql/executor.rs` → `src/api/reedql/`)
- `304-[SPLIT]-00-btree-page.md` - Split page logic (`src/btree/page.rs` → `src/store/btree/`)

### Medium Priority
- `305-[SPLIT]-00-database-execute.md` - Split execute (`src/database/execute.rs` → `src/api/db/`)

### Low Priority (nice to have)
- `306-[SPLIT]-00-bin-formatters.md` - Extract formatters (`src/bin/formatters/` → `src/api/cli/formatters/`)

## Implementation Pattern

For each large file:

1. **Analyze responsibilities**
   - What distinct jobs does this file do?
   - Can they be separated cleanly?
   - What are the natural boundaries?

2. **Design split structure**
   ```
   module/
   ├── core.rs              # Main struct + core logic
   ├── operation_a.rs       # Specific operation A
   ├── operation_b.rs       # Specific operation B
   └── mod.rs               # Public exports
   ```

3. **Extract incrementally**
   - Start with easiest separation
   - Move one responsibility at a time
   - Test after each move
   - Commit after each successful split

4. **Update imports**
   - Internal module imports
   - Public API re-exports in mod.rs
   - External imports (shouldn't change)

5. **Verify**
   ```bash
   cargo test --lib module::
   cargo check
   ```

## Verification
- [ ] All 6 files split
- [ ] No file >400 lines
- [ ] Each file has single clear responsibility
- [ ] All tests pass
- [ ] Public APIs unchanged
- [ ] Documentation updated
- [ ] Copyright headers on all new files

## Files Affected
**Created**: ~18-20 new files (3-4 per large file)
**Modified**: 6 large files (now smaller core modules)
**Updated**: 6 mod.rs files (new module declarations)

## Notes
**Why 400 lines as threshold?**
- Fits on ~2 screens with context
- Easy to understand in one sitting
- Clear focused responsibility
- Better for code review

**Execution Order**:
1. **tree.rs** (`src/btree/` → `src/store/btree/`) - Most complex, highest impact
2. **parser.rs** (`src/reedql/` → `src/api/reedql/`) - Clear natural boundaries
3. **executor.rs** (`src/reedql/` → `src/api/reedql/`) - Pairs with parser
4. **page.rs** (`src/btree/` → `src/store/btree/`) - Related to tree.rs
5. **execute.rs** (`src/database/` → `src/api/db/`) - Natural split by operation
6. **formatters/mod.rs** (`src/bin/` → `src/api/cli/formatters/`) - Easiest, lowest impact

**Risk Mitigation**:
- Split one file at a time
- Run full test suite after each split
- Commit after each successful split
- Can revert individual splits if needed
