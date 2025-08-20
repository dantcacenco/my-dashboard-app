import { NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import Stripe from 'stripe'

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2024-11-20.acacia'
})

export async function POST(request: Request) {
  try {
    const supabase = await createClient()
    const body = await request.json()
    
    const { 
      proposalId, 
      amount, 
      customerEmail, 
      proposalNumber,
      selectedAddons 
    } = body

    if (!proposalId || !amount) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      )
    }

    // Create Stripe checkout session
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [
        {
          price_data: {
            currency: 'usd',
            product_data: {
              name: `Proposal #${proposalNumber}`,
              description: 'HVAC Services'
            },
            unit_amount: Math.round(amount * 100) // Convert to cents
          },
          quantity: 1
        }
      ],
      mode: 'payment',
      success_url: `${process.env.NEXT_PUBLIC_APP_URL}/proposal/payment-success?session_id={CHECKOUT_SESSION_ID}&proposal=${proposalId}`,
      cancel_url: `${process.env.NEXT_PUBLIC_APP_URL}/proposal/view/${proposalId}`,
      customer_email: customerEmail,
      metadata: {
        proposalId,
        proposalNumber,
        selectedAddons: JSON.stringify(selectedAddons || [])
      }
    })

    return NextResponse.json({ url: session.url })
  } catch (error) {
    console.error('Error creating payment session:', error)
    return NextResponse.json(
      { error: 'Failed to create payment session' },
      { status: 500 }
    )
  }
}
