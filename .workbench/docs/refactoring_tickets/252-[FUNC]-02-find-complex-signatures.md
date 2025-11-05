# FUNC-252-02: Find Functions with >5 Parameters

## Status
- [x] Not Started
- [ ] In Progress
- [ ] Complete

## Priority
**MEDIUM** - Part of function analysis (Standards #4 & #6)

## Estimated Effort
20 minutes

## Parent Ticket
250-[FUNC]-00: Analyze and Split Swiss Army Knife Functions

## Context

**Rule**: Functions with >5 parameters often do too much

**Better**: Use configuration structs or builder pattern

## Implementation

### Step 1: Find Complex Signatures

```bash
cd reedbase/src

# Find functions with many parameters
# (rough heuristic: signature line >100 chars often means many params)
rg "fn \w+\([^)]{100,}\)" --type rust --line-number | \
  tee /tmp/complex_signatures.txt

# Count
echo "Functions with complex signatures:"
wc -l < /tmp/complex_signatures.txt
```

### Step 2: Manual Count Parameters

For each finding:
```bash
# Example: Count parameters in specific function
rg "fn execute_query" src/database/execute.rs -A5 | \
  grep -o "," | wc -l
# Add 1 to comma count = parameter count
```

### Step 3: Categorize

```markdown
## Function: `create_index` in indices/builder.rs:234

**Signature**:
```rust
pub fn create_index(
    table: &str,
    columns: Vec<String>,
    index_type: IndexType,
    unique: bool,
    partial: Option<Predicate>,
    storage: StorageOptions,
    compression: CompressionLevel,
) -> Result<Index>
```

**Parameter count**: 7 (TOO MANY)

**Assessment**: ❌ NEEDS REFACTOR

**Recommendation**: Configuration struct

**Better design**:
```rust
pub struct IndexConfig {
    pub table: String,
    pub columns: Vec<String>,
    pub index_type: IndexType,
    pub unique: bool,
    pub partial: Option<Predicate>,
    pub storage: StorageOptions,
    pub compression: CompressionLevel,
}

pub fn create_index(config: IndexConfig) -> Result<Index>
```

**Effort**: 30 minutes

**Create ticket**: 25X-[FUNC]-XX-refactor-create-index.md
```

### Step 4: Prioritize

**High Priority** (refactor):
- Functions with >7 parameters
- Public API functions (user-facing)
- Functions called from many places

**Medium Priority**:
- Functions with 6 parameters
- Internal functions

**Acceptable**:
- Functions with 5 parameters that make sense
- Functions with primitive params (not struct-worthy)

### Step 5: Create Refactor Tickets

For each function needing refactoring:
- Create ticket: `25X-[FUNC]-XX-refactor-[function-name]-signature.md`

## Verification

- [ ] All complex signatures found
- [ ] Parameter counts verified
- [ ] Refactor recommendations made
- [ ] Tickets created for >6 parameters

## Expected Findings

Conservative: 3-7 functions with >5 parameters

## Output

Create: `_workbench/analysis/complex_signatures_analysis.md`
