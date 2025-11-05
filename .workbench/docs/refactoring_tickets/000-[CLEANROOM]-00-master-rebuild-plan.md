# 000-[CLEANROOM]-00: Master Clean Room Rebuild Plan

**Category**: Architecture / Complete Rebuild  
**Effort**: 30-40 hours  
**Priority**: CRITICAL (Foundation for v0.2.0-beta)

---

## Overview

**Complete rebuild of ReedBase from ground up for v0.2.0-beta Open Source launch.**

**User Decision**: Option C - Reiner Fresh Start
> "100% neu schreiben, maximale Qualität"

**Strategy**: Clean Room Implementation
- `src/` → `src-old/` (backup, reference, tests)
- `src/` rebuilt from scratch with perfect architecture
- Each module: Design → Implement → Test → Verify
- QS-Matrix in EVERY ticket for continuous quality

---

## Why Clean Room Approach?

### ✅ Advantages

1. **Perfect Architecture from Day 1**
   - `src/core/` established immediately
   - Folder structure (api/, store/, validate/, process/, ops/) correct from start
   - No "migration chaos"

2. **Zero Legacy Cruft**
   - No forgotten duplicates
   - No dead code
   - No "legacy imports"

3. **100% Redundancy-Free Guaranteed**
   - Every function consciously evaluated
   - Duplicates actively prevented
   - Single source of truth enforced

4. **Integrated QS from Start**
   - Every ticket has QS-Matrix
   - All 8 CLAUDE.md standards checked continuously
   - No "technical debt" accumulated

5. **Perfect for Open Source Launch**
   - Clean git history (no "moved file" commits)
   - Exemplary code quality
   - Well-documented architecture

### Cost

**Time**: 30-40 hours (vs. 20-30h in-place refactoring)  
**Benefit**: Maximale Qualität, perfekte Basis für v0.2.0-beta

---

## Clean Room Workflow

### Phase 0: Preparation (1h)

**Ticket: 001-[PREP]-00**

```bash
# 1. Backup current implementation
mv src src-old
git add -A
git commit -m "[CLEAN-001] backup: preserve current implementation as src-old

All functionality preserved in src-old/ for:
- Reference during rebuild
- Test verification
- Rollback safety

This commit enables Clean Room rebuild for v0.2.0-beta."

# 2. Create new architecture structure
mkdir -p src/{core,api/{db,reedql},store/{btree,tables,indices},validate/{schema,rbks},process/{concurrent,locks},ops/{backup,versioning,metrics}}

# 3. Create root files
touch src/lib.rs src/error.rs

# 4. Create module scaffolds
touch src/core/mod.rs src/api/mod.rs src/store/mod.rs ...

git add src/
git commit -m "[CLEAN-001] feat: create clean architecture structure

Established folder hierarchy:
- src/core/       : Default functions (paths, validation)
- src/api/        : Public API (db, reedql)
- src/store/      : Storage layer (btree, tables, indices)
- src/validate/   : Validation (schema, RBKS)
- src/process/    : Processing (concurrent, locks)
- src/ops/        : Operations (backup, versioning, metrics)

Ready for module-by-module rebuild."
```

---

### Phase 1: Core Foundation (2-3h)

**Why core/ first?**
- All other modules depend on it
- Establishes default functions immediately
- Prevents duplication from the start

**Tickets: 010-[CORE]-XX**

#### 010-[CORE]-01: Core Module Structure (0.5h)
- Create `core/mod.rs`, `core/paths.rs`, `core/validation.rs`
- Define public API
- Copyright headers

#### 010-[CORE]-02: Path Utilities (1h)
- Analyse src-old/ for path operations
- Implement centralised path construction
- `db_dir()`, `table_path()`, `backup_dir()`, `wal_dir()`
- Tests in `core/paths_test.rs`

#### 010-[CORE]-03: Validation Utilities (1h)
- Analyse src-old/ for validation logic
- Implement centralised validators
- `validate_key()`, `validate_table_name()`
- Tests in `core/validation_test.rs`

#### 010-[CORE]-04: Error Types (0.5h)
- Create `src/error.rs`
- Define `ReedError` enum (all variants from src-old)
- `From<T>` trait implementations
- Tests in `src/error_test.rs`

**Deliverable**: Complete `src/core/` + `src/error.rs` with 100% test coverage

---

### Phase 2: Storage Layer (8-10h)

**Dependency**: Requires Phase 1 (core/)

**Tickets: 020-[STORE]-XX**

#### 020-[STORE]-01: B-Tree Core (3-4h)
- `store/btree/tree.rs` - B-Tree implementation
- `store/btree/node.rs` - Node structures
- `store/btree/types.rs` - Type definitions
- Reference: src-old/btree/
- **QS-Matrix applied**: Each file <400 lines, tests separate

#### 020-[STORE]-02: B-Tree Operations (2-3h)
- `store/btree/iter.rs` - Iteration
- `store/btree/page.rs` - Page management
- `store/btree/wal.rs` - Write-Ahead Log
- **Uses**: `core::paths` for WAL directory

#### 020-[STORE]-03: CSV Tables (2-3h)
- `store/tables/parser.rs` - CSV parsing (replaces scattered logic)
- `store/tables/table.rs` - Table structures
- `store/tables/writer.rs` - Atomic CSV writes
- **QS-Matrix**: No duplicates, uses core::paths

#### 020-[STORE]-04: Smart Indices (3-4h)
- `store/indices/btree_index.rs` - B-Tree based index
- `store/indices/hashmap_index.rs` - HashMap index
- `store/indices/hierarchy.rs` - Hierarchical keys
- `store/indices/namespace.rs` - Namespace support
- `store/indices/manager.rs` - Index management
- `store/indices/builder.rs` - Index builder
- Reference: src-old/indices/

**Deliverable**: Complete storage layer with Smart Indices

---

### Phase 3: Validation Layer (2-3h)

**Dependency**: Requires Phase 1-2

**Tickets: 030-[VALIDATE]-XX**

#### 030-[VALIDATE]-01: Schema System (1-1.5h)
- `validate/schema/loader.rs` - Schema loading
- `validate/schema/types.rs` - Schema types
- `validate/schema/validation.rs` - Schema validation

#### 030-[VALIDATE]-02: RBKS v2 (1-1.5h)
- `validate/rbks/parser.rs` - RBKS key parsing
- `validate/rbks/validator.rs` - RBKS validation with angle-bracket modifiers
- `validate/rbks/types.rs` - RBKS types
- Reference: src-old/schema/rbks.rs

**Deliverable**: Schema + RBKS v2 validation

---

### Phase 4: API Layer (8-10h)

**Dependency**: Requires Phase 1-3

**Tickets: 040-[API]-XX**

#### 040-[API]-01: Database Core (2-3h)
- `api/db/database.rs` - Database struct
- `api/db/types.rs` - Type definitions
- `api/db/stats.rs` - Statistics
- Reference: src-old/database/

#### 040-[API]-02: Query Operations (2-3h)
- `api/db/query.rs` - Query execution
- `api/db/index.rs` - Index operations
- Uses: `store::btree`, `store::indices`

#### 040-[API]-03: Data Operations (2-3h)
- `api/db/insert.rs` - INSERT operations
- `api/db/update.rs` - UPDATE operations
- `api/db/delete.rs` - DELETE operations
- **QS-Matrix**: Split from old 661-line execute.rs

#### 040-[API]-04: ReedQL Parser (2-3h)
- `api/reedql/parser.rs` - Query parsing
- `api/reedql/types.rs` - AST types
- **QS-Matrix**: Split from old 730-line parser.rs

#### 040-[API]-05: ReedQL Execution (2-3h)
- `api/reedql/executor.rs` - Query execution
- `api/reedql/planner.rs` - Query planning
- `api/reedql/analyzer.rs` - Query analysis
- **QS-Matrix**: Split from old 697-line executor.rs

**Deliverable**: Complete public API (db + reedql)

---

### Phase 5: Process Layer (2-3h)

**Dependency**: Requires Phase 1-4

**Tickets: 050-[PROCESS]-XX**

#### 050-[PROCESS]-01: Concurrency (1-1.5h)
- `process/concurrent/lock.rs` - Lock implementations
- `process/concurrent/queue.rs` - Queue structures
- `process/concurrent/types.rs`

#### 050-[PROCESS]-02: Conflict Resolution (1-1.5h)
- `process/conflict/resolution.rs` - Conflict resolution strategies
- `process/conflict/types.rs`

**Deliverable**: Concurrency + conflict handling

---

### Phase 6: Operations Layer (3-4h)

**Dependency**: Requires Phase 1-5

**Tickets: 060-[OPS]-XX**

#### 060-[OPS]-01: Backup System (1-1.5h)
- `ops/backup/create.rs` - Backup creation (XZ compression)
- `ops/backup/restore.rs` - Backup restoration
- `ops/backup/list.rs` - Backup listing
- `ops/backup/types.rs`
- **Uses**: `core::paths` for backup directory

#### 060-[OPS]-02: Versioning (1-1.5h)
- `ops/version/delta.rs` - Delta tracking
- `ops/version/rebuild.rs` - Crash recovery
- `ops/version/index.rs` - Version index

#### 060-[OPS]-03: Metrics (1h)
- `ops/metrics/collector.rs` - Metrics collection
- `ops/metrics/aggregator.rs` - Aggregation
- `ops/metrics/storage.rs` - Storage
- `ops/metrics/types.rs`

**Deliverable**: Complete operations layer

---

### Phase 7: Logging & Merge (2-3h)

**Tickets: 070-[LOG]-XX, 080-[MERGE]-XX**

#### 070-[LOG]-01: Log System (1-1.5h)
- `ops/log/encoder.rs` - Log encoding
- `ops/log/decoder.rs` - Log decoding
- `ops/log/validator.rs` - CRC32 validation

#### 080-[MERGE]-01: Merge Operations (1-1.5h)
- `ops/merge/csv.rs` - CSV merging
- `ops/merge/diff.rs` - Diff algorithm

**Deliverable**: Logging + merge functionality

---

### Phase 8: Binary & CLI (3-4h)

**Tickets: 090-[BIN]-XX**

#### 090-[BIN]-01: CLI Structure (1h)
- `bin/reedbase.rs` - Main entry point
- `bin/commands/mod.rs` - Command dispatcher

#### 090-[BIN]-02: Commands (2-3h)
- `bin/commands/query.rs` - Query command
- `bin/commands/insert.rs` - Insert command
- `bin/commands/backup.rs` - Backup command
- `bin/formatters/` - Output formatters

**Deliverable**: Complete CLI

---

### Phase 9: Verification & Documentation (3-4h)

**Tickets: 900-[VERIFY]-XX**

#### 900-[VERIFY]-01: Function Coverage (1h)
```bash
# Compare functions src vs src-old
rg "pub fn" src/ > src-functions.txt
rg "pub fn" src-old/ > src-old-functions.txt
diff src-functions.txt src-old-functions.txt

# Document intentionally not migrated
vim MIGRATION.md
```

#### 900-[VERIFY]-02: Test Coverage (1h)
```bash
# All tests passing?
cargo test --all

# Coverage report
cargo tarpaulin --out Html
# Target: 90%+ coverage
```

#### 900-[VERIFY]-03: CLAUDE.md Compliance (1h)
```bash
# Run all quality checks
for file in $(find src -name "*.rs" -type f); do
    ./scripts/quality-check.sh "$file"
done

# Expected: All files pass all 8 standards
```

#### 900-[VERIFY]-04: Documentation (1-2h)
- Update README.md with new architecture
- Create ARCHITECTURE.md explaining layers
- Document migration in MIGRATION.md
- Update CHANGELOG.md

**Deliverable**: 100% verified, documented, v0.2.0-beta ready

---

## ✅ Integrierte Qualitätssicherungs-Matrix

**EVERY ticket (010-090) MUST include this QS-Matrix.**

See: `QS-MATRIX-TEMPLATE.md` for complete checklist.

### Pre-Implementation
- [ ] Standard #0: Funktionssuche durchgeführt (keine Duplikate)
- [ ] Standard #3: Dateiname spezifisch (keine generischen Namen)
- [ ] Standard #8: Architektur-Layer korrekt (NO MVC)

### During Implementation  
- [ ] Standard #1: BBC English (comments, docstrings, errors)
- [ ] Standard #4: Single Responsibility (eine Funktion = ein Job)
- [ ] Standard #6: No Swiss Army (keine Multi-Purpose Functions)
- [ ] Standard #7: Spezifische Namen (Funktionen, Variablen, Structs)

### Post-Implementation
- [ ] Standard #2: Line count <400 (wc -l file.rs)
- [ ] Standard #5: Tests in separate _test.rs file
- [ ] Standard #0: Keine Duplikate erstellt (verify nochmal)

### Final Verification
```bash
# Run quality check before commit
./scripts/quality-check.sh src/module/file.rs

# All tests pass
cargo test --package reedbase --lib module::tests

# Commit with QS confirmation
git commit -m "[CLEAN-XXX] feat(module): implement feature

✅ QS-Matrix verified:
- Standard #0: No duplicates (searched existing functions)
- Standard #1: BBC English (all comments/docs)
- Standard #2: File size 287 lines (<400)
- Standard #3: Specific filename (feature.rs)
- Standard #4: Single responsibility (5 functions, <100 lines each)
- Standard #5: Tests in feature_test.rs
- Standard #6: No Swiss Army patterns
- Standard #7: Specific names throughout
- Standard #8: Layered architecture (no MVC)

All tests passing."
```

---

## Ticket Overview

### Summary by Phase

| Phase | Tickets | Effort | Deliverable |
|-------|---------|--------|-------------|
| 0. Preparation | 001 | 1h | src-old backup + structure |
| 1. Core | 010-[CORE]-01 to 04 | 2-3h | core/ + error.rs |
| 2. Storage | 020-[STORE]-01 to 04 | 8-10h | btree + tables + indices |
| 3. Validation | 030-[VALIDATE]-01 to 02 | 2-3h | schema + RBKS v2 |
| 4. API | 040-[API]-01 to 05 | 8-10h | db + reedql |
| 5. Process | 050-[PROCESS]-01 to 02 | 2-3h | concurrent + conflict |
| 6. Operations | 060-[OPS]-01 to 03 | 3-4h | backup + version + metrics |
| 7. Log+Merge | 070-080 | 2-3h | logging + merging |
| 8. Binary | 090-[BIN]-01 to 02 | 3-4h | CLI |
| 9. Verification | 900-[VERIFY]-01 to 04 | 3-4h | tests + docs |

**Total**: ~35-40 tickets, 30-40 hours

---

## Execution Order

**STRICT SEQUENCE** (dependencies enforced):

```
001 → 010 → 020 → 030 → 040 → 050 → 060 → 070/080 → 090 → 900
 ↓     ↓     ↓     ↓     ↓     ↓     ↓       ↓       ↓     ↓
Prep  Core  Store Valid API   Proc  Ops    Log/M   CLI  Verify
```

**Within each phase**: Tickets can be partially parallelised (e.g., 020-01 and 020-03 independent)

**After each phase**: Full test suite must pass before proceeding

---

## Success Criteria

### Phase-Level Success

After each phase (010, 020, ..., 090):
- ✅ All phase tickets completed
- ✅ All tests passing (`cargo test`)
- ✅ QS-Matrix verified for all files
- ✅ No compiler warnings
- ✅ Git committed with QS confirmation

### Final Success (900 complete)

- ✅ **Functionality**: 100% of src-old functionality in src/
- ✅ **Tests**: All tests passing, 90%+ coverage
- ✅ **CLAUDE.md**: All 8 standards 100% compliant
- ✅ **Architecture**: Clean layered structure, NO MVC
- ✅ **Redundancy**: Zero duplicate functions
- ✅ **Documentation**: ARCHITECTURE.md, MIGRATION.md, README.md
- ✅ **Ready**: v0.2.0-beta tag, Open Source launch

---

## Risk Mitigation

### Risk: Missing Functionality

**Mitigation**: Function checklist in 900-[VERIFY]-01
- Compare pub fn lists (src vs src-old)
- Intentionally omitted functions documented in MIGRATION.md

### Risk: Performance Regression

**Mitigation**: Benchmark suite
```bash
cargo bench --all
# Compare to src-old benchmarks
# Document any regressions with justification
```

### Risk: Breaking Changes

**Mitigation**: Integration tests
```bash
# Test against real-world usage
cargo run --example cms_integration
cargo run --example query_workload
```

### Risk: Time Overrun

**Mitigation**: MVP scope
- Phases 0-6: MUST DO (core functionality)
- Phases 7-8: SHOULD DO (full features)
- Phase 9: MUST DO (verification)

If time pressure: Can launch with minimal 7-8, full features in v0.2.1

---

## Benefits vs. Costs

### Costs

| Cost | Amount |
|------|--------|
| **Time** | 30-40h (vs. 20-30h in-place) |
| **Effort** | Manual transfer all code |
| **Risk** | Could miss functionality |

### Benefits

| Benefit | Value |
|---------|-------|
| **Quality** | 100% CLAUDE.md from Day 1 |
| **Architecture** | Perfect layered structure |
| **Redundancy** | Guaranteed zero duplicates |
| **Documentation** | Clean git history |
| **Open Source** | Exemplary codebase |
| **Maintenance** | Easier long-term |
| **Confidence** | No legacy cruft |

**ROI**: +10-15h upfront investment → Saves 50+ hours in future maintenance

---

## Next Steps

1. **Review this master plan** - Confirm approach with user
2. **Create Phase 0 ticket** - 001-[PREP]-00 (src backup + structure)
3. **Create Phase 1 tickets** - 010-[CORE]-01 to 04 (core module)
4. **Create QS-Matrix script** - `scripts/quality-check.sh`
5. **Begin execution** - Start with 001-[PREP]-00

---

**Status**: Master Plan Complete  
**Next Ticket**: 001-[PREP]-00 (Phase 0: Preparation)  
**Estimated Total Effort**: 30-40 hours  
**Target**: v0.2.0-beta Open Source Launch  
**Quality**: 100% CLAUDE.md compliant, zero redundancy, exemplary architecture
