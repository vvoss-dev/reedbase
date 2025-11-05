# Master Refactoring Tracking

**Goal**: Transform ReedBase to mustergültig (exemplary) codebase  
**Started**: 2025-11-05  
**Target Completion**: Before v0.2.0-beta launch  
**Total Estimated Time**: 6-8 hours

---

## Quick Status

| Phase | Tickets | Status | Progress |
|-------|---------|--------|----------|
| **Phase 0: Preparation** | 001-002 | ⏳ Not Started | 0/2 |
| **Phase 1: Analysis** | 150, 210, 250 + subs | ⏳ Not Started | 0/13 |
| **Phase 2: Test Extraction** | 100-117 | ⏳ Not Started | 0/18 |
| **Phase 3: BBC English** | 151-154 | ⏳ Not Started | 0/4 |
| **Phase 4: Rename/Audit** | 200, 211-213 | ⏳ Not Started | 0/4 |
| **Phase 5: Function Refactor** | 251-253 + results | ⏳ Not Started | 0/3+ |
| **Phase 6: File Splits** | 300-306 | ⏳ Not Started | 0/7 |
| **Phase 7: Verification** | 600 | ⏳ Not Started | 0/1 |
| **Phase 8: Launch** | 900 | ⏳ Not Started | 0/1 |
| **TOTAL** | **43+ tickets** | **0% complete** | **0/43+** |

---

## Critical Path

```
FIX-001 (MUST complete first - tests broken)
   ↓
TESTS-100 series (17 files - can do in parallel)
   ↓
RENAME-200 (2 files - quick)
   ↓
SPLIT-300 series (6 files - do in order)
   ↓
VERIFY-600 (comprehensive check)
   ↓
COMMIT-900 (squash & launch)
   ↓
🚀 LAUNCH v0.2.0-beta
```

---

## Detailed Ticket List

### 🚨 Phase 0: Preparation (CRITICAL)

| Ticket | Title | Priority | Effort | Status | Notes |
|--------|-------|----------|--------|--------|-------|
| **001-[PREP]-00** | Fix test registry setup | CRITICAL | 30m | ⏳ Not Started | 27 tests failing, blocks everything |
| **002-[STRUCT]-00** | Reorganise folders | OPTIONAL | 1h | ⏳ Not Started | Creates api/store/validate/process/ops structure |

**Why Critical**: Can't refactor if tests don't pass. Must fix first.

---

### 📊 Phase 1: Analysis (Find All Violations)

| Ticket | Title | Effort | Status | Finds |
|--------|-------|--------|--------|-------|
| **150-[LANG]-00** | BBC English audit (parent) | 1h | ⏳ Not Started | American spellings |
| **151-[LANG]-01** | Fix -ize endings | 20m | ⏳ Not Started | initialize, optimize, etc. |
| **152-[LANG]-02** | Fix -yze endings | 10m | ⏳ Not Started | analyze, etc. |
| **153-[LANG]-03** | Fix -or endings | 10m | ⏳ Not Started | color, behavior, etc. |
| **154-[LANG]-04** | Fix -er endings | 10m | ⏳ Not Started | center, meter, etc. |
| **210-[AUDIT]-00** | Generic names audit (parent) | 30m | ⏳ Not Started | helpers.rs, utils.rs, etc. |
| **211-[AUDIT]-01** | Find helpers/utils/common | 15m | ⏳ Not Started | Generic filenames |
| **212-[AUDIT]-02** | Audit types.rs files | 15m | ⏳ Not Started | Large types.rs (>200 lines) |
| **213-[AUDIT]-03** | Audit mod.rs files | 10m | ⏳ Not Started | mod.rs with logic (>50 lines) |
| **250-[FUNC]-00** | Function analysis (parent) | 2-3h | ⏳ Not Started | Swiss Army knife functions |
| **251-[FUNC]-01** | Find long functions | 30m | ⏳ Not Started | Functions >100 lines |
| **252-[FUNC]-02** | Find complex signatures | 20m | ⏳ Not Started | Functions with >5 params |
| **253-[FUNC]-03** | Find vague names | 20m | ⏳ Not Started | handle/process/manage names |

**Subtotal**: 13 tickets, ~3 hours

**Output**: Analysis reports identifying all violations → feeding into fix tickets

---

### ✅ Stufe 1: Non-Breaking Cleanup

### ✅ Phase 2: Test Extraction (MANDATORY - Standard #5)

| Ticket | File | Lines | Effort | Status |
|--------|------|-------|--------|--------|
| **100-[TESTS]-00** | Overview (parent) | - | - | ⏳ Not Started |
| **101-[TESTS]-00** | database/types.rs | 570 | 10m | ⏳ Not Started |
| **102-[TESTS]-00** | database/execute.rs | 661 | 10m | ⏳ Not Started |
| **103-[TESTS]-00** | database/query.rs | 387 | 10m | ⏳ Not Started |
| **104-[TESTS]-00** | database/index.rs | 532 | 10m | ⏳ Not Started |
| **105-[TESTS]-00** | database/stats.rs | 200 | 10m | ⏳ Not Started |
| **106-[TESTS]-00** | reedql/types.rs | 483 | 10m | ⏳ Not Started |
| **107-[TESTS]-00** | reedql/executor.rs | 697 | 10m | ⏳ Not Started |
| **108-[TESTS]-00** | merge/types.rs | 200 | 10m | ⏳ Not Started |
| **109-[TESTS]-00** | conflict/types.rs | 404 | 10m | ⏳ Not Started |
| **110-[TESTS]-00** | schema/types.rs | 306 | 10m | ⏳ Not Started |
| **111-[TESTS]-00** | btree/page.rs | 669 | 10m | ⏳ Not Started |
| **112-[TESTS]-00** | btree/types.rs | 150 | 10m | ⏳ Not Started |
| **113-[TESTS]-00** | version/rebuild.rs | 200 | 10m | ⏳ Not Started |
| **114-[TESTS]-00** | concurrent/types.rs | 100 | 10m | ⏳ Not Started |
| **115-[TESTS]-00** | reedql/parser.rs | 730 | 10m | ⏳ Not Started |
| **116-[TESTS]-00** | tables/ops.rs | 300 | 10m | ⏳ Not Started |
| **117-[TESTS]-00** | indices/builder.rs | 400 | 10m | ⏳ Not Started |

**Subtotal**: 18 tickets (1 parent + 17 files), ~2.5 hours

---

### 🔤 Phase 3: BBC English Fixes (MANDATORY - Standard #1)

Already covered by Phase 1 (151-154), executed after analysis.

---

### 📁 Phase 4: File Renaming & Audit (MANDATORY - Standards #3 & #7)

| Ticket | File | Action | Effort | Status |
|--------|------|--------|--------|--------|
| **200-[RENAME]-00** | tables/helpers.rs | → table_operations.rs | 15m | ⏳ Not Started |
| **200-[RENAME]-00** | indices/builder_tests.rs | → builder_test.rs | 5m | ⏳ Not Started |

**Plus results from 211-213** (found during audit) - TBD

**Subtotal**: 4+ tickets, ~1 hour

---

### ⚙️ Phase 5: Function Refactoring (Standards #4 & #6)

Results from 251-253 analysis will generate additional tickets.

**Estimated**: 5-10 function refactoring tickets @ 30-60 min each = 3-5 hours

---

### 📂 Phase 6: File Splits (Standard #2 - KISS)

---

| Ticket | File | Lines | New Files | Effort | Priority | Status |
|--------|------|-------|-----------|--------|----------|--------|
| **300-[SPLIT]-00** | Overview (parent) | - | - | - | - | ⏳ Not Started |
| **301-[SPLIT]-00** | btree/tree.rs | 782 | 5 files | 2h | CRITICAL | ⏳ Not Started |
| **302-[SPLIT]-00** | reedql/parser.rs | 730 | 4 files | 1.5h | CRITICAL | ⏳ Not Started |
| **303-[SPLIT]-00** | reedql/executor.rs | 697 | 3 files | 1h | HIGH | ⏳ Not Started |
| **304-[SPLIT]-00** | btree/page.rs | 669 | 2 files | 1h | HIGH | ⏳ Not Started |
| **305-[SPLIT]-00** | database/execute.rs | 661 | 4 files | 1h | MEDIUM | ⏳ Not Started |
| **306-[SPLIT]-00** | bin/formatters/mod.rs | 177 | 4 files | 30m | LOW | ⏳ Not Started |

**Subtotal**: 7 tickets (1 parent + 6 splits), ~7 hours

**Note**: Can skip 305-306 if time constrained (MEDIUM/LOW priority).

---

### ✅ Phase 7: Verification & Quality Gate

| Ticket | Title | Effort | Status |
|--------|-------|--------|--------|
| **600-[VERIFY]-00** | Final verification checklist | 1h | ⏳ Not Started |

**Checks all 7 CLAUDE.md standards** before launch.

---

### 🚀 Phase 8: Launch

| Ticket | Title | Effort | Status |
|--------|-------|--------|--------|
| **900-[LAUNCH]-00** | Squash commits & launch | 15m | ⏳ Not Started |

**Final clean commit** and push to GitHub.

---

## Time Estimates (Updated with Sub-Tickets)

### 📊 Phase-by-Phase Breakdown

| Phase | Tasks | Effort | Can Skip? |
|-------|-------|--------|-----------|
| **Phase 0** | Fix tests + folder reorg | 1.5h | ❌ Tests MANDATORY |
| **Phase 1** | Analysis (find all violations) | 3h | ❌ MANDATORY |
| **Phase 2** | Extract 17 inline tests | 2.5h | ❌ MANDATORY |
| **Phase 3** | BBC English fixes | 1h | ❌ MANDATORY |
| **Phase 4** | Rename generic files + audit results | 1h | ❌ MANDATORY |
| **Phase 5** | Function refactoring | 3-5h | ⚠️ Partial skip possible |
| **Phase 6** | File splits (6 files) | 7h | ⚠️ Can skip 305-306 |
| **Phase 7** | Verification | 1h | ❌ MANDATORY |
| **Phase 8** | Launch | 15m | ❌ MANDATORY |

### 🎯 Execution Scenarios

**Minimum (MANDATORY only)**:
- Phase 0-4, 7-8 (skip function refactor + file splits)
- **Total: ~10 hours**
- ⚠️ Warning: May not pass full CLAUDE.md compliance

**Recommended (High value)**:
- Phase 0-4, 7-8 + critical file splits (301-304)
- **Total: ~15 hours**
- ✅ Good CLAUDE.md compliance

**Full (Exemplary codebase)**:
- All phases, all tickets
- **Total: ~20 hours**
- ✅ 100% CLAUDE.md compliance
- 🏆 "Mustergültig" quality

---

## Execution Strategy

### Day 1 (4 hours)
1. ✅ FIX-001-00 (30m) - MUST DO FIRST
2. ✅ TESTS-100 series (2.5h) - Batch process
3. ✅ RENAME-200 (30m) - Quick wins
4. ⏸️ Break - commit progress

### Day 2 (4 hours)
5. ✅ SPLIT-301-00 (btree/tree.rs) - 2h
6. ✅ SPLIT-302-00 (reedql/parser.rs) - 1.5h
7. ⏸️ Break - commit progress
8. ✅ SPLIT-303-00 (reedql/executor.rs) - 30m

### Day 3 (2-3 hours)
9. ✅ SPLIT-304-00 (btree/page.rs) - 1h
10. ✅ VERIFY-600-00 - 1h
11. ✅ COMMIT-900-00 - 15m
12. 🚀 **LAUNCH**

---

## Decision Points

### Must Do (Non-negotiable)
- ✅ FIX-001 - Tests must pass
- ✅ TESTS-100 series - CLAUDE.md mandatory
- ✅ RENAME-200 - CLAUDE.md mandatory
- ✅ VERIFY-600 - Quality gate
- ✅ COMMIT-900 - Clean launch

### Should Do (High value)
- ✅ SPLIT-301 (btree/tree.rs) - Most complex, biggest impact
- ✅ SPLIT-302 (reedql/parser.rs) - Clear boundaries
- ✅ SPLIT-303 (reedql/executor.rs) - Pairs with parser

### Could Skip (Lower priority)
- ⚠️ SPLIT-304 (btree/page.rs) - Nice to have but not critical
- ⚠️ SPLIT-305 (database/execute.rs) - Medium priority
- ⚠️ SPLIT-306 (bin/formatters/mod.rs) - Low impact

**Vivian's Choice**: Full refactoring (Option B) - so we do ALL splits.

---

## Progress Tracking

Update this section as tickets are completed:

### Completed Tickets
- [ ] FIX-001-00 (registry setup)
- [ ] TESTS-100-00 (overview)
- [ ] TESTS-101-00 (database/types)
- [ ] TESTS-102-00 (database/execute)
- ... (update as we go)

### Current Ticket
**Working on**: None yet - start with FIX-001-00

**Blocked by**: Nothing

**Next up**: TESTS-100 series

---

## Notes & Learnings

### Session 2025-11-05
- Created comprehensive ticket system
- Identified 27 test failures (registry issue)
- Catalogued 17 files with inline tests
- Identified 6 large files for splitting
- Created backup snapshot in `_workbench/Archive/ReedBase/pre-refactoring-2025-11-05-snapshot/`

### Decisions Made
1. ✅ Chose Option B (Comprehensive) - full refactoring before launch
2. ✅ Ticket-based approach for session persistence
3. ✅ Uncompressed backup for easy reference
4. ✅ Will squash all commits to single launch commit

### Open Questions
- None currently

---

## Quick Commands

```bash
# Check current status
grep "Status" .workbench/docs/refactoring_tickets/*.md | grep -v "Not Started"

# Count completed
grep "Status" .workbench/docs/refactoring_tickets/*.md | grep "Complete" | wc -l

# Find next ticket
grep "Status" .workbench/docs/refactoring_tickets/*.md | grep "Not Started" | head -1

# Run tests
cd reedbase && cargo test --lib

# Check for inline tests remaining
grep -r "#\[cfg(test)\]" src --include="*.rs" | grep "mod tests" | grep -v "_test.rs" | wc -l
```

---

## Launch Readiness

| Requirement | Status | Details |
|-------------|--------|---------|
| All tests pass | ❌ Not Ready | 27 failures (registry issue) |
| No inline test modules | ❌ Not Ready | 17 files to fix |
| No generic filenames | ❌ Not Ready | 2 files to rename |
| No files >400 lines | ❌ Not Ready | 6 files to split |
| BBC English | ✅ Ready | Already compliant |
| Copyright headers | ✅ Ready | All present |
| Documentation | ✅ Ready | README, CHANGELOG, etc. |

**Overall**: 🔴 **NOT READY** - Requires refactoring before launch

**After refactoring**: 🟢 **READY FOR LAUNCH**

---

## 📁 STRUCT-050: Folder Structure Reorganization (ADDED)

**Decision**: Reorganize flat structure into 5 clear categories.

**New Structure**:
```
src/
├── api/         # External interfaces (db/, reedql/, cli/)
├── store/       # Storage layer (tables/, btree/, indices/, registry/)
├── validate/    # Data validation (schema/, functions/)
├── process/     # Process coordination (locks/, conflict/, merge/, version/)
└── ops/         # Operations (backup/, metrics/, log/)
```

**Why**: KISS for developers - clear hierarchy shows relationships and intent.

**When**: After FIX-001, before or after TESTS-100.

**Effort**: 1 hour (mostly import updates)

---

## Updated Critical Path

```
FIX-001 (30m - CRITICAL)
   ↓
STRUCT-050 (1h - NEW: Folder restructure) ← OPTIONAL but recommended
   ↓
TESTS-100 series (2.5h)
   ↓
RENAME-200 (30m)
   ↓
SPLIT-300 series (7h)
   ↓
VERIFY-600 (1h)
   ↓
COMMIT-900 (15m)
```

**Decision point**: Include STRUCT-050 or skip?
- **Include**: Better structure for all subsequent work (recommended)
- **Skip**: Faster path to completion

