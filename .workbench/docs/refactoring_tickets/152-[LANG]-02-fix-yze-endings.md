# LANG-152-02: Fix -yze to -yse Endings

## Status
- [x] Not Started
- [ ] In Progress
- [ ] Complete

## Priority
**HIGH** - Part of BBC English compliance (Standard #1)

## Estimated Effort
10 minutes

## Parent Ticket
150-[LANG]-00: Fix American Spellings to BBC English

## Context

**Pattern**: `-yze` → `-yse` (British English)

Common words:
- `analyze` → `analyse`
- `paralyze` → `paralyse`

**Scope**: All `.rs` files in `src/`

## Implementation

### Step 1: Find All -yze Words

```bash
cd reedbase/src

# Find -yze words
rg "\b\w*yze\b" --type rust > /tmp/yze_words.txt

# Count
echo "Total -yze occurrences:"
wc -l /tmp/yze_words.txt
```

### Step 2: Apply Fixes

```bash
# Fix analyze/analyse
find src -name "*.rs" -type f -exec sed -i '' \
  -e 's/\([^a-zA-Z]\)analyze/\1analyse/g' \
  -e 's/\([^a-zA-Z]\)paralyze/\1paralyse/g' \
  {} \;

# Capitalized
find src -name "*.rs" -type f -exec sed -i '' \
  -e 's/Analyze/Analyse/g' \
  -e 's/Paralyze/Paralyse/g' \
  {} \;
```

### Step 3: Verify

```bash
# Should find nothing
rg "\banalyze\b" src/ --type rust

# Test
cargo check
cargo test --lib
```

## Verification

- [ ] All `-yze` words changed to `-yse`
- [ ] `cargo check` passes
- [ ] `cargo test --lib` passes

## Expected Changes

Less common than `-ize`, expect 5-10 occurrences.

## Files Affected

Likely in:
- Query analysis code
- Statistics/metrics code
