#!/bin/bash
echo "🔧 Fixing all Stripe API versions in the project..."

# Fix all files that might contain Stripe API version
echo "Checking all TypeScript files for Stripe API version..."

# Use grep to find files and sed to replace
grep -r "2024-11-20.acacia" --include="*.ts" --include="*.tsx" . 2>/dev/null | cut -d: -f1 | sort -u | while read -r file; do
    echo "Updating: $file"
    sed -i.bak 's/2024-11-20\.acacia/2025-07-30.basil/g' "$file"
    rm "${file}.bak"
done

# Also check for any other Stripe API version patterns
grep -r "apiVersion.*2024" --include="*.ts" --include="*.tsx" . 2>/dev/null | cut -d: -f1 | sort -u | while read -r file; do
    echo "Found potential Stripe version in: $file"
done

# Specifically update the create-payment route just to be sure
if [ -f "app/api/create-payment/route.ts" ]; then
    echo "Specifically updating app/api/create-payment/route.ts"
    sed -i 's/apiVersion: .*/apiVersion: '\''2025-07-30.basil'\''/' app/api/create-payment/route.ts
fi

# Also check payment-success page
if [ -f "app/proposal/payment-success/page.tsx" ]; then
    echo "Checking app/proposal/payment-success/page.tsx"
    sed -i 's/apiVersion: .*/apiVersion: '\''2025-07-30.basil'\''/' app/proposal/payment-success/page.tsx
fi

# Show what changed
echo ""
echo "Changes made:"
git diff --name-only

# Commit and push
git add -A
git commit -m "fix: update all Stripe API versions to 2025-07-30.basil"
git push origin main

echo "✅ All Stripe API versions should now be updated!"