# Claude Code Guidelines for ReedBase

**Project**: ReedBase v0.2.0-beta Clean Room Rebuild  
**Status**: Active Development (Clean Room Implementation)  
**Architecture**: Cargo Workspace with current/ (new) and last/ (reference)

---

## 🚀 Quick Start for New Sessions

### FIRST: Read Session Handover

**⚠️ CRITICAL - Read this FIRST in every new session**:
```bash
cat .workbench/docs/SESSION_HANDOVER.md
```

**What it contains**:
- Current project status (what phase are we in?)
- What's been completed since last session
- Next steps to execute
- Critical warnings and context
- Update history from previous sessions

**Time**: 2-3 minutes → fully oriented about project state

### When You Get a Ticket

**Step 1: Orientierung (30 seconds)**
```bash
# Read the ticket
cat .workbench/docs/refactoring_tickets/0XX-[MODULE]-YY-description.md

# Read workspace commands
cat .workbench/docs/refactoring_tickets/WORKSPACE-CHEATSHEET.md

# Read QS matrix
cat .workbench/docs/refactoring_tickets/QS-MATRIX-TEMPLATE.md
```

**Step 2: Understand Workspace Structure**
```
reedbase/
├── Cargo.toml              [workspace] root
├── current/                ← NEW implementation (your work here)
│   ├── Cargo.toml          [package] name = "reedbase"
│   └── src/
└── last/                   ← OLD implementation (reference, tests)
    ├── Cargo.toml          [package] name = "reedbase-last"
    └── src/
```

**Step 3: Use Correct Commands**
```bash
# ✅ ALWAYS specify package
cargo test -p reedbase              # Test current/
cargo test -p reedbase-last         # Test last/ (baseline)

# ✅ ALWAYS use workspace paths
./scripts/quality-check.sh current/src/module/file.rs
```

**Step 4: Execute Ticket**
- Follow Implementation Steps in ticket
- Check all 16 QS-Matrix items
- Run verification scripts
- Commit with proper format

---

## 📂 Project Structure

### Workspace Layout

**Root Level**:
- `Cargo.toml` - Workspace definition
- `CLAUDE.md` - This file (project guidelines)
- `README.md` - User documentation
- `LICENSE` - Apache 2.0
- `scripts/` - Quality check and regression scripts
- `.workbench/` - Planning documents, tickets, analysis

**Data Directories** (shared by both packages):
- `.reed/tables/` - ReedCMS test data (SHARED)
- `.reedbase/` - ReedBase test database (SHARED)
- `benches/` - Benchmarks (compare current/ vs last/)

**Package: current/** (New Implementation):
```
current/
├── Cargo.toml              [package] name = "reedbase"
├── src/
│   ├── lib.rs
│   ├── error.rs
│   ├── core/               # Default functions (paths, validation)
│   ├── api/                # Public API (db, reedql)
│   │   ├── db/
│   │   └── reedql/
│   ├── store/              # Storage layer (btree, tables, indices)
│   │   ├── btree/
│   │   ├── tables/
│   │   └── indices/
│   ├── validate/           # Validation (schema, RBKS)
│   │   ├── schema/
│   │   └── rbks/
│   ├── process/            # Processing (concurrent, locks)
│   │   ├── concurrent/
│   │   └── locks/
│   └── ops/                # Operations (backup, versioning, metrics)
│       ├── backup/
│       ├── versioning/
│       └── metrics/
├── tests/                  # Integration tests
└── benches/                # Performance benchmarks
```

**Package: last/** (Reference Implementation):
```
last/
├── Cargo.toml              [package] name = "reedbase-last"
├── src/                    # Original implementation (unchanged)
├── tests/                  # Original tests (baseline)
└── benches/                # Original benchmarks (baseline)
```

---

## 🚨 GOLDEN RULE: NO SHORTCUTS - COMPLETE PARITY MANDATORY

**⚠️ CRITICAL: This is the MOST IMPORTANT rule in this entire document**

### The Golden Rule

**`last/` is the specification. `current/` must be EXACTLY identical in behaviour.**

**Absolutely FORBIDDEN**:
- ❌ Simplifying error types ("we only need 10 variants, not 40")
- ❌ Omitting functions ("this looks unused, let's skip it")
- ❌ Reducing enum variants ("we can combine these cases")
- ❌ Skipping trait implementations ("not needed right now")
- ❌ Abbreviating implementations ("we'll add this later")
- ❌ "Modernising" or "improving" anything without explicit approval

**Why this rule exists**:
> "Es muss exakt das gleiche Ergebnis nach dem Refactoring dabei herauskommen. Wenn du jetzt irgendetwas weglässt, fehlt es später und niemand weiss mehr warum!"

**Translation**: The result must be EXACTLY the same after refactoring. If you omit anything now, it will be missing later and nobody will know why!

**The ONLY acceptable approach**:
1. ✅ Read complete implementation from `last/src/`
2. ✅ Copy ALL types, ALL variants, ALL functions, ALL traits
3. ✅ Preserve ALL behaviour, ALL error cases, ALL edge cases
4. ✅ Adapt tests to verify COMPLETE parity
5. ✅ Document any INTENTIONAL differences in MIGRATION.md

**When in doubt**:
- "Should I include this variant?" → **YES**
- "This function looks unused, skip it?" → **ASK USER** (mit Beweis dass wirklich unbenutzt)
- "Can I simplify this?" → **ASK USER** (mit konkretem Vorschlag)
- "Should I ask first?" → **YES**

**What IS allowed**:
- ✅ **Suggesting improvements** - "This could be solved better with X, shall I?"
- ✅ **Proposing removals** - "Function Y is provably unused (grep shows 0 calls), remove?"
- ✅ **Better solutions** - "Pattern Z is cleaner than current approach, switch?"
- ✅ **Refactoring proposals** - "Duplicated code could be unified, proceed?"

**The key difference**:
- ❌ **Silently omitting** - Just leaving things out → FORBIDDEN
- ✅ **Proposing with evidence** - Suggesting with proof → ENCOURAGED

**Examples of violations that MUST be prevented**:
- Copying ReedError enum with 10 variants when `last/` has 40 variants
- Implementing `Display` but skipping `std::error::Error` trait
- Creating "just the essentials" instead of complete API surface
- Omitting From<T> conversions "for now"

**Remember**: Clean Room Rebuild means **clean**, not **reduced**.

---

## 🎯 Critical Rules

### Rule #0: ALWAYS Use Workspace Commands

```bash
# ❌ WRONG - Runs both packages (confusing!)
cargo test
cargo build

# ✅ RIGHT - Specify package
cargo test -p reedbase
cargo build -p reedbase

# ✅ RIGHT - Test baseline
cargo test -p reedbase-last
```

### Rule #1: ALWAYS Use Workspace Paths

```bash
# ❌ WRONG - src/ doesn't exist at root
./scripts/quality-check.sh src/core/paths.rs

# ✅ RIGHT - Use current/ or last/
./scripts/quality-check.sh current/src/core/paths.rs
rg "pub fn" last/src/core/
```

### Rule #2: ALWAYS Check Regression

Every ticket MUST:
- ✅ Adapt tests from last/ to current/
- ✅ Verify behaviour identical to last/
- ✅ Run `./scripts/regression-verify.sh module`
- ✅ Document any intentional differences in MIGRATION.md

### Rule #3: ALWAYS Follow QS-Matrix

Every ticket has 16 mandatory checks:
- 8x CLAUDE.md Standards (#0-#7)
- 8x Regression Testing

See: `.workbench/docs/refactoring_tickets/QS-MATRIX-TEMPLATE.md`

---

## 📋 CLAUDE.md Standards (8 Total)

### Standard #0: Code Reuse
**NEVER duplicate existing functions**
- Check: `grep "function_name" _workbench/analysis/050-all-functions.txt`
- Use: Existing functions from current/ or last/
- If similar exists: Extend it, don't duplicate

### Standard #1: BBC English
**ALL comments and docs in British English**
- ✅ `initialise`, `optimise`, `analyse`, `behaviour`, `colour`
- ❌ `initialize`, `optimize`, `analyze`, `behavior`, `color`
- Exception: Code identifiers from ecosystem (e.g., `serialize` from serde)

### Standard #2: KISS - File Size <400 Lines
**Keep files simple and focused**
- Check: `wc -l current/src/module/file.rs`
- If >400 lines: Split into multiple files
- Each file = ONE clear responsibility

### Standard #3: File Naming
**Specific names, not generic**
- ✅ `path_construction.rs`, `key_validation.rs`
- ❌ `helpers.rs`, `utils.rs`, `common.rs`, `misc.rs`

### Standard #4: One Function = One Job
**Single responsibility per function**
- Functions <100 lines preferred
- Parameters <5 preferred
- No boolean flags (use separate functions or enums)

### Standard #5: Separate Test Files
**NEVER inline test modules**
- ✅ `file.rs` + `file_test.rs`
- ❌ `#[cfg(test)] mod tests` inside file.rs

### Standard #6: No Swiss Army Functions
**No multi-purpose functions**
- No `handle()`, `process()`, `manage()` doing many things
- No `do_thing(x, mode, flag1, flag2)` with complex branching
- Split into focused functions

### Standard #7: No Generic Names
**Specific, contextual names**
- ✅ `validate_table_name()`, `QueryExecutor`
- ❌ `validate()`, `Executor`, `process()`, `get()`

---

## 🏗️ Architecture Principles

### NO MVC!
ReedBase uses **Layered Architecture**, not MVC:

```
ops/        → Operations (backup, metrics, versioning)
process/    → Processing (concurrent, locks)
validate/   → Validation (schema, RBKS)
api/        → API (db, reedql)
store/      → Storage (btree, tables, indices)
core/       → Core utilities (paths, validation)
```

**Forbidden**:
- ❌ Controllers (`handle_request()` in lib)
- ❌ Models with behaviour (`impl Table { fn save() }`)
- ❌ Views (`Display`, `format!`, `println!` in lib)

**Allowed**:
- ✅ Pure functions (data in → data out)
- ✅ Trait-based polymorphism
- ✅ Builder patterns (no behaviour on data)

---

## 🔧 Essential Commands Reference

### Development Workflow

```bash
# 1. Quick compile check
cargo check -p reedbase

# 2. Run specific test
cargo test -p reedbase --lib module::tests::test_name

# 3. Quality check
./scripts/quality-check.sh current/src/module/file.rs

# 4. Regression check
./scripts/regression-verify.sh module

# 5. Baseline check (old tests still passing)
cargo test -p reedbase-last --lib module

# 6. Commit
git add current/src/module/
git commit -m "[CLEAN-0XX] feat(module): implement feature

✅ QS-Matrix: All 16 checks verified
✅ Regression: XX/XX tests passing
✅ Behaviour: Identical to last/

Workspace: current/ and last/ both passing"
```

### Watch Mode (Auto-Test)

```bash
# Install cargo-watch if needed
cargo install cargo-watch

# Watch and test current/ on changes
cargo watch -p reedbase -x "test --lib module"

# With clear screen
cargo watch -c -p reedbase -x test
```

---

## 📖 Essential Documentation

**Read FIRST in new session**:
1. **WORKSPACE-CHEATSHEET.md** - Cargo commands, common mistakes
2. **QS-MATRIX-TEMPLATE.md** - 16 checks per ticket
3. **REGRESSION-TESTING-PROTOCOL.md** - How to ensure old = new behaviour

**Planning Documents**:
- **000-[CLEANROOM]-00-master-rebuild-plan.md** - Complete rebuild strategy
- **EXECUTION-ORDER-CLEANROOM.md** - Phase-by-phase guide
- **EXECUTIVE-SUMMARY.md** - Project overview

**Scripts** (in `scripts/`):
- **quality-check.sh** - Validates all 8 CLAUDE.md standards
- **regression-verify.sh** - Compares current/ with last/

---

## 🎯 Ticket Execution Checklist

**Before Starting**:
- [ ] Read ticket file
- [ ] Read WORKSPACE-CHEATSHEET.md
- [ ] Understand workspace structure (current/ vs last/)
- [ ] Find corresponding code in last/src/

**During Implementation**:
- [ ] Work in current/src/
- [ ] Adapt tests from last/ to current/
- [ ] Use `cargo test -p reedbase` frequently
- [ ] Follow QS-Matrix Pre/During checks

**Before Commit**:
- [ ] All 16 QS-Matrix items checked
- [ ] `./scripts/quality-check.sh current/src/...` passes
- [ ] `./scripts/regression-verify.sh module` passes
- [ ] `cargo test -p reedbase` all green
- [ ] `cargo test -p reedbase-last` still green (baseline)
- [ ] `cargo clippy -p reedbase` no warnings

**Commit Format**:
```
[CLEAN-0XX] feat(module): short description

✅ QS-Matrix verified (all 8 CLAUDE.md standards)
✅ Regression tests: XX/XX passing
✅ Behaviour identical to last/
✅ Performance: Within X% of baseline

Workspace packages:
- reedbase (current): Implementation complete
- reedbase-last (last): Baseline tests still passing
```

---

## 📊 Data Directories (Shared)

### .reed/tables/ (ReedCMS Test Data)
**Purpose**: Test data from ReedCMS project  
**Used By**: Both current/ and last/ (shared)  
**DO NOT**: Modify during rebuild  
**Location**: `reedbase/.reed/tables/`

### .reedbase/ (Test Database)
**Purpose**: ReedBase test database  
**Used By**: Both current/ and last/ (shared)  
**DO NOT**: Modify during rebuild  
**Location**: `reedbase/.reedbase/`

### benches/ (Performance Benchmarks)
**Purpose**: Compare current/ vs last/ performance  
**Structure**:
```
benches/
├── comparison/             # Benchmarks running both versions
│   ├── btree_bench.rs      # Compare B-Tree performance
│   └── query_bench.rs      # Compare query performance
└── ... (other benchmarks)
```

**Usage**:
```bash
# Run benchmarks for current/
cargo bench -p reedbase --bench btree_bench

# Run comparison benchmarks (both versions)
cargo bench --bench comparison
```

**Important**: Benchmarks use SHARED data directories to ensure fair comparison.

---

## 🚨 Common Mistakes & Solutions

### Mistake 1: Testing Both Packages
```bash
# ❌ WRONG
cd reedbase/
cargo test
# → Tests both current/ and last/ (confusing output!)

# ✅ RIGHT
cargo test -p reedbase
```

### Mistake 2: Wrong Paths
```bash
# ❌ WRONG
./scripts/quality-check.sh src/core/paths.rs
# Error: src/ doesn't exist!

# ✅ RIGHT
./scripts/quality-check.sh current/src/core/paths.rs
```

### Mistake 3: Forgetting Regression Check
```bash
# ❌ INCOMPLETE
cargo test -p reedbase
git commit

# ✅ COMPLETE
cargo test -p reedbase
cargo test -p reedbase-last  # Baseline check!
./scripts/regression-verify.sh module
git commit
```

### Mistake 4: Modifying Shared Data
```bash
# ❌ WRONG
rm -rf .reedbase/
# → Breaks tests for BOTH packages!

# ✅ RIGHT
# Never modify .reedbase/ or .reed/tables/ during rebuild
```

---

## 💡 Tips for Efficient Development

### Tip 1: Use Shell Aliases
```bash
# Add to ~/.bashrc or ~/.zshrc
alias ct="cargo test -p reedbase"
alias cb="cargo build -p reedbase"
alias cc="cargo check -p reedbase"
alias ctl="cargo test -p reedbase-last"
```

### Tip 2: Quick Feedback Loop
```bash
# Edit file
vim current/src/core/paths.rs

# Quick check (no linking, fast)
cargo check -p reedbase

# Run specific test
cargo test -p reedbase --lib core::tests::test_db_dir

# Quality check
./scripts/quality-check.sh current/src/core/paths.rs
```

### Tip 3: Compare Implementations
```bash
# Side-by-side diff
diff -u last/src/core/paths.rs current/src/core/paths.rs

# Function count comparison
rg "^pub fn" last/src/core/ | wc -l
rg "^pub fn" current/src/core/ | wc -l
```

---

## 📚 Where to Find Things

| What | Where |
|------|-------|
| **Session handover** | `.workbench/docs/SESSION_HANDOVER.md` ⭐ READ FIRST |
| **Workspace commands** | `.workbench/docs/refactoring_tickets/WORKSPACE-CHEATSHEET.md` |
| **QS checklist** | `.workbench/docs/refactoring_tickets/QS-MATRIX-TEMPLATE.md` |
| **Regression protocol** | `.workbench/docs/refactoring_tickets/REGRESSION-TESTING-PROTOCOL.md` |
| **Master plan** | `.workbench/docs/refactoring_tickets/000-[CLEANROOM]-00-master-rebuild-plan.md` |
| **Execution order** | `.workbench/docs/refactoring_tickets/EXECUTION-ORDER-CLEANROOM.md` |
| **Tickets** | `.workbench/docs/refactoring_tickets/0XX-[MODULE]-YY-*.md` |
| **Scripts** | `scripts/quality-check.sh`, `scripts/regression-verify.sh` |
| **Old code** | `last/src/` (after 001 complete) |
| **New code** | `current/src/` (after 001 complete) |
| **Test data** | `.reed/tables/`, `.reedbase/` |
| **Benchmarks** | `benches/` |

---

## 🎯 Success Criteria

### Per Ticket
- ✅ All 16 QS-Matrix checks passed
- ✅ `quality-check.sh` passes
- ✅ `regression-verify.sh` passes
- ✅ All tests passing (current/ and last/)
- ✅ No clippy warnings

### Per Phase
- ✅ All phase tickets completed
- ✅ All module tests passing
- ✅ Regression verification passing

### v0.2.0-beta Launch
- ✅ 100% CLAUDE.md compliance
- ✅ 0 regressions (except documented bug fixes)
- ✅ Performance ≤ 110% of last/
- ✅ 90%+ test coverage
- ✅ Complete documentation

---

## 📞 Getting Help

**If stuck in new session**:
1. Read this CLAUDE.md file
2. Read WORKSPACE-CHEATSHEET.md
3. Read the specific ticket
4. Check Master Plan (000-[CLEANROOM]-00)
5. Look at last/src/ for reference

**Common questions**:
- "What package name?" → `reedbase` (current) or `reedbase-last` (last)
- "What path?" → Always prefix with `current/` or `last/`
- "Which tests?" → Both: `cargo test -p reedbase` AND `cargo test -p reedbase-last`
- "Where's the old code?" → `last/src/`
- "Where do I work?" → `current/src/`

---

**Project**: ReedBase v0.2.0-beta  
**License**: Apache 2.0  
**Author**: Vivian Voss <ask@vvoss.dev>  
**Repository**: https://github.com/vvoss-dev/reedbase
