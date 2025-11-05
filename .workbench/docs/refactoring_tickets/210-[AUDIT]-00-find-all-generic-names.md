# AUDIT-210-00: Find All Generic Filenames

## Status
- [x] Not Started
- [ ] In Progress
- [ ] Complete

## Priority
**HIGH** - Violates CLAUDE.md mandatory standard #7

## Estimated Effort
30 minutes

## Path References

**⚠️ NOTE**: Searches all Rust files regardless of folder structure.

## Context
CLAUDE.md requires:
> **7. Avoid**: Generic names like `handler.rs`, `middleware.rs`, `utils.rs`

**Known violations** (from 200-[RENAME]-00):
- `tables/helpers.rs` → Will be renamed to `table_operations.rs`
- `indices/builder_tests.rs` → Will be renamed to `builder_test.rs`

**This ticket**: Systematic search for ALL generic names we might have missed.

## Generic Names to Search For

| Pattern | Why Bad | Better Examples |
|---------|---------|----------------|
| `helpers.rs` | Too vague | `table_operations.rs`, `csv_parsing.rs` |
| `utils.rs` | Too generic | `string_utils.rs` → `text_formatting.rs` |
| `common.rs` | No meaning | `shared_types.rs`, `constants.rs` |
| `handler.rs` | What does it handle? | `request_handler.rs`, `event_processor.rs` |
| `middleware.rs` | What middleware? | `auth_middleware.rs`, `logging_interceptor.rs` |
| `types.rs` | Too broad | `query_types.rs`, `database_types.rs` |
| `mod.rs` with logic | Should only export | Extract logic to named files |

## Implementation Steps

### Step 1: Automated Search

```bash
cd src

# Find exact matches of forbidden names
echo "=== Exact matches of generic names ==="
find . -name "helpers.rs" -o -name "utils.rs" -o -name "common.rs" -o -name "handler.rs" -o -name "middleware.rs"

# Find files ending in generic suffixes
echo "=== Files with generic suffixes ==="
find . -name "*_helpers.rs" -o -name "*_utils.rs" -o -name "*_common.rs"

# Find overly broad 'types.rs' files
echo "=== Broad types.rs files (check if they should be more specific) ==="
find . -name "types.rs" -exec sh -c 'lines=$(wc -l < "{}"); if [ "$lines" -gt 200 ]; then echo "{} ($lines lines)"; fi' \;

# Find mod.rs files with actual code (should only have exports)
echo "=== mod.rs files with logic (>50 lines) ==="
find . -name "mod.rs" -exec sh -c 'lines=$(wc -l < "{}"); if [ "$lines" -gt 50 ]; then echo "{} ($lines lines)"; fi' \;

# Check for vague module names
echo "=== Vague top-level directories ==="
find . -maxdepth 1 -type d -name "common" -o -name "utils" -o -name "helpers" -o -name "misc"
```

### Step 2: Manual Review

For each finding, ask:
1. **What does this file actually do?**
2. **Can we name it more specifically?**
3. **Should it be split** (if it does multiple things)?

### Step 3: Categorize Findings

**Immediate renaming** (clear better name):
```markdown
- src/database/utils.rs → src/database/query_formatting.rs
- src/schema/helpers.rs → src/schema/validation_rules.rs
```

**Needs analysis** (unclear what it does):
```markdown
- src/common/types.rs (200 lines) → Review: What types? Split or rename?
```

**Acceptable** (generic but justified):
```markdown
- src/btree/types.rs (50 lines, all B-tree type definitions) → OK, scoped to module
- src/mod.rs (10 lines, only pub use statements) → OK, mod.rs is standard
```

### Step 4: Create Renaming Plan

```markdown
## Renaming Plan

### High Priority (vague names, >100 lines)
1. `common/utils.rs` (300 lines) → Split into:
   - `string_formatting.rs`
   - `file_operations.rs`
   - `date_helpers.rs`

### Medium Priority (vague but small)
2. `database/helpers.rs` (80 lines) → `connection_pool.rs`

### Low Priority (acceptable but could be better)
3. `schema/types.rs` (150 lines) → `validation_types.rs` (more specific)
```

### Step 5: Execute Renames

For each file:
```bash
# Example
cd src/database
git mv utils.rs query_formatting.rs

# Update mod.rs
vim mod.rs
# Change: pub mod utils;
# To: pub mod query_formatting;

# Update imports across codebase
rg "database::utils" ../.. --files-with-matches | xargs sed -i '' 's/database::utils/database::query_formatting/g'

# Test
cargo test --lib database::
```

### Step 6: Update Documentation

Check if README or docs mention old names:
```bash
grep -r "utils.rs\|helpers.rs\|common.rs" ../docs/ ../../README.md
```

## Verification

- [ ] No files named `helpers.rs`, `utils.rs`, `common.rs`
- [ ] No files named `handler.rs`, `middleware.rs` (unless highly specific context)
- [ ] All `types.rs` files are scoped to clear domain (e.g., `database/types.rs` OK)
- [ ] All `mod.rs` files <50 lines (mostly exports)
- [ ] All filenames clearly indicate their purpose
- [ ] `cargo check` passes
- [ ] `cargo test --lib` passes

## Expected Findings

Based on codebase size and typical patterns:

**Conservative estimate**:
- 2-4 `*_helpers.rs` files
- 1-2 `*_utils.rs` files
- 0-1 `common.rs` files
- 3-5 overly broad `types.rs` files (>200 lines)
- 2-3 `mod.rs` files with logic

**Total files to rename/refactor**: 8-15 files

## Files Affected

**Will be determined** after Step 1 search.

Likely candidates:
- Any module with `helpers`, `utils`, `common` in name
- Large `types.rs` files (should be more specific)
- `mod.rs` files with implementation code

## Notes

### When Generic Names Are OK

**Acceptable cases**:
```rust
// OK: types.rs scoped to specific module
src/database/types.rs  // Database-specific types only

// OK: mod.rs with only exports
src/btree/mod.rs       // Just "pub mod tree; pub use tree::BPlusTree;"

// OK: Generic but standard Rust conventions
lib.rs, main.rs        // Standard entry points
```

**Not acceptable**:
```rust
// BAD: Too broad
src/types.rs           // What types? Split by domain!

// BAD: mod.rs with logic
src/database/mod.rs    // 300 lines of implementation code

// BAD: Vague helpers
src/helpers.rs         // Helpers for what?
```

### Renaming Strategy

**If file does ONE clear thing**:
```
helpers.rs → [what_it_helps_with].rs
utils.rs → [what_utility].rs
common.rs → [what's_common].rs
```

**If file does MULTIPLE things**:
```
utils.rs (300 lines) → Split into:
  - string_formatting.rs
  - file_operations.rs
  - date_conversion.rs
```

## Related Tickets

- **200-[RENAME]-00**: Renames 2 known violations (helpers.rs, builder_tests.rs)
- **This ticket**: Systematic search for ALL violations
- **600-[VERIFY]-00**: Final verification includes filename check

**Workflow**: This ticket → feeds into → 200-[RENAME]-00 or new tickets
