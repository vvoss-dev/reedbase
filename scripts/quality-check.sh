#!/usr/bin/env bash
# Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
# SPDX-License-Identifier: Apache-2.0

# Quality check script for CLAUDE.md compliance
# Usage: ./scripts/quality-check.sh <file.rs>

set -e

FILE=$1
WARNINGS=0
ERRORS=0

if [ -z "$FILE" ]; then
    echo "Usage: $0 <file.rs>"
    echo ""
    echo "Example: $0 src/core/paths.rs"
    exit 1
fi

if [ ! -f "$FILE" ]; then
    echo "❌ Error: File not found: $FILE"
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 CLAUDE.md Quality Check: $FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ============================================================================
# Standard #0: Code Reuse - No Duplicates
# ============================================================================
echo "📋 Standard #0: Code Reuse"
echo "────────────────────────────────────────────────────────────────"

# Check if function registry exists for duplicate search
if [ -f "_workbench/analysis/050-all-functions.txt" ]; then
    # Extract function names from this file
    FUNCS=$(rg "pub fn (\w+)" "$FILE" -o --replace '$1' 2>/dev/null || true)

    if [ -n "$FUNCS" ]; then
        echo "Functions in this file:"
        echo "$FUNCS" | while read func; do
            # Search in function registry (excluding current file)
            DUPS=$(grep "$func" _workbench/analysis/050-all-functions.txt | grep -v "$FILE" || true)
            if [ -n "$DUPS" ]; then
                echo "  ⚠️  $func - Also found in:"
                echo "$DUPS" | sed 's/^/      /'
                ((WARNINGS++)) || true
            else
                echo "  ✅ $func - Unique"
            fi
        done
    else
        echo "  ℹ️  No public functions found"
    fi
else
    echo "  ⚠️  Function registry not found (_workbench/analysis/050-all-functions.txt)"
    echo "     Run 050-[REUSE]-00 analysis first to enable duplicate detection"
    ((WARNINGS++)) || true
fi
echo ""

# ============================================================================
# Standard #1: BBC English
# ============================================================================
echo "🇬🇧 Standard #1: BBC English"
echo "────────────────────────────────────────────────────────────────"

# Check for American English spellings
AMERICAN=$(rg -n "initialize|optimize|analyze|behavior(?!al)|color(?!_)" "$FILE" || true)
if [ -n "$AMERICAN" ]; then
    echo "  ⚠️  Possible American English detected:"
    echo "$AMERICAN" | sed 's/^/      /'
    echo "     Review manually - code identifiers may be OK if established in ecosystem"
    ((WARNINGS++)) || true
else
    echo "  ✅ No American English spellings detected"
fi

# Check copyright header
if ! head -1 "$FILE" | grep -q "Copyright.*Vivian Voss.*Apache"; then
    echo "  ❌ Missing copyright header"
    echo "     Expected: // Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0."
    ((ERRORS++)) || true
else
    echo "  ✅ Copyright header present"
fi

# Check SPDX identifier
if ! head -2 "$FILE" | grep -q "SPDX-License-Identifier: Apache-2.0"; then
    echo "  ❌ Missing SPDX identifier"
    echo "     Expected: // SPDX-License-Identifier: Apache-2.0"
    ((ERRORS++)) || true
else
    echo "  ✅ SPDX identifier present"
fi
echo ""

# ============================================================================
# Standard #2: KISS - File Size <400 Lines
# ============================================================================
echo "📏 Standard #2: KISS (File Size)"
echo "────────────────────────────────────────────────────────────────"

LINES=$(wc -l < "$FILE")
if [ "$LINES" -gt 400 ]; then
    echo "  ❌ File has $LINES lines (limit: 400)"
    echo "     Split file into smaller modules"
    ((ERRORS++)) || true
elif [ "$LINES" -gt 350 ]; then
    echo "  ⚠️  File has $LINES lines (approaching limit of 400)"
    echo "     Consider splitting if adding more code"
    ((WARNINGS++)) || true
else
    echo "  ✅ File size OK ($LINES lines / 400)"
fi
echo ""

# ============================================================================
# Standard #3: File Naming
# ============================================================================
echo "📝 Standard #3: File Naming"
echo "────────────────────────────────────────────────────────────────"

BASENAME=$(basename "$FILE")
if [[ "$BASENAME" =~ ^(helpers|utils|common|misc|stuff)\.rs$ ]]; then
    echo "  ❌ Generic filename detected: $BASENAME"
    echo "     Use specific names like 'path_construction.rs' instead of 'helpers.rs'"
    ((ERRORS++)) || true
elif [[ "$BASENAME" =~ ^(mod|lib)\.rs$ ]]; then
    echo "  ℹ️  Module file: $BASENAME (OK for module roots)"
elif [[ "$BASENAME" =~ _test\.rs$ ]]; then
    echo "  ✅ Test file: $BASENAME (follows Standard #5)"
else
    echo "  ✅ Specific filename: $BASENAME"
fi
echo ""

# ============================================================================
# Standard #4: One Function = One Job
# ============================================================================
echo "🎯 Standard #4: One Function = One Job"
echo "────────────────────────────────────────────────────────────────"

# Find functions with >100 lines
LONG_FUNCS=$(rg "^pub fn \w+" "$FILE" -n 2>/dev/null || true)
if [ -n "$LONG_FUNCS" ]; then
    echo "$LONG_FUNCS" | while IFS=: read -r line_no func_line; do
        # Count lines until next "pub fn" or EOF
        NEXT_FUNC=$(rg "^pub fn" "$FILE" -n | awk -F: -v start="$line_no" '$1 > start {print $1; exit}')
        if [ -z "$NEXT_FUNC" ]; then
            NEXT_FUNC=$(wc -l < "$FILE")
        fi
        FUNC_LINES=$((NEXT_FUNC - line_no))

        FUNC_NAME=$(echo "$func_line" | rg "pub fn (\w+)" -o --replace '$1')

        if [ "$FUNC_LINES" -gt 100 ]; then
            echo "  ⚠️  $FUNC_NAME() has ~$FUNC_LINES lines (recommended: <100)"
            echo "      Consider splitting into smaller functions"
            ((WARNINGS++)) || true
        fi
    done

    # Count functions
    FUNC_COUNT=$(echo "$LONG_FUNCS" | wc -l | tr -d ' ')
    echo "  ℹ️  Total public functions: $FUNC_COUNT"
else
    echo "  ℹ️  No public functions found"
fi

# Find functions with >5 parameters
COMPLEX_SIGS=$(rg "pub fn \w+\([^)]*,[^)]*,[^)]*,[^)]*,[^)]*," "$FILE" -n || true)
if [ -n "$COMPLEX_SIGS" ]; then
    echo "  ⚠️  Complex function signatures detected (>5 parameters):"
    echo "$COMPLEX_SIGS" | sed 's/^/      /'
    echo "      Consider using a struct or builder pattern"
    ((WARNINGS++)) || true
fi
echo ""

# ============================================================================
# Standard #5: Separate Test Files
# ============================================================================
echo "🧪 Standard #5: Separate Test Files"
echo "────────────────────────────────────────────────────────────────"

if grep -q "#\[cfg(test)\] mod" "$FILE"; then
    echo "  ❌ Inline test module detected"
    echo "     Tests must be in separate _test.rs files"
    echo "     Example: file.rs → file_test.rs"
    ((ERRORS++)) || true
else
    echo "  ✅ No inline test modules"

    # Check if corresponding test file exists
    if [[ "$BASENAME" != "mod.rs" ]] && [[ "$BASENAME" != "lib.rs" ]] && [[ ! "$BASENAME" =~ _test\.rs$ ]]; then
        TEST_FILE="${FILE%.rs}_test.rs"
        if [ -f "$TEST_FILE" ]; then
            echo "  ✅ Test file exists: $(basename "$TEST_FILE")"
        else
            echo "  ⚠️  No test file found (expected: $(basename "$TEST_FILE"))"
            echo "      Create tests for public functions"
            ((WARNINGS++)) || true
        fi
    fi
fi
echo ""

# ============================================================================
# Standard #6: No Swiss Army Functions
# ============================================================================
echo "🔪 Standard #6: No Swiss Army Functions"
echo "────────────────────────────────────────────────────────────────"

# Check for generic function names (red flags)
SWISS=$(rg "pub fn (handle|process|manage|execute)_\w+" "$FILE" || true)
if [ -n "$SWISS" ]; then
    echo "  ⚠️  Generic function names detected (potential Swiss Army patterns):"
    echo "$SWISS" | sed 's/^/      /'
    echo "      Review: Do these functions do too many things?"
    ((WARNINGS++)) || true
else
    echo "  ✅ No obvious Swiss Army patterns detected"
fi

# Check for excessive boolean parameters (red flag)
BOOL_PARAMS=$(rg "pub fn \w+\([^)]*bool[^)]*bool" "$FILE" || true)
if [ -n "$BOOL_PARAMS" ]; then
    echo "  ⚠️  Multiple boolean parameters detected:"
    echo "$BOOL_PARAMS" | sed 's/^/      /'
    echo "      Consider: Separate functions or enum for modes"
    ((WARNINGS++)) || true
fi
echo ""

# ============================================================================
# Standard #7: No Generic Names
# ============================================================================
echo "🏷️  Standard #7: No Generic Names"
echo "────────────────────────────────────────────────────────────────"

# Check for generic function names
GENERIC_FUNCS=$(rg "pub fn (get|set|process|handle|do|make|create|new)\(" "$FILE" || true)
if [ -n "$GENERIC_FUNCS" ]; then
    echo "  ⚠️  Generic function names detected:"
    echo "$GENERIC_FUNCS" | sed 's/^/      /'
    echo "      Review: Are names specific enough?"
    echo "      Better: get_table_by_name() instead of get()"
    ((WARNINGS++)) || true
else
    echo "  ✅ No generic function names detected"
fi

# Check for generic struct names
GENERIC_STRUCTS=$(rg "pub struct (Handler|Manager|Processor|Controller|Service|Helper)" "$FILE" || true)
if [ -n "$GENERIC_STRUCTS" ]; then
    echo "  ⚠️  Generic struct names detected:"
    echo "$GENERIC_STRUCTS" | sed 's/^/      /'
    echo "      Review: Add domain context (e.g., QueryExecutor not Executor)"
    ((WARNINGS++)) || true
else
    echo "  ✅ No generic struct names detected"
fi
echo ""

# ============================================================================
# Standard #8: Architecture - NO MVC
# ============================================================================
echo "🏛️  Standard #8: Architecture (NO MVC)"
echo "────────────────────────────────────────────────────────────────"

# Check for controller patterns (request/response)
CONTROLLER=$(rg "(Request|Response|handle_\w+_request)" "$FILE" || true)
if [ -n "$CONTROLLER" ] && [[ ! "$FILE" =~ bin/ ]]; then
    echo "  ⚠️  Controller pattern detected in lib code:"
    echo "$CONTROLLER" | sed 's/^/      /'
    echo "      ReedBase uses layered architecture, not MVC"
    echo "      Controllers only allowed in bin/ (CLI entry point)"
    ((WARNINGS++)) || true
fi

# Check for model with behaviour (save/load methods)
MODEL_BEHAVIOUR=$(rg "impl.*\{\s*(pub fn (save|load|persist|fetch))" "$FILE" -U || true)
if [ -n "$MODEL_BEHAVIOUR" ]; then
    echo "  ⚠️  Model with behaviour detected:"
    echo "$MODEL_BEHAVIOUR" | sed 's/^/      /'
    echo "      Structs should be pure data, behaviour in separate functions"
    ((WARNINGS++)) || true
fi

# Check for view patterns (Display, format! in lib)
if [[ ! "$FILE" =~ bin/ ]] && [[ ! "$FILE" =~ _test\.rs$ ]]; then
    VIEW=$(rg "(impl.*Display|println!|eprintln!)" "$FILE" || true)
    if [ -n "$VIEW" ]; then
        echo "  ⚠️  View pattern detected in lib code:"
        echo "$VIEW" | sed 's/^/      /'
        echo "      Formatting/output should be in bin/ only"
        ((WARNINGS++)) || true
    fi
fi

# Check if file is in correct layer
DIRNAME=$(dirname "$FILE")
if [[ "$DIRNAME" =~ src/(core|api|store|validate|process|ops) ]]; then
    echo "  ✅ File in correct architecture layer: $DIRNAME"
elif [[ "$DIRNAME" =~ src/bin ]]; then
    echo "  ✅ CLI binary code (formatting allowed)"
elif [[ "$FILE" == "src/lib.rs" ]] || [[ "$FILE" == "src/error.rs" ]]; then
    echo "  ✅ Root module file"
else
    echo "  ⚠️  File not in expected architecture layer: $DIRNAME"
    echo "      Expected: src/{core,api,store,validate,process,ops}/"
    ((WARNINGS++)) || true
fi
echo ""

# ============================================================================
# Summary
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "✅ ALL CHECKS PASSED"
    echo ""
    echo "File is fully compliant with all CLAUDE.md standards."
    echo "Ready for commit."
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo "⚠️  WARNINGS: $WARNINGS"
    echo ""
    echo "No critical errors, but please review warnings."
    echo "Manual review recommended before commit."
    exit 0
else
    echo "❌ ERRORS: $ERRORS"
    echo "⚠️  WARNINGS: $WARNINGS"
    echo ""
    echo "Critical errors must be fixed before commit."
    exit 1
fi
