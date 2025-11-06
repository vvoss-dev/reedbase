# 040-[API]-04: ReedQL Types + Parser + Analyzer

**Created**: 2025-11-06  
**Phase**: 4 (API Layer)  
**Estimated Effort**: 4-5 hours  
**Dependencies**: 040-02 (Database Core)  
**Blocks**: 040-05 (Executor)

---

## 🚨 GOLDEN RULE: COMPLETE PARITY

**Verification Date**: 2025-11-06

- [x] **types.rs: 483 lines → SPLIT 2 files** (types_ast ~250, types_query ~233)
- [x] **parser.rs: 730 lines → SPLIT 3 files** (parser_select ~250, parser_dml ~250, parser_ddl ~230)
- [x] **analyzer.rs: 192 lines → OK**

**Files**:
```
types.rs        483 → types_ast.rs (~250) + types_query.rs (~233)
parser.rs       730 → parser_select.rs + parser_dml.rs + parser_ddl.rs (~250 each)
analyzer.rs     192 → analyzer.rs (complete)
Total: 1405 → ~1450 lines (6 files)
```

**AST Types**:
```rust
// types_ast.rs:
pub enum Statement { Select, Insert, Update, Delete, CreateTable, CreateIndex }
pub struct SelectStatement { columns, from, where_clause, order_by, limit }
pub struct WhereClause { conditions, operators }

// types_query.rs:
pub struct QueryPlan { operations, estimated_cost, index_selection }
pub enum Operation { TableScan, IndexScan, Filter, Sort, Limit }
```

**Parser Functions**:
- parser_select.rs: parse_select, parse_where, parse_order_by
- parser_dml.rs: parse_insert, parse_update, parse_delete
- parser_ddl.rs: parse_create_table, parse_create_index

**Dependencies**:
```rust
use crate::error::{ReedError, ReedResult};
use nom::{IResult, bytes::complete::*, character::complete::*};
```

---

## Split Strategy

**types.rs → 2 files**:
1. **types_ast.rs** (~250): AST nodes (Statement, SelectStatement, etc.)
2. **types_query.rs** (~233): Query plan types (QueryPlan, Operation)

**parser.rs → 3 files**:
1. **parser_select.rs** (~250): SELECT parsing
2. **parser_dml.rs** (~250): INSERT/UPDATE/DELETE
3. **parser_ddl.rs** (~230): CREATE TABLE/INDEX

---

## Implementation Steps

1. **types_ast.rs** (40 min): AST types
2. **types_query.rs** (35 min): Query plan types
3. **parser_select.rs** (60 min): SELECT parser
4. **parser_dml.rs** (50 min): DML parsers
5. **parser_ddl.rs** (45 min): DDL parsers
6. **analyzer.rs** (35 min): Query analyzer
7. **Tests** (60 min): Adapt tests
8. **Verify** (25 min): QS-Matrix

---

## QS-Matrix (16 checks)

**Pre**:
- [x] Golden Rule: 1405 lines, 6-file split validated
- [x] Standard #0: Uses nom parser combinators
- [x] Standard #3: parser_select, types_ast (not parser_helpers)
- [x] Standard #8: Layered query processing

**During**:
- [ ] Standard #1: BBC English (analyse queries)
- [ ] Standard #4: Single Responsibility (SELECT≠DML≠DDL)

**Post**:
- [ ] Standard #2: All 6 files <400
- [ ] Standard #5: Separate tests
- [ ] Regression: Tests passing

---

## Success Criteria

- ✅ Full ReedQL grammar parsed
- ✅ AST generation working
- ✅ Query analysis complete
- ✅ 6 files split successful

---

## Commit

```
[CLEAN-040-04] feat(api): implement ReedQL types + parser

Phase 4 - API Layer - Ticket 4/6

✅ types.rs split (483 → 2 files <400)
✅ parser.rs split (730 → 3 files <400)
✅ analyzer.rs complete (192 lines)
✅ Full ReedQL grammar parsing

Quality: 6 files split ✅, nom parser ✅
```
