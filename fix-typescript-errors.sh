#!/bin/bash

echo "🔧 Fixing TypeScript errors from column name changes..."
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Fix ProposalView.tsx - change progressAmount to progressPaymentAmount
echo "Fixing ProposalView.tsx prop names..."
sed -i '' 's/progressAmount={proposal\.progress_payment_amount/progressPaymentAmount={proposal.progress_payment_amount/g' "app/(authenticated)/proposals/[id]/ProposalView.tsx"
sed -i '' 's/finalAmount={proposal\.final_payment_amount/finalPaymentAmount={proposal.final_payment_amount/g' "app/(authenticated)/proposals/[id]/ProposalView.tsx"

# Fix PaymentStages.tsx interface
echo "Fixing PaymentStages.tsx interface..."
sed -i '' 's/progressAmount:/progressPaymentAmount:/g' "app/(authenticated)/proposals/[id]/PaymentStages.tsx"
sed -i '' 's/finalAmount:/finalPaymentAmount:/g' "app/(authenticated)/proposals/[id]/PaymentStages.tsx"
sed -i '' 's/progressAmount,/progressPaymentAmount,/g' "app/(authenticated)/proposals/[id]/PaymentStages.tsx"
sed -i '' 's/finalAmount,/finalPaymentAmount,/g' "app/(authenticated)/proposals/[id]/PaymentStages.tsx"
sed -i '' 's/finalAmount}/finalPaymentAmount}/g' "app/(authenticated)/proposals/[id]/PaymentStages.tsx"
sed -i '' 's/{progressAmount}/{progressPaymentAmount}/g' "app/(authenticated)/proposals/[id]/PaymentStages.tsx"
sed -i '' 's/{finalAmount}/{finalPaymentAmount}/g' "app/(authenticated)/proposals/[id]/PaymentStages.tsx"
sed -i '' 's/amount: progressAmount/amount: progressPaymentAmount/g' "app/(authenticated)/proposals/[id]/PaymentStages.tsx"
sed -i '' 's/amount: finalAmount/amount: finalPaymentAmount/g' "app/(authenticated)/proposals/[id]/PaymentStages.tsx"

# Fix types/index.ts - remove duplicate lines
echo "Fixing duplicate type definitions..."
# Create a temporary file with deduplicated content
cat app/types/index.ts | awk '
  /progress_payment_amount: number$/ { if (!seen1++) print; next }
  /final_payment_amount: number$/ { if (!seen2++) print; next }
  { print }
' > app/types/index.ts.tmp
mv app/types/index.ts.tmp app/types/index.ts

echo ""
echo "🧪 Testing TypeScript compilation..."
npx tsc --noEmit
if [ $? -eq 0 ]; then
  echo "✅ TypeScript compilation successful!"
else
  echo "⚠️ Still have TypeScript errors, checking..."
  npx tsc --noEmit 2>&1 | head -20
fi

echo ""
echo "💾 Committing fixes..."
git add -A
git commit -m "fix: resolve TypeScript errors from column name changes"
git push origin main

echo ""
echo "✅ TypeScript fixes complete!"
rm -f "$0"
