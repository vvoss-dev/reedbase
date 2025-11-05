# AUDIT-213-03: Audit mod.rs Files with Logic

## Status
- [x] Not Started
- [ ] In Progress
- [ ] Complete

## Priority
**MEDIUM** - Part of generic filename audit (Standard #7)

## Estimated Effort
10 minutes

## Parent Ticket
210-[AUDIT]-00: Find All Generic Filenames

## Context

**Rule**: `mod.rs` should only contain:
- Module declarations (`pub mod submodule;`)
- Re-exports (`pub use submodule::Type;`)
- Maybe a small module docstring (`//!`)

**Violation**: `mod.rs` with actual implementation code (>50 lines)

## Implementation

### Step 1: Find Large mod.rs Files

```bash
cd reedbase/src

# Find all mod.rs files with line counts
find . -name "mod.rs" | while read file; do
  lines=$(wc -l < "$file")
  echo "$lines|$file"
done | sort -rn > /tmp/mod_files.txt

# Show ones >50 lines (suspicious)
cat /tmp/mod_files.txt | awk -F'|' '$1 > 50 {print $2 " (" $1 " lines)"}'
```

### Step 2: Analyze Each Large mod.rs

```bash
# For each large mod.rs, check what's in it
for file in $(cat /tmp/mod_files.txt | awk -F'|' '$1 > 50 {print $2}'); do
  echo "=== $file ==="
  
  # Count declarations vs implementation
  echo "Module declarations:"
  grep "^pub mod\|^mod " "$file" | wc -l
  
  echo "Re-exports:"
  grep "^pub use" "$file" | wc -l
  
  echo "Functions:"
  grep "^pub fn\|^fn " "$file" | wc -l
  
  echo "Structs:"
  grep "^pub struct" "$file" | wc -l
  
  echo "---"
done
```

### Step 3: Categorize

**Acceptable** (mostly exports):
```rust
// src/module/mod.rs (60 lines)
//! Module documentation

pub mod submodule_a;
pub mod submodule_b;
pub mod submodule_c;

pub use submodule_a::{Type1, Type2};
pub use submodule_b::{Type3, Type4};
// ... 50 lines of re-exports is OK
```

**Violation** (has implementation):
```rust
// src/module/mod.rs (150 lines)
pub mod submodule;

// ❌ BAD: Implementation in mod.rs
pub struct Config { ... }

impl Config {
  pub fn new() { ... }  // 100 lines of implementation
}
```

### Step 4: Create Action Plan

For mod.rs with implementation:
```markdown
## File: src/database/mod.rs (150 lines)

**Has**:
- 10 lines of module declarations
- 5 lines of re-exports
- **135 lines of Config struct implementation** ❌

**Action**: Extract Config to `database/config.rs`

**Create ticket**: 2XX-[EXTRACT]-XX-extract-database-config.md
```

## Verification

- [ ] All mod.rs files >50 lines reviewed
- [ ] Implementation-heavy mod.rs identified
- [ ] Extract tickets created for violations
- [ ] Pure-export mod.rs documented (keep as-is)

## Expected Findings

Typical: 2-3 mod.rs files with implementation code to extract

## Output

Create: `_workbench/analysis/mod_files_audit.md` with findings
