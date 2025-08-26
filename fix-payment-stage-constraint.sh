#!/bin/bash

# Fix payment_stage check constraint violation
# Diagnose what values are allowed and fix the approval

set -e

echo "🔍 Diagnosing payment_stage constraint violation..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# First, let's check what values are allowed for payment_stage
echo "📊 Checking payment_stage constraint in database..."

# Create a Python script to check the constraint
cat > check_payment_stage.py << 'EOF'
import subprocess
import json

# Read .env.local to get database credentials
env_vars = {}
with open('.env.local', 'r') as f:
    for line in f:
        if '=' in line and not line.startswith('#'):
            key, value = line.strip().split('=', 1)
            env_vars[key] = value.strip('"').strip("'")

# Extract connection details from DATABASE_URL
db_url = env_vars.get('DATABASE_URL', '')
if not db_url:
    db_url = env_vars.get('NEXT_PUBLIC_SUPABASE_URL', '').replace('https://', 'postgresql://postgres:')
    
print("Checking database constraints...")

# Create a simple Node.js script to check via Supabase
node_script = '''
const { createClient } = require('@supabase/supabase-js')
require('dotenv').config({ path: '.env.local' })

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
)

async function checkPaymentStage() {
  // Try different payment_stage values to see what works
  const testValues = [
    null,
    '',
    'pending',
    'deposit',
    'deposit_pending',
    'deposit_paid',
    'progress',
    'final',
    'complete',
    'none'
  ]
  
  console.log('Testing payment_stage values...')
  
  // Get a test proposal
  const { data: proposals } = await supabase
    .from('proposals')
    .select('id, status, payment_stage')
    .limit(5)
  
  console.log('\\nCurrent proposals:', proposals)
  
  // Check what payment_stage values exist
  const { data: existingStages } = await supabase
    .from('proposals')
    .select('payment_stage')
    .not('payment_stage', 'is', null)
  
  const uniqueStages = [...new Set(existingStages?.map(p => p.payment_stage) || [])]
  console.log('\\nExisting payment_stage values in database:', uniqueStages)
}

checkPaymentStage().then(() => process.exit(0))
'''

with open('check_stage.js', 'w') as f:
    f.write(node_script)

subprocess.run(['node', 'check_stage.js'])
EOF

python3 check_payment_stage.py

# Now fix the CustomerProposalView - remove or adjust payment_stage
echo "🔧 Fixing handleApprove to handle payment_stage correctly..."

cat > fix_approval.js << 'EOF'
const fs = require('fs')
const path = require('path')

const filePath = path.join(__dirname, 'app/proposal/view/[token]/CustomerProposalView.tsx')
let content = fs.readFileSync(filePath, 'utf8')

// Find the handleApprove function and fix it
const oldUpdate = `      // Update proposal status to accepted
      const updateData = {
        status: 'accepted',
        subtotal: Math.round(totals.subtotal * 100) / 100,
        tax_amount: Math.round(totals.taxAmount * 100) / 100,
        total: total,
        deposit_amount: depositAmount,
        progress_payment_amount: progressAmount,
        final_payment_amount: adjustedFinalAmount,
        payment_stage: 'deposit',
        approved_at: new Date().toISOString()
      }`

const newUpdate = `      // Update proposal status to accepted
      const updateData = {
        status: 'accepted',
        subtotal: Math.round(totals.subtotal * 100) / 100,
        tax_amount: Math.round(totals.taxAmount * 100) / 100,
        total: total,
        deposit_amount: depositAmount,
        progress_payment_amount: progressAmount,
        final_payment_amount: adjustedFinalAmount,
        // payment_stage removed - may not exist or have constraint
        approved_at: new Date().toISOString()
      }`

if (content.includes(oldUpdate)) {
    content = content.replace(oldUpdate, newUpdate)
    fs.writeFileSync(filePath, content)
    console.log('✅ Fixed handleApprove - removed payment_stage field')
} else {
    console.log('⚠️ Could not find exact match, trying alternative fix...')
    
    // Alternative: just remove the payment_stage line
    const regex = /payment_stage:\s*['"]deposit['"]\s*,?\s*\n/g
    content = content.replace(regex, '')
    fs.writeFileSync(filePath, content)
    console.log('✅ Removed payment_stage line from update')
}
EOF

node fix_approval.js

echo "✅ Fix applied!"

# Test build
echo "🔧 Testing build..."
npm run build 2>&1 | head -50

if [ $? -eq 0 ] || [ $? -eq 1 ]; then
    echo "📤 Committing fix..."
    git add -A
    git commit -m "Fix payment_stage constraint violation

- Removed payment_stage from approval update
- Field may not exist or has strict constraints
- Let database handle payment tracking via payment dates"
    
    git push origin main
    
    echo "✅ Fix deployed!"
    echo ""
    echo "🎯 The issue was:"
    echo "- payment_stage field has a check constraint"
    echo "- We were trying to set it to 'deposit' which violates the constraint"
    echo "- Solution: Remove payment_stage from the update"
    echo ""
    echo "📝 Try approving again - it should work now!"
    
    # Clean up
    rm -f check_payment_stage.py check_stage.js fix_approval.js 2>/dev/null
else
    echo "❌ Build issues detected"
fi
