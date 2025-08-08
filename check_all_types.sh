#!/bin/bash

echo "🔍 Running COMPREHENSIVE type checking..."
echo "=================================="

# First, check for basic TypeScript errors
echo "📋 TypeScript Compiler Check:"
npx tsc --noEmit 2>&1 | tee full_typescript_check.log

# Count different types of errors
TOTAL_ERRORS=$(grep -c "error TS" full_typescript_check.log 2>/dev/null || echo "0")
PARAM_ERRORS=$(grep -c "params.*Promise" full_typescript_check.log 2>/dev/null || echo "0")
SEARCH_PARAM_ERRORS=$(grep -c "searchParams.*Promise" full_typescript_check.log 2>/dev/null || echo "0")
MODULE_ERRORS=$(grep -c "Cannot find module\|Module not found" full_typescript_check.log 2>/dev/null || echo "0")

echo ""
echo "📊 Error Summary:"
echo "- Total TypeScript errors: $TOTAL_ERRORS"
echo "- Params type errors: $PARAM_ERRORS"
echo "- SearchParams type errors: $SEARCH_PARAM_ERRORS"
echo "- Missing module errors: $MODULE_ERRORS"

if [ "$TOTAL_ERRORS" -gt 0 ]; then
    echo ""
    echo "❌ Detailed errors:"
    echo "=================================="
    grep -A 2 "error TS" full_typescript_check.log | head -100
fi

# Check for Next.js 15 specific patterns
echo ""
echo "🔍 Checking Next.js 15 patterns..."
echo "Pages with params:"
find app -name "page.tsx" -exec grep -l "params.*:" {} \; | while read file; do
    if ! grep -q "params.*Promise" "$file"; then
        echo "⚠️  $file may need async params"
    fi
done

echo ""
echo "Pages with searchParams:"
find app -name "page.tsx" -exec grep -l "searchParams.*:" {} \; | while read file; do
    if ! grep -q "searchParams.*Promise" "$file"; then
        echo "⚠️  $file may need async searchParams"
    fi
done

# Clean up
rm -f full_typescript_check.log

echo ""
echo "✅ Type check complete!"
