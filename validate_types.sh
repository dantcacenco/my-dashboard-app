#!/bin/bash

echo "🔍 TYPE VALIDATION SYSTEM"
echo "========================"

# Check for type mismatches
echo "📋 Checking component prop usage..."

# Find all component usage and verify props
find app -name "*.tsx" -o -name "*.ts" | while read file; do
    # Skip type definition files
    if [[ "$file" == *"types/index.ts"* ]]; then
        continue
    fi
    
    # Check for component usage with wrong props
    if grep -q "PaymentSuccessView" "$file" 2>/dev/null; then
        echo "Checking PaymentSuccessView usage in: $file"
        grep -A 5 -B 5 "PaymentSuccessView" "$file" || true
    fi
done

# Run TypeScript check with detailed output
echo ""
echo "📋 Running TypeScript validation..."
npx tsc --noEmit --pretty 2>&1 | tee type_validation.log

# Analyze specific error patterns
echo ""
echo "📊 Error Analysis:"
if grep -q "Type.*is missing.*properties" type_validation.log 2>/dev/null; then
    echo "❌ Found missing property errors:"
    grep -A 2 "Type.*is missing.*properties" type_validation.log
fi

if grep -q "Type.*is not assignable" type_validation.log 2>/dev/null; then
    echo "❌ Found type assignment errors:"
    grep -A 2 "Type.*is not assignable" type_validation.log
fi

# Clean up
rm -f type_validation.log

echo ""
echo "✅ Type validation complete!"
