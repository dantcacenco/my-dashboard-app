#!/bin/bash

# Local Syntax Checker for Service Pro (No Supabase Required)
# Checks TypeScript without running full Next.js build

echo "🔍 Service Pro Quick Syntax Checker"
echo "===================================="
echo "Note: Skipping full build check (Supabase not required locally)"
echo ""

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "❌ Error: package.json not found. Are you in the project root?"
    exit 1
fi

# Clean .next directory to avoid stale type errors
echo "🧹 Cleaning build artifacts..."
rm -rf .next

# 1. TypeScript syntax check ONLY
echo ""
echo "📝 Checking TypeScript syntax..."

# Create a temporary tsconfig for checking that excludes .next completely
cat > tsconfig.check.json << 'EOFINNER'
{
  "extends": "./tsconfig.json",
  "exclude": ["node_modules", ".next", "dist", "build"],
  "include": ["app/**/*", "components/**/*", "lib/**/*", "*.ts", "*.tsx"]
}
EOFINNER

# Run TypeScript check with the temporary config
if npx tsc --noEmit -p tsconfig.check.json; then
    echo "✅ TypeScript syntax check passed!"
    rm tsconfig.check.json
else
    echo "❌ TypeScript errors found. Fix them before pushing."
    rm tsconfig.check.json
    exit 1
fi

# 2. ESLint check (if configured)
if [ -f ".eslintrc.json" ] || [ -f ".eslintrc.js" ]; then
    echo ""
    echo "🔍 Running ESLint..."
    if npm run lint 2>/dev/null; then
        echo "✅ ESLint check passed!"
    else
        echo "⚠️  ESLint warnings (not blocking)"
    fi
fi

# 3. Environment variable info (just informational)
echo ""
echo "📋 Environment Status:"
if [ -f ".env.local" ]; then
    echo "✅ .env.local file found"
else
    echo "ℹ️  No .env.local file (OK - Vercel has the env vars)"
fi

# 4. Check for common issues
echo ""
echo "🔍 Quick code quality check..."

# Count console.logs
if [ -d "app" ]; then
    CONSOLE_LOGS=$(find app components lib -name "*.ts" -o -name "*.tsx" 2>/dev/null | xargs grep "console\.log" 2>/dev/null | wc -l || echo "0")
    if [ "$CONSOLE_LOGS" -gt 10 ]; then
        echo "⚠️  Found $CONSOLE_LOGS console.log statements"
    fi
fi

echo ""
echo "✨ TypeScript check complete!"
echo "   (Skipped full build - Vercel will handle that)"
echo ""
