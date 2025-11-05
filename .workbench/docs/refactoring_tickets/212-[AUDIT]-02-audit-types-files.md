# AUDIT-212-02: Audit Large types.rs Files

## Status
- [x] Not Started
- [ ] In Progress
- [ ] Complete

## Priority
**MEDIUM** - Part of generic filename audit (Standard #7)

## Estimated Effort
15 minutes

## Parent Ticket
210-[AUDIT]-00: Find All Generic Filenames

## Context

`types.rs` is acceptable when scoped to a module:
- ✅ `database/types.rs` - Database-specific types
- ✅ `btree/types.rs` - B-tree types
- ❌ `types.rs` at root - Too broad!
- ❌ `database/types.rs` with 500 lines - Too many unrelated types

**Goal**: Find types.rs files that are too large/broad.

## Implementation

### Step 1: Find All types.rs Files

```bash
cd reedbase/src

# Find all types.rs
find . -name "types.rs" | while read file; do
  lines=$(wc -l < "$file")
  echo "$file|$lines"
done | sort -t'|' -k2 -rn > /tmp/types_files.txt

# Show large ones (>200 lines)
cat /tmp/types_files.txt | awk -F'|' '$2 > 200'
```

### Step 2: Analyze Large Files

For files >200 lines:
```bash
# Count type definitions
grep "^pub struct\|^pub enum\|^pub type" src/module/types.rs | wc -l

# List them
grep "^pub struct\|^pub enum\|^pub type" src/module/types.rs
```

### Step 3: Categorize

For each large `types.rs`:

**Questions**:
1. Are all types related to one domain?
2. Can they be grouped into sub-categories?
3. Should this be split?

**Examples**:

```markdown
## File: database/types.rs (350 lines, 25 types)

**Categories found**:
- Query types: 8 structs
- Schema types: 7 structs
- Index types: 6 structs
- Misc: 4 structs

**Recommendation**: Split into:
- `query_types.rs`
- `schema_types.rs`
- `index_types.rs`
- Keep small misc in `types.rs` (core types)

**Action**: Create split ticket
```

```markdown
## File: btree/types.rs (150 lines, 8 types)

**All related**: Yes, all B-tree specific

**Recommendation**: KEEP - scoped and focused

**Action**: None
```

### Step 4: Create Action Plan

For types.rs needing split:
- Create ticket: `2XX-[SPLIT]-XX-split-module-types.md`

## Verification

- [ ] All types.rs files reviewed
- [ ] Large files (>200 lines) assessed
- [ ] Split tickets created where needed
- [ ] Acceptable files documented (keep as-is)

## Expected Findings

Typical Rust project:
- 10-15 types.rs files total
- 2-4 over 200 lines
- 1-2 needing split

## Output

Create: `_workbench/analysis/types_files_audit.md` with findings
