# 040-[API]-03: Database Execute + Index Management

**Created**: 2025-11-06  
**Phase**: 4 (API Layer)  
**Estimated Effort**: 4-5 hours  
**Dependencies**: 040-02 (Database Core)  
**Blocks**: 040-04 (ReedQL)

---

## 🚨 GOLDEN RULE: COMPLETE PARITY

**Verification Date**: 2025-11-06

- [x] **execute.rs: 661 lines → SPLIT 2 files** (execute_write ~350, execute_delete ~310)
- [x] **index.rs: 532 lines → SPLIT 2 files** (index_create ~280, index_auto ~250)
- [x] **INSERT/UPDATE/DELETE + auto-indexing**

**Files**:
```
execute.rs      661 → execute_write.rs (~350) + execute_delete.rs (~310)
index.rs        532 → index_create.rs (~280) + index_auto.rs (~250)
Total: 1193 → ~1210 lines (4 files)
```

**Operations**:
- execute_write.rs: INSERT, UPDATE
- execute_delete.rs: DELETE, TRUNCATE
- index_create.rs: CREATE INDEX, DROP INDEX
- index_auto.rs: Auto-detection, pattern tracking

**Dependencies**:
```rust
use super::database::{Database};
use crate::store::tables::Table;
use crate::store::indices::{IndexBuilder, IndexManager};
use crate::validate::schema::validate_row;
```

---

## Split Strategy

**execute.rs → 2 files**:
1. **execute_write.rs** (~350): INSERT + UPDATE logic
2. **execute_delete.rs** (~310): DELETE + TRUNCATE logic

**index.rs → 2 files**:
1. **index_create.rs** (~280): Manual index creation/deletion
2. **index_auto.rs** (~250): Auto-detection algorithm

---

## Implementation Steps

1. **execute_write.rs** (60 min): INSERT + UPDATE
2. **execute_delete.rs** (50 min): DELETE + TRUNCATE
3. **index_create.rs** (50 min): CREATE/DROP INDEX
4. **index_auto.rs** (50 min): Auto-indexing detection
5. **Tests** (60 min): Adapt tests
6. **Verify** (25 min): QS-Matrix

---

## QS-Matrix (16 checks)

**Pre**:
- [x] Golden Rule: 1193 lines, 4-file split validated
- [x] Standard #0: Uses Table, IndexBuilder, validate_row
- [x] Standard #3: execute_write, index_auto (not execute_helpers)
- [x] Standard #8: Layered API

**During**:
- [ ] Standard #1: BBC English (optimise indexing)
- [ ] Standard #4: Single Responsibility (write≠delete, create≠auto)

**Post**:
- [ ] Standard #2: All 4 files <400
- [ ] Standard #5: Separate tests
- [ ] Standard #6: No Swiss Army execute()
- [ ] Regression: Tests passing

---

## Success Criteria

- ✅ INSERT/UPDATE/DELETE working
- ✅ Manual index creation
- ✅ Auto-indexing after 10x patterns
- ✅ 4 files split successful

---

## Commit

```
[CLEAN-040-03] feat(api): implement execute + index management

Phase 4 - API Layer - Ticket 3/6

✅ execute.rs split (661 → 2 files <400)
✅ index.rs split (532 → 2 files <400)
✅ INSERT/UPDATE/DELETE + auto-indexing
✅ Pattern detection working

Quality: 4 files split ✅, single responsibility ✅
```
