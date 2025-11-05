# LANG-150-00: Fix American Spellings to BBC English

## Status
- [x] Not Started
- [ ] In Progress
- [ ] Complete

## Priority
**HIGH** - Violates CLAUDE.md mandatory standard #1

## Estimated Effort
1 hour

## Path References

**⚠️ NOTE**: Searches all Rust files regardless of folder structure.

## Context
CLAUDE.md requires:
> **1. Language**: All code comments and docs in BBC English

This means:
- `color` → `colour`
- `initialize` → `initialise`
- `organize` → `organise`
- `optimize` → `optimise`
- `analyze` → `analyse`
- `synchronize` → `synchronise`

**Scope**: All `.rs` files in `src/`

## Current State

**Unknown** - Need to search systematically for American spellings.

## Common American → BBC English Corrections

| American | BBC English | Pattern |
|----------|-------------|---------|
| `color` | `colour` | -or → -our |
| `initialize` | `initialise` | -ize → -ise |
| `organize` | `organise` | -ize → -ise |
| `optimize` | `optimise` | -ize → -ise |
| `analyze` | `analyse` | -yze → -yse |
| `synchronize` | `synchronise` | -ize → -ise |
| `serialize` | `serialise` | -ize → -ise |
| `catalog` | `catalogue` | -og → -ogue |
| `center` | `centre` | -er → -re |
| `meter` | `metre` | -er → -re |

## Implementation Steps

### Step 1: Find All American Spellings

```bash
cd src

# Search for -ize endings (should be -ise)
echo "=== -ize words (should be -ise) ==="
grep -rn "ize" --include="*.rs" | grep -v "size" | grep -v "resize"

# Search for -yze endings (should be -yse)
echo "=== -yze words (should be -yse) ==="
grep -rn "yze" --include="*.rs"

# Search for color (should be colour)
echo "=== color (should be colour) ==="
grep -rn "color" --include="*.rs" | grep -v "//"

# Search for -or endings (should be -our)
echo "=== -or words (should be -our) ==="
grep -rn "\bcolor\b\|\bflavor\b\|\bhonor\b" --include="*.rs"

# Search for -og endings (should be -ogue)
echo "=== catalog (should be catalogue) ==="
grep -rn "catalog" --include="*.rs"

# Search for center/meter (should be centre/metre)
echo "=== center/meter (should be centre/metre) ==="
grep -rn "\bcenter\b\|\bmeter\b" --include="*.rs" | grep -v "parameter" | grep -v "kilometer"
```

### Step 2: Create Correction Script

```bash
# Save all findings to analysis file
cd reedbase
./scripts/find_american_spellings.sh > _workbench/docs/american_spellings_found.txt
```

### Step 3: Manual Review

**Why manual?** Some words are:
- Variable names (API compatibility)
- External library names (must keep)
- Code identifiers (would break compilation)
- In strings that must match external systems

**Review each finding**:
1. Is it in a comment? → Safe to change
2. Is it in documentation? → Safe to change
3. Is it a function/variable name? → Ask user first
4. Is it in a string literal? → Depends on context

### Step 4: Apply Corrections

**For comments and docs** (safe):
```bash
# Example: Fix "initialize" in comments
find src -name "*.rs" -exec sed -i '' 's/\([^a-z]\)initialize/\1initialise/g' {} \;
find src -name "*.rs" -exec sed -i '' 's/Initialize/Initialise/g' {} \;

# Example: Fix "optimize" in comments
find src -name "*.rs" -exec sed -i '' 's/\([^a-z]\)optimize/\1optimise/g' {} \;
find src -name "*.rs" -exec sed -i '' 's/Optimize/Optimise/g' {} \;
```

**For code identifiers** (requires user approval):
```bash
# List all function/variable names with American spelling
rg "fn.*initialize|let.*initialize|pub.*initialize" src/ --no-heading

# User decides: rename or keep for API compatibility
```

### Step 5: Verify No Breakage

```bash
# Compile check
cargo check

# Run tests
cargo test --lib

# Run clippy
cargo clippy
```

### Step 6: Update Documentation

Check all markdown files:
```bash
# Search README, CHANGELOG, etc.
grep -rn "ize\|yze\|color\|center" *.md _workbench/**/*.md
```

## Verification

- [ ] All comments use BBC English
- [ ] All documentation uses BBC English
- [ ] Code identifiers reviewed (user approved any kept American spellings)
- [ ] `cargo check` passes
- [ ] `cargo test --lib` passes
- [ ] `cargo clippy` shows no warnings
- [ ] No American spellings in user-facing strings

## Files Affected

**Will be determined** after Step 1 (systematic search).

Expect:
- 20-50 files with comment corrections
- 5-10 files with code identifier changes (user approval required)
- README.md, CHANGELOG.md (documentation)

## Notes

### API Compatibility Exceptions

If external APIs use American spelling, we may need to keep:
```rust
// External crate uses American spelling - keep for compatibility
pub fn serialize_to_json() { ... }  // ⚠️ Exception: external API

// Our internal docs use BBC English
/// Serialises the data to JSON format using...
```

### Decision Template

For each American spelling found:
1. **Comment/doc** → Change to BBC English ✅
2. **Function/variable name** → Ask user (API compatibility?)
3. **String literal** → Ask user (external system dependency?)
4. **External library** → Keep as-is (can't change third-party code)

### Common False Positives

Words to ignore:
- `size`, `resize` (not "sise"!)
- `prize`, `seize` (correct spelling)
- `parameter`, `kilometer` (correct spelling)
- Rust keywords and std library names

## Related Tickets

- **600-[VERIFY]-00**: Final verification includes BBC English check
- **This ticket**: Proactive search and fix

**Difference**: 600 verifies, this ticket fixes.
