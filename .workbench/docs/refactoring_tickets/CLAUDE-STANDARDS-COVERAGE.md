# CLAUDE.md Standards Coverage Matrix

**Goal**: Ensure 100% compliance with all 7 mandatory CLAUDE.md standards.

**Created**: 2025-11-05
**Status**: ✅ All standards have systematic audit tickets

---

## Standards Overview

| # | Standard | Coverage | Tickets | Status |
|---|----------|----------|---------|--------|
| 1 | **BBC English** | ✅ Complete | 150-[LANG]-00 | Systematic search & fix |
| 2 | **KISS Principle** | ✅ Complete | 300-[SPLIT]-00 series | Split large files |
| 3 | **File Naming** | ✅ Complete | 200-[RENAME]-00, 210-[AUDIT]-00 | Rename + audit |
| 4 | **Functions** | ✅ Complete | 250-[FUNC]-00 | Analyze & split |
| 5 | **Testing** | ✅ Complete | 100-[TESTS]-00 series | Extract inline tests |
| 6 | **No Swiss Army** | ✅ Complete | 250-[FUNC]-00 | Same as #4 |
| 7 | **No Generic Names** | ✅ Complete | 210-[AUDIT]-00 | Systematic audit |

---

## Detailed Coverage

### Standard #1: BBC English
**Rule**: All code comments and docs in BBC English

**Violations**: American spellings (color, initialize, organize, etc.)

**Coverage**:
- ✅ **150-[LANG]-00**: Systematic search for -ize/-yze/-or patterns
  - Searches all `.rs` files for American spellings
  - Manual review for API compatibility
  - Automated corrections for comments/docs
  - **Effort**: 1 hour

**Verification**:
- 600-[VERIFY]-00: Final grep check for common American spellings

---

### Standard #2: KISS Principle
**Rule**: Keep It Simple, Stupid - no overly complex files

**Violations**: Files >600 lines (too complex)

**Coverage**:
- ✅ **300-[SPLIT]-00**: Overview of 6 large files
- ✅ **301-[SPLIT]-00**: btree/tree.rs (782 lines) → 5 files
- ✅ **302-[SPLIT]-00**: reedql/parser.rs (730 lines) → 4 files
- ✅ **303-[SPLIT]-00**: reedql/executor.rs (697 lines) → 3 files
- ✅ **304-[SPLIT]-00**: btree/page.rs (669 lines) → 2 files
- ✅ **305-[SPLIT]-00**: database/execute.rs (661 lines) → 4 files
- ✅ **306-[SPLIT]-00**: bin/formatters/mod.rs (177 lines) → 4 files
- **Total effort**: 4-7 hours

**Verification**:
- 600-[VERIFY]-00: Check no files >400 lines

---

### Standard #3: File Naming (One file = one responsibility)
**Rule**: Filenames must clearly indicate their single purpose

**Violations**: Generic names (helpers.rs, utils.rs, common.rs)

**Coverage**:
- ✅ **200-[RENAME]-00**: Rename 2 known violations
  - `tables/helpers.rs` → `table_operations.rs`
  - `indices/builder_tests.rs` → `builder_test.rs`
  - **Effort**: 30 minutes

- ✅ **210-[AUDIT]-00**: Systematic search for ALL generic names
  - Searches for helpers.rs, utils.rs, common.rs, handler.rs
  - Checks large types.rs files (>200 lines - too broad?)
  - Checks mod.rs files with logic (>50 lines - should only export)
  - **Effort**: 30 minutes

**Verification**:
- 600-[VERIFY]-00: Final check for forbidden filenames

---

### Standard #4: Functions (One function = one job)
**Rule**: Each function should have one distinctive purpose

**Violations**: "Swiss Army knife" functions doing multiple things

**Coverage**:
- ✅ **250-[FUNC]-00**: Systematic function analysis
  - Find functions >100 lines
  - Find functions with >5 parameters
  - Find vaguely named functions (handle, process, manage)
  - Identify functions with multiple responsibilities
  - Create sub-tickets for splits
  - **Effort**: 2-3 hours

**Verification**:
- 600-[VERIFY]-00: Manual review of 10 random functions

---

### Standard #5: Testing (Separate test files)
**Rule**: All tests in `{name}_test.rs` files, never inline `#[cfg(test)]` modules

**Violations**: 17 files with inline `#[cfg(test)] mod tests`

**Coverage**:
- ✅ **100-[TESTS]-00**: Overview of all 17 files
- ✅ **101-115-[TESTS]-00**: Individual tickets per file
  - Extract inline tests to separate `_test.rs` files
  - Maintain same test structure
  - **Effort**: 2.5 hours total

**Verification**:
- 600-[VERIFY]-00: `grep -r "#\[cfg(test)\]" src | grep "mod tests"` must return nothing

---

### Standard #6: Avoid Swiss Army Knife Functions
**Rule**: No functions doing multiple unrelated things

**Violations**: Same as Standard #4

**Coverage**:
- ✅ **250-[FUNC]-00**: Same ticket as Standard #4
  - This standard is enforced by the same analysis
  - Functions doing multiple things will be split

**Verification**:
- 600-[VERIFY]-00: Check no functions >100 lines

---

### Standard #7: Avoid Generic Names
**Rule**: No vague filenames like handler.rs, middleware.rs, utils.rs

**Violations**: Same as Standard #3, but needs systematic audit

**Coverage**:
- ✅ **210-[AUDIT]-00**: Comprehensive filename audit
  - Searches beyond the 2 known violations
  - Finds ALL generic patterns
  - May create additional rename tickets if more found
  - **Effort**: 30 minutes

**Verification**:
- 600-[VERIFY]-00: Final grep for forbidden patterns

---

## Execution Order (Optimized)

```
Phase 0: CRITICAL
├─ 001-[PREP]-00: Fix test registry (30m) - MUST DO FIRST
└─ 002-[STRUCT]-00: Reorganize folders (1h) - OPTIONAL

Phase 1: ANALYSIS (Can run in parallel)
├─ 150-[LANG]-00: Find American spellings (15m analysis)
├─ 210-[AUDIT]-00: Find generic names (15m analysis)
└─ 250-[FUNC]-00: Find Swiss Army functions (30m analysis)

Phase 2: NON-BREAKING FIXES
├─ 150-[LANG]-00: Fix American spellings (45m fixes)
├─ 100-[TESTS]-00: Extract inline tests (2.5h)
├─ 200-[RENAME]-00: Rename known violations (30m)
└─ 210-[AUDIT]-00: Rename found violations (15m)

Phase 3: BREAKING CHANGES (Do in order)
├─ 250-[FUNC]-00: Split Swiss Army functions (2-3h)
└─ 300-[SPLIT]-00: Split large files (4-7h)

Phase 4: VERIFICATION & LAUNCH
├─ 600-[VERIFY]-00: Final verification (1h)
└─ 900-[LAUNCH]-00: Squash & launch (15m)
```

**Total time**: 12-16 hours (depends on findings from analysis tickets)

---

## Coverage Metrics

### Before Refactoring
- ❌ Standard #1: Unknown compliance
- ❌ Standard #2: 6 files >600 lines
- ❌ Standard #3: 2+ generic filenames
- ❌ Standard #4: Unknown function quality
- ❌ Standard #5: 17 files with inline tests
- ❌ Standard #6: Unknown Swiss Army functions
- ❌ Standard #7: 2+ generic names

### After Refactoring (Target)
- ✅ Standard #1: 100% BBC English
- ✅ Standard #2: No files >400 lines
- ✅ Standard #3: All files have clear names
- ✅ Standard #4: All functions <100 lines (except justified)
- ✅ Standard #5: 0 inline test modules
- ✅ Standard #6: No Swiss Army functions
- ✅ Standard #7: No generic names

---

## Decision Points

### Must Do (Non-negotiable for launch)
1. ✅ **001-[PREP]-00**: Tests must pass
2. ✅ **100-[TESTS]-00**: MANDATORY (Standard #5)
3. ✅ **150-[LANG]-00**: MANDATORY (Standard #1)
4. ✅ **200-[RENAME]-00**: MANDATORY (Standard #3)
5. ✅ **210-[AUDIT]-00**: MANDATORY (Standard #7)
6. ✅ **600-[VERIFY]-00**: Quality gate
7. ✅ **900-[LAUNCH]-00**: Clean commit

### Should Do (High value, CLAUDE.md compliance)
8. ✅ **250-[FUNC]-00**: Standards #4 & #6 compliance
9. ✅ **301-302-[SPLIT]-00**: Critical file splits (btree, reedql parser)

### Could Skip (Lower priority, can do post-launch)
10. ⚠️ **303-306-[SPLIT]-00**: Additional file splits
11. ⚠️ **002-[STRUCT]-00**: Folder reorganization (nice but not blocking)

---

## Quality Gates

Before marking a standard as ✅ COMPLETE:

1. **Analysis ticket complete** (findings documented)
2. **Fix tickets complete** (all violations addressed)
3. **Tests pass** (`cargo test --lib`)
4. **Code compiles** (`cargo check`)
5. **Verification passes** (600-[VERIFY]-00 checklist)

---

## Related Documentation

- **CLAUDE.md**: Full standards document (project root)
- **MASTER-TRACKING.md**: Overall refactoring progress
- **Individual tickets**: Detailed implementation steps

---

## Summary

**✅ Coverage Status**: 100% - All 7 CLAUDE.md standards have systematic audit tickets

**📊 Ticket Count**:
- Analysis tickets: 3 (150, 210, 250)
- Fix tickets: 28+ (100-115, 200, 300-306, etc.)
- Verification: 1 (600)
- Launch: 1 (900)

**⏱️ Total Effort**: 12-16 hours (full compliance)

**🎯 Goal**: Ship ReedBase v0.2.0-beta as "mustergültig" (exemplary) codebase
