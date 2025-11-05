# LANG-154-04: Fix -er to -re Endings

## Status
- [x] Not Started
- [ ] In Progress
- [ ] Complete

## Priority
**LOW** - Part of BBC English compliance (Standard #1)

## Estimated Effort
10 minutes

## Parent Ticket
150-[LANG]-00: Fix American Spellings to BBC English

## Context

**Pattern**: `-er` → `-re` (British English)

Common words:
- `center` → `centre`
- `meter` → `metre`
- `fiber` → `fibre`
- `liter` → `litre`

**Warning**: Many false positives (parameter, enter, filter, etc.)

## Implementation

### Step 1: Find Specific Words

```bash
cd reedbase/src

# Only search specific words (not pattern - too many false positives)
rg "\bcenter\b|\bmeter\b|\bfiber\b|\bliter\b" --type rust | \
  grep -v "parameter" | \
  grep -v "kilometer" | \
  grep -v "perimeter" \
  > /tmp/er_words.txt
```

### Step 2: Manual Review

**Critical**: Don't change:
- `parameter` (correct spelling!)
- `kilometer`, `centimeter` (correct!)
- `enter`, `filter`, `cluster` (correct!)

Only change if:
- Literally means "center" (middle point)
- Literally means "meter" (measurement unit)

### Step 3: Apply Fixes (Careful!)

```bash
# Only if found - use word boundaries to avoid false positives
find src -name "*.rs" -type f -exec sed -i '' \
  -e 's/\bcenter\b/centre/g' \
  -e 's/\bCenter\b/Centre/g' \
  {} \;

# DON'T use pattern replacement for "meter" - too dangerous
# Manual review required
```

### Step 4: Verify

```bash
# Make sure we didn't break anything
rg "parametre|centimetre|kilometre" src/ --type rust
# Should find NOTHING - these would be wrong!

cargo check
cargo test --lib
```

## Verification

- [ ] Only true "center/centre" changed (not parameter, etc.)
- [ ] No false positives (centimetre, parametre)
- [ ] Tests pass

## Expected Changes

Very rare, expect 0-2 occurrences.

## Files Affected

Unlikely to affect any files - database code rarely uses these terms.

## Notes

**High Risk of False Positives** - Be very careful with this pattern!
