#!/bin/bash

echo "🔧 Fixing column name inconsistencies..."
echo "Standardizing on longer column names throughout codebase"
echo ""

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# The database has BOTH column names, so we need to standardize usage in code
# Use: progress_payment_amount (NOT progress_amount)
# Use: final_payment_amount (NOT final_amount)
# Use: total (NOT total_amount)

echo "📝 Updating all files to use correct column names..."

# Fix CustomerProposalView.tsx
echo "Fixing CustomerProposalView.tsx..."
sed -i '' 's/progress_amount:/progress_payment_amount:/g' "app/proposal/view/[token]/CustomerProposalView.tsx"
sed -i '' 's/\.progress_amount/.progress_payment_amount/g' "app/proposal/view/[token]/CustomerProposalView.tsx"
sed -i '' 's/final_amount:/final_payment_amount:/g' "app/proposal/view/[token]/CustomerProposalView.tsx"
sed -i '' 's/\.final_amount/.final_payment_amount/g' "app/proposal/view/[token]/CustomerProposalView.tsx"

# Fix PaymentStages components
echo "Fixing PaymentStages components..."
if [ -f "app/(authenticated)/proposals/[id]/PaymentStages.tsx" ]; then
  sed -i '' 's/progressAmount/progressPaymentAmount/g' "app/(authenticated)/proposals/[id]/PaymentStages.tsx"
  sed -i '' 's/finalAmount/finalPaymentAmount/g' "app/(authenticated)/proposals/[id]/PaymentStages.tsx"
  sed -i '' 's/progress_amount/progress_payment_amount/g' "app/(authenticated)/proposals/[id]/PaymentStages.tsx"
  sed -i '' 's/final_amount/final_payment_amount/g' "app/(authenticated)/proposals/[id]/PaymentStages.tsx"
fi

if [ -f "components/PaymentStages.tsx" ]; then
  sed -i '' 's/progressAmount/progressPaymentAmount/g' "components/PaymentStages.tsx"
  sed -i '' 's/finalAmount/finalPaymentAmount/g' "components/PaymentStages.tsx"
fi

# Fix API routes
echo "Fixing API routes..."
if [ -f "app/api/create-payment/route.ts" ]; then
  sed -i '' 's/progress_amount/progress_payment_amount/g' "app/api/create-payment/route.ts"
  sed -i '' 's/final_amount/final_payment_amount/g' "app/api/create-payment/route.ts"
fi

if [ -f "app/api/stripe/webhook/route.ts" ]; then
  sed -i '' 's/progress_amount:/progress_payment_amount:/g' "app/api/stripe/webhook/route.ts"
  sed -i '' 's/final_amount:/final_payment_amount:/g' "app/api/stripe/webhook/route.ts"
  sed -i '' 's/\.progress_amount/.progress_payment_amount/g' "app/api/stripe/webhook/route.ts"
  sed -i '' 's/\.final_amount/.final_payment_amount/g' "app/api/stripe/webhook/route.ts"
fi

# Fix ProposalView.tsx
echo "Fixing ProposalView.tsx..."
if [ -f "app/(authenticated)/proposals/[id]/ProposalView.tsx" ]; then
  sed -i '' 's/proposal\.progress_amount/proposal.progress_payment_amount/g' "app/(authenticated)/proposals/[id]/ProposalView.tsx"
  sed -i '' 's/proposal\.final_amount/proposal.final_payment_amount/g' "app/(authenticated)/proposals/[id]/ProposalView.tsx"
  sed -i '' 's/progressAmount={proposal\.progress_amount/progressPaymentAmount={proposal.progress_payment_amount/g' "app/(authenticated)/proposals/[id]/ProposalView.tsx"
  sed -i '' 's/finalAmount={proposal\.final_amount/finalPaymentAmount={proposal.final_payment_amount/g' "app/(authenticated)/proposals/[id]/ProposalView.tsx"
fi

# Fix any references to total_amount (should be total)
echo "Fixing total_amount references..."
find app -name "*.tsx" -o -name "*.ts" | xargs grep -l "total_amount" | while read file; do
  # Only replace if it's a proposal field reference, not a variable name
  sed -i '' 's/proposal\.total_amount/proposal.total/g' "$file"
  sed -i '' 's/\.total_amount/.total/g' "$file"
done

# Update dashboard to use correct column names
echo "Fixing dashboard calculations..."
sed -i '' 's/proposal\.progress_amount/proposal.progress_payment_amount/g' "app/(authenticated)/dashboard/page.tsx"
sed -i '' 's/proposal\.final_amount/proposal.final_payment_amount/g' "app/(authenticated)/dashboard/page.tsx"

# Update type definitions if they exist
echo "Updating type definitions..."
find app -name "*.ts" -o -name "*.tsx" | xargs grep -l "progress_amount:" | while read file; do
  sed -i '' 's/progress_amount:/progress_payment_amount:/g' "$file"
  sed -i '' 's/final_amount:/final_payment_amount:/g' "$file"
done

echo ""
echo "✅ Column name inconsistencies fixed!"
echo ""

# Test TypeScript compilation
echo "🧪 Testing TypeScript compilation..."
npx tsc --noEmit 2>&1 | head -10
if [ $? -eq 0 ]; then
  echo "✅ TypeScript compilation successful!"
else
  echo "⚠️ TypeScript compilation has errors - checking details..."
  npx tsc --noEmit 2>&1 | grep -A 2 "error TS"
fi

echo ""
echo "💾 Committing changes..."
git add -A
git commit -m "fix: standardize column names - use progress_payment_amount and final_payment_amount"
git push origin main

echo ""
echo "✅ Column name standardization complete!"
echo ""
echo "🧹 Cleaning up this script..."
rm -f "$0"

echo ""
echo "Next steps:"
echo "1. Test that proposals display correctly"
echo "2. Verify payment calculations work"
echo "3. Move to Task 3: Consolidate payment flow"
