# SPLIT-300-00: Split Large Files - Overview

## Status
- [x] Not Started
- [ ] In Progress
- [ ] Complete

## Priority
**HIGH** - Violates KISS principle (files >600 lines too complex)

## Estimated Effort
4-5 hours total (6 files)

## Context
CLAUDE.md requires:
> **2. Principle**: KISS (Keep It Simple, Stupid)
> **3. File Naming**: One file = one clear responsibility

Files over 600 lines are candidates for splitting. We have **6 files**:

| File | Lines | Issue | Split Priority |
|------|-------|-------|----------------|
| `btree/tree.rs` | 782 | All B+-Tree ops in one file | **CRITICAL** |
| `reedql/parser.rs` | 730 | All SQL parsing in one file | **CRITICAL** |
| `reedql/executor.rs` | 697 | All query execution in one file | **HIGH** |
| `btree/page.rs` | 669 | Page + serialization mixed | **HIGH** |
| `database/execute.rs` | 661 | All writes in one file | **MEDIUM** |
| `bin/formatters/mod.rs` | 177 | All formatters in mod.rs | **LOW** |

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
- `SPLIT-301-00-btree-tree.md` - Split 782-line B+-Tree into focused modules
- `SPLIT-302-00-reedql-parser.md` - Split 730-line parser by SQL statement type

### High Priority
- `SPLIT-303-00-reedql-executor.md` - Split 697-line executor into read/write
- `SPLIT-304-00-btree-page.md` - Split 669-line page into ops + serialization

### Medium Priority
- `SPLIT-305-00-database-execute.md` - Split 661-line execute into INSERT/UPDATE/DELETE

### Low Priority (nice to have)
- `SPLIT-306-00-bin-formatters.md` - Extract formatters from mod.rs

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
1. **btree/tree.rs** - Most complex, highest impact
2. **reedql/parser.rs** - Clear natural boundaries
3. **reedql/executor.rs** - Pairs with parser
4. **btree/page.rs** - Related to tree.rs
5. **database/execute.rs** - Natural split by operation
6. **bin/formatters/mod.rs** - Easiest, lowest impact

**Risk Mitigation**:
- Split one file at a time
- Run full test suite after each split
- Commit after each successful split
- Can revert individual splits if needed
