#!/bin/bash
set -e

echo "🔧 Making Stripe URLs work automatically without environment variables..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Update create-payment API to auto-detect URL
echo "📝 Updating create-payment API..."
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

    // Auto-detect the correct URL based on where we're running
    const host = request.headers.get('host') || ''
    let baseUrl = ''
    
    if (host.includes('localhost')) {
      baseUrl = `http://${host}`
    } else if (host.includes('vercel.app')) {
      baseUrl = `https://${host}`
    } else if (host) {
      baseUrl = `https://${host}`
    } else {
      // Fallback to your known production URL
      baseUrl = 'https://my-dashboard-app-tau.vercel.app'
    }

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

# Update create-payment-session API
echo "📝 Updating create-payment-session API..."
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

    // Auto-detect the correct URL based on where we're running
    const host = request.headers.get('host') || ''
    let baseUrl = ''
    
    if (host.includes('localhost')) {
      baseUrl = `http://${host}`
    } else if (host.includes('vercel.app')) {
      baseUrl = `https://${host}`
    } else if (host) {
      baseUrl = `https://${host}`
    } else {
      // Fallback to your known production URL
      baseUrl = 'https://my-dashboard-app-tau.vercel.app'
    }

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

echo "✅ Fixed to auto-detect URLs!"

# Remove the .env.example since we don't need it
rm -f .env.example

# Commit
git add -A
git commit -m "Auto-detect URLs for Stripe redirects - no env vars needed

- Automatically detect localhost vs production
- Use request headers to determine correct URL
- Works on localhost with http://
- Works on Vercel with https://
- No environment variables required"

git push origin main

echo "✅ URLs now work automatically!"
echo "No environment variables needed - it detects the URL from the request!"
