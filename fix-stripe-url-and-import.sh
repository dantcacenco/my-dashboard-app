#!/bin/bash
set -e

echo "🔧 Fixing Stripe redirect URL and PaymentStages import..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# 1. Fix the Stripe redirect URL to use production URL
echo "📝 Fixing create-payment API to use proper URLs..."
cat > app/api/create-payment/route.ts << 'EOF'
import { NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import Stripe from 'stripe'

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || '', {
  apiVersion: '2025-07-30.basil'
})

export async function POST(request: Request) {
  try {
    const supabase = await createClient()
    const body = await request.json()
    
    const {
      proposal_id,
      proposal_number,
      customer_name,
      customer_email,
      amount,
      payment_type = 'card',
      payment_stage,
      description
    } = body

    console.log('Creating payment for stage:', payment_stage, 'Amount:', amount)

    if (!proposal_id || !amount) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      )
    }

    // Get proposal details
    const { data: proposal } = await supabase
      .from('proposals')
      .select('*')
      .eq('id', proposal_id)
      .single()

    if (!proposal) {
      return NextResponse.json(
        { error: 'Proposal not found' },
        { status: 404 }
      )
    }

    // Use production URL or fallback to request origin
    const baseUrl = process.env.NEXT_PUBLIC_APP_URL || 
                    process.env.NEXT_PUBLIC_BASE_URL || 
                    `https://${request.headers.get('host')}` ||
                    'https://my-dashboard-app-tau.vercel.app'

    // Create Stripe checkout session
    const session = await stripe.checkout.sessions.create({
      payment_method_types: [payment_type],
      line_items: [
        {
          price_data: {
            currency: 'usd',
            product_data: {
              name: description || `${payment_stage} Payment - Proposal #${proposal_number}`,
              description: `HVAC Services - ${payment_stage} payment`
            },
            unit_amount: Math.round(amount * 100) // Convert to cents
          },
          quantity: 1
        }
      ],
      mode: 'payment',
      success_url: `${baseUrl}/proposal/payment-success?session_id={CHECKOUT_SESSION_ID}&proposal_id=${proposal_id}&stage=${payment_stage}`,
      cancel_url: `${baseUrl}/proposal/view/${proposal.customer_view_token}`,
      customer_email: customer_email,
      metadata: {
        proposal_id: proposal_id,
        proposal_number: proposal_number,
        payment_stage: payment_stage,
        amount: amount.toString()
      }
    })

    // Update payment_stages table
    await supabase
      .from('payment_stages')
      .update({
        stripe_session_id: session.id,
        last_attempt: new Date().toISOString()
      })
      .eq('proposal_id', proposal_id)
      .eq('stage', payment_stage)

    return NextResponse.json({
      checkout_url: session.url,
      session_id: session.id
    })
    
  } catch (error: any) {
    console.error('Error creating payment session:', error)
    return NextResponse.json(
      { error: error.message || 'Failed to create payment session' },
      { status: 500 }
    )
  }
}
EOF

# 2. Fix the create-payment-session API as well
echo "📝 Fixing create-payment-session API..."
cat > app/api/create-payment-session/route.ts << 'EOF'
import { NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import Stripe from 'stripe'

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || '', {
  apiVersion: '2025-07-30.basil'
})

export async function POST(request: Request) {
  try {
    const body = await request.json()
    const supabase = await createClient()
    
    const {
      proposalId,
      amount,
      customerEmail,
      proposalNumber,
      paymentStage = 'full',
      stageDescription = 'Full Payment',
      selectedAddons
    } = body

    if (!proposalId || !amount) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      )
    }

    // Get proposal to get customer_view_token
    const { data: proposal } = await supabase
      .from('proposals')
      .select('customer_view_token')
      .eq('id', proposalId)
      .single()

    if (!proposal) {
      return NextResponse.json(
        { error: 'Proposal not found' },
        { status: 404 }
      )
    }

    // Use production URL or fallback to request origin
    const baseUrl = process.env.NEXT_PUBLIC_APP_URL || 
                    process.env.NEXT_PUBLIC_BASE_URL || 
                    `https://${request.headers.get('host')}` ||
                    'https://my-dashboard-app-tau.vercel.app'

    // Create Stripe checkout session
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [
        {
          price_data: {
            currency: 'usd',
            product_data: {
              name: `${stageDescription} - Proposal #${proposalNumber}`,
              description: 'HVAC Services'
            },
            unit_amount: Math.round(amount * 100)
          },
          quantity: 1
        }
      ],
      mode: 'payment',
      success_url: `${baseUrl}/proposal/payment-success?session_id={CHECKOUT_SESSION_ID}&proposal_id=${proposalId}`,
      cancel_url: `${baseUrl}/proposal/view/${proposal.customer_view_token}`,
      customer_email: customerEmail,
      metadata: {
        proposalId,
        proposalNumber,
        paymentStage,
        selectedAddons: JSON.stringify(selectedAddons || [])
      }
    })

    // Update proposal with session info
    await supabase
      .from('proposals')
      .update({
        stripe_session_id: session.id,
        payment_initiated_at: new Date().toISOString()
      })
      .eq('id', proposalId)

    return NextResponse.json({ 
      url: session.url,
      sessionId: session.id 
    })

  } catch (error: any) {
    console.error('Payment session error:', error)
    return NextResponse.json(
      { error: error.message || 'Failed to create payment session' },
      { status: 500 }
    )
  }
}
EOF

# 3. Fix PaymentStages import issue
echo "📝 Fixing PaymentStages import in ProposalView..."
sed -i '' "s/import PaymentStages from '.\/PaymentStages'/import { PaymentStages } from '.\/PaymentStages'/" app/\(authenticated\)/proposals/\[id\]/ProposalView.tsx

# 4. Add environment variable to .env.local (if it doesn't exist)
echo "📝 Creating env example file..."
cat > .env.example << 'EOF'
# Production URL (update this with your actual domain)
NEXT_PUBLIC_APP_URL=https://my-dashboard-app-tau.vercel.app
NEXT_PUBLIC_BASE_URL=https://my-dashboard-app-tau.vercel.app

# Supabase
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# Stripe
STRIPE_SECRET_KEY=your_stripe_secret_key
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=your_stripe_publishable_key
STRIPE_WEBHOOK_SECRET=your_webhook_secret

# Resend
RESEND_API_KEY=your_resend_api_key
EOF

echo "✅ Fixed Stripe URLs and PaymentStages import!"

# Test TypeScript
echo "🔍 Checking TypeScript..."
npx tsc --noEmit 2>&1 | head -20

# Commit
git add -A
git commit -m "Fix Stripe redirect URL and PaymentStages import

- Use production URL for Stripe success/cancel redirects
- Fix localhost redirect issue by using proper environment variables
- Fix PaymentStages named import (not default export)
- Add .env.example for environment variable documentation
- Support multiple URL fallbacks for robustness"

git push origin main

echo "✅ All fixes applied!"
echo ""
echo "⚠️  IMPORTANT: Add this environment variable to Vercel:"
echo "   NEXT_PUBLIC_APP_URL=https://my-dashboard-app-tau.vercel.app"
echo ""
echo "Go to: Vercel Dashboard → Settings → Environment Variables"
echo "Add the variable above to ensure proper redirects"
