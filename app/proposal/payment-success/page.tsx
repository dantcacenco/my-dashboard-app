import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import Stripe from 'stripe'
import PaymentSuccessView from './PaymentSuccessView'

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2025-07-30.basil'
})

interface PageProps {
  searchParams: Promise<{ session_id?: string; proposal_id?: string }>
}

export default async function PaymentSuccessPage({ searchParams }: PageProps) {
  const { session_id, proposal_id } = await searchParams
  
  if (!session_id || !proposal_id) {
    console.error('Missing session_id or proposal_id')
    redirect('/proposals')
  }

  const supabase = await createClient()

  try {
    // Verify the Stripe session
    const session = await stripe.checkout.sessions.retrieve(session_id)
    
    if (session.payment_status !== 'paid') {
      console.error('Payment not completed:', session.payment_status)
      redirect(`/proposals?payment=failed`)
    }

    // Get proposal details
    const { data: proposal, error: fetchError } = await supabase
      .from('proposals')
      .select(`
        *,
        customers (id, name, email, phone)
      `)
      .eq('id', proposal_id)
      .single()

    if (fetchError || !proposal) {
      console.error('Error fetching proposal:', fetchError)
      redirect('/proposals?payment=error')
    }

    const paymentStage = session.metadata?.payment_stage || 'deposit'
    const paidAmount = session.amount_total ? session.amount_total / 100 : 0
    const now = new Date().toISOString()

    // Record payment in payments table
    const { error: paymentError } = await supabase
      .from('payments')
      .insert({
        proposal_id,
        stripe_session_id: session_id,
        stripe_payment_intent_id: session.payment_intent as string,
        amount: paidAmount,
        status: 'completed',
        payment_method: session.metadata?.payment_type || 'card',
        customer_email: session.customer_email,
        payment_stage: paymentStage,
        metadata: session.metadata
      })

    if (paymentError) {
      console.error('Error recording payment:', paymentError)
    }

    // Update payment_stages table
    const { error: stageError } = await supabase
      .from('payment_stages')
      .update({
        paid: true,
        paid_at: now,
        stripe_session_id: session_id,
        amount_paid: paidAmount,
        payment_method: session.metadata?.payment_type || 'card'
      })
      .eq('proposal_id', proposal_id)
      .eq('stage', paymentStage)

    if (stageError) {
      console.error('Error updating payment stage:', stageError)
    }

    // Calculate total paid
    const { data: allPayments } = await supabase
      .from('payments')
      .select('amount')
      .eq('proposal_id', proposal_id)
      .eq('status', 'completed')

    const totalPaid = allPayments?.reduce((sum, p) => sum + Number(p.amount), 0) || 0

    // Determine next stage
    let nextStage = null
    let paymentStatus = 'partial'
    
    if (paymentStage === 'deposit') {
      nextStage = 'roughin'
    } else if (paymentStage === 'roughin') {
      nextStage = 'final'
    } else if (paymentStage === 'final') {
      paymentStatus = 'paid'
      nextStage = null
    }

    // Update proposal with payment info
    const updateData: any = {
      payment_status: paymentStatus,
      payment_method: session.metadata?.payment_type || 'card',
      stripe_session_id: session_id,
      total_paid: totalPaid,
      current_payment_stage: nextStage,
      last_payment_attempt: now
    }

    // Update specific payment stage fields
    if (paymentStage === 'deposit') {
      updateData.deposit_paid_at = now
      updateData.deposit_amount = paidAmount
    } else if (paymentStage === 'roughin') {
      updateData.progress_paid_at = now
      updateData.progress_payment_amount = paidAmount
      updateData.progress_amount = paidAmount // Update both columns
    } else if (paymentStage === 'final') {
      updateData.final_paid_at = now
      updateData.final_payment_amount = paidAmount
      updateData.final_amount = paidAmount // Update both columns
    }

    const { error: updateError } = await supabase
      .from('proposals')
      .update(updateData)
      .eq('id', proposal_id)

    if (updateError) {
      console.error('Error updating proposal:', updateError)
    }

    return (
      <PaymentSuccessView
        proposal={proposal}
        paymentAmount={paidAmount}
        paymentMethod={session.metadata?.payment_type || 'card'}
        sessionId={session_id}
        paymentStage={paymentStage}
        nextStage={nextStage}
      />
    )

  } catch (error: any) {
    console.error('Error processing payment success:', error)
    redirect(`/proposals?payment=error`)
  }
}
