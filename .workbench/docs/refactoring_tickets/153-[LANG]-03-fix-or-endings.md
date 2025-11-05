# LANG-153-03: Fix -or to -our Endings

## Status
- [x] Not Started
- [ ] In Progress
- [ ] Complete

## Priority
**MEDIUM** - Part of BBC English compliance (Standard #1)

## Estimated Effort
10 minutes

## Parent Ticket
150-[LANG]-00: Fix American Spellings to BBC English

## Context

**Pattern**: `-or` → `-our` (British English)

Common words:
- `color` → `colour`
- `behavior` → `behaviour`
- `flavor` → `flavour`
- `honor` → `honour`

**Scope**: All `.rs` files in `src/` (comments/docs only - unlikely in code)

## Implementation

### Step 1: Find -or Words

```bash
cd reedbase/src

# Find color/flavor/behavior/honor
rg "\bcolor\b|\bbehavior\b|\bflavor\b|\bhonor\b" --type rust > /tmp/or_words.txt

# Count
wc -l /tmp/or_words.txt
```

### Step 2: Manual Review

**Critical**: These words are rare in systems code but check context:
- Is it in a comment? → Safe to change
- Is it a variable name? → Ask user
- Is it in a string literal? → Depends on use case

### Step 3: Apply Fixes (Comments Only)

```bash
# Only fix in comments/docs
rg "//.*color" --type rust --files-with-matches | \
  xargs sed -i '' 's/color/colour/g'

rg "///.*color" --type rust --files-with-matches | \
  xargs sed -i '' 's/color/colour/g'

# Same for behavior
rg "//.*behavior" --type rust --files-with-matches | \
  xargs sed -i '' 's/behavior/behaviour/g'
```

### Step 4: Verify

```bash
# Check remaining occurrences (should be in code only)
rg "\bcolor\b" src/ --type rust

cargo check
cargo test --lib
```

## Verification

- [ ] Comments/docs use `-our` spelling
- [ ] Code identifiers reviewed with user (if any)
- [ ] Tests pass

## Expected Changes

Rare in database code, expect 0-5 occurrences.

## Files Affected

Unlikely to find many - this pattern is rare in Rust systems code.
