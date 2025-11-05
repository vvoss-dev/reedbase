# Clean Room Execution Order

**Approach**: Option C - Reiner Fresh Start (100% Neubau)  
**Strategy**: src → src-old, kompletter Rebuild von Grund auf  
**Quality**: QS-Matrix in JEDEM Ticket für kontinuierliche Qualität

---

## 🎯 Execution Phases

### Phase 0: Preparation (1h)

```
001-[PREP]-00: Backup & Structure Setup
    ├─ mv src/ last/src/
    ├─ Create new folder structure (core/, api/, store/, ...)
    └─ Create module scaffolds (mod.rs files)
    
    Result: Clean slate, last/ as reference + test backup
```

**Critical**: src-old bleibt erhalten für:
- Referenz während Rebuild
- Test-Verifikation (Tests laufen weiter)
- Rollback Safety

---

### Phase 1: Core Foundation (2-3h)

**Why first?** Alle anderen Module brauchen core/

```
010-[CORE]-01: Module Structure (0.5h)
    └─ Create core/mod.rs, paths.rs, validation.rs

010-[CORE]-02: Path Utilities (1h)
    ├─ Analyse src-old for path operations
    ├─ Implement centralised path construction
    ├─ db_dir(), table_path(), backup_dir(), wal_dir()
    └─ Tests in core/paths_test.rs
    
    ✅ QS-Matrix: No duplicates, BBC English, <400 lines

010-[CORE]-03: Validation Utilities (1h)
    ├─ Analyse src-old for validation logic
    ├─ Implement centralised validators
    ├─ validate_key(), validate_table_name()
    └─ Tests in core/validation_test.rs
    
    ✅ QS-Matrix: Specific names, single responsibility

010-[CORE]-04: Error Types (0.5h)
    ├─ Create src/error.rs
    ├─ Define ReedError enum (all variants)
    ├─ From<T> trait implementations
    └─ Tests in error_test.rs
    
    ✅ QS-Matrix: Complete

Result: Complete src/core/ + src/error.rs
Verify: cargo test --lib core error
```

---

### Phase 2: Storage Layer (8-10h)

**Dependency**: Requires Phase 1 complete

```
020-[STORE]-01: B-Tree Core (3-4h)
    ├─ store/btree/tree.rs - B-Tree implementation
    ├─ store/btree/node.rs - Node structures  
    ├─ store/btree/types.rs - Type definitions
    └─ Reference: last/src/btree/
    
    ✅ QS-Matrix: Each file <400 lines, tests separate
    ✅ Uses core::paths for data directories

020-[STORE]-02: B-Tree Operations (2-3h)
    ├─ store/btree/iter.rs - Iteration
    ├─ store/btree/page.rs - Page management (<669 lines, split if needed)
    ├─ store/btree/wal.rs - Write-Ahead Log
    └─ Uses core::paths for WAL directory
    
    ✅ QS-Matrix: No Swiss Army functions

020-[STORE]-03: CSV Tables (2-3h)
    ├─ store/tables/parser.rs - CSV parsing (replaces ALL scattered logic)
    ├─ store/tables/table.rs - Table structures
    ├─ store/tables/writer.rs - Atomic CSV writes
    └─ NO helpers.rs (generic name forbidden)
    
    ✅ QS-Matrix: Standard #0 (eliminates duplicates)
    ✅ Uses core::paths for .reedbase/ paths

020-[STORE]-04: Smart Indices (3-4h)
    ├─ store/indices/btree_index.rs - B-Tree index
    ├─ store/indices/hashmap_index.rs - HashMap index
    ├─ store/indices/hierarchy.rs - Hierarchical keys
    ├─ store/indices/namespace.rs - Namespace support
    ├─ store/indices/manager.rs - Index management
    ├─ store/indices/builder.rs - Index builder (<200 lines)
    └─ Reference: last/src/indices/
    
    ✅ QS-Matrix: Specific names (no "utils", "helpers")

Result: Complete storage layer
Verify: cargo test --lib store
```

---

### Phase 3: Validation Layer (2-3h)

**Dependency**: Requires Phase 1-2

```
030-[VALIDATE]-01: Schema System (1-1.5h)
    ├─ validate/schema/loader.rs - Schema loading
    ├─ validate/schema/types.rs - Schema types
    ├─ validate/schema/validation.rs - Schema validation
    └─ Uses core::validation for key checks
    
    ✅ QS-Matrix: Layered architecture (not MVC)

030-[VALIDATE]-02: RBKS v2 (1-1.5h)
    ├─ validate/rbks/parser.rs - RBKS key parsing
    ├─ validate/rbks/validator.rs - Validation with angle-bracket modifiers
    ├─ validate/rbks/types.rs - RBKS types
    └─ Reference: last/src/schema/rbks.rs
    
    ✅ QS-Matrix: Single responsibility per function

Result: Schema + RBKS v2 validation
Verify: cargo test --lib validate
```

---

### Phase 4: API Layer (8-10h)

**Dependency**: Requires Phase 1-3

```
040-[API]-01: Database Core (2-3h)
    ├─ api/db/database.rs - Database struct
    ├─ api/db/types.rs - Type definitions
    ├─ api/db/stats.rs - Statistics
    └─ Reference: last/src/database/
    
    ✅ QS-Matrix: NO MVC (no handle_request patterns)

040-[API]-02: Query Operations (2-3h)
    ├─ api/db/query.rs - Query execution
    ├─ api/db/index.rs - Index operations
    └─ Uses store::btree, store::indices
    
    ✅ QS-Matrix: Pure functions (data in → data out)

040-[API]-03: Data Operations (2-3h)
    ├─ api/db/insert.rs - INSERT operations
    ├─ api/db/update.rs - UPDATE operations
    ├─ api/db/delete.rs - DELETE operations
    └─ Split from last/src/database/execute.rs (was 661 lines)
    
    ✅ QS-Matrix: Each file <400 lines (was 661!)

040-[API]-04: ReedQL Parser (2-3h)
    ├─ api/reedql/parser.rs - Main parser (<400 lines)
    ├─ api/reedql/lexer.rs - Tokenisation (split from old parser)
    ├─ api/reedql/ast.rs - AST construction (split from old parser)
    ├─ api/reedql/types.rs - Type definitions
    └─ Split from last/src/reedql/parser.rs (was 730 lines!)
    
    ✅ QS-Matrix: Standard #2 (KISS, split large files)

040-[API]-05: ReedQL Execution (2-3h)
    ├─ api/reedql/executor.rs - Query execution (<400 lines)
    ├─ api/reedql/planner.rs - Query planning
    ├─ api/reedql/analyzer.rs - Query analysis
    └─ Split from last/src/reedql/executor.rs (was 697 lines)
    
    ✅ QS-Matrix: Single responsibility per file

Result: Complete public API
Verify: cargo test --lib api
```

---

### Phase 5: Process Layer (2-3h)

**Dependency**: Requires Phase 1-4

```
050-[PROCESS]-01: Concurrency (1-1.5h)
    ├─ process/concurrent/lock.rs - Lock implementations
    ├─ process/concurrent/queue.rs - Queue structures
    ├─ process/concurrent/types.rs
    └─ Reference: last/src/concurrent/
    
    ✅ QS-Matrix: Tests in lock_test.rs, queue_test.rs

050-[PROCESS]-02: Conflict Resolution (1-1.5h)
    ├─ process/conflict/resolution.rs - Resolution strategies
    ├─ process/conflict/types.rs
    └─ Reference: last/src/conflict/
    
    ✅ QS-Matrix: Specific function names

Result: Concurrency + conflict handling
Verify: cargo test --lib process
```

---

### Phase 6: Operations Layer (3-4h)

**Dependency**: Requires Phase 1-5

```
060-[OPS]-01: Backup System (1-1.5h)
    ├─ ops/backup/create.rs - Backup creation (XZ compression)
    ├─ ops/backup/restore.rs - Backup restoration
    ├─ ops/backup/list.rs - Backup listing
    ├─ ops/backup/types.rs
    └─ Uses core::paths for backup directory
    
    ✅ QS-Matrix: No duplicates (single backup implementation)

060-[OPS]-02: Versioning (1-1.5h)
    ├─ ops/version/delta.rs - Delta tracking
    ├─ ops/version/rebuild.rs - Crash recovery (CRC32)
    ├─ ops/version/index.rs - Version index
    └─ Reference: last/src/version/
    
    ✅ QS-Matrix: Tests in delta_test.rs, rebuild_test.rs

060-[OPS]-03: Metrics (1h)
    ├─ ops/metrics/collector.rs - Metrics collection
    ├─ ops/metrics/aggregator.rs - Aggregation
    ├─ ops/metrics/storage.rs - Storage
    ├─ ops/metrics/types.rs
    └─ Reference: last/src/metrics/
    
    ✅ QS-Matrix: Specific names (not "manager", "handler")

Result: Complete operations layer
Verify: cargo test --lib ops
```

---

### Phase 7: Logging & Merge (2-3h)

**Dependency**: Requires Phase 1-6

```
070-[LOG]-01: Log System (1-1.5h)
    ├─ ops/log/encoder.rs - Log encoding
    ├─ ops/log/decoder.rs - Log decoding
    ├─ ops/log/validator.rs - CRC32 validation
    ├─ ops/log/types.rs
    └─ Reference: last/src/log/
    
    ✅ QS-Matrix: Tests in encoder_test.rs, decoder_test.rs

080-[MERGE]-01: Merge Operations (1-1.5h)
    ├─ ops/merge/csv.rs - CSV merging
    ├─ ops/merge/diff.rs - Diff algorithm
    ├─ ops/merge/types.rs
    └─ Reference: last/src/merge/
    
    ✅ QS-Matrix: Uses store::tables::parser (no duplicate CSV logic)

Result: Logging + merge functionality
Verify: cargo test --lib ops::log ops::merge
```

---

### Phase 8: Binary & CLI (3-4h)

**Dependency**: Requires Phase 1-7

```
090-[BIN]-01: CLI Structure (1h)
    ├─ bin/reedbase.rs - Main entry point
    ├─ bin/commands/mod.rs - Command dispatcher
    └─ Reference: last/src/bin/reedbase.rs
    
    ✅ QS-Matrix: Only layer with formatting/Display allowed

090-[BIN]-02: Commands (2-3h)
    ├─ bin/commands/query.rs - Query command
    ├─ bin/commands/insert.rs - Insert command
    ├─ bin/commands/update.rs - Update command
    ├─ bin/commands/delete.rs - Delete command
    ├─ bin/commands/backup.rs - Backup command
    ├─ bin/commands/restore.rs - Restore command
    └─ bin/formatters/ - Output formatters
    
    ✅ QS-Matrix: Each command <400 lines
    
090-[BIN]-03: Formatters (1h)
    ├─ bin/formatters/table.rs - Table formatting
    ├─ bin/formatters/json.rs - JSON output
    ├─ bin/formatters/csv.rs - CSV output
    └─ Split from last/src/bin/formatters/mod.rs
    
    ✅ QS-Matrix: Specific names (not "helpers")

Result: Complete CLI
Verify: cargo test --bin reedbase
        cargo build --release
        ./target/release/reedbase --help
```

---

### Phase 9: Verification & Documentation (3-4h)

**CRITICAL**: Ensures nothing missing, 100% quality

```
900-[VERIFY]-01: Function Coverage (1h)
    ├─ Compare pub fn lists (src vs src-old)
    ├─ Document intentionally not migrated
    └─ Create MIGRATION.md
    
    bash
    rg "pub fn" src/ > src-functions.txt
    rg "pub fn" last/src/ > src-old-functions.txt
    diff src-functions.txt src-old-functions.txt > migration-diff.txt
    

900-[VERIFY]-02: Test Coverage (1h)
    ├─ All tests passing?
    ├─ Coverage report (target: 90%+)
    └─ Benchmark comparison
    
    bash
    cargo test --all
    cargo tarpaulin --out Html
    cargo bench --all
    

900-[VERIFY]-03: CLAUDE.md Compliance (1h)
    ├─ Run quality-check.sh on ALL files
    ├─ Verify all 8 standards 100% compliant
    └─ Document any exceptions
    
    bash
    for file in $(find src -name "*.rs" -type f); do
        ./scripts/quality-check.sh "$file" || echo "FAIL: $file"
    done
    

900-[VERIFY]-04: Documentation (1-2h)
    ├─ Update README.md with new architecture
    ├─ Create ARCHITECTURE.md (layered structure)
    ├─ Update CHANGELOG.md for v0.2.0-beta
    ├─ Document migration in MIGRATION.md
    └─ Update CONTRIBUTING.md if needed

Result: 100% verified, documented, v0.2.0-beta ready
```

---

## 🔄 After Each Phase: Verification Checklist

**MUST complete before next phase**:

```bash
# 1. All phase tickets completed
✅ Check: All 01X-[PHASE]-XX tickets done

# 2. All tests passing
cargo test --lib module
✅ Expected: All tests green

# 3. QS-Matrix verified for all new files
for file in $(git diff --name-only main | grep "\.rs$"); do
    ./scripts/quality-check.sh "$file"
done
✅ Expected: All checks pass or warnings documented

# 4. No compiler warnings
cargo clippy -- -D warnings
✅ Expected: No warnings

# 5. Commit with QS confirmation
git commit -m "[CLEAN-0XX] feat(phase): complete Phase X

✅ All tickets: 0X1, 0X2, ... completed
✅ All tests passing (cargo test --lib module)
✅ QS-Matrix verified for all files
✅ No compiler warnings

Phase X deliverable complete."
```

---

## 📊 Progress Tracking

### Overall Progress

| Phase | Tickets | Effort | Status | Commit |
|-------|---------|--------|--------|--------|
| 0. Prep | 001 | 1h | ⬜ TODO | - |
| 1. Core | 010-01 to 04 | 2-3h | ⬜ TODO | - |
| 2. Storage | 020-01 to 04 | 8-10h | ⬜ TODO | - |
| 3. Validation | 030-01 to 02 | 2-3h | ⬜ TODO | - |
| 4. API | 040-01 to 05 | 8-10h | ⬜ TODO | - |
| 5. Process | 050-01 to 02 | 2-3h | ⬜ TODO | - |
| 6. Operations | 060-01 to 03 | 3-4h | ⬜ TODO | - |
| 7. Log+Merge | 070-080 | 2-3h | ⬜ TODO | - |
| 8. Binary | 090-01 to 03 | 3-4h | ⬜ TODO | - |
| 9. Verification | 900-01 to 04 | 3-4h | ⬜ TODO | - |

**Total**: ~35-40 hours

### Current Phase Tracking

```bash
# Create tracking file
cat > .workbench/progress.txt << 'EOF'
Phase 0: ⬜ TODO
Phase 1: ⬜ TODO  
Phase 2: ⬜ TODO
Phase 3: ⬜ TODO
Phase 4: ⬜ TODO
Phase 5: ⬜ TODO
Phase 6: ⬜ TODO
Phase 7: ⬜ TODO
Phase 8: ⬜ TODO
Phase 9: ⬜ TODO

Legend:
⬜ TODO
🔄 IN PROGRESS
✅ DONE
EOF

# Update after each phase
sed -i 's/Phase 1: ⬜ TODO/Phase 1: ✅ DONE/' .workbench/progress.txt
```

---

## 🎯 Success Criteria

### Phase-Level Success

After EVERY phase:
- ✅ All phase tickets completed
- ✅ All tests passing (`cargo test --lib module`)
- ✅ QS-Matrix verified (all files pass quality-check.sh)
- ✅ No compiler warnings (`cargo clippy`)
- ✅ Git committed with QS confirmation

### Final Success (Phase 9 complete)

- ✅ **Functionality**: 100% of src-old in src/ (verified in 900-01)
- ✅ **Tests**: All passing, 90%+ coverage (verified in 900-02)
- ✅ **CLAUDE.md**: All 8 standards 100% compliant (verified in 900-03)
- ✅ **Architecture**: Clean layered structure, NO MVC
- ✅ **Redundancy**: Zero duplicate functions (enforced via QS-Matrix)
- ✅ **Documentation**: Complete (ARCHITECTURE.md, MIGRATION.md, etc.)
- ✅ **Ready**: v0.2.0-beta tag, Open Source launch

---

## 🚀 Getting Started

### Step 1: Read Master Plan

```bash
cat .workbench/docs/refactoring_tickets/000-[CLEANROOM]-00-master-rebuild-plan.md
cat .workbench/docs/refactoring_tickets/QS-MATRIX-TEMPLATE.md
```

### Step 2: Setup Quality Check

```bash
# Make script executable (should already be done)
chmod +x scripts/quality-check.sh

# Test it
./scripts/quality-check.sh last/src/error.rs
```

### Step 3: Start Phase 0

```bash
# Execute 001-[PREP]-00
mv src/ last/src/
mkdir -p src/{core,api,store,validate,process,ops}/{...}
# ... (see Phase 0 details above)

git commit -m "[CLEAN-001] backup: preserve current implementation as src-old"
```

### Step 4: Continue Phase by Phase

Follow execution order strictly:  
001 → 010 → 020 → 030 → 040 → 050 → 060 → 070/080 → 090 → 900

---

**Strategy**: Clean Room = Maximale Qualität  
**QS-Matrix**: In JEDEM Ticket = Kontinuierliche Qualität  
**Result**: 100% CLAUDE.md compliant, zero redundancy, exemplary codebase
