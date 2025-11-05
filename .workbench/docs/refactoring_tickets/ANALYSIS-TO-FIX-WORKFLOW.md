# Analysis → Fix Ticket Workflow

## Problem
Analysis tickets (150, 210, 250) find violations dynamically.
Question: WHO creates the fix tickets based on findings?

## Solution: Two-Phase Workflow

### Phase 1: Analysis (Find All Violations)

**Tickets**: 151-154, 211-213, 251-253

**Output**: Analysis reports in `_workbench/analysis/`

**Format**:
```markdown
# File: _workbench/analysis/long_functions_found.md

## Found: 8 functions >100 lines

1. execute_query (database/execute.rs:145) - 234 lines
   - Priority: HIGH
   - Effort: 1h
   - Action: SPLIT

2. parse_select (reedql/parser.rs:89) - 156 lines
   - Priority: MEDIUM
   - Effort: 30m
   - Action: SPLIT
   
...

## Recommended Tickets:
- 254-[FUNC]-04-split-execute-query.md
- 255-[FUNC]-05-split-parse-select.md
...
```

### Phase 2: User Review + Ticket Creation

**Step 1: User Reviews Analysis**
```bash
# Read analysis reports
cat _workbench/analysis/long_functions_found.md
cat _workbench/analysis/generic_files_found.md
cat _workbench/analysis/american_spellings_found.md
```

**Step 2: User Decides**
- Which violations to fix? (all / high priority only / skip)
- What's the approach? (split / rename / keep with justification)

**Step 3: Create Fix Tickets**

**Option A: Manual Creation**
```bash
# User creates tickets based on template
cp templates/func-split-template.md 254-[FUNC]-04-split-execute-query.md
# Edit with specific details
```

**Option B: Script-Assisted**
```bash
# Helper script to generate tickets from analysis
./scripts/generate_fix_tickets.sh _workbench/analysis/long_functions_found.md

# Creates:
# - 254-[FUNC]-04-split-execute-query.md
# - 255-[FUNC]-05-split-parse-select.md
# etc.
```

**Step 4: Update MASTER-TRACKING.md**
```markdown
Phase 5: Function Refactoring
- 250-253: Analysis (completed)
- 254: Split execute_query (generated from 251 findings)
- 255: Split parse_select (generated from 251 findings)
- ... (total: 8 tickets generated)
```

## Expected Ticket Counts

**After Phase 1 Analysis:**

| Parent | Analysis Tickets | Expected Fix Tickets |
|--------|------------------|---------------------|
| 150-[LANG]-00 | 151-154 (4) | 0-3 (code identifiers needing user decision) |
| 210-[AUDIT]-00 | 211-213 (3) | 2-8 (additional generic files found) |
| 250-[FUNC]-00 | 251-253 (3) | 5-15 (functions/signatures to refactor) |

**Total Generated**: ~7-26 additional tickets (depends on findings)

## Workflow Example

```
[151-LANG-01] Find -ize words
    ↓
    Output: _workbench/analysis/ize_words.txt
    ↓
    → 90% in comments (auto-fix) ✅
    → 10% in function names (ask user) ⚠️
    ↓
    User reviews: "Rename 2 of 5 functions"
    ↓
    Create tickets:
    - 155-[LANG]-05-rename-initialize-func.md
    - 156-[LANG]-06-rename-optimize-func.md
```

## Templates

### Function Split Template
```markdown
# FUNC-XXX-XX: Split [function_name]

## Generated from: 251-[FUNC]-01 (long functions analysis)

## Context
Function: `function_name` in `file.rs:line`
Current lines: XXX
Responsibilities: 3 (list them)

## Target
Split into:
- `function_name` (orchestration)
- `function_name_step_a` (step A)
- `function_name_step_b` (step B)

## Steps
...
```

## Who Does What?

| Role | Responsibility |
|------|---------------|
| **Analysis Tickets (251-253)** | Find violations, generate reports |
| **User (Vivian)** | Review reports, decide what to fix |
| **User or Script** | Create fix tickets based on decisions |
| **Fix Tickets (254+)** | Execute the actual fixes |

## This is NORMAL in Refactoring!

Analysis discovers problems → creates work items → those get done.
This is **expected** and **correct** workflow.
