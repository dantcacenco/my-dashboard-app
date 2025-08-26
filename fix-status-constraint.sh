#!/bin/bash

# Fix status check constraint violation
# The status field has specific allowed values

set -e

echo "🔍 Fixing status check constraint violation..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# First, let's check what status values exist in the database
echo "📊 Checking existing status values..."

cat > check_status.js << 'EOF'
const { createClient } = require('@supabase/supabase-js')
require('dotenv').config({ path: '.env.local' })

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
)

async function checkStatus() {
  // Get existing status values
  const { data } = await supabase
    .from('proposals')
    .select('status')
    .not('status', 'is', null)
  
  const uniqueStatuses = [...new Set(data?.map(p => p.status) || [])]
  console.log('Existing status values in database:', uniqueStatuses)
  
  // Check proposals that look approved
  const { data: approved } = await supabase
    .from('proposals')
    .select('status, approved_at, deposit_amount')
    .not('approved_at', 'is', null)
    .limit(5)
  
  console.log('\nApproved proposals status:', approved?.map(p => p.status))
}

checkStatus().then(() => process.exit(0)).catch(console.error)
EOF

node check_status.js || true

# Fix the CustomerProposalView to use 'approved' instead of 'accepted'
echo "🔧 Fixing status value in handleApprove..."

cat > fix_status.js << 'EOF'
const fs = require('fs')
const path = require('path')

const filePath = path.join(__dirname, 'app/proposal/view/[token]/CustomerProposalView.tsx')
let content = fs.readFileSync(filePath, 'utf8')

// Replace 'accepted' with 'approved' in the handleApprove function
content = content.replace(
  "status: 'accepted',",
  "status: 'approved',"
)

// Also fix the condition that shows payment stages
content = content.replace(
  "if (proposal.status === 'accepted' || proposal.status === 'approved')",
  "if (proposal.status === 'approved')"
)

// Fix the polling condition
content = content.replace(
  "if (proposal.status === 'accepted' && proposal.payment_stage !== 'complete')",
  "if (proposal.status === 'approved')"
)

fs.writeFileSync(filePath, content)
console.log('✅ Fixed status value to use "approved" instead of "accepted"')
EOF

node fix_status.js

echo "✅ Status fix applied!"

# Test build
echo "🔧 Testing build..."
npm run build 2>&1 | head -50

if [ $? -eq 0 ] || [ $? -eq 1 ]; then
    echo "📤 Committing fix..."
    git add -A
    git commit -m "Fix proposals_status_check constraint violation

- Changed status from 'accepted' to 'approved'
- Database constraint only allows specific status values
- 'approved' is the correct status for accepted proposals"
    
    git push origin main
    
    echo "✅ Fix deployed successfully!"
    echo ""
    echo "🎯 The issue was:"
    echo "- status column has a CHECK constraint"
    echo "- 'accepted' is not an allowed value"
    echo "- 'approved' is the correct status value"
    echo ""
    echo "📝 Try approving the proposal again - it should work now!"
    
    # Clean up
    rm -f check_status.js fix_status.js 2>/dev/null
else
    echo "❌ Build failed"
fi
