import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import Stripe from 'stripe'
import PaymentSuccessView from './PaymentSuccessView'

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2024-06-20'
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

    // Update proposal with payment information
    await supabase
      .from('proposals')
      .update({
        payment_status: 'deposit_paid',
        payment_method: session.metadata?.payment_type || 'card',
        stripe_session_id: session_id,
        deposit_paid_at: new Date().toISOString(),
        deposit_amount: session.amount_total ? session.amount_total / 100 : 0
      })
      .eq('id', proposal_id)

    // Log the payment activity
    await supabase
      .from('proposal_activities')
      .insert({
        proposal_id: proposal_id,
        activity_type: 'deposit_payment_received',
        description: `Deposit payment received via ${session.metadata?.payment_type || 'card'}`,
        metadata: {
          stripe_session_id: session_id,
          amount: session.amount_total ? session.amount_total / 100 : 0,
          payment_method: session.metadata?.payment_type || 'card',
          customer_email: proposal.customers.email
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
          stripe_session_id: session_id
        })
      })
    } catch (emailError) {
      console.error('Failed to send payment notification email:', emailError)
      // Don't fail the whole process if email fails
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