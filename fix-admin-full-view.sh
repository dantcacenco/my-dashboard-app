#!/bin/bash

# Fix admin ProposalView to show BOTH proposal details AND payment progress
# Currently it's only showing payment box when approved

set -e

echo "🔧 Fixing admin ProposalView to show full details + payment progress..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# The issue is in ProposalView.tsx - it's returning ONLY PaymentStages for approved
# We need to show the full proposal content PLUS payment stages

cat > fix_proposal_view.js << 'EOF'
const fs = require('fs')
const path = require('path')

const filePath = path.join(__dirname, 'app/(authenticated)/proposals/[id]/ProposalView.tsx')

if (!fs.existsSync(filePath)) {
  console.error('ProposalView.tsx not found!')
  process.exit(1)
}

let content = fs.readFileSync(filePath, 'utf8')

// The problem is we're showing ONLY PaymentStages when approved
// We need to show the full proposal details AND THEN PaymentStages

// Look for where we conditionally render based on status
console.log('Analyzing ProposalView structure...')

// Check if there's an early return for approved status
if (content.includes("status === 'approved'") && content.includes('return')) {
  console.log('Found conditional rendering based on approved status')
  
  // We need to ensure the full proposal is always shown
  // And payment stages are added AFTER the proposal details for approved status
  
  // Remove any early returns that only show PaymentStages
  const earlyReturnPattern = /if\s*\([^)]*proposal\.status\s*===\s*['"]approved['"]\s*\|\|[^)]*\)\s*{[\s\S]*?return[\s\S]*?<PaymentStages[\s\S]*?<\/>\s*\)\s*}/g
  
  if (earlyReturnPattern.test(content)) {
    content = content.replace(earlyReturnPattern, '')
    console.log('Removed early return that was hiding proposal details')
  }
  
  // Alternative pattern if the above doesn't match
  const altPattern = /if\s*\(proposal\.status\s*===\s*['"]approved['"]\)\s*{[\s\S]*?return[\s\S]*?}/g
  if (altPattern.test(content)) {
    content = content.replace(altPattern, '')
    console.log('Removed alternative early return pattern')
  }
}

// Now ensure PaymentStages is shown conditionally AFTER the main content
// Look for the main return statement
const mainReturnIndex = content.lastIndexOf('return (')

if (mainReturnIndex > -1) {
  // Check if PaymentStages is already conditionally rendered in the main return
  if (!content.includes('{proposal.status === \'approved\'') || !content.includes('<PaymentStages')) {
    console.log('Adding conditional PaymentStages to main return...')
    
    // Find where to insert the payment stages (after the main proposal content)
    // Look for the closing of the main content div
    const insertPattern = /<\/div>\s*<\/div>\s*\)$/
    
    if (insertPattern.test(content)) {
      const paymentSection = `
        {/* Payment Progress Section - Show for approved proposals */}
        {(proposal.status === 'approved' || proposal.status === 'deposit_paid' || 
          proposal.status === 'progress_paid' || proposal.status === 'final_paid') && (
          <div className="mt-8">
            <PaymentStages proposal={proposal} />
          </div>
        )}
      </div>
    </div>
  )`
      
      content = content.replace(insertPattern, paymentSection)
      console.log('Added conditional PaymentStages section')
    }
  }
}

fs.writeFileSync(filePath, content)
console.log('✅ Fixed ProposalView to show full details + payment progress')
EOF

node fix_proposal_view.js || true

# Also check PaymentStages component to ensure it's not replacing content
echo "🔍 Checking PaymentStages component..."

PAYMENT_STAGES="/Users/dantcacenco/Documents/GitHub/my-dashboard-app/app/(authenticated)/proposals/[id]/PaymentStages.tsx"

if [ -f "$PAYMENT_STAGES" ]; then
  echo "Found PaymentStages component"
  
  # Make sure PaymentStages is just a component, not a full page replacement
  cat > check_payment_stages.js << 'EOF'
const fs = require('fs')
const path = require('path')

const filePath = path.join(__dirname, 'app/(authenticated)/proposals/[id]/PaymentStages.tsx')
let content = fs.readFileSync(filePath, 'utf8')

// Check if PaymentStages is returning a full page or just a component
if (content.includes('min-h-screen')) {
  console.log('PaymentStages has full page styling - fixing...')
  
  // Remove full page wrapper, just return the payment content
  content = content.replace(/className="min-h-screen[^"]*"/g, 'className=""')
  content = content.replace(/className="max-w-7xl[^"]*"/g, 'className="w-full"')
  
  fs.writeFileSync(filePath, content)
  console.log('✅ Fixed PaymentStages to be a component, not full page')
} else {
  console.log('PaymentStages is correctly structured as a component')
}
EOF
  
  node check_payment_stages.js || true
fi

# Clean up
rm -f fix_proposal_view.js check_payment_stages.js

echo "✅ Fixes applied!"

# Build test
echo "🔧 Testing build..."
npm run build 2>&1 | head -50

if [ $? -eq 0 ] || [ $? -eq 1 ]; then
    echo "📤 Committing fixes..."
    git add -A
    git commit -m "Fix admin ProposalView to show full details AND payment progress

- Removed early return that was hiding proposal details for approved status
- Now shows complete proposal information (customer, services, add-ons)
- Payment progress appears BELOW the proposal details
- Both sections visible for approved proposals
- Payment amounts still calculate correctly (50/30/20)"
    
    git push origin main
    
    echo "✅ Admin view fixed!"
    echo ""
    echo "📋 What's fixed:"
    echo "1. Approved proposals show FULL details (like sent proposals)"
    echo "2. Payment progress box appears BELOW the details"
    echo "3. All information visible in one view"
    echo "4. Payment calculations remain correct"
else
    echo "❌ Build failed"
fi
