import { NextRequest, NextResponse } from 'next/server'
import { headers } from 'next/headers'
import Stripe from 'stripe'
import { createClient } from '@/lib/supabase/server'

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2025-07-30.basil'
})

const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET!

export async function POST(request: NextRequest) {
  const body = await request.text()
  const signature = headers().get('stripe-signature')!

  let event: Stripe.Event

  try {
    event = stripe.webhooks.constructEvent(body, signature, webhookSecret)
  } catch (err: any) {
    console.error('Webhook signature verification failed:', err.message)
    return NextResponse.json({ error: 'Invalid signature' }, { status: 400 })
  }

  const supabase = await createClient()

  // Handle the event
  switch (event.type) {
    case 'checkout.session.completed': {
      const session = event.data.object as Stripe.Checkout.Session
      
      console.log('Payment completed for session:', session.id)
      console.log('Session metadata:', session.metadata)
      
      if (session.payment_status === 'paid' && session.metadata) {
        const { proposal_id, payment_stage } = session.metadata
        
        if (!proposal_id || !payment_stage) {
          console.error('Missing proposal_id or payment_stage in metadata')
          break
        }

        try {
          // Get the proposal to calculate amounts
          const { data: proposal } = await supabase
            .from('proposals')
            .select('*')
            .eq('id', proposal_id)
            .single()
          
          if (!proposal) {
            console.error('Proposal not found:', proposal_id)
            break
          }

          // Update payment status based on stage
          const updateData: any = {}
          const now = new Date().toISOString()
          
          switch(payment_stage) {
            case 'deposit':
              updateData.deposit_paid_at = now
              updateData.total_paid = proposal.deposit_amount || 0
              updateData.status = 'deposit paid'
              updateData.payment_stage = 'deposit'
              break
            case 'roughin':
              updateData.progress_paid_at = now
              updateData.total_paid = (proposal.deposit_amount || 0) + (proposal.progress_payment_amount || 0)
              updateData.status = 'rough-in paid'
              updateData.payment_stage = 'roughin'
              break
            case 'final':
              updateData.final_paid_at = now
              updateData.total_paid = proposal.total
              updateData.status = 'completed'
              updateData.payment_stage = 'complete'
              break
          }
          
          console.log('Updating proposal with:', updateData)
          
          // Update the proposal with payment info
          const { error: updateError } = await supabase
            .from('proposals')
            .update(updateData)
            .eq('id', proposal_id)
          
          if (updateError) {
            console.error('Error updating payment status:', updateError)
          } else {
            console.log('Successfully updated proposal payment status')
          }
          
          // Log the payment
          const { error: paymentError } = await supabase
            .from('payments')
            .insert({
              proposal_id,
              amount: session.amount_total ? session.amount_total / 100 : 0, // Convert from cents
              payment_type: 'stripe',
              payment_stage,
              stripe_session_id: session.id,
              stripe_payment_intent: session.payment_intent as string,
              customer_id: proposal.customer_id,
              paid_at: now
            })
          
          if (paymentError) {
            console.error('Error logging payment:', paymentError)
          }
          
        } catch (error) {
          console.error('Error processing payment:', error)
        }
      }
      break
    }
    
    default:
      console.log(`Unhandled event type: ${event.type}`)
  }

  return NextResponse.json({ received: true })
}
