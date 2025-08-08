#!/bin/bash

echo "🔍 Running comprehensive type checks..."

# Run TypeScript compiler
echo "📋 Running TypeScript compiler..."
npx tsc --noEmit 2>&1 | tee typescript_errors.log

# Count errors
ERROR_COUNT=$(grep -c "error TS" typescript_errors.log 2>/dev/null || echo "0")

if [ "$ERROR_COUNT" -gt 0 ]; then
    echo "❌ Found $ERROR_COUNT TypeScript errors:"
    echo "=================================="
    grep -A 2 "error TS" typescript_errors.log | head -50
    echo "=================================="
    
    # Check for specific Next.js 15 params errors
    if grep -q "Type.*params.*Promise" typescript_errors.log; then
        echo "⚠️  Found Next.js 15 params errors - these need async handling"
    fi
    
    # Check for missing props errors
    if grep -q "Property.*is missing in type" typescript_errors.log; then
        echo "⚠️  Found missing props errors"
    fi
else
    echo "✅ No TypeScript errors found!"
fi

# Clean up
rm -f typescript_errors.log

# Run build check (quick version)
echo ""
echo "🏗️  Running quick build check..."
timeout 30 npm run build 2>&1 | head -50 || true

echo ""
echo "✅ Type check complete!"
echo "Total errors: $ERROR_COUNT"
