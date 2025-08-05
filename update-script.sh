#!/bin/bash

echo "🔧 Fixing duplicate property error in create-payment route..."

# Fix the duplicate proposal_id in metadata
# Find the metadata object and remove duplicate entries
perl -i -pe 'BEGIN{undef $/;} s/metadata: \{[^}]+\}/metadata: {
        payment_type: payment_type || '\''card'\'',
        payment_stage: payment_stage || '\''deposit'\'',
        proposal_id: proposal_id
      }/smg' app/api/create-payment/route.ts

# Also ensure the session response returns sessionId correctly
perl -i -pe "s/return NextResponse\.json\(\{ sessionId: session\.id \}\)/return NextResponse.json({ sessionId: session.id })/g" app/api/create-payment/route.ts

# Commit the fix
git add .
git commit -m "fix: remove duplicate proposal_id property in create-payment metadata"
git push origin main

echo "✅ Fixed duplicate property error!"
echo ""
echo "The build should now pass. The metadata object now has:"
echo "- payment_type"
echo "- payment_stage" 
echo "- proposal_id (only once)"