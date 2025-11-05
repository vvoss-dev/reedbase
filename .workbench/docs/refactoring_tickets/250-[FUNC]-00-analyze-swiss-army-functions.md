# FUNC-250-00: Analyze and Split Swiss Army Knife Functions

## Status
- [x] Not Started
- [ ] In Progress
- [ ] Complete

## Priority
**MEDIUM** - Violates CLAUDE.md standards #4 and #6

## Estimated Effort
2-3 hours (depends on findings)

## Path References

**⚠️ NOTE**: Analyzes all Rust files regardless of folder structure.

## Context
CLAUDE.md requires:
> **4. Functions**: One function = one distinctive job
> **6. Avoid**: Swiss Army knife functions

**What is a "Swiss Army knife function"?**
- Does multiple unrelated things
- Has multiple responsibilities
- Hard to name clearly
- >100 lines (usually)
- Many parameters (>5 typically)
- Complex control flow (multiple nested ifs/matches)

## Current State

**Unknown** - Need systematic analysis.

## Detection Strategy

### Automated Checks

```bash
# 1. Find very long functions (>100 lines)
cd src
for file in $(find . -name "*.rs"); do
  # Extract function lengths
  grep -n "^pub fn\|^fn" "$file" | while read line; do
    # Complex awk to count lines between functions
    echo "$file: $line"
  done
done

# 2. Find functions with many parameters (>5)
rg "fn \w+\([^)]{100,}\)" src/ --no-heading

# 3. Find functions with deep nesting (>4 levels)
# This is harder - manual inspection needed

# 4. Find functions with vague names
rg "fn (handle|process|manage|do|execute|run|perform)\w*\(" src/ --no-heading
```

### Manual Analysis Required

For each function found:
1. **Read the function** - What does it do?
2. **Count responsibilities** - How many distinct jobs?
3. **Check naming** - Can you name it clearly in <4 words?
4. **Assess splitability** - Natural boundaries for extraction?

## Common Patterns to Look For

### Pattern 1: "Do Everything" Functions

```rust
// ❌ BAD: Does too much
pub fn execute_query(query: &str, db: &Database, options: Options) -> Result<Response> {
    // Parse query (responsibility 1)
    let parsed = parse_sql(query)?;
    
    // Validate permissions (responsibility 2)
    check_permissions(&parsed)?;
    
    // Optimize query plan (responsibility 3)
    let plan = optimize(&parsed)?;
    
    // Execute (responsibility 4)
    let results = run_query(&plan, db)?;
    
    // Format output (responsibility 5)
    format_results(results, options)
}

// ✅ GOOD: Split into focused functions
pub fn execute_query(query: &str, db: &Database) -> Result<QueryResults> {
    let parsed = parse_query(query)?;
    validate_query(&parsed)?;
    let plan = create_query_plan(&parsed)?;
    run_query_plan(&plan, db)
}
```

### Pattern 2: Multiple Unrelated Operations

```rust
// ❌ BAD: Unrelated operations in one function
pub fn handle_request(req: Request) -> Result<Response> {
    match req.action {
        Action::Insert => { /* 30 lines */ },
        Action::Update => { /* 30 lines */ },
        Action::Delete => { /* 30 lines */ },
        Action::Query => { /* 30 lines */ },
    }
}

// ✅ GOOD: Separate handler per action
pub fn handle_request(req: Request) -> Result<Response> {
    match req.action {
        Action::Insert => handle_insert(req),
        Action::Update => handle_update(req),
        Action::Delete => handle_delete(req),
        Action::Query => handle_query(req),
    }
}
```

### Pattern 3: God Functions with Many Parameters

```rust
// ❌ BAD: Too many parameters, does too much
pub fn process_data(
    input: Vec<u8>,
    validate: bool,
    transform: Option<Transform>,
    output_format: Format,
    compression: CompressionLevel,
    encryption: Option<Cipher>,
    callback: Box<dyn Fn(Progress)>,
) -> Result<Vec<u8>> {
    // 200 lines of complexity
}

// ✅ GOOD: Configuration struct + focused functions
pub fn process_data(input: Vec<u8>, config: ProcessConfig) -> Result<Vec<u8>> {
    let validated = validate_input(&input, &config)?;
    let transformed = apply_transform(&validated, &config)?;
    let formatted = format_output(&transformed, &config)?;
    compress_and_encrypt(formatted, &config)
}
```

## Implementation Steps

### Step 1: Find Candidate Functions

```bash
# Create analysis workspace
mkdir -p _workbench/analysis

# Find long functions
cd src
echo "# Functions >100 lines" > ../_workbench/analysis/long_functions.txt
# Use manual inspection or custom script

# Find functions with many parameters
echo "# Functions with >5 parameters" > ../_workbench/analysis/complex_signatures.txt
rg "fn \w+\([^)]{100,}\)" . >> ../_workbench/analysis/complex_signatures.txt

# Find vaguely named functions
echo "# Vaguely named functions" > ../_workbench/analysis/vague_names.txt
rg "fn (handle|process|manage|do|execute|run|perform)" . >> ../_workbench/analysis/vague_names.txt
```

### Step 2: Manual Review

For each candidate:
```markdown
## Function: `execute_query` in database/execute.rs:123

**Lines**: 156
**Parameters**: 4
**Responsibilities**:
1. Parse input
2. Validate permissions
3. Execute query
4. Format results

**Assessment**: SPLIT NEEDED
**Recommendation**: Extract parse, validate, format to separate functions

**Effort**: 30 minutes
**Priority**: HIGH (most called function)
```

### Step 3: Prioritize Findings

**High Priority** (fix first):
- Functions in hot paths (frequently called)
- Functions >150 lines
- Functions with >3 distinct responsibilities

**Medium Priority**:
- Functions 100-150 lines
- Functions with 2-3 responsibilities
- Functions in critical modules

**Low Priority** (nice to have):
- Functions 80-100 lines
- Clear purpose but could be cleaner
- Low-traffic code paths

### Step 4: Create Sub-Tickets

For each HIGH priority function:
```bash
# Example
cat > 251-[FUNC]-01-split-execute-query.md << 'TICKET'
# FUNC-251-01: Split execute_query into focused functions
...
TICKET
```

### Step 5: Execute Splits

Per sub-ticket:
1. Read function completely
2. Identify natural boundaries
3. Extract helper functions
4. Refactor main function to orchestrate
5. Test thoroughly
6. Commit

## Verification

- [ ] All functions <100 lines (except unavoidable cases)
- [ ] All functions have single clear purpose
- [ ] Function names clearly describe what they do
- [ ] No functions with >5 parameters (use config structs)
- [ ] No "handle/process/manage" generic names
- [ ] All tests still pass
- [ ] Code is more maintainable

## Expected Findings

Based on codebase size (31,600 lines, 126 files):

**Conservative estimate**:
- 10-15 functions >100 lines
- 5-10 "Swiss Army knife" functions
- 3-5 functions with >5 parameters

**Effort per function**:
- Analysis: 10 minutes
- Split implementation: 20-40 minutes
- Testing: 10 minutes

**Total**: 2-3 hours for all splits

## Files Likely Affected

High probability candidates:
- `database/execute.rs` (661 lines) - likely has complex execute functions
- `reedql/executor.rs` (697 lines) - SQL execution orchestration
- `reedql/parser.rs` (730 lines) - parsing orchestration
- `btree/tree.rs` (782 lines) - tree operation orchestration
- Any file with "handler" or "process" in function names

## Notes

### When NOT to Split

**Keep together if**:
- The function is a state machine (natural complexity)
- Splitting would add more complexity than it removes
- The function is algorithmically complex but does ONE thing (e.g., sorting algorithm)
- It's a generated function (protobuf, etc.)

**Example: Keep together**
```rust
// This is long but does ONE thing: parse CSV row
// Splitting would make it harder to understand
pub fn parse_csv_row(line: &str) -> Result<Row> {
    // 150 lines of parsing logic with error handling
    // All focused on ONE job: parsing
}
```

### Refactoring Pattern

**Before**:
```rust
pub fn big_function(input: Data) -> Result<Output> {
    // 150 lines doing A, B, C, D
}
```

**After**:
```rust
pub fn big_function(input: Data) -> Result<Output> {
    let a = do_step_a(input)?;
    let b = do_step_b(a)?;
    let c = do_step_c(b)?;
    do_step_d(c)
}

fn do_step_a(input: Data) -> Result<DataA> { /* focused */ }
fn do_step_b(a: DataA) -> Result<DataB> { /* focused */ }
fn do_step_c(b: DataB) -> Result<DataC> { /* focused */ }
fn do_step_d(c: DataC) -> Result<Output> { /* focused */ }
```

## Related Tickets

- **300-[SPLIT]-00**: Splits large FILES (this splits large FUNCTIONS)
- **600-[VERIFY]-00**: Final verification checks function lengths

**Difference**: This ticket is function-level, 300 is file-level.
