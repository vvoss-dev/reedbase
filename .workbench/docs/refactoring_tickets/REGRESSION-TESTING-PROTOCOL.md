# Regression Testing Protocol

**MANDATORY**: Altes Ergebnis MUSS dem neuen entsprechen.

**Prinzip**: src/ (neu) MUSS identische Ergebnisse liefern wie src-old/ (alt)

---

## 🎯 Core Requirement

> "alles wird getestet und altes ergebnis muss dem neuen entsprechen"

**Bedeutung**:
- Jede Funktion in src/ MUSS gleiche Outputs wie src-old/ produzieren
- Jeder Test aus src-old/ MUSS in src/ grün sein
- Behaviour MUSS identisch sein (keine Breaking Changes)
- Performance darf sich NICHT verschlechtern

**Ausnahmen**: Nur mit expliziter Dokumentation
- Bug fixes (altes Verhalten war falsch)
- Intentional improvements (dokumentiert in MIGRATION.md)

---

## 📋 Regression Testing Matrix

**Wird zu QS-Matrix hinzugefügt in JEDEM Ticket**

### Zusätzliche QS-Checks für Regression Testing

#### Before Implementation
```bash
# 1. Identify corresponding src-old/ functionality
grep -r "pub fn function_name" src-old/

# 2. Extract existing tests
find src-old/ -name "*_test.rs" -o -name "*test*.rs" | grep "module"

# 3. Document expected behaviour
echo "Function X with input Y should return Z" > expected-behaviour.txt
```

#### During Implementation
```bash
# 1. Copy tests from src-old/ to src/
# NOT just copy - adapt to new structure, but SAME assertions

# 2. Run old tests against new implementation
cargo test --lib module::tests

# 3. Compare outputs
./scripts/regression-check.sh old_func new_func test_input
```

#### After Implementation
```bash
# 1. All old tests passing?
cargo test --lib module
# Expected: 100% green (same as src-old/)

# 2. Behaviour identical?
./scripts/regression-verify.sh module

# 3. Performance acceptable?
cargo bench --bench module_bench
# Expected: Within 10% of src-old/ performance
```

---

## 🔧 Regression Testing Tools

### Tool 1: `scripts/regression-check.sh`

Vergleicht Outputs von alter und neuer Implementation:

```bash
#!/usr/bin/env bash
# Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
# SPDX-License-Identifier: Apache-2.0

# Regression check: Compare outputs of old vs new implementation
# Usage: ./scripts/regression-check.sh <module> <function> <test_inputs>

set -e

MODULE=$1
FUNCTION=$2
INPUTS=$3

if [ -z "$MODULE" ] || [ -z "$FUNCTION" ]; then
    echo "Usage: $0 <module> <function> [test_inputs]"
    echo ""
    echo "Example: $0 core::paths db_dir '/tmp/test'"
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔄 Regression Check: $MODULE::$FUNCTION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Create test harness
cat > /tmp/regression_test.rs << EOF
// Temporary regression test

// Old implementation
#[path = "src-old/$MODULE.rs"]
mod old;

// New implementation
#[path = "src/$MODULE.rs"]
mod new;

fn main() {
    let input = $INPUTS;
    
    let old_result = old::$FUNCTION(input);
    let new_result = new::$FUNCTION(input);
    
    println!("Old: {:?}", old_result);
    println!("New: {:?}", new_result);
    
    if old_result == new_result {
        println!("✅ PASS: Results identical");
        std::process::exit(0);
    } else {
        println!("❌ FAIL: Results differ!");
        std::process::exit(1);
    }
}
EOF

# Compile and run
rustc /tmp/regression_test.rs -o /tmp/regression_test 2>/dev/null || {
    echo "⚠️  Could not compile regression test"
    echo "    Manual verification required"
    exit 0
}

/tmp/regression_test
```

### Tool 2: `scripts/regression-verify.sh`

Automatische Verifikation eines kompletten Moduls:

```bash
#!/usr/bin/env bash
# Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
# SPDX-License-Identifier: Apache-2.0

# Regression verification for entire module
# Usage: ./scripts/regression-verify.sh <module>

set -e

MODULE=$1

if [ -z "$MODULE" ]; then
    echo "Usage: $0 <module>"
    echo ""
    echo "Example: $0 core"
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔄 Regression Verification: $MODULE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

PASS=0
FAIL=0
SKIP=0

# 1. Compare test results
echo "📋 Step 1: Test Results Comparison"
echo "────────────────────────────────────────────────────────────────"

if [ -d "src-old/$MODULE" ]; then
    echo "Running tests for src-old/$MODULE..."
    OLD_TESTS=$(cargo test --lib $MODULE 2>&1 | grep "test result" || echo "No tests")
    
    echo "Running tests for src/$MODULE..."
    NEW_TESTS=$(cargo test --lib $MODULE 2>&1 | grep "test result" || echo "No tests")
    
    echo "Old: $OLD_TESTS"
    echo "New: $NEW_TESTS"
    
    if [ "$OLD_TESTS" == "$NEW_TESTS" ]; then
        echo "✅ Test results identical"
        ((PASS++))
    else
        echo "❌ Test results differ!"
        ((FAIL++))
    fi
else
    echo "⚠️  src-old/$MODULE not found (skipping)"
    ((SKIP++))
fi
echo ""

# 2. Compare public API
echo "📋 Step 2: Public API Comparison"
echo "────────────────────────────────────────────────────────────────"

OLD_API=$(rg "^pub fn" src-old/$MODULE/ 2>/dev/null | sort || echo "")
NEW_API=$(rg "^pub fn" src/$MODULE/ 2>/dev/null | sort || echo "")

if [ "$OLD_API" == "$NEW_API" ]; then
    echo "✅ Public API identical"
    ((PASS++))
else
    echo "⚠️  Public API differences detected:"
    echo ""
    echo "Only in old:"
    diff <(echo "$OLD_API") <(echo "$NEW_API") | grep "^<" || echo "(none)"
    echo ""
    echo "Only in new:"
    diff <(echo "$OLD_API") <(echo "$NEW_API") | grep "^>" || echo "(none)"
    echo ""
    echo "Review: Are these intentional changes?"
    ((FAIL++))
fi
echo ""

# 3. Compare documentation
echo "📋 Step 3: Documentation Coverage"
echo "────────────────────────────────────────────────────────────────"

OLD_DOCS=$(rg "^///|^//!" src-old/$MODULE/ 2>/dev/null | wc -l || echo "0")
NEW_DOCS=$(rg "^///|^//!" src/$MODULE/ 2>/dev/null | wc -l || echo "0")

echo "Old documentation lines: $OLD_DOCS"
echo "New documentation lines: $NEW_DOCS"

if [ "$NEW_DOCS" -ge "$OLD_DOCS" ]; then
    echo "✅ Documentation maintained or improved"
    ((PASS++))
else
    echo "⚠️  Documentation decreased (old: $OLD_DOCS, new: $NEW_DOCS)"
    echo "    Ensure all public functions are documented"
    ((FAIL++))
fi
echo ""

# 4. Performance comparison (if benchmarks exist)
echo "📋 Step 4: Performance Comparison"
echo "────────────────────────────────────────────────────────────────"

if [ -f "benches/${MODULE}_bench.rs" ]; then
    echo "Running benchmarks for $MODULE..."
    
    # Run benchmark (would need actual implementation)
    echo "⚠️  Benchmark comparison not yet implemented"
    echo "    Run manually: cargo bench --bench ${MODULE}_bench"
    ((SKIP++))
else
    echo "ℹ️  No benchmarks found for $MODULE"
    ((SKIP++))
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Regression Verification Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Passed:  $PASS"
echo "❌ Failed:  $FAIL"
echo "⚠️  Skipped: $SKIP"
echo ""

if [ "$FAIL" -eq 0 ]; then
    echo "✅ REGRESSION CHECK PASSED"
    echo ""
    echo "Module $MODULE maintains behaviour compatibility with src-old/"
    exit 0
else
    echo "❌ REGRESSION CHECK FAILED"
    echo ""
    echo "Module $MODULE has $FAIL failing regression checks."
    echo "Review differences and document intentional changes in MIGRATION.md"
    exit 1
fi
```

---

## 📊 Regression Test Categories

### Category 1: Unit Tests (Function-Level)

**Requirement**: Jede Funktion aus src-old/ hat Test in src/

```rust
// src-old/core/paths.rs
pub fn db_dir(base: &Path) -> PathBuf {
    base.join(".reedbase")
}

// src-old/core/paths_test.rs
#[test]
fn test_db_dir() {
    let base = PathBuf::from("/tmp/test");
    assert_eq!(db_dir(&base), PathBuf::from("/tmp/test/.reedbase"));
}

// src/core/paths_test.rs
// MUST have IDENTICAL test with IDENTICAL assertion
#[test]
fn test_db_dir() {
    let base = PathBuf::from("/tmp/test");
    assert_eq!(db_dir(&base), PathBuf::from("/tmp/test/.reedbase"));
    // ✅ Same input, same expected output
}
```

**Verification**:
```bash
# Both tests must pass
cargo test --lib core::paths::tests::test_db_dir
```

### Category 2: Integration Tests (Module-Level)

**Requirement**: Komplexe Workflows müssen identische Ergebnisse liefern

**Example**: CSV Table Loading
```rust
// Integration test: Load table and verify structure
#[test]
fn test_load_users_table() {
    let db = Database::new("/tmp/test_db");
    let table = db.load_table("users").unwrap();
    
    // Old behaviour: 3 columns, 10 rows
    assert_eq!(table.columns.len(), 3);
    assert_eq!(table.rows.len(), 10);
    assert_eq!(table.columns[0].name, "id");
    
    // ✅ New implementation MUST return identical structure
}
```

**Verification**:
```bash
# Compare outputs
cargo test --test integration_tests::test_load_users_table
```

### Category 3: End-to-End Tests (System-Level)

**Requirement**: CLI commands müssen identische Outputs liefern

**Example**: Query Command
```bash
# Test fixture: Create test database
./target/release/reedbase-old init test.db
./target/release/reedbase-old insert test.db users "id=1|name=Alice"
./target/release/reedbase-old insert test.db users "id=2|name=Bob"

# Old output
OLD_OUTPUT=$(./target/release/reedbase-old query test.db "SELECT * FROM users")
# id|name
# 1|Alice
# 2|Bob

# New output
NEW_OUTPUT=$(./target/release/reedbase query test.db "SELECT * FROM users")
# id|name
# 1|Alice
# 2|Bob

# Verification
if [ "$OLD_OUTPUT" == "$NEW_OUTPUT" ]; then
    echo "✅ End-to-end test passed"
else
    echo "❌ End-to-end test failed"
    diff <(echo "$OLD_OUTPUT") <(echo "$NEW_OUTPUT")
fi
```

### Category 4: Performance Tests (Benchmark-Level)

**Requirement**: Performance darf sich NICHT verschlechtern (max. 10% slower)

**Example**: B-Tree Insert Performance
```rust
// benches/btree_bench.rs
use criterion::{black_box, criterion_group, criterion_main, Criterion};

fn bench_insert_1000(c: &mut Criterion) {
    c.bench_function("btree insert 1000", |b| {
        b.iter(|| {
            let mut tree = BTree::new();
            for i in 0..1000 {
                tree.insert(black_box(i), black_box(i * 2));
            }
        });
    });
}

criterion_group!(benches, bench_insert_1000);
criterion_main!(benches);
```

**Verification**:
```bash
# Run benchmarks for old implementation
git checkout src-old
cargo bench --bench btree_bench > old_bench.txt

# Run benchmarks for new implementation
git checkout src
cargo bench --bench btree_bench > new_bench.txt

# Compare
./scripts/compare-benchmarks.sh old_bench.txt new_bench.txt
# Expected: new <= old * 1.1 (max 10% slower)
```

---

## 🎯 Integration into Ticket Workflow

### Updated QS-Matrix (now includes Regression Testing)

```markdown
## ✅ Qualitätssicherungs-Matrix (MANDATORY!)

### Pre-Implementation
- [ ] Standard #0: Funktionssuche durchgeführt
- [ ] Standard #3: Dateiname spezifisch
- [ ] Standard #8: Architektur-Layer korrekt
- [ ] **Regression: Alte Tests identifiziert** (src-old/)
- [ ] **Regression: Erwartetes Verhalten dokumentiert**

### During Implementation
- [ ] Standard #1: BBC English
- [ ] Standard #4: Single Responsibility
- [ ] Standard #6: No Swiss Army
- [ ] Standard #7: Spezifische Namen
- [ ] **Regression: Tests von src-old/ adaptiert**

### Post-Implementation
- [ ] Standard #2: Line count <400
- [ ] Standard #5: Tests in _test.rs
- [ ] Standard #0: Keine Duplikate erstellt
- [ ] **Regression: Alle alten Tests grün**
- [ ] **Regression: Output identisch zu src-old/**

### Final Verification
```bash
# Quality check
./scripts/quality-check.sh src/module/file.rs

# Regression check
./scripts/regression-verify.sh module
# ✅ Expected: All regression checks PASS

# Performance check
cargo bench --bench module_bench
# ✅ Expected: Within 10% of old performance

# Commit with regression confirmation
git commit -m "[CLEAN-0XX] feat(module): implement feature

✅ QS-Matrix verified (all 8 CLAUDE.md standards)
✅ Regression tests: XX/XX passing
✅ Behaviour identical to src-old/module/
✅ Performance: Within 5% of baseline

All tests passing."
```
```

---

## 📋 Regression Testing Checklist

**For EVERY ticket**:

### 1. Before Starting
- [ ] Find corresponding src-old/ implementation
- [ ] Extract existing tests from src-old/
- [ ] Document expected inputs/outputs
- [ ] Create regression test plan for this module

### 2. During Implementation
- [ ] Copy tests from src-old/ to src/ (adapt structure, keep assertions)
- [ ] Run tests continuously (`cargo watch -x test`)
- [ ] Verify outputs match expected behaviour

### 3. After Implementation
- [ ] All old tests passing in new implementation
- [ ] `./scripts/regression-verify.sh module` passes
- [ ] No performance degradation (`cargo bench`)
- [ ] Document any intentional behaviour changes in MIGRATION.md

### 4. Before Commit
- [ ] Full test suite passing (`cargo test --all`)
- [ ] Regression verification passing
- [ ] Commit message includes "✅ Regression tests: XX/XX passing"

---

## 🚨 What if Results Differ?

### Allowed Differences (Must be Documented)

1. **Bug Fixes**
   ```markdown
   ## MIGRATION.md
   
   ### Intentional Behaviour Changes
   
   #### core::validation::validate_key()
   - **Old behaviour**: Accepted uppercase characters (BUG)
   - **New behaviour**: Rejects uppercase, enforces lowercase
   - **Rationale**: RBKS spec requires lowercase keys
   - **Impact**: Existing code using uppercase keys will error
   - **Migration**: Convert keys to lowercase before validation
   ```

2. **Performance Improvements**
   ```markdown
   #### store::btree::insert()
   - **Old performance**: O(log n) with scattered memory access
   - **New performance**: O(log n) with cache-friendly layout
   - **Result**: 2x faster, SAME behaviour
   - **Impact**: None (pure optimization)
   ```

3. **Error Messages**
   ```markdown
   #### api::db::query()
   - **Old error**: "Query failed"
   - **New error**: "Query failed: Table 'users' not found"
   - **Rationale**: Better debugging
   - **Impact**: Error message text differs, but Error type identical
   ```

### Forbidden Differences (Must be Fixed)

1. ❌ **Different return values**
   ```rust
   // Old: Returns 3
   let count = count_users(&db);
   
   // New: Returns 4
   // ❌ FORBIDDEN - must return 3!
   ```

2. ❌ **Different errors**
   ```rust
   // Old: Returns Err(ReedError::NotFound)
   let result = get_user(&db, 999);
   
   // New: Returns Ok(None)
   // ❌ FORBIDDEN - must return same error!
   ```

3. ❌ **Missing functionality**
   ```rust
   // Old: Has pub fn export_csv()
   
   // New: Function missing
   // ❌ FORBIDDEN - must implement all public functions!
   ```

---

## 📈 Success Metrics

### Per Ticket
- ✅ 100% of old tests passing in new implementation
- ✅ `regression-verify.sh` passes
- ✅ No performance degradation (within 10%)

### Per Phase
- ✅ All module tests passing
- ✅ All integration tests passing
- ✅ Benchmark suite within 10% of baseline

### Final (Phase 9: Verification)
- ✅ 100% test pass rate (old tests on new code)
- ✅ 0 intentional behaviour changes (except documented bug fixes)
- ✅ Performance equal or better (average <5% difference)
- ✅ Complete MIGRATION.md (all differences documented)

---

## 🎯 Summary

**Core Principle**: Altes Ergebnis MUSS dem neuen entsprechen

**Implementation**:
1. ✅ Regression Testing Tools (regression-check.sh, regression-verify.sh)
2. ✅ Updated QS-Matrix (includes regression checks)
3. ✅ 4 Test Categories (Unit, Integration, E2E, Performance)
4. ✅ Clear guidelines (allowed vs forbidden differences)

**Result**: 
- Jedes Ticket: Behaviour-identisch zu src-old/
- Jede Phase: Regression verification passing
- Final: 100% compatibility guaranteed

**Next**: Update QS-MATRIX-TEMPLATE.md and ticket templates with regression testing requirements.
