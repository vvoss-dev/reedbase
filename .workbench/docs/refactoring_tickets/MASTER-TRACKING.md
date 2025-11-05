# Master Refactoring Tracking

**Goal**: Transform ReedBase to mustergültig (exemplary) codebase  
**Started**: 2025-11-05  
**Target Completion**: Before v0.2.0-beta launch  
**Total Estimated Time**: 6-8 hours

---

## Quick Status

| Phase | Tickets | Status | Progress |
|-------|---------|--------|----------|
| **Preparation** | FIX-001 | ⏳ Not Started | 0/1 |
| **Stufe 1: Tests** | TESTS-100 to 115 | ⏳ Not Started | 0/17 |
| **Stufe 1: Rename** | RENAME-200 | ⏳ Not Started | 0/2 |
| **Stufe 2: Split** | SPLIT-300 to 306 | ⏳ Not Started | 0/6 |
| **Stufe 3: Verify** | VERIFY-600 | ⏳ Not Started | 0/1 |
| **Final: Commit** | COMMIT-900 | ⏳ Not Started | 0/1 |
| **TOTAL** | **28 tickets** | **0% complete** | **0/28** |

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
| **FIX-001-00** | Fix test registry setup | CRITICAL | 30m | ⏳ Not Started | 27 tests failing, blocks everything |

**Why Critical**: Can't refactor if tests don't pass. Must fix first.

---

### ✅ Stufe 1: Non-Breaking Cleanup

#### Test Extraction (TESTS-100 series)

| Ticket | File | Lines | Effort | Status |
|--------|------|-------|--------|--------|
| TESTS-100-00 | Overview | - | - | ⏳ Not Started |
| TESTS-101-00 | database/types.rs | 570 | 10m | ⏳ Not Started |
| TESTS-102-00 | database/execute.rs | 661 | 10m | ⏳ Not Started |
| TESTS-103-00 | database/query.rs | 387 | 10m | ⏳ Not Started |
| TESTS-104-00 | database/index.rs | 532 | 10m | ⏳ Not Started |
| TESTS-105-00 | database/stats.rs | 200 | 10m | ⏳ Not Started |
| TESTS-106-00 | reedql/types.rs | 483 | 10m | ⏳ Not Started |
| TESTS-107-00 | reedql/executor.rs | 697 | 10m | ⏳ Not Started |
| TESTS-108-00 | merge/types.rs | 200 | 10m | ⏳ Not Started |
| TESTS-109-00 | conflict/types.rs | 404 | 10m | ⏳ Not Started |
| TESTS-110-00 | schema/types.rs | 306 | 10m | ⏳ Not Started |
| TESTS-111-00 | btree/page.rs | 669 | 10m | ⏳ Not Started |
| TESTS-112-00 | btree/types.rs | 150 | 10m | ⏳ Not Started |
| TESTS-113-00 | version/rebuild.rs | 200 | 10m | ⏳ Not Started |
| TESTS-114-00 | concurrent/types.rs | 100 | 10m | ⏳ Not Started |
| TESTS-115-00 | Remaining files | Varies | 30m | ⏳ Not Started |

**Subtotal**: 17 files, ~2.5 hours

#### File Renaming (RENAME-200 series)

| Ticket | File | New Name | Effort | Status |
|--------|------|----------|--------|--------|
| RENAME-200-00 | tables/helpers.rs | table_operations.rs | 15m | ⏳ Not Started |
| RENAME-200-00 | indices/builder_tests.rs | builder_test.rs | 5m | ⏳ Not Started |

**Subtotal**: 2 files, ~30 minutes

---

### 🔄 Stufe 2: File Splitting

| Ticket | File | Lines | New Files | Effort | Priority | Status |
|--------|------|-------|-----------|--------|----------|--------|
| SPLIT-300-00 | Overview | - | - | - | - | ⏳ Not Started |
| SPLIT-301-00 | btree/tree.rs | 782 | 5 files | 2h | CRITICAL | ⏳ Not Started |
| SPLIT-302-00 | reedql/parser.rs | 730 | 4 files | 1.5h | CRITICAL | ⏳ Not Started |
| SPLIT-303-00 | reedql/executor.rs | 697 | 3 files | 1h | HIGH | ⏳ Not Started |
| SPLIT-304-00 | btree/page.rs | 669 | 2 files | 1h | HIGH | ⏳ Not Started |
| SPLIT-305-00 | database/execute.rs | 661 | 4 files | 1h | MEDIUM | ⏳ Not Started |
| SPLIT-306-00 | bin/formatters/mod.rs | 177 | 4 files | 30m | LOW | ⏳ Not Started |

**Subtotal**: 6 files → ~22 new files, ~7 hours

**Note**: Can potentially skip SPLIT-305 and SPLIT-306 if time constrained (MEDIUM/LOW priority).

---

### ✓ Stufe 3: Verification & Launch

| Ticket | Title | Effort | Status |
|--------|-------|--------|--------|
| VERIFY-600-00 | Final verification checklist | 1h | ⏳ Not Started |
| COMMIT-900-00 | Squash commits & launch | 15m | ⏳ Not Started |

**Subtotal**: ~1.25 hours

---

## Time Estimates

### Minimum (Skip optional splits)
- FIX-001: 30m
- TESTS-100 series: 2.5h
- RENAME-200: 30m
- SPLIT-301, SPLIT-302 (critical only): 3.5h
- VERIFY-600: 1h
- COMMIT-900: 15m
- **Total: ~8 hours**

### Full (All splits)
- FIX-001: 30m
- TESTS-100 series: 2.5h
- RENAME-200: 30m
- SPLIT-300 series (all): 7h
- VERIFY-600: 1h
- COMMIT-900: 15m
- **Total: ~11.75 hours**

### Recommended (High priority only)
- FIX-001: 30m
- TESTS-100 series: 2.5h
- RENAME-200: 30m
- SPLIT-301, SPLIT-302, SPLIT-303, SPLIT-304: 5.5h
- VERIFY-600: 1h
- COMMIT-900: 15m
- **Total: ~10 hours**

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

