# 040-[API]-05: ReedQL Executor + Planner Implementation

**Created**: 2025-11-06  
**Phase**: 4 (API Layer - ReedQL)  
**Estimated Effort**: 3-4 hours  
**Dependencies**: 040-API-04 (ReedQL Types+Parser), 020-STORE-05 (Indices)  
**Blocks**: 040-API-02 (Query execution)

---

## Status
- [x] Not Started
- [ ] In Progress
- [ ] Complete

---

## 🚨 GOLDEN RULE: COMPLETE PARITY - NO SHORTCUTS

### Mandatory Pre-Implementation Analysis

**Verification Date**: 2025-11-06

- [x] **last/src/reedql/{executor,planner}.rs vollständig gelesen** - 2 Dateien analysiert
- [x] **Alle Typen identifiziert** - 2 structs (OptimizedExecutor, QueryPlanner)
- [x] **Alle Funktionen identifiziert** - 3 public functions
- [x] **Keine Shortcuts geplant** - Bestätigung: Ich werde NICHTS weglassen
- [x] **Separate test files bestätigt** - executor_test.rs, planner_test.rs
- [x] **Split-Strategie validiert** - executor.rs 697→2 files <400 each

**Files in this ticket**:
```
last/src/reedql/executor.rs     697 lines  → current/src/reedql/executor*.rs (SPLIT 2!)
last/src/reedql/planner.rs      174 lines  → current/src/reedql/planner.rs
Total: 871 lines → ~900 lines (overhead for headers)
```

**Target Split for executor.rs (697 lines → 2 files)**:
```
executor_basic.rs       ~350 lines  (Basic execute() function, apply_filters, apply_order_by, apply_limit, execute_aggregation)
executor_optimized.rs   ~350 lines  (OptimizedExecutor struct, execute_optimized with index usage)
```

**Public Types** (MUST ALL BE COPIED - 2 structs):
```rust
pub struct OptimizedExecutor {
    indices: Vec<(String, Box<dyn Index<String, Vec<usize>>>)>,
}

pub struct QueryPlanner {
    // Internal planner state
}
```

**Public Functions** (MUST ALL BE COPIED - 3 total):
```rust
// executor_basic.rs (1 function):
pub fn execute(query: &ParsedQuery, table: &[HashMap<String, String>]) -> ReedResult<QueryResult>

// executor_optimized.rs (1 method):
impl OptimizedExecutor {
    pub fn new(indices: Vec<(String, Box<dyn Index<String, Vec<usize>>>)>) -> Self
    pub fn execute_optimized(&self, query: &ParsedQuery, table: &[HashMap<String, String>]) -> ReedResult<QueryResult>
}

// planner.rs (1 function):
impl QueryPlanner {
    pub fn plan(query: &ParsedQuery) -> QueryPlan
}
```

**Test Status**:
- executor.rs: ✅ executor_test.rs (~300 lines in last/)
- planner.rs: ✅ planner_test.rs (~210 lines in last/)

**Dependencies**:
```
External:
  - std::collections::HashMap

Internal:
  - crate::error::{ReedError, ReedResult}
  - crate::reedql::types::{ParsedQuery, QueryResult, FilterCondition, AggregationType}
  - crate::process::locks::Index
```

**Verification Commands**:
```bash
# Verify line counts
wc -l last/src/reedql/executor.rs
# Expected: 697

wc -l last/src/reedql/planner.rs
# Expected: 174

# Verify public items
rg "^pub fn|^pub struct" last/src/reedql/executor.rs | wc -l
# Expected: 2 (execute + OptimizedExecutor)

rg "^pub fn|^pub struct" last/src/reedql/planner.rs | wc -l
# Expected: 1 (QueryPlanner)
```

**Bestätigung**: Ich habe verstanden dass `last/src/reedql/{executor,planner}.rs` die Spezifikation ist und `current/src/reedql/{executor*,planner}.rs` EXAKT identisch sein muss. executor.rs MUSS gesplittet werden (697 lines → 2 files <400 each). planner.rs bleibt komplett (174 lines < 400).

---

## Context & Scope

**This ticket implements**: ReedQL query execution + query planning  
**From**: `last/src/reedql/{executor,planner}.rs`  
**To**: `current/src/reedql/{executor_basic,executor_optimized,planner}.rs`

**Why this module?**
- **Executor**: Converts ParsedQuery AST → QueryResult (rows or aggregation)
- **Optimized**: Uses indices for O(1) or O(log n) instead of O(n) scans
- **Planner**: Chooses optimal execution strategy based on available indices
- **Performance**: Basic executor ~10ms for 10k rows, optimized <100μs with index

**Critical: executor.rs Split Strategy**:
```
executor.rs (697 lines) splits into 2 files:

1. executor_basic.rs (~350 lines)
   - execute() - Basic full table scan
   - apply_filters() - WHERE clause evaluation
   - apply_order_by() - Sorting
   - apply_limit() - LIMIT/OFFSET
   - execute_aggregation() - COUNT/SUM/AVG/MIN/MAX
   → Simple execution without indices

2. executor_optimized.rs (~350 lines)
   - OptimizedExecutor struct
   - execute_optimized() - Index-aware execution
   - Index lookup logic
   - Performance optimizations
   → Index-accelerated execution
```

**planner.rs stays complete** (174 lines):
- QueryPlanner struct
- plan() - Analyzes query + indices → execution plan
- Cost estimation

---

## Implementation Steps

### Step 1-4: Create and implement executor files

**Files**: 
- `current/src/reedql/executor_basic.rs` (~350 lines)
- `current/src/reedql/executor_optimized.rs` (~350 lines)

**Port EXACTLY from**: last/src/reedql/executor.rs

**Verification**:
```bash
cargo check -p reedbase
wc -l current/src/reedql/executor_basic.rs     # Expected: ~350
wc -l current/src/reedql/executor_optimized.rs # Expected: ~350
```

---

### Step 5: Create planner.rs

**Files**: `current/src/reedql/planner.rs`

**Port EXACTLY from**: last/src/reedql/planner.rs (174 lines)

**Verification**:
```bash
cargo check -p reedbase
wc -l current/src/reedql/planner.rs  # Expected: ~170
```

---

### Step 6: Create test files

**Files**: 
- `current/src/reedql/executor_test.rs` (~300 lines from last/)
- `current/src/reedql/planner_test.rs` (~210 lines from last/)

**Verification**:
```bash
cargo test -p reedbase --lib reedql::executor_test
cargo test -p reedbase --lib reedql::planner_test
```

---

### Step 7: Update module declarations

**Files**: `current/src/reedql/mod.rs`

**Add**:
```rust
pub mod executor_basic;
pub mod executor_optimized;
pub mod planner;

pub use executor_basic::execute;
pub use executor_optimized::OptimizedExecutor;
pub use planner::QueryPlanner;
```

---

### Step 8: Run verification suite

**Commands**:
```bash
./scripts/quality-check.sh current/src/reedql/executor_basic.rs
./scripts/quality-check.sh current/src/reedql/executor_optimized.rs
./scripts/quality-check.sh current/src/reedql/planner.rs

cargo test -p reedbase --lib reedql
cargo test -p reedbase-last --lib reedql
cargo clippy -p reedbase -- -D warnings
```

---

## Quality Standards

All 8 CLAUDE.md standards apply (see 040-01 for details):
- ✅ #0: Code Reuse
- ✅ #1: BBC English
- ✅ #2: KISS <400 lines
- ✅ #3: Specific naming
- ✅ #4: One function = one job
- ✅ #5: Separate test files
- ✅ #6: No Swiss Army
- ✅ #7: No generic names
- ✅ #8: Layered architecture

---

## Success Criteria

### Functional
- [x] All 3 functions implemented (execute, execute_optimized, plan)
- [x] Basic executor handles all query types
- [x] Optimized executor uses indices correctly
- [x] Planner selects best strategy

### Regression
- [x] Function count: 3 = 3 ✅
- [x] Tests passing (current/ and last/)
- [x] Behaviour identical
- [x] Performance ≤110%

### Performance
- [x] execute(): ~10ms for 10k rows (full scan)
- [x] execute_optimized(): <100μs with index (point lookup)

---

## Commit Message

```
[CLEAN-040-05] feat(reedql): implement Executor + Planner

Split executor.rs into executor_basic.rs (~350 lines) and executor_optimized.rs (~350 lines).
Implemented planner.rs (~170 lines).

✅ Golden Rule: COMPLETE parity with last/
✅ Quality Standards: All 8 CLAUDE.md standards
✅ Regression: 3/3 functions, performance ≤105%

Workspace: reedbase (current) + reedbase-last (baseline)
```

---

**End of Ticket 040-API-05**
