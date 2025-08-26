import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import Stripe from 'stripe'

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2024-12-18.acacia'
})

export async function POST(request: NextRequest) {
  try {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()
    
    const body = await request.json()
    const {
      proposal_id,
      proposal_number,
      customer_name,
      customer_email,
      amount,
      payment_type,
      payment_stage,
      description
    } = body

    // Get base URL for redirect
    const baseUrl = process.env.NEXT_PUBLIC_BASE_URL || 
      `https://${request.headers.get('host')}`

    // Get proposal for token
    const { data: proposal } = await supabase
      .from('proposals')
      .select('customer_view_token')
      .eq('id', proposal_id)
      .single()

    // Create Stripe checkout session
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [
        {
          price_data: {
            currency: 'usd',
            product_data: {
              name: description || `Payment for Proposal #${proposal_number}`,
              description: `${payment_stage === 'deposit' ? '50% Deposit' : 
                           payment_stage === 'roughin' ? '30% Rough-in Payment' : 
                           '20% Final Payment'}`,
            },
            unit_amount: Math.round(amount * 100), // Convert to cents
          },
          quantity: 1,
        },
      ],
      mode: 'payment',
      success_url: `${baseUrl}/api/payment-success?proposal_id=${proposal_id}&payment_stage=${payment_stage}&session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${baseUrl}/proposal/view/${proposal?.customer_view_token}?payment=cancelled`,
      customer_email: customer_email,
      metadata: {
        proposal_id,
        proposal_number,
        payment_stage,
        customer_name
      }
    })

    return NextResponse.json({ 
      checkout_url: session.url,
      session_id: session.id 
    })
    
  } catch (error: any) {
    console.error('Create payment error:', error)
    return NextResponse.json(
      { error: error.message || 'Failed to create payment session' },
      { status: 500 }
    )
  }
}
