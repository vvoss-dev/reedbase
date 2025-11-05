# LANG-151-01: Fix -ize to -ise Endings

## Status
- [x] Not Started
- [ ] In Progress
- [ ] Complete

## Priority
**HIGH** - Part of BBC English compliance (Standard #1)

## Estimated Effort
20 minutes

## Parent Ticket
150-[LANG]-00: Fix American Spellings to BBC English

## Context

**Pattern**: `-ize` → `-ise` (British English)

Common words:
- `initialize` → `initialise`
- `optimize` → `optimise`  
- `organize` → `organise`
- `synchronize` → `synchronise`
- `serialize` → `serialise`
- `finalize` → `finalise`
- `customize` → `customise`

**Scope**: All `.rs` files in `src/`

## Implementation

### Step 1: Find All -ize Words

```bash
cd reedbase/src

# Find -ize words (exclude false positives)
rg "\b\w*ize\b" --type rust | \
  grep -v "size" | \
  grep -v "resize" | \
  grep -v "prize" | \
  grep -v "seize" > /tmp/ize_words.txt

# Count occurrences
echo "Total -ize occurrences:"
wc -l /tmp/ize_words.txt
```

### Step 2: Categorize by Context

```bash
# Comments (safe to change)
rg "//.*\w*ize" --type rust > /tmp/ize_comments.txt

# Doc comments (safe to change)
rg "///.*\w*ize" --type rust > /tmp/ize_docs.txt

# Code identifiers (needs review)
rg "fn.*ize|let.*ize|struct.*ize" --type rust > /tmp/ize_code.txt
```

### Step 3: Apply Automated Fixes (Comments & Docs)

```bash
# Fix in comments and docs (case-sensitive)
find src -name "*.rs" -type f -exec sed -i '' \
  -e 's/\([^a-zA-Z]\)initialize/\1initialise/g' \
  -e 's/\([^a-zA-Z]\)optimize/\1optimise/g' \
  -e 's/\([^a-zA-Z]\)organize/\1organise/g' \
  -e 's/\([^a-zA-Z]\)synchronize/\1synchronise/g' \
  -e 's/\([^a-zA-Z]\)serialize/\1serialise/g' \
  -e 's/\([^a-zA-Z]\)finalize/\1finalise/g' \
  -e 's/\([^a-zA-Z]\)customize/\1customise/g' \
  {} \;

# Fix capitalized versions
find src -name "*.rs" -type f -exec sed -i '' \
  -e 's/Initialize/Initialise/g' \
  -e 's/Optimize/Optimise/g' \
  -e 's/Organize/Organise/g' \
  -e 's/Synchronize/Synchronise/g' \
  -e 's/Serialize/Serialise/g' \
  -e 's/Finalize/Finalise/g' \
  -e 's/Customize/Customise/g' \
  {} \;
```

### Step 4: Manual Review for Code Identifiers

If code identifiers found:
```bash
# List function names with -ize
rg "fn \w*ize" --type rust --no-heading

# Ask user: Rename or keep for API compatibility?
```

### Step 5: Verify

```bash
# Should find nothing (except size, resize, prize, seize)
rg "\boptimize\b|\binitialize\b|\borganize\b" src/ --type rust

# Compile check
cargo check

# Test
cargo test --lib
```

## Verification

- [ ] All `-ize` comments/docs changed to `-ise`
- [ ] Function/variable names reviewed with user
- [ ] No false positives changed (size, resize, prize, seize)
- [ ] `cargo check` passes
- [ ] `cargo test --lib` passes

## Expected Changes

Based on typical Rust projects:
- Comments/docs: 20-40 occurrences
- Function names: 0-3 (rare in systems code)

## Notes

**False Positives to Ignore**:
- `size`, `resize`, `usize`, `isize` (correct spelling!)
- `prize`, `seize` (correct spelling)
- External crate names (can't change)

## Files Affected

Will be determined after Step 1 (search).

Likely candidates:
- Files with initialization code
- Files with optimization logic
- Files with serialization (if any)
