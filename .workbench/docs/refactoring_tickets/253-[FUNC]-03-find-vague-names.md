# FUNC-253-03: Find Vaguely Named Functions

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

**Rule**: Function names should clearly describe what they do

**Vague names** (red flags):
- `handle_*` - Handle what?
- `process_*` - Process how?
- `manage_*` - Manage in what way?
- `do_*` - Do what exactly?
- `execute_*` - Execute what?
- `run_*` - Run what?
- `perform_*` - Perform what?

**Better**: Specific action verbs (parse, validate, transform, store, etc.)

## Implementation

### Step 1: Find Vaguely Named Functions

```bash
cd reedbase/src

# Search for common vague patterns
echo "=== handle_* functions ===" > /tmp/vague_functions.txt
rg "fn handle_\w+" --type rust --no-heading >> /tmp/vague_functions.txt

echo "\n=== process_* functions ===" >> /tmp/vague_functions.txt
rg "fn process_\w+" --type rust --no-heading >> /tmp/vague_functions.txt

echo "\n=== manage_* functions ===" >> /tmp/vague_functions.txt
rg "fn manage_\w+" --type rust --no-heading >> /tmp/vague_functions.txt

echo "\n=== do_* functions ===" >> /tmp/vague_functions.txt
rg "fn do_\w+" --type rust --no-heading >> /tmp/vague_functions.txt

echo "\n=== perform_* functions ===" >> /tmp/vague_functions.txt
rg "fn perform_\w+" --type rust --no-heading >> /tmp/vague_functions.txt

# Count total
grep "fn " /tmp/vague_functions.txt | wc -l
```

### Step 2: Analyze Each Function

For each vague name:

```markdown
## Function: `handle_request` in api/server.rs:89

**Current name**: `handle_request`

**What it actually does**:
- Parses request
- Routes to correct handler
- Returns response

**Assessment**: ❌ VAGUE

**Better name**: `route_request` or `dispatch_request`

**Reason**: "Handle" is too generic - "route" describes the specific action

**Effort**: 10 minutes (rename + update callers)

**Create ticket**: 25X-[FUNC]-XX-rename-handle-request.md
```

**vs**

```markdown
## Function: `execute_query` in database/execute.rs:145

**Current name**: `execute_query`

**Assessment**: ✅ ACCEPTABLE (in context)

**Reason**: 
- In a module called "execute.rs"
- The context makes "execute" specific
- Alternative "run_query" not better

**Action**: KEEP
```

### Step 3: Categorize

**Must Rename** (truly vague):
- Name doesn't indicate actual action
- Multiple responsibilities (needs split first)
- Confusing in context

**Acceptable** (context makes it clear):
- Module name + function name = clear
- Domain-specific terminology
- No better alternative exists

### Step 4: Create Rename Tickets

For each must-rename function:
- Create ticket: `25X-[FUNC]-XX-rename-[old-name].md`

## Verification

- [ ] All vague patterns searched
- [ ] Each function analyzed (RENAME / KEEP)
- [ ] Rename tickets created
- [ ] Better names proposed

## Expected Findings

Conservative: 5-15 vaguely named functions, 3-8 needing rename

## Output

Create: `_workbench/analysis/vague_function_names.md`
