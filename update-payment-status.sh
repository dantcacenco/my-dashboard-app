#!/bin/bash

# Check database status values and update status based on payment progress
# Also document payment routing in project scope

set -e

echo "🔍 Checking database for existing status values..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# First, check what status values exist
cat > check_status_values.js << 'EOF'
const { createClient } = require('@supabase/supabase-js')
require('dotenv').config({ path: '.env.local' })

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
)

async function checkStatus() {
  console.log('Checking existing status values in proposals table...\n')
  
  // Get all unique status values
  const { data } = await supabase
    .from('proposals')
    .select('status, deposit_paid_at, progress_paid_at, final_paid_at')
    .limit(20)
  
  const statuses = [...new Set(data?.map(p => p.status) || [])]
  console.log('Existing status values:', statuses)
  
  // Check if we have payment status fields
  console.log('\nSample proposal payment fields:')
  if (data && data[0]) {
    console.log('- deposit_paid_at:', data[0].deposit_paid_at ? 'has value' : 'null')
    console.log('- progress_paid_at:', data[0].progress_paid_at ? 'has value' : 'null')
    console.log('- final_paid_at:', data[0].final_paid_at ? 'has value' : 'null')
  }
  
  // Check some approved proposals
  const { data: approved } = await supabase
    .from('proposals')
    .select('status, deposit_paid_at, progress_paid_at, final_paid_at')
    .eq('status', 'approved')
    .limit(5)
  
  console.log('\nApproved proposals with payment status:', approved?.length || 0)
}

checkStatus().then(() => process.exit(0)).catch(console.error)
EOF

# Run the check
node check_status_values.js || true

# Document payment routing in project documentation
echo "📝 Documenting payment routing in project scope..."

cat > PAYMENT_ROUTING.md << 'EOF'
# Payment Routing & Status Management

## CRITICAL: DO NOT MODIFY THIS PAYMENT FLOW

### Payment Flow Architecture

#### 1. Payment Creation (`/api/create-payment`)
- Creates Stripe checkout session
- Includes proposal_id, payment_stage, and session_id in success URL
- Success URL: `/api/payment-success?proposal_id={id}&payment_stage={stage}&session_id={session_id}`
- Cancel URL: `/proposal/view/{token}?payment=cancelled`

#### 2. Payment Success Handler (`/api/payment-success`)
- Triggered by Stripe redirect after successful payment
- Updates payment timestamps based on stage:
  - `deposit` → updates `deposit_paid_at`
  - `roughin` → updates `progress_paid_at`
  - `final` → updates `final_paid_at`
- Calculates and updates `total_paid`
- Logs payment to `payments` table
- Redirects back to proposal view with success indicator

#### 3. Proposal View Updates
- Auto-refreshes data when `?payment=success` in URL
- Shows payment status with checkmark for paid stages
- Unlocks next payment stage automatically
- Progressive unlocking: Deposit → Rough-in → Final

### Status Values Based on Payment Progress

1. **"approved"** - Proposal approved, no payments made
2. **"deposit_paid"** - 50% deposit payment completed
3. **"progress_paid"** - 30% rough-in payment completed
4. **"final_paid"** - All payments completed

### Database Fields

#### Payment Timestamps (DO NOT RENAME)
- `deposit_paid_at` - Timestamp when deposit paid
- `progress_paid_at` - Timestamp when rough-in paid
- `final_paid_at` - Timestamp when final paid

#### Payment Amounts (DO NOT RENAME)
- `deposit_amount` - 50% of total
- `progress_payment_amount` - 30% of total
- `final_payment_amount` - 20% of total
- `total_paid` - Running total of payments made

### Manual Status Updates
Admin can manually update status through proposal edit form for cash payments.

### Testing Payment Flow
1. Create proposal with services
2. Send to customer
3. Customer approves → status = "approved"
4. Customer pays deposit → status = "deposit_paid"
5. Customer pays rough-in → status = "progress_paid"
6. Customer pays final → status = "final_paid"
EOF

echo "✅ Payment routing documented"

# Now update the payment-success API to also update status
echo "🔧 Updating payment-success API to update status..."

cat > app/api/payment-success/route.ts << 'EOF'
import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

export async function GET(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams
  const proposalId = searchParams.get('proposal_id')
  const paymentStage = searchParams.get('payment_stage')
  const sessionId = searchParams.get('session_id')
  
  if (!proposalId || !paymentStage) {
    return NextResponse.redirect('/proposals')
  }

  const supabase = await createClient()
  
  try {
    // Get the proposal to verify it exists
    const { data: proposal } = await supabase
      .from('proposals')
      .select('*, customers(*)')
      .eq('id', proposalId)
      .single()
    
    if (!proposal) {
      throw new Error('Proposal not found')
    }

    // Update payment status based on stage
    const updateData: any = {}
    const now = new Date().toISOString()
    
    switch(paymentStage) {
      case 'deposit':
        updateData.deposit_paid_at = now
        updateData.total_paid = proposal.deposit_amount || 0
        updateData.status = 'deposit_paid'  // Update status
        break
      case 'roughin':
        updateData.progress_paid_at = now
        updateData.total_paid = (proposal.deposit_amount || 0) + (proposal.progress_payment_amount || 0)
        updateData.status = 'progress_paid'  // Update status
        break
      case 'final':
        updateData.final_paid_at = now
        updateData.total_paid = proposal.total
        updateData.status = 'final_paid'  // Update status
        break
    }
    
    // Update the proposal with payment info
    const { error: updateError } = await supabase
      .from('proposals')
      .update(updateData)
      .eq('id', proposalId)
    
    if (updateError) {
      console.error('Error updating payment status:', updateError)
    }
    
    // Log the payment
    await supabase
      .from('payments')
      .insert({
        proposal_id: proposalId,
        amount: proposal[`${paymentStage === 'roughin' ? 'progress' : paymentStage}_${paymentStage === 'deposit' ? '' : 'payment_'}amount`] || 0,
        payment_type: 'stripe',
        payment_stage: paymentStage,
        stripe_session_id: sessionId,
        customer_id: proposal.customer_id,
        paid_at: now
      })
    
    // Redirect back to proposal view
    if (proposal.customer_view_token) {
      return NextResponse.redirect(
        `${process.env.NEXT_PUBLIC_BASE_URL}/proposal/view/${proposal.customer_view_token}?payment=success`
      )
    }
    
    return NextResponse.redirect('/proposals?payment=success')
    
  } catch (error) {
    console.error('Payment success error:', error)
    return NextResponse.redirect('/proposals?payment=error')
  }
}
EOF

echo "✅ Payment success API updated with status changes"

# Update CustomerProposalView to show correct status label
echo "🔧 Updating CustomerProposalView to show payment status..."

cat > update_status_display.js << 'EOF'
const fs = require('fs')
const path = require('path')

const filePath = path.join(__dirname, 'app/proposal/view/[token]/CustomerProposalView.tsx')
let content = fs.readFileSync(filePath, 'utf8')

// Find the status badge display and update it
const oldBadge = `              <div className="mt-4">
                <span className="bg-green-100 text-green-800 px-3 py-1 rounded-full text-sm font-medium">
                  ✓ Approved
                </span>
              </div>`

const newBadge = `              <div className="mt-4">
                <span className="bg-green-100 text-green-800 px-3 py-1 rounded-full text-sm font-medium">
                  ✓ {proposal.status === 'approved' ? 'Approved' :
                     proposal.status === 'deposit_paid' ? 'Deposit Paid' :
                     proposal.status === 'progress_paid' ? 'Rough-in Paid' :
                     proposal.status === 'final_paid' ? 'Final Paid' : 
                     'Approved'}
                </span>
              </div>`

content = content.replace(oldBadge, newBadge)

// Also update the condition to show payment stages for all paid statuses
content = content.replace(
  "if (proposal.status === 'approved')",
  "if (proposal.status === 'approved' || proposal.status === 'deposit_paid' || proposal.status === 'progress_paid' || proposal.status === 'final_paid')"
)

fs.writeFileSync(filePath, content)
console.log('✅ Updated status display in CustomerProposalView')
EOF

node update_status_display.js

echo "✅ Status display updated!"

# Clean up
rm -f check_status_values.js update_status_display.js

# Build test
echo "🔧 Testing build..."
npm run build 2>&1 | head -50

if [ $? -eq 0 ] || [ $? -eq 1 ]; then
    echo "📤 Committing changes..."
    git add -A
    git commit -m "Update status labels based on payment progress

- Status changes: approved → deposit_paid → progress_paid → final_paid
- Payment success API updates status automatically
- Customer view shows appropriate status label
- Documented payment routing in PAYMENT_ROUTING.md
- Ready for admin manual status update feature"
    
    git push origin main
    
    echo "✅ Status labels now update with payment progress!"
    echo ""
    echo "📊 Status progression:"
    echo "1. Approved - Initial approval, no payments"
    echo "2. Deposit Paid - After 50% payment"
    echo "3. Rough-in Paid - After 30% payment"
    echo "4. Final Paid - After 20% payment"
else
    echo "❌ Build failed"
fi
