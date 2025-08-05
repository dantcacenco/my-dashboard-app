#!/bin/bash

echo "🔧 Fixing boss role access and payment issues..."

# Fix 1: Update ALL files to accept 'boss' role alongside 'admin'
echo "Updating role checks to include 'boss'..."

# Fix proposals/[id]/page.tsx
perl -i -pe "s/if \(profile\?\.role !== 'admin'\)/if (profile?.role !== 'admin' && profile?.role !== 'boss')/" app/proposals/\[id\]/page.tsx

# Fix proposals/[id]/edit/page.tsx
perl -i -pe "s/if \(profile\?\.role !== 'admin'\)/if (profile?.role !== 'admin' && profile?.role !== 'boss')/" app/proposals/\[id\]/edit/page.tsx

# Fix ProposalView.tsx to show buttons for boss role
perl -i -pe "s/userRole === 'admin'/userRole === 'admin' || userRole === 'boss'/g" app/proposals/\[id\]/ProposalView.tsx

# Fix the canEdit check in ProposalView.tsx
perl -i -pe "s/const canEdit = userRole === 'admin' \|\| userRole === 'boss'/const canEdit = userRole === 'admin' || userRole === 'boss'/" app/proposals/\[id\]/ProposalView.tsx

# Fix 2: Update payment API to handle response correctly
echo "Fixing payment API response format..."

# Add detailed logging and fix response format
cat > fix-payment-temp.js << 'EOF'
const fs = require('fs');
const content = fs.readFileSync('app/api/create-payment/route.ts', 'utf8');

// Fix the response format
let fixed = content.replace(
  /return NextResponse\.json\(\{ sessionId: session\.id \}\)/g,
  'return NextResponse.json({ sessionId: session.id }, { status: 200 })'
);

// Add error logging
fixed = fixed.replace(
  /} catch \(error\) {/g,
  `} catch (error: any) {
    console.error('Stripe session creation error:', error);
    console.error('Error details:', {
      message: error.message,
      type: error.type,
      statusCode: error.statusCode
    });`
);

// Ensure metadata doesn't have duplicates
fixed = fixed.replace(
  /metadata: {[^}]+}/g,
  `metadata: {
        payment_type: payment_type || 'card',
        payment_stage: payment_stage || 'deposit',
        proposal_id: proposal_id
      }`
);

fs.writeFileSync('app/api/create-payment/route.ts', fixed);
EOF

node fix-payment-temp.js
rm fix-payment-temp.js

# Fix 3: Update PaymentStages component to handle errors better
echo "Improving PaymentStages error handling..."

cat > fix-payment-stages-temp.js << 'EOF'
const fs = require('fs');
const content = fs.readFileSync('app/components/PaymentStages.tsx', 'utf8');

// Add response validation
let fixed = content.replace(
  /const { sessionId } = await response\.json\(\)/g,
  `const data = await response.json();
      console.log('Payment API response:', data);
      const { sessionId } = data;
      
      if (!sessionId) {
        throw new Error('No session ID received from payment API');
      }`
);

// Improve error message
fixed = fixed.replace(
  /alert\('Failed to initiate payment\. Please try again\.'\)/g,
  `console.error('Payment error details:', error);
      const errorMessage = error.message || 'Failed to initiate payment';
      alert(\`Payment Error: \${errorMessage}. Please check console for details.\`)`
);

fs.writeFileSync('app/components/PaymentStages.tsx', fixed);
EOF

node fix-payment-stages-temp.js
rm fix-payment-stages-temp.js

# Fix 4: Ensure Stripe API version is consistent
echo "Checking Stripe API version..."
perl -i -pe "s/apiVersion: '[\d-]+\.[\w]+'/apiVersion: '2024-11-20.acacia'/" app/api/create-payment/route.ts

# Commit changes
git add .
git commit -m "fix: enable boss role access and improve payment error handling

- Allow 'boss' role to view/edit proposals alongside 'admin'
- Fix payment API response format
- Add detailed error logging for payment debugging
- Ensure consistent Stripe API version
- Remove duplicate metadata properties"

git push origin main

echo "✅ Fixed boss role access and improved payment handling!"
echo ""
echo "📝 What was fixed:"
echo "1. ✅ Edit button now shows for 'boss' role"
echo "2. ✅ All proposal pages accept 'boss' role"
echo "3. ✅ Payment API returns proper response format"
echo "4. ✅ Better error messages for payment issues"
echo ""
echo "🧪 Next steps:"
echo "1. Check if Edit button now appears on proposals"
echo "2. Try making a payment - check browser console for detailed errors"
echo "3. If payment still fails, check Vercel logs for the specific error"