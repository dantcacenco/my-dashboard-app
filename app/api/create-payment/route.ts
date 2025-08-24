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
      success_url: `${process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000'}/proposal/payment-success?session_id={CHECKOUT_SESSION_ID}&proposal_id=${proposal_id}&stage=${payment_stage}`,
      cancel_url: `${process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000'}/proposal/view/${proposal.customer_view_token}`,
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
