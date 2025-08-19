import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'
import Stripe from 'stripe'

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2025-07-30.basil'
})

export async function POST(request: Request) {
  try {
    const supabase = await createClient()
    const body = await request.text()
    const sig = request.headers.get('stripe-signature')!

    // Debug logging
    console.log('Payment notification received')

    let event: Stripe.Event

    try {
      event = stripe.webhooks.constructEvent(
        body,
        sig,
        process.env.STRIPE_WEBHOOK_SECRET!
      )
    } catch (err: any) {
      console.error('Webhook signature verification failed:', err.message)
      return NextResponse.json({ error: 'Invalid signature' }, { status: 400 })
    }

    console.log('Stripe event type:', event.type)

    // Handle the event
    if (event.type === 'checkout.session.completed') {
      const session = event.data.object as Stripe.Checkout.Session
      
      console.log('Session completed:', {
        id: session.id,
        payment_status: session.payment_status,
        amount_total: session.amount_total,
        metadata: session.metadata
      })

      // Get the proposal ID from metadata
      const proposalId = session.metadata?.proposalId
      const paymentStage = session.metadata?.paymentStage || 'deposit'
      
      if (!proposalId) {
        console.error('No proposal ID in session metadata')
        return NextResponse.json({ error: 'No proposal ID' }, { status: 400 })
      }

      // Get the actual amount paid (convert from cents)
      const amountPaid = (session.amount_total || 0) / 100

      // Update the proposal with payment info
      const updateData: any = {
        stripe_session_id: session.id,
        last_payment_attempt: new Date().toISOString()
      }

      // Update based on payment stage
      if (paymentStage === 'deposit') {
        updateData.deposit_amount = amountPaid
        updateData.deposit_paid_at = new Date().toISOString()
        updateData.payment_status = 'deposit_paid'
        updateData.current_payment_stage = 'progress'
      } else if (paymentStage === 'progress') {
        updateData.progress_payment_amount = amountPaid
        updateData.progress_paid_at = new Date().toISOString()
        updateData.payment_status = 'progress_paid'
        updateData.current_payment_stage = 'final'
      } else if (paymentStage === 'final') {
        updateData.final_payment_amount = amountPaid
        updateData.final_paid_at = new Date().toISOString()
        updateData.payment_status = 'fully_paid'
        updateData.current_payment_stage = 'completed'
      }

      // Calculate total paid
      const { data: currentProposal } = await supabase
        .from('proposals')
        .select('deposit_amount, progress_payment_amount, final_payment_amount')
        .eq('id', proposalId)
        .single()

      const totalPaid = 
        (currentProposal?.deposit_amount || 0) +
        (currentProposal?.progress_payment_amount || 0) +
        (currentProposal?.final_payment_amount || 0) +
        amountPaid

      updateData.total_paid = totalPaid

      // Update proposal
      const { error: updateError } = await supabase
        .from('proposals')
        .update(updateData)
        .eq('id', proposalId)

      if (updateError) {
        console.error('Error updating proposal:', updateError)
        return NextResponse.json({ error: 'Failed to update proposal' }, { status: 500 })
      }

      // Update payment stage
      const { error: stageError } = await supabase
        .from('payment_stages')
        .update({
          paid: true,
          paid_at: new Date().toISOString(),
          stripe_session_id: session.id,
          amount_paid: amountPaid,
          payment_method: 'stripe'
        })
        .eq('proposal_id', proposalId)
        .eq('stage', paymentStage)

      if (stageError) {
        console.error('Error updating payment stage:', stageError)
      }

      // Create payment record
      await supabase
        .from('payments')
        .insert({
          proposal_id: proposalId,
          stripe_session_id: session.id,
          stripe_payment_intent_id: session.payment_intent as string,
          amount: amountPaid,
          status: 'completed',
          payment_method: 'card',
          customer_email: session.customer_details?.email,
          payment_stage: paymentStage,
          metadata: session.metadata
        })

      // Log activity
      await supabase
        .from('proposal_activities')
        .insert({
          proposal_id: proposalId,
          activity_type: 'payment_received',
          description: `${paymentStage} payment of ${amountPaid} received`,
          metadata: {
            amount: amountPaid,
            stage: paymentStage,
            session_id: session.id
          }
        })

      console.log('Payment processed successfully:', {
        proposalId,
        stage: paymentStage,
        amount: amountPaid
      })
    }

    return NextResponse.json({ received: true })
  } catch (error) {
    console.error('Error processing payment notification:', error)
    return NextResponse.json(
      { error: 'Failed to process webhook' },
      { status: 500 }
    )
  }
}
