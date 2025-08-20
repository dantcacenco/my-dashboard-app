import { NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import Stripe from 'stripe'

// Initialize Stripe with proper error handling
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || '', {
  apiVersion: '2025-07-30.basil'
})

export async function POST(request: Request) {
  try {
    // Check if Stripe key exists
    if (!process.env.STRIPE_SECRET_KEY) {
      console.error('STRIPE_SECRET_KEY is not configured')
      return NextResponse.json(
        { error: 'Payment system not configured' },
        { status: 500 }
      )
    }

    const supabase = await createClient()
    const body = await request.json()
    
    const { 
      proposalId, 
      amount, 
      customerEmail, 
      proposalNumber,
      selectedAddons 
    } = body

    console.log('Creating payment session for:', {
      proposalId,
      amount,
      customerEmail,
      proposalNumber
    })

    if (!proposalId || !amount) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      )
    }

    // Ensure amount is a valid number
    const amountInCents = Math.round(parseFloat(amount.toString()) * 100)
    
    if (isNaN(amountInCents) || amountInCents <= 0) {
      return NextResponse.json(
        { error: 'Invalid amount' },
        { status: 400 }
      )
    }

    try {
      // Create Stripe checkout session
      const session = await stripe.checkout.sessions.create({
        payment_method_types: ['card'],
        line_items: [
          {
            price_data: {
              currency: 'usd',
              product_data: {
                name: `Proposal #${proposalNumber || 'N/A'}`,
                description: 'HVAC Services'
              },
              unit_amount: amountInCents
            },
            quantity: 1
          }
        ],
        mode: 'payment',
        success_url: `${process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000'}/proposal/payment-success?session_id={CHECKOUT_SESSION_ID}&proposal=${proposalId}`,
        cancel_url: `${process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000'}/proposal/view/${proposalId}`,
        customer_email: customerEmail || undefined,
        metadata: {
          proposalId,
          proposalNumber: proposalNumber || '',
          selectedAddons: JSON.stringify(selectedAddons || [])
        }
      })

      console.log('Stripe session created:', session.id)

      return NextResponse.json({ 
        url: session.url,
        sessionId: session.id 
      })
    } catch (stripeError: any) {
      console.error('Stripe error:', stripeError)
      return NextResponse.json(
        { 
          error: 'Failed to create payment session', 
          details: stripeError.message 
        },
        { status: 500 }
      )
    }
  } catch (error: any) {
    console.error('Error creating payment session:', error)
    return NextResponse.json(
      { 
        error: 'Internal server error', 
        details: error.message || 'Unknown error'
      },
      { status: 500 }
    )
  }
}
