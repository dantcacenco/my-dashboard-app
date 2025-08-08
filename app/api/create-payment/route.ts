import { NextRequest, NextResponse } from 'next/server'
import Stripe from 'stripe'
import { createClient } from '@/lib/supabase/server'

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2025-07-30.basil'
})

export async function POST(request: NextRequest) {
  try {
    const {
      proposal_id,
      proposal_number,
      customer_name,
      customer_email,
      amount,
      payment_type,
      description,
      payment_stage = 'deposit'
    } = await request.json()

    console.log('Creating payment for:', {
      proposal_id,
      payment_stage,
      amount,
      payment_type
    })

    if (!proposal_id || !amount || !customer_email) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      )
    }

    // Get the proposal with customer_view_token
    const supabase = await createClient()
    const { data: proposal, error: fetchError } = await supabase
      .from('proposals')
      .select('customer_view_token, total')
      .eq('id', proposal_id)
      .single()

    if (fetchError || !proposal) {
      console.error('Error fetching proposal:', fetchError)
      return NextResponse.json(
        { error: 'Proposal not found' },
        { status: 404 }
      )
    }

    // Ensure customer_view_token exists
    let customerViewToken = proposal.customer_view_token
    if (!customerViewToken) {
      const { data: tokenData, error: tokenError } = await supabase
        .from('proposals')
        .update({ customer_view_token: crypto.randomUUID() })
        .eq('id', proposal_id)
        .select('customer_view_token')
        .single()
      
      if (tokenError || !tokenData) {
        console.error('Error generating token:', tokenError)
        return NextResponse.json(
          { error: 'Failed to generate customer token' },
          { status: 500 }
        )
      }
      customerViewToken = tokenData.customer_view_token
    }

    // Create or update payment stage record
    const { error: stageError } = await supabase
      .from('payment_stages')
      .upsert({
        proposal_id,
        stage: payment_stage,
        amount: amount,
        percentage: payment_stage === 'deposit' ? 50 : payment_stage === 'roughin' ? 30 : 20,
        due_date: new Date().toISOString().split('T')[0],
        paid: false
      }, {
        onConflict: 'proposal_id,stage'
      })

    if (stageError) {
      console.error('Error creating payment stage:', stageError)
    }

    // Define payment method types
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
              description: `${description} for proposal ${proposal_number}`,
            },
            unit_amount: Math.round(amount * 100) // Convert to cents
          },
          quantity: 1
        }
      ],
      mode: 'payment',
      customer_email: customer_email,
      success_url: `${process.env.NEXT_PUBLIC_BASE_URL || 'https://servicepro-hvac.vercel.app'}/proposal/payment-success?session_id={CHECKOUT_SESSION_ID}&proposal_id=${proposal_id}`,
      cancel_url: `${process.env.NEXT_PUBLIC_BASE_URL || 'https://servicepro-hvac.vercel.app'}/proposal/view/${customerViewToken}?payment=cancelled`,
      metadata: {
        proposal_id,
        proposal_number,
        customer_name,
        payment_type: payment_type || 'card',
        payment_stage: payment_stage,
        customer_view_token: customerViewToken
      },
      billing_address_collection: 'required',
      phone_number_collection: {
        enabled: true
      },
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

    console.log('Stripe session created successfully:', session.id)

    return NextResponse.json({ 
      checkout_url: session.url,
      session_id: session.id 
    })

  } catch (error: any) {
    console.error('Error creating Stripe checkout session:', error)
    return NextResponse.json(
      { error: error.message || 'Failed to create payment session' },
      { status: 500 }
    )
  }
}
