# REED-CLEAN-090-03: CLAUDE.md Compliance Verification

**Created**: 2025-11-06  
**Phase**: 9 (Verification & Documentation)  
**Estimated Effort**: 1-2 hours  
**Dependencies**: All phases 1-8 complete  
**Blocks**: v0.2.0-beta release

---

## Status

- [ ] Ticket understood
- [ ] quality-check.sh run on ALL files
- [ ] All 8 standards verified
- [ ] Exceptions documented (if any)
- [ ] Compliance report created
- [ ] 100% compliance confirmed
- [ ] Committed

---

## 🚨 CRITICAL: This is Verification, Not Implementation

**Purpose**: Verify that ALL code follows the 8 CLAUDE.md standards.

**NO NEW CODE** - This ticket only runs verification and documents results.

---

## The 8 CLAUDE.md Standards

### Standard #0: Code Reuse
**Rule**: NEVER duplicate existing functions
- Check: No duplicate implementations
- Verify: `project_functions.csv` up to date

### Standard #1: BBC English
**Rule**: All comments in British English
- Check: "initialise", "optimise", "behaviour", "colour"
- NOT: "initialize", "optimize", "behavior", "color"

### Standard #2: KISS - Files <400 Lines
**Rule**: Every file must be < 400 lines
- Check: `wc -l *.rs`
- Split: If > 400 lines

### Standard #3: Specific File Naming
**Rule**: No generic names like utils.rs, helpers.rs
- Check: All filenames are specific
- NOT: utils.rs, helpers.rs, common.rs

### Standard #4: One Function = One Job
**Rule**: Single responsibility per function
- Check: No Swiss Army knife functions
- Check: No boolean flag parameters

### Standard #5: Separate Test Files
**Rule**: NEVER inline #[cfg(test)] modules
- Check: All tests in *_test.rs files
- NOT: #[cfg(test)] mod tests

### Standard #6: No Swiss Army Functions
**Rule**: No multi-purpose functions
- Check: No handle(), process(), manage() doing many things
- Check: Functions have single, clear purpose

### Standard #7: No Generic Names
**Rule**: Specific, contextual names
- Check: Functions/types have descriptive names
- NOT: process(), handle(), get(), set()

### Standard #8: Layered Architecture (not MVC)
**Rule**: Clean layered structure
- Check: No controllers, models with behaviour, views
- Check: Pure functions, trait-based polymorphism

---

## Verification Steps

### Step 1: Run Quality Check on All Files

```bash
# Create verification directory
mkdir -p .workbench/verification/quality-checks

# Run quality check on ALL source files
for file in $(find current/src -name "*.rs" -type f); do
    echo "Checking: $file"
    ./scripts/quality-check.sh "$file" > .workbench/verification/quality-checks/$(basename $file).log 2>&1
    if [ $? -ne 0 ]; then
        echo "FAIL: $file" >> .workbench/verification/quality-check-failures.txt
    fi
done

# Summary
echo "Total files checked: $(find current/src -name "*.rs" | wc -l)"
echo "Failures: $(wc -l < .workbench/verification/quality-check-failures.txt 2>/dev/null || echo 0)"
```

---

### Step 2: Verify Each Standard Individually

**Standard #0: Code Reuse**
```bash
# Check for duplicate function names
rg "^pub fn" current/src/ | cut -d: -f2 | sort | uniq -d > .workbench/verification/duplicate-functions.txt

# Should be empty
if [ -s .workbench/verification/duplicate-functions.txt ]; then
    echo "❌ FAIL: Duplicate functions found"
    cat .workbench/verification/duplicate-functions.txt
else
    echo "✅ PASS: No duplicate functions"
fi
```

**Standard #1: BBC English**
```bash
# Check for American spelling
rg -i "initialize|optimize|behavior|color(?!:)" current/src/ --type rust > .workbench/verification/american-spelling.txt

# Should be empty (except for crate names like serde::serialize)
if [ -s .workbench/verification/american-spelling.txt ]; then
    echo "⚠️ WARNING: American spelling found (review for exceptions)"
    cat .workbench/verification/american-spelling.txt
else
    echo "✅ PASS: BBC English throughout"
fi
```

**Standard #2: KISS - Files <400 Lines**
```bash
# Find files > 400 lines
find current/src -name "*.rs" -type f -exec wc -l {} \; | awk '$1 > 400' > .workbench/verification/large-files.txt

# Should be empty
if [ -s .workbench/verification/large-files.txt ]; then
    echo "❌ FAIL: Files > 400 lines found"
    cat .workbench/verification/large-files.txt
else
    echo "✅ PASS: All files < 400 lines"
fi
```

**Standard #3: Specific File Naming**
```bash
# Check for generic names
find current/src -name "*.rs" | grep -E "(utils|helpers|common|misc|tools)\.rs" > .workbench/verification/generic-names.txt

# Should be empty
if [ -s .workbench/verification/generic-names.txt ]; then
    echo "❌ FAIL: Generic file names found"
    cat .workbench/verification/generic-names.txt
else
    echo "✅ PASS: All file names specific"
fi
```

**Standard #4: One Function = One Job**
```bash
# Check for boolean flag parameters (common anti-pattern)
rg "pub fn.*: bool" current/src/ --type rust > .workbench/verification/boolean-flags.txt

# Review manually (some boolean flags are acceptable, like "include_header")
echo "⚠️ REVIEW: Boolean flag parameters (some may be acceptable)"
cat .workbench/verification/boolean-flags.txt
```

**Standard #5: Separate Test Files**
```bash
# Check for inline test modules
rg "#\[cfg\(test\)\]" current/src/ --type rust > .workbench/verification/inline-tests.txt

# Should be empty
if [ -s .workbench/verification/inline-tests.txt ]; then
    echo "❌ FAIL: Inline test modules found"
    cat .workbench/verification/inline-tests.txt
else
    echo "✅ PASS: All tests in separate files"
fi
```

**Standard #6: No Swiss Army Functions**
```bash
# Check for generic function names that often indicate Swiss Army functions
rg "pub fn (handle|process|manage|execute)\(" current/src/ --type rust > .workbench/verification/swiss-army-candidates.txt

# Review manually (context matters)
echo "⚠️ REVIEW: Potential Swiss Army functions (manual review needed)"
cat .workbench/verification/swiss-army-candidates.txt
```

**Standard #7: No Generic Names**
```bash
# Check for overly generic function/type names
rg "pub (fn|struct|enum) (get|set|data|info|item|thing|stuff)\b" current/src/ --type rust > .workbench/verification/generic-identifiers.txt

# Review manually (context matters)
echo "⚠️ REVIEW: Generic identifiers (manual review needed)"
cat .workbench/verification/generic-identifiers.txt
```

**Standard #8: Layered Architecture**
```bash
# Check for MVC patterns (controllers, models with save(), views)
rg "impl.*\{\s*pub fn save\(" current/src/ --type rust > .workbench/verification/mvc-patterns.txt
rg "struct.*Controller" current/src/ --type rust >> .workbench/verification/mvc-patterns.txt
rg "impl.*Display for" current/src/(?!bin) --type rust >> .workbench/verification/mvc-patterns.txt

# Should be empty (except Display in bin/)
if [ -s .workbench/verification/mvc-patterns.txt ]; then
    echo "⚠️ WARNING: Potential MVC patterns found (review)"
    cat .workbench/verification/mvc-patterns.txt
else
    echo "✅ PASS: Layered architecture (no MVC)"
fi
```

---

### Step 3: Create Compliance Report

**Create `.workbench/verification/CLAUDE-COMPLIANCE-REPORT.md`**:

```markdown
# CLAUDE.md Compliance Report

**Date**: 2025-11-06  
**Verified By**: Claude  
**Status**: [PASS/FAIL]

---

## Executive Summary

- **Total Files Checked**: XXX
- **Passing Files**: XXX
- **Failing Files**: X
- **Warnings**: X
- **Overall Compliance**: XX%

**Status**: [✅ PASS - 100% compliant / ❌ FAIL - Issues found]

---

## Standard #0: Code Reuse

**Status**: [✅ PASS / ❌ FAIL]

- Duplicate functions: X
- Issues:
  - [List any issues or "None"]

**Verification**:
\`\`\`bash
rg "^pub fn" current/src/ | cut -d: -f2 | sort | uniq -d
\`\`\`

---

## Standard #1: BBC English

**Status**: [✅ PASS / ⚠️ WARNING]

- American spellings found: X
- Exceptions: X (documented below)

**Issues**:
- [List any issues or "None"]

**Exceptions** (acceptable):
- `serde::serialize` - Ecosystem crate name
- `colorize` - External crate function

**Verification**:
\`\`\`bash
rg -i "initialize|optimize|behavior" current/src/ --type rust
\`\`\`

---

## Standard #2: KISS - Files <400 Lines

**Status**: [✅ PASS / ❌ FAIL]

- Files checked: XXX
- Files > 400 lines: X

**Large Files** (if any):
| File | Lines | Status |
|------|-------|--------|
| example.rs | 450 | ❌ Needs split |

**Verification**:
\`\`\`bash
find current/src -name "*.rs" -exec wc -l {} \; | awk '$1 > 400'
\`\`\`

---

## Standard #3: Specific File Naming

**Status**: [✅ PASS / ❌ FAIL]

- Generic names found: X

**Issues** (if any):
- [List any issues or "None"]

**Verification**:
\`\`\`bash
find current/src -name "*.rs" | grep -E "(utils|helpers|common)\.rs"
\`\`\`

---

## Standard #4: One Function = One Job

**Status**: [✅ PASS / ⚠️ REVIEW]

- Functions with boolean flags: X
- Acceptable: X
- Needs review: X

**Acceptable Boolean Flags**:
- `include_header: bool` in formatters (clear, binary choice)

**Needs Review**:
- [List any questionable functions or "None"]

**Verification**:
\`\`\`bash
rg "pub fn.*: bool" current/src/ --type rust
\`\`\`

---

## Standard #5: Separate Test Files

**Status**: [✅ PASS / ❌ FAIL]

- Inline test modules: X

**Issues** (if any):
- [List files with inline tests or "None"]

**Verification**:
\`\`\`bash
rg "#\[cfg\(test\)\]" current/src/ --type rust
\`\`\`

---

## Standard #6: No Swiss Army Functions

**Status**: [✅ PASS / ⚠️ REVIEW]

- Generic function names: X
- Needs review: X

**Acceptable Uses**:
- `execute()` in command modules (clear context)
- `process()` with specific purpose documented

**Needs Review**:
- [List any questionable functions or "None"]

**Verification**:
\`\`\`bash
rg "pub fn (handle|process|manage)" current/src/ --type rust
\`\`\`

---

## Standard #7: No Generic Names

**Status**: [✅ PASS / ⚠️ REVIEW]

- Generic identifiers: X
- Acceptable: X
- Needs review: X

**Acceptable Generic Names** (with context):
- `get_table()` in database module (specific context)
- `set_value()` in specific data structure

**Needs Review**:
- [List any questionable names or "None"]

**Verification**:
\`\`\`bash
rg "pub (fn|struct) (get|set|data|info)\b" current/src/ --type rust
\`\`\`

---

## Standard #8: Layered Architecture

**Status**: [✅ PASS / ❌ FAIL]

- MVC patterns found: X
- Issues:
  - [List any issues or "None"]

**Acceptable Display Implementations**:
- `bin/` directory only (CLI presentation layer)

**Verification**:
\`\`\`bash
rg "impl.*Display for" current/src/(?!bin) --type rust
\`\`\`

---

## Files Requiring Action

(If any failures found)

| File | Standard | Issue | Action Required |
|------|----------|-------|-----------------|
| example.rs | #2 | 450 lines | Split into 2 files |

---

## Summary of Exceptions

(Document any acceptable violations of standards)

| File | Standard | Reason | Approved By |
|------|----------|--------|-------------|
| none | - | - | - |

---

## Recommendations

1. [Recommendation 1 if any issues found]
2. [Recommendation 2 if any issues found]

---

## Conclusion

**Overall Status**: [✅ PASS - 100% compliant / ❌ FAIL]

- All 8 standards: [✅ / ❌]
- Ready for v0.2.0-beta: [YES / NO]

**Next Steps**:
- [Fix any issues found, or "None - ready for release"]
```

---

### Step 4: Document Compliance in README

**Add to `current/README.md`**:

```markdown
## Code Quality Standards

ReedBase v0.2.0-beta follows strict quality standards defined in `CLAUDE.md`:

✅ **Standard #0**: No duplicate code  
✅ **Standard #1**: BBC English throughout  
✅ **Standard #2**: All files < 400 lines (KISS principle)  
✅ **Standard #3**: Specific file naming (no utils.rs, helpers.rs)  
✅ **Standard #4**: One function = one job  
✅ **Standard #5**: Separate test files (*_test.rs)  
✅ **Standard #6**: No Swiss Army functions  
✅ **Standard #7**: Specific, contextual names  
✅ **Standard #8**: Layered architecture (not MVC)  

**Compliance**: 100% verified (see `.workbench/verification/CLAUDE-COMPLIANCE-REPORT.md`)

**Quality Check**: Run `./scripts/quality-check.sh <file>` to verify any file.
```

---

## Success Criteria

### Compliance Requirements ✅
- [x] All 8 standards verified
- [x] quality-check.sh run on all files
- [x] 100% compliance OR exceptions documented
- [x] All failures have action plans
- [x] Report created and complete

### Documentation Requirements ✅
- [x] CLAUDE-COMPLIANCE-REPORT.md created
- [x] Exceptions documented and justified
- [x] Recommendations provided (if needed)
- [x] README.md updated with compliance badge

---

## Commit Message

```
[CLEAN-090-03] docs: verify CLAUDE.md compliance (100%)

✅ All 8 Standards: PASS
✅ Files Checked: XXX
✅ Compliance: 100%

Standard #0 (Code Reuse): ✅ PASS
- No duplicate functions found

Standard #1 (BBC English): ✅ PASS
- All comments in British English
- Exceptions: serde::serialize (ecosystem)

Standard #2 (KISS <400 lines): ✅ PASS
- Largest file: XXX lines
- All files within limit

Standard #3 (Specific Naming): ✅ PASS
- No generic file names (utils.rs, helpers.rs)

Standard #4 (One Function = One Job): ✅ PASS
- Boolean flags: Only in formatters (acceptable)

Standard #5 (Separate Tests): ✅ PASS
- No inline #[cfg(test)] modules
- All tests in *_test.rs files

Standard #6 (No Swiss Army): ✅ PASS
- execute() only in command context
- All functions have single purpose

Standard #7 (No Generic Names): ✅ PASS
- All identifiers contextual and specific

Standard #8 (Layered Architecture): ✅ PASS
- No MVC patterns
- Display only in bin/ (CLI layer)

Documentation:
- Created CLAUDE-COMPLIANCE-REPORT.md
- Updated README.md with compliance info
- Documented all verification steps

Files:
- .workbench/verification/CLAUDE-COMPLIANCE-REPORT.md
- .workbench/verification/quality-checks/*.log
- current/README.md (compliance section)
```

---

## Notes

### Automated vs Manual Review

**Automated checks** (scripts):
- Standard #0: Duplicate function names
- Standard #1: American spellings
- Standard #2: File line counts
- Standard #3: Generic file names
- Standard #5: Inline test modules

**Manual review required**:
- Standard #4: Function complexity
- Standard #6: Swiss Army functions (context matters)
- Standard #7: Generic names (context matters)
- Standard #8: Architecture patterns

### Common False Positives

1. **"serialize"**: From serde crate (ecosystem name)
2. **"color"**: May be in color: #RRGGBB (CSS)
3. **execute()**: Acceptable in command/executor context
4. **get/set**: Acceptable with specific context (get_table, set_value)

### Quality Check Script

The `quality-check.sh` script checks:
- File size (< 400 lines)
- No #[cfg(test)] inline
- BBC English keywords
- Generic file names

Run on any file: `./scripts/quality-check.sh current/src/module/file.rs`

---

**Ticket Complete**: Verification only, no implementation.
