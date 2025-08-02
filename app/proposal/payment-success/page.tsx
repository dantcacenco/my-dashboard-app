import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import Stripe from 'stripe'

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2025-07-30.basil'
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

    // Determine which payment stage was completed
    const paymentStage = session.metadata?.payment_stage || 'deposit'
    const now = new Date().toISOString()

    // Update proposal with payment information based on stage
    const updateData: any = {
      payment_method: session.metadata?.payment_type || 'card',
      stripe_session_id: session_id,
    }

    switch (paymentStage) {
      case 'deposit':
        updateData.payment_status = 'deposit_paid'
        updateData.deposit_paid_at = now
        updateData.deposit_amount = session.amount_total ? session.amount_total / 100 : 0
        updateData.current_payment_stage = 'deposit'
        break
      case 'progress':
        updateData.payment_status = 'progress_paid'
        updateData.progress_paid_at = now
        updateData.progress_payment_amount = session.amount_total ? session.amount_total / 100 : 0
        updateData.current_payment_stage = 'progress'
        break
      case 'final':
        updateData.payment_status = 'paid'
        updateData.final_paid_at = now
        updateData.final_payment_amount = session.amount_total ? session.amount_total / 100 : 0
        updateData.current_payment_stage = 'final'
        break
    }

    // Calculate total paid
    const totalPaid = (proposal.deposit_amount || 0) + 
                     (proposal.progress_payment_amount || 0) + 
                     (updateData.final_payment_amount || 0) +
                     (updateData.deposit_amount || 0) +
                     (updateData.progress_payment_amount || 0)
    
    updateData.total_paid = totalPaid

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
          customer_email: proposal.customers.email,
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
          customer_name: proposal.customers.name,
          customer_email: proposal.customers.email,
          amount: session.amount_total ? session.amount_total / 100 : 0,
          payment_method: session.metadata?.payment_type || 'card',
          stripe_session_id: session_id,
          payment_stage: paymentStage
        })
      })
    } catch (emailError) {
      console.error('Failed to send payment notification email:', emailError)
      // Don't fail the whole process if email fails
    }

    // Redirect back to proposal view with success message
    redirect(`/proposal/view/${proposal.customer_view_token}?payment=success&stage=${paymentStage}`)

  } catch (error) {
    console.error('Error processing payment success:', error)
    redirect(`/proposal/view/${proposal_id}?payment=error`)
  }
}
