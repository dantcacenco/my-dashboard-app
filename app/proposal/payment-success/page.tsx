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
      redirect('/proposals?payment=failed')
    }

    // Get full proposal details with fresh data
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
    await supabase
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

    // Update payment_stages table if it exists
    await supabase
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

    // Calculate total paid
    const { data: allPayments } = await supabase
      .from('payments')
      .select('amount')
      .eq('proposal_id', proposal_id)
      .eq('status', 'completed')

    const totalPaid = allPayments?.reduce((sum, p) => sum + Number(p.amount), 0) || paidAmount

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

    // Update proposal with payment info - IMPORTANT: Also ensure status stays 'approved'
    const updateData: any = {
      status: 'approved', // Keep it approved!
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
      updateData.progress_amount = paidAmount
    } else if (paymentStage === 'final') {
      updateData.final_paid_at = now
      updateData.final_payment_amount = paidAmount
      updateData.final_amount = paidAmount
    }

    await supabase
      .from('proposals')
      .update(updateData)
      .eq('id', proposal_id)

    // Send payment notification email
    try {
      const businessEmail = process.env.BUSINESS_EMAIL || 'dantcacenco@gmail.com'
      const fromEmail = process.env.EMAIL_FROM || 'onboarding@resend.dev'
      
      await fetch(`${process.env.NEXT_PUBLIC_BASE_URL || 'https://my-dashboard-app-tau.vercel.app'}/api/payment-notification`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          proposal_id,
          proposal_number: proposal.proposal_number,
          customer_name: proposal.customers.name,
          customer_email: proposal.customers.email,
          amount: paidAmount,
          payment_method: session.metadata?.payment_type || 'card',
          payment_stage: paymentStage,
          stripe_session_id: session_id
        })
      })
    } catch (emailError) {
      console.error('Failed to send payment notification:', emailError)
    }

    return (
      <PaymentSuccessView
        proposal={proposal}
        paymentAmount={paidAmount}
        paymentMethod={session.metadata?.payment_type || 'card'}
        sessionId={session_id}
        paymentStage={paymentStage}
        nextStage={nextStage}
        customerViewToken={proposal.customer_view_token}
      />
    )

  } catch (error: any) {
    console.error('Error processing payment success:', error)
    redirect(`/proposals?payment=error`)
  }
}
