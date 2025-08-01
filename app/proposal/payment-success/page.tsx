import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import Stripe from 'stripe'
import PaymentSuccessView from './PaymentSuccessView'

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2025-06-30.basil'
})

interface PageProps {
  searchParams: Promise<{ session_id?: string; proposal_id?: string }>
}

export default async function PaymentSuccessPage({ searchParams }: PageProps) {
  const { session_id, proposal_id } = await searchParams
  
  if (!session_id || !proposal_id) {
    redirect('/proposals')
  }

  const supabase = await createClient()

  try {
    // Verify the Stripe session
    const session = await stripe.checkout.sessions.retrieve(session_id)
    
    if (session.payment_status !== 'paid') {
      redirect(`/proposal/view/${proposal_id}?payment=failed`)
    }

    // Get proposal details
    const { data: proposal } = await supabase
      .from('proposals')
      .select(`
        *,
        customers (
          id,
          name,
          email,
          phone
        )
      `)
      .eq('id', proposal_id)
      .single()

    if (!proposal) {
      redirect('/proposals')
    }

    // Get payment stage from metadata
    const paymentStage = session.metadata?.payment_stage || 'deposit'
    const updateData: any = {
      payment_method: session.metadata?.payment_type || 'card',
      stripe_session_id: session_id,
    }

    // Update the correct timestamp and amount based on stage
    if (paymentStage === 'deposit') {
      updateData.deposit_paid_at = new Date().toISOString()
      updateData.deposit_amount = session.amount_total ? session.amount_total / 100 : 0
      updateData.current_payment_stage = 'progress'
      updateData.payment_status = 'deposit_paid'
    } else if (paymentStage === 'progress') {
      updateData.progress_paid_at = new Date().toISOString()
      updateData.progress_amount = session.amount_total ? session.amount_total / 100 : 0
      updateData.current_payment_stage = 'final'
      updateData.payment_status = 'progress_paid'
    } else if (paymentStage === 'final') {
      updateData.final_paid_at = new Date().toISOString()
      updateData.final_amount = session.amount_total ? session.amount_total / 100 : 0
      updateData.current_payment_stage = 'completed'
      updateData.payment_status = 'paid'
    }

    // Calculate total paid
    const { data: currentProposal } = await supabase
      .from('proposals')
      .select('deposit_amount, progress_amount, final_amount')
      .eq('id', proposal_id)
      .single()

    if (currentProposal) {
      const totalPaid = 
        (currentProposal.deposit_amount || 0) +
        (currentProposal.progress_amount || 0) +
        (currentProposal.final_amount || 0) +
        (session.amount_total ? session.amount_total / 100 : 0)
      
      updateData.total_paid = totalPaid
    }

    // Update proposal with payment information
    await supabase
      .from('proposals')
      .update(updateData)
      .eq('id', proposal_id)

    // Log the payment activity
    await supabase
      .from('proposal_activities')
      .insert({
        proposal_id: proposal_id,
        activity_type: `${paymentStage}_payment_received`,
        description: `${paymentStage.charAt(0).toUpperCase() + paymentStage.slice(1)} payment received via ${session.metadata?.payment_type || 'card'}`,
        metadata: {
          stripe_session_id: session_id,
          amount: session.amount_total ? session.amount_total / 100 : 0,
          payment_method: session.metadata?.payment_type || 'card',
          customer_email: proposal.customers[0]?.email,
          payment_stage: paymentStage
        }
      })

    // Send notification email to business
    try {
      await fetch(`${process.env.NEXT_PUBLIC_BASE_URL}/api/payment-notification`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          proposal_id: proposal_id,
          proposal_number: proposal.proposal_number,
          customer_name: proposal.customers[0]?.name,
          customer_email: proposal.customers[0]?.email,
          amount: session.amount_total ? session.amount_total / 100 : 0,
          payment_method: session.metadata?.payment_type || 'card',
          stripe_session_id: session_id,
          payment_stage: paymentStage
        })
      })
    } catch (emailError) {
      console.error('Failed to send payment notification email:', emailError)
    }

    // Get the customer view token to redirect back to proposal
    const { data: proposalData } = await supabase
      .from('proposals')
      .select('customer_view_token')
      .eq('id', proposal_id)
      .single()

    if (proposalData?.customer_view_token) {
      redirect(`/proposal/view/${proposalData.customer_view_token}?payment=success&stage=${paymentStage}`)
    }

    return (
      <PaymentSuccessView
        proposal={proposal}
        paymentAmount={session.amount_total ? session.amount_total / 100 : 0}
        paymentMethod={session.metadata?.payment_type || 'card'}
        sessionId={session_id}
      />
    )

  } catch (error) {
    console.error('Error processing payment success:', error)
    redirect(`/proposal/view/${proposal_id}?payment=error`)
  }
}
