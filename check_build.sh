#!/bin/bash

# Local Build and Syntax Checker for Service Pro
# Run this before pushing to save time!

set -e

echo "🔍 Service Pro Local Build Checker"
echo "================================="

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "❌ Error: package.json not found. Are you in the project root?"
    exit 1
fi

# 1. TypeScript syntax check
echo ""
echo "📝 Checking TypeScript syntax..."
if npx tsc --noEmit; then
    echo "✅ TypeScript syntax check passed!"
else
    echo "❌ TypeScript errors found. Fix them before pushing."
    exit 1
fi

# 2. ESLint check (if configured)
if [ -f ".eslintrc.json" ] || [ -f ".eslintrc.js" ]; then
    echo ""
    echo "🔍 Running ESLint..."
    if npm run lint; then
        echo "✅ ESLint check passed!"
    else
        echo "❌ ESLint errors found. Fix them before pushing."
        exit 1
    fi
fi

# 3. Check for required environment variables
echo ""
echo "🔐 Checking environment variables..."
ENV_VARS=(
    "NEXT_PUBLIC_SUPABASE_URL"
    "NEXT_PUBLIC_SUPABASE_ANON_KEY"
    "SUPABASE_SERVICE_ROLE_KEY"
    "NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY"
    "STRIPE_SECRET_KEY"
    "NEXT_PUBLIC_BASE_URL"
)

MISSING_VARS=()
for var in "${ENV_VARS[@]}"; do
    if [ -z "${!var}" ] && ! grep -q "^$var=" .env.local 2>/dev/null; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    echo "⚠️  Warning: Missing environment variables in .env.local:"
    printf '   - %s\n' "${MISSING_VARS[@]}"
    echo "   Make sure these are set in Vercel!"
else
    echo "✅ All required environment variables found!"
fi

# 4. Next.js build check
echo ""
echo "🏗️  Running Next.js build (this may take a minute)..."
if npm run build; then
    echo "✅ Build successful!"
else
    echo "❌ Build failed. Fix errors before pushing."
    exit 1
fi

# 5. Check for common issues
echo ""
echo "🔍 Checking for common issues..."

# Check for console.log statements (optional)
CONSOLE_LOGS=$(grep -r "console\.log" --include="*.tsx" --include="*.ts" app/ components/ lib/ 2>/dev/null | wc -l)
if [ $CONSOLE_LOGS -gt 0 ]; then
    echo "⚠️  Found $CONSOLE_LOGS console.log statements. Consider removing for production."
fi

# Check for TODO comments
TODOS=$(grep -r "TODO" --include="*.tsx" --include="*.ts" app/ components/ lib/ 2>/dev/null | wc -l)
if [ $TODOS -gt 0 ]; then
    echo "📝 Found $TODOS TODO comments."
fi

echo ""
echo "✨ All checks complete! Safe to push to GitHub."
echo ""
echo "Quick push command:"
echo "  git add . && git commit -m 'your message' && git push origin main"
echo ""
