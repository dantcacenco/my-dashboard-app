import { NextRequest, NextResponse } from 'next/server'
import Stripe from 'stripe'
import { createClient } from '@/lib/supabase/server'

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2025-07-30.basil'
})

export async function POST(request: NextRequest) {
  try {
    // Check for required environment variables
    if (!process.env.STRIPE_SECRET_KEY) {
      console.error('Missing STRIPE_SECRET_KEY environment variable')
      return NextResponse.json(
        { error: 'Payment system not configured. Please contact support.' },
        { status: 500 }
      )
    }

    if (!process.env.NEXT_PUBLIC_BASE_URL) {
      console.error('Missing NEXT_PUBLIC_BASE_URL environment variable')
      return NextResponse.json(
        { error: 'Payment system configuration error. Please contact support.' },
        { status: 500 }
      )
    }

    const {
      proposal_id,
      proposal_number,
      customer_name,
      customer_email,
      amount,
      payment_type,
      payment_stage,
      description
    } = await request.json()

    console.log('Creating payment session:', {
      proposal_id,
      amount,
      payment_type,
      payment_stage,
      base_url: process.env.NEXT_PUBLIC_BASE_URL
    })

    if (!proposal_id || !amount || !customer_email) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      )
    }

    // Get proposal to ensure we have the customer_view_token
    const supabase = await createClient()
    const { data: proposal, error: proposalError } = await supabase
      .from('proposals')
      .select('customer_view_token')
      .eq('id', proposal_id)
      .single()

    if (proposalError || !proposal) {
      console.error('Error fetching proposal:', proposalError)
      return NextResponse.json(
        { error: 'Proposal not found' },
        { status: 404 }
      )
    }

    // Define payment method types based on selection
    const paymentMethodTypes = payment_type === 'ach' 
      ? ['us_bank_account' as const] 
      : ['card' as const]

    // Create Stripe checkout session
    const session = await stripe.checkout.sessions.create({
      payment_method_types: paymentMethodTypes,
      line_items: [
        {
          price_data: {
            currency: 'usd',
            product_data: {
              name: `Service Pro - ${description}`,
              description: `${description} for HVAC services proposal ${proposal_number}`,
              images: [] // Add your logo URL here if you have one
            },
            unit_amount: Math.round(amount * 100) // Convert to cents
          },
          quantity: 1
        }
      ],
      mode: 'payment',
      customer_email: customer_email,
      success_url: `${process.env.NEXT_PUBLIC_BASE_URL}/proposal/payment-success?session_id={CHECKOUT_SESSION_ID}&proposal_id=${proposal_id}`,
      cancel_url: `${process.env.NEXT_PUBLIC_BASE_URL}/proposal/view/${proposal.customer_view_token}?payment=cancelled`,
      metadata: {
        proposal_id,
        proposal_number,
        customer_name,
        payment_type: payment_type || 'card',
        payment_stage: payment_stage || 'deposit',
        customer_view_token: proposal.customer_view_token
      },
      billing_address_collection: 'required',
      phone_number_collection: {
        enabled: true
      },
      // For ACH payments, add additional configuration
      ...(payment_type === 'ach' && {
        payment_method_options: {
          us_bank_account: {
            financial_connections: {
              permissions: ['payment_method' as const]
            }
          }
        }
      })
    })

    console.log('Stripe session created:', session.id)
    console.log('Checkout URL:', session.url)

    return NextResponse.json({ 
      checkout_url: session.url,
      session_id: session.id 
    })

  } catch (error: any) {
    console.error('Error creating Stripe checkout session:', error)
    
    // Provide more specific error messages
    if (error.type === 'StripeAuthenticationError') {
      return NextResponse.json(
        { error: 'Invalid Stripe API key. Please check configuration.' },
        { status: 500 }
      )
    }
    
    if (error.type === 'StripeInvalidRequestError') {
      return NextResponse.json(
        { error: `Stripe configuration error: ${error.message}` },
        { status: 400 }
      )
    }
    
    return NextResponse.json(
      { error: 'Failed to create payment session. Please try again.' },
      { status: 500 }
    )
  }
}
