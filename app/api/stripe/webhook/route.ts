import { NextRequest, NextResponse } from 'next/server'
import { headers } from 'next/headers'
import Stripe from 'stripe'
import { createClient } from '@/lib/supabase/server'

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2025-07-30.basil'
})

const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET

if (!webhookSecret) {
  console.error('❌ CRITICAL: STRIPE_WEBHOOK_SECRET not found in environment variables!')
}

console.log('Webhook initialized with secret:', webhookSecret ? `${webhookSecret.substring(0, 10)}...` : 'NOT SET')

export async function POST(request: NextRequest) {
  console.log('=== WEBHOOK RECEIVED ===')
  
  const body = await request.text()
  console.log('Body length:', body.length)
  
  const headersList = await headers()
  const signature = headersList.get('stripe-signature')
  console.log('Signature present:', !!signature)
  console.log('Webhook secret configured:', !!webhookSecret)
  
  if (!signature) {
    console.error('Missing stripe-signature header')
    return NextResponse.json({ error: 'Missing signature' }, { status: 400 })
  }

  let event: Stripe.Event

  try {
    if (!webhookSecret) {
      throw new Error('Webhook secret not configured')
    }
    event = stripe.webhooks.constructEvent(body, signature, webhookSecret)
    console.log('✅ Webhook signature verified successfully')
  } catch (err: any) {
    console.error('❌ Webhook signature verification failed:', err.message)
    console.error('Expected signing secret starts with:', webhookSecret?.substring(0, 10))
    return NextResponse.json({ error: 'Invalid signature' }, { status: 400 })
  }

  console.log('Event type:', event.type)
  console.log('Event ID:', event.id)

  const supabase = await createClient()

  // Handle the event
  switch (event.type) {
    case 'checkout.session.completed': {
      const session = event.data.object as Stripe.Checkout.Session
      
      console.log('=== PROCESSING CHECKOUT.SESSION.COMPLETED ===')
      console.log('Session ID:', session.id)
      console.log('Payment status:', session.payment_status)
      console.log('Session metadata:', JSON.stringify(session.metadata))
      
      if (session.payment_status === 'paid' && session.metadata) {
        const { proposal_id, payment_stage } = session.metadata
        
        console.log('Proposal ID:', proposal_id)
        console.log('Payment stage:', payment_stage)
        
        if (!proposal_id || !payment_stage) {
          console.error('❌ Missing proposal_id or payment_stage in metadata')
          console.error('Metadata received:', session.metadata)
          break
        }

        try {
          // Get the proposal to calculate amounts
          console.log('Fetching proposal:', proposal_id)
          const { data: proposal, error: fetchError } = await supabase
            .from('proposals')
            .select('*')
            .eq('id', proposal_id)
            .single()
          
          if (fetchError) {
            console.error('❌ Error fetching proposal:', fetchError)
            break
          }
          
          if (!proposal) {
            console.error('❌ Proposal not found:', proposal_id)
            break
          }
          
          console.log('✅ Found proposal:', proposal.id)
          console.log('Current deposit_paid_at:', proposal.deposit_paid_at)
          console.log('Current progress_paid_at:', proposal.progress_paid_at)

          // Update payment status based on stage
          const updateData: any = {}
          const now = new Date().toISOString()
          
          switch(payment_stage) {
            case 'deposit':
              updateData.deposit_paid_at = now
              updateData.total_paid = proposal.deposit_amount || 0
              updateData.status = 'deposit paid'
              // Remove payment_stage field - it's causing constraint violation
              console.log('Setting deposit payment data')
              break
            case 'roughin':
              updateData.progress_paid_at = now
              updateData.total_paid = (proposal.deposit_amount || 0) + (proposal.progress_payment_amount || 0)
              updateData.status = 'rough-in paid'
              // Remove payment_stage field - it's causing constraint violation
              console.log('Setting rough-in payment data')
              break
            case 'final':
              updateData.final_paid_at = now
              updateData.total_paid = proposal.total
              updateData.status = 'completed'
              // Remove payment_stage field - it's causing constraint violation
              console.log('Setting final payment data')
              break
            default:
              console.error('❌ Unknown payment stage:', payment_stage)
              break
          }
          
          console.log('Update data to be applied:', JSON.stringify(updateData, null, 2))
          
          // Update the proposal with payment info
          console.log('Updating proposal in database...')
          const { data: updatedProposal, error: updateError } = await supabase
            .from('proposals')
            .update(updateData)
            .eq('id', proposal_id)
            .select()
            .single()
          
          if (updateError) {
            console.error('❌ Error updating payment status:', updateError)
            console.error('Update error details:', JSON.stringify(updateError, null, 2))
          } else {
            console.log('✅ Successfully updated proposal payment status')
            console.log('Updated proposal:', JSON.stringify(updatedProposal, null, 2))
          }
          
          // Log the payment (remove customer_id as it doesn't exist in payments table)
          const paymentLogData: any = {
            proposal_id,
            amount: session.amount_total ? session.amount_total / 100 : 0, // Convert from cents
            payment_type: 'stripe',
            payment_stage,
            stripe_session_id: session.id,
            stripe_payment_intent: session.payment_intent as string,
            paid_at: now
          }
          
          // Only add customer_id if the column exists
          if (proposal.customer_id) {
            // Skip customer_id for now as the column doesn't exist
            console.log('Skipping customer_id in payment log')
          }
          
          console.log('Logging payment:', JSON.stringify(paymentLogData, null, 2))
          
          const { error: paymentError } = await supabase
            .from('payments')
            .insert(paymentLogData)
          
          if (paymentError) {
            console.error('❌ Error logging payment (non-critical):', paymentError)
            console.error('Payment log error details:', JSON.stringify(paymentError, null, 2))
          } else {
            console.log('✅ Payment logged successfully')
          }
          
        } catch (error) {
          console.error('❌ CRITICAL ERROR processing payment:', error)
          console.error('Error stack:', error instanceof Error ? error.stack : 'No stack trace')
          // Don't throw - return 200 to Stripe to prevent retries
        }
      } else {
        console.log('Session not paid or missing metadata')
        console.log('Payment status:', session.payment_status)
        console.log('Has metadata:', !!session.metadata)
      }
      break
    }
    
    default:
      console.log(`Unhandled event type: ${event.type}`)
  }

  return NextResponse.json({ received: true })
}
