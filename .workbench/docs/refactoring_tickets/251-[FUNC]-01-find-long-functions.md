# FUNC-251-01: Find All Functions >100 Lines

## Status
- [x] Not Started
- [ ] In Progress
- [ ] Complete

## Priority
**HIGH** - Part of function analysis (Standards #4 & #6)

## Estimated Effort
30 minutes

## Parent Ticket
250-[FUNC]-00: Analyze and Split Swiss Army Knife Functions

## Context

**Rule**: Functions should be <100 lines (except justified cases)

**Goal**: Find all functions >100 lines and assess if they need splitting.

## Implementation

### Step 1: Create Analysis Script

```bash
cat > /tmp/find_long_functions.sh << 'SCRIPT'
#!/bin/bash
# Find functions >100 lines in Rust code

for file in $(find src -name "*.rs" -type f); do
  # Extract function signatures and count lines until next function/EOF
  awk '
    /^[[:space:]]*(pub[[:space:]]+)?fn[[:space:]]/ {
      if (fn_name != "") {
        lines = NR - fn_start
        if (lines > 100) {
          printf "%s:%d:%s (%d lines)\n", FILENAME, fn_start, fn_name, lines
        }
      }
      fn_name = $0
      fn_start = NR
    }
    END {
      if (fn_name != "") {
        lines = NR - fn_start
        if (lines > 100) {
          printf "%s:%d:%s (%d lines)\n", FILENAME, fn_start, fn_name, lines
        }
      }
    }
  ' "$file"
done | sort -t: -k4 -rn
SCRIPT

chmod +x /tmp/find_long_functions.sh
```

### Step 2: Run Analysis

```bash
cd reedbase
/tmp/find_long_functions.sh > _workbench/analysis/long_functions.txt

# Show summary
echo "Functions >100 lines:"
wc -l < _workbench/analysis/long_functions.txt

# Show top 10 longest
head -10 _workbench/analysis/long_functions.txt
```

### Step 3: Categorize Each Function

For each function found, analyze:

```markdown
## Function: `execute_query` in database/execute.rs:145 (234 lines)

**What it does**:
- Parses query
- Validates schema
- Optimizes plan
- Executes
- Formats results

**Responsibilities count**: 5 (TOO MANY)

**Assessment**: ❌ MUST SPLIT

**Recommendation**:
- Extract parse_query_internal() - 40 lines
- Extract validate_schema_internal() - 30 lines
- Extract optimize_plan() - 50 lines
- Keep execute core logic - 50 lines
- Extract format_results() - 40 lines

**Effort**: 1 hour

**Priority**: HIGH (hot path)

**Create ticket**: 252-[FUNC]-02-split-execute-query.md
```

**vs**

```markdown
## Function: `parse_csv_row` in tables/csv.rs:89 (156 lines)

**What it does**:
- Parses one CSV row with all edge cases

**Responsibilities count**: 1 (parsing)

**Assessment**: ✅ ACCEPTABLE

**Reason**: 
- Single clear purpose
- Algorithmic complexity (state machine)
- Splitting would make it harder to understand

**Action**: KEEP (add comment explaining length)

**No ticket needed**
```

### Step 4: Prioritize Findings

**High Priority** (must split):
- Functions in hot paths (frequently called)
- Functions >150 lines
- Functions with >3 responsibilities

**Medium Priority**:
- Functions 100-150 lines
- Functions with 2-3 responsibilities
- Functions in critical modules

**Low/Acceptable**:
- Functions <120 lines with single clear purpose
- Algorithmic complexity (state machines, parsers)
- Can't split without making worse

### Step 5: Create Split Tickets

For each HIGH priority function:
- Create detailed ticket: `25X-[FUNC]-XX-split-[function-name].md`

## Verification

- [ ] All functions >100 lines documented
- [ ] Each categorized (MUST SPLIT / SHOULD SPLIT / ACCEPTABLE)
- [ ] Split tickets created for MUST SPLIT cases
- [ ] Total effort estimated

## Expected Findings

Based on 31,600 lines, ~1,000 functions:
- 10-20 functions >100 lines
- 5-10 need splitting
- 5-10 acceptable (algorithmic complexity)

## Output

Create: `_workbench/analysis/long_functions_analysis.md` with full details
