# AUDIT-211-01: Find All helpers/utils/common Files

## Status
- [x] Not Started
- [ ] In Progress
- [ ] Complete

## Priority
**HIGH** - Part of generic filename audit (Standard #7)

## Estimated Effort
15 minutes

## Parent Ticket
210-[AUDIT]-00: Find All Generic Filenames

## Context

Search for the most obviously generic filenames:
- `helpers.rs`, `*_helpers.rs`
- `utils.rs`, `*_utils.rs`
- `common.rs`, `*_common.rs`

**Known violation** (will be fixed in 200-[RENAME]-00):
- `tables/helpers.rs` → `table_operations.rs`

**This ticket**: Find if there are MORE we don't know about.

## Implementation

### Step 1: Search

```bash
cd reedbase/src

# Find exact matches
echo "=== Exact generic names ==="
find . -name "helpers.rs" \
  -o -name "utils.rs" \
  -o -name "common.rs" \
  -o -name "misc.rs" \
  -o -name "shared.rs"

# Find with prefixes
echo "=== Prefixed generic names ==="
find . -name "*_helpers.rs" \
  -o -name "*_utils.rs" \
  -o -name "*_common.rs" \
  -o -name "*_misc.rs"
```

### Step 2: Document Findings

For each file found:
```markdown
## File: src/module/helpers.rs (200 lines)

**What it actually does**:
- Function A: Does X
- Function B: Does Y
- Function C: Does Z

**Assessment**: 
- [ ] Multiple unrelated helpers → SPLIT
- [ ] All helpers for one thing → RENAME

**Better name**: 
- If single purpose: `[specific_operation].rs`
- If must split: Create multiple focused files

**Action**: Create rename ticket or split ticket
```

### Step 3: Create Action Tickets

For each finding:
- **If single purpose**: Add to 200-[RENAME]-00 or create new rename ticket
- **If multiple purposes**: Create split ticket (similar to 300-[SPLIT]-00)

## Verification

- [ ] All helpers/utils/common files documented
- [ ] Action plan created for each
- [ ] No generic files will remain after execution

## Expected Findings

Conservative: 2-5 files beyond the known `tables/helpers.rs`

## Output

Create: `_workbench/analysis/generic_files_found.md` with findings
