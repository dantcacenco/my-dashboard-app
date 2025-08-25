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
