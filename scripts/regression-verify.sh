#!/usr/bin/env bash
# Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
# SPDX-License-Identifier: Apache-2.0

# Regression verification for entire module
# Verifies that new implementation has identical behaviour to old

set -e

MODULE=$1

if [ -z "$MODULE" ]; then
    echo "Usage: $0 <module>"
    echo ""
    echo "Example: $0 core"
    echo "Example: $0 store/btree"
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔄 Regression Verification: $MODULE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

PASS=0
FAIL=0
SKIP=0

# ============================================================================
# Step 1: Test Results Comparison
# ============================================================================
echo "📋 Step 1: Test Results Comparison"
echo "────────────────────────────────────────────────────────────────"

if [ -d "last/src/$MODULE" ] && [ -d "current/src/$MODULE" ]; then
    echo "Running tests for last/src/$MODULE..."
    OLD_TEST_OUTPUT=$(cargo test -p reedbase-last --lib ${MODULE/\//:} 2>&1 || true)
    OLD_PASS=$(echo "$OLD_TEST_OUTPUT" | grep -oP '\d+(?= passed)' | head -1 || echo "0")
    OLD_FAIL=$(echo "$OLD_TEST_OUTPUT" | grep -oP '\d+(?= failed)' | head -1 || echo "0")

    echo "Old: $OLD_PASS passed, $OLD_FAIL failed"

    echo "Running tests for current/src/$MODULE..."
    NEW_TEST_OUTPUT=$(cargo test -p reedbase --lib ${MODULE/\//:} 2>&1 || true)
    NEW_PASS=$(echo "$NEW_TEST_OUTPUT" | grep -oP '\d+(?= passed)' | head -1 || echo "0")
    NEW_FAIL=$(echo "$NEW_TEST_OUTPUT" | grep -oP '\d+(?= failed)' | head -1 || echo "0")

    echo "New: $NEW_PASS passed, $NEW_FAIL failed"

    if [ "$NEW_PASS" -ge "$OLD_PASS" ] && [ "$NEW_FAIL" -eq 0 ]; then
        echo "✅ All tests passing (old: $OLD_PASS, new: $NEW_PASS)"
        ((PASS++))
    else
        echo "❌ Test regression detected!"
        echo "   Old had $OLD_PASS passing, new has $NEW_PASS passing"
        ((FAIL++))
    fi
else
    if [ ! -d "last/src/$MODULE" ]; then
        echo "⚠️  last/src/$MODULE not found (new module?)"
    fi
    if [ ! -d "current/src/$MODULE" ]; then
        echo "⚠️  current/src/$MODULE not found (not yet implemented?)"
    fi
    ((SKIP++))
fi
echo ""

# ============================================================================
# Step 2: Public API Comparison
# ============================================================================
echo "📋 Step 2: Public API Comparison"
echo "────────────────────────────────────────────────────────────────"

if [ -d "last/src/$MODULE" ] && [ -d "current/src/$MODULE" ]; then
    OLD_API=$(rg "^pub fn \w+" last/src/$MODULE/ -o --no-filename 2>/dev/null | sort | uniq || echo "")
    NEW_API=$(rg "^pub fn \w+" current/src/$MODULE/ -o --no-filename 2>/dev/null | sort | uniq || echo "")

    OLD_COUNT=$(echo "$OLD_API" | grep -c "pub fn" || echo "0")
    NEW_COUNT=$(echo "$NEW_API" | grep -c "pub fn" || echo "0")

    echo "Old: $OLD_COUNT public functions"
    echo "New: $NEW_COUNT public functions"

    if [ "$OLD_API" == "$NEW_API" ]; then
        echo "✅ Public API identical"
        ((PASS++))
    else
        echo "⚠️  Public API differences detected:"
        echo ""

        # Functions only in old
        ONLY_OLD=$(comm -23 <(echo "$OLD_API") <(echo "$NEW_API"))
        if [ -n "$ONLY_OLD" ]; then
            echo "  ❌ Missing in new implementation:"
            echo "$ONLY_OLD" | sed 's/^/      /'
            ((FAIL++))
        fi

        # Functions only in new
        ONLY_NEW=$(comm -13 <(echo "$OLD_API") <(echo "$NEW_API"))
        if [ -n "$ONLY_NEW" ]; then
            echo "  ℹ️  New functions (not in old):"
            echo "$ONLY_NEW" | sed 's/^/      /'
            echo "     Review: Are these intentional additions?"
        fi

        if [ -z "$ONLY_OLD" ]; then
            echo "  ✅ All old functions present in new"
            ((PASS++))
        fi
    fi
else
    echo "⚠️  Cannot compare (missing last/ or current/)"
    ((SKIP++))
fi
echo ""

# ============================================================================
# Step 3: Documentation Coverage
# ============================================================================
echo "📋 Step 3: Documentation Coverage"
echo "────────────────────────────────────────────────────────────────"

if [ -d "last/src/$MODULE" ] && [ -d "current/src/$MODULE" ]; then
    OLD_DOCS=$(rg "^///|^//!" last/src/$MODULE/ 2>/dev/null | wc -l || echo "0")
    NEW_DOCS=$(rg "^///|^//!" current/src/$MODULE/ 2>/dev/null | wc -l || echo "0")

    OLD_DOCS=$(echo "$OLD_DOCS" | tr -d ' ')
    NEW_DOCS=$(echo "$NEW_DOCS" | tr -d ' ')

    echo "Old documentation lines: $OLD_DOCS"
    echo "New documentation lines: $NEW_DOCS"

    if [ "$NEW_DOCS" -ge "$OLD_DOCS" ]; then
        echo "✅ Documentation maintained or improved"
        ((PASS++))
    else
        DIFF=$((OLD_DOCS - NEW_DOCS))
        echo "⚠️  Documentation decreased by $DIFF lines"
        echo "    Ensure all public functions are documented"
        ((FAIL++))
    fi
else
    echo "⚠️  Cannot compare documentation"
    ((SKIP++))
fi
echo ""

# ============================================================================
# Step 4: Type Definitions Check
# ============================================================================
echo "📋 Step 4: Type Definitions Check"
echo "────────────────────────────────────────────────────────────────"

if [ -d "last/src/$MODULE" ] && [ -d "current/src/$MODULE" ]; then
    OLD_STRUCTS=$(rg "^pub struct \w+" last/src/$MODULE/ -o --no-filename 2>/dev/null | sort || echo "")
    NEW_STRUCTS=$(rg "^pub struct \w+" current/src/$MODULE/ -o --no-filename 2>/dev/null | sort || echo "")

    OLD_ENUMS=$(rg "^pub enum \w+" last/src/$MODULE/ -o --no-filename 2>/dev/null | sort || echo "")
    NEW_ENUMS=$(rg "^pub enum \w+" current/src/$MODULE/ -o --no-filename 2>/dev/null | sort || echo "")

    STRUCTS_MATCH="yes"
    ENUMS_MATCH="yes"

    if [ "$OLD_STRUCTS" != "$NEW_STRUCTS" ]; then
        STRUCTS_MATCH="no"
        MISSING_STRUCTS=$(comm -23 <(echo "$OLD_STRUCTS") <(echo "$NEW_STRUCTS"))
        if [ -n "$MISSING_STRUCTS" ]; then
            echo "  ⚠️  Structs missing in new:"
            echo "$MISSING_STRUCTS" | sed 's/^/      /'
        fi
    fi

    if [ "$OLD_ENUMS" != "$NEW_ENUMS" ]; then
        ENUMS_MATCH="no"
        MISSING_ENUMS=$(comm -23 <(echo "$OLD_ENUMS") <(echo "$NEW_ENUMS"))
        if [ -n "$MISSING_ENUMS" ]; then
            echo "  ⚠️  Enums missing in new:"
            echo "$MISSING_ENUMS" | sed 's/^/      /'
        fi
    fi

    if [ "$STRUCTS_MATCH" == "yes" ] && [ "$ENUMS_MATCH" == "yes" ]; then
        echo "✅ Type definitions match"
        ((PASS++))
    else
        echo "⚠️  Type definition differences detected"
        echo "    Review: Are these intentional API changes?"
        ((FAIL++))
    fi
else
    echo "⚠️  Cannot compare type definitions"
    ((SKIP++))
fi
echo ""

# ============================================================================
# Step 5: Test File Presence
# ============================================================================
echo "📋 Step 5: Test File Presence"
echo "────────────────────────────────────────────────────────────────"

if [ -d "last/src/$MODULE" ] && [ -d "current/src/$MODULE" ]; then
    OLD_TEST_FILES=$(find last/src/$MODULE -name "*_test.rs" -o -name "*test.rs" | wc -l)
    NEW_TEST_FILES=$(find current/src/$MODULE -name "*_test.rs" -o -name "*test.rs" | wc -l)

    OLD_TEST_FILES=$(echo "$OLD_TEST_FILES" | tr -d ' ')
    NEW_TEST_FILES=$(echo "$NEW_TEST_FILES" | tr -d ' ')

    echo "Old: $OLD_TEST_FILES test files"
    echo "New: $NEW_TEST_FILES test files"

    if [ "$NEW_TEST_FILES" -ge "$OLD_TEST_FILES" ]; then
        echo "✅ Test coverage maintained ($NEW_TEST_FILES files)"
        ((PASS++))
    else
        DIFF=$((OLD_TEST_FILES - NEW_TEST_FILES))
        echo "❌ Missing $DIFF test files in new implementation"
        ((FAIL++))
    fi
else
    echo "⚠️  Cannot compare test files"
    ((SKIP++))
fi
echo ""

# ============================================================================
# Summary
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Regression Verification Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Passed:  $PASS checks"
echo "❌ Failed:  $FAIL checks"
echo "⚠️  Skipped: $SKIP checks"
echo ""

TOTAL=$((PASS + FAIL))
if [ "$TOTAL" -gt 0 ]; then
    PERCENT=$((PASS * 100 / TOTAL))
    echo "Pass Rate: $PERCENT%"
    echo ""
fi

if [ "$FAIL" -eq 0 ]; then
    if [ "$PASS" -eq 0 ]; then
        echo "⚠️  NO CHECKS PERFORMED"
        echo ""
        echo "Module $MODULE could not be verified (missing src or src-old)"
        exit 2
    else
        echo "✅ REGRESSION CHECK PASSED"
        echo ""
        echo "Module $MODULE maintains behaviour compatibility with last/src/"
        exit 0
    fi
else
    echo "❌ REGRESSION CHECK FAILED"
    echo ""
    echo "Module $MODULE has $FAIL failing regression checks."
    echo ""
    echo "Required actions:"
    echo "1. Review differences listed above"
    echo "2. Fix missing functions/tests OR"
    echo "3. Document intentional changes in MIGRATION.md"
    exit 1
fi
