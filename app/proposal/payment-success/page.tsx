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
    console.error('Missing session_id or proposal_id in payment success page')
    redirect('/proposals')
  }

  const supabase = await createClient()
  let customerViewToken: string | null = null

  try {
    // First get the proposal to have the customer_view_token for redirects
    const { data: proposalData, error: proposalError } = await supabase
      .from('proposals')
      .select('customer_view_token')
      .eq('id', proposal_id)
      .single()

    if (proposalError || !proposalData) {
      console.error('Error fetching proposal for redirect:', proposalError)
      redirect('/proposals')
    }

    customerViewToken = proposalData.customer_view_token

    // Verify the Stripe session
    console.log('Verifying Stripe session:', session_id)
    const session = await stripe.checkout.sessions.retrieve(session_id)
    
    if (session.payment_status !== 'paid') {
      console.error('Payment not completed, status:', session.payment_status)
      redirect(`/proposal/view/${customerViewToken}?payment=failed`)
    }

    // Get full proposal details
    const { data: proposal, error: fetchError } = await supabase
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

    if (fetchError || !proposal) {
      console.error('Error fetching full proposal:', fetchError)
      redirect(`/proposal/view/${customerViewToken}?payment=error`)
    }

    // Determine which payment stage was completed
    const paymentStage = session.metadata?.payment_stage || 'deposit'
    console.log('Processing payment for stage:', paymentStage)
    
    const now = new Date().toISOString()
    const paidAmount = session.amount_total ? session.amount_total / 100 : 0

    // Update proposal with payment information based on stage
    const updateData: any = {
      payment_method: session.metadata?.payment_type || 'card',
      stripe_session_id: session_id,
    }

    switch (paymentStage) {
      case 'deposit':
        updateData.payment_status = 'deposit_paid'
        updateData.deposit_paid_at = now
        updateData.deposit_amount = paidAmount
        updateData.current_payment_stage = 'deposit'
        updateData.total_paid = paidAmount
        break
      case 'roughin':
        updateData.payment_status = 'roughin_paid'
        updateData.progress_paid_at = now
        updateData.progress_payment_amount = paidAmount
        updateData.current_payment_stage = 'roughin'
        updateData.total_paid = (proposal.deposit_amount || 0) + paidAmount
        break
      case 'final':
        updateData.payment_status = 'paid'
        updateData.final_paid_at = now
        updateData.final_payment_amount = paidAmount
        updateData.current_payment_stage = 'final'
        updateData.total_paid = (proposal.deposit_amount || 0) + 
                               (proposal.progress_payment_amount || 0) + 
                               paidAmount
        break
    }

    console.log('Updating proposal with:', updateData)

    const { error: updateError } = await supabase
      .from('proposals')
      .update(updateData)
      .eq('id', proposal_id)

    if (updateError) {
      console.error('Error updating proposal:', updateError)
      throw updateError
    }

    // Log the payment activity
    const { error: activityError } = await supabase
      .from('proposal_activities')
      .insert({
        proposal_id: proposal_id,
        activity_type: `${paymentStage}_payment_received`,
        description: `${paymentStage === 'roughin' ? 'Rough-in' : paymentStage.charAt(0).toUpperCase() + paymentStage.slice(1)} payment received via ${session.metadata?.payment_type || 'card'}`,
        metadata: {
          stripe_session_id: session_id,
          amount: paidAmount,
          payment_method: session.metadata?.payment_type || 'card',
          customer_email: proposal.customers.email,
          payment_stage: paymentStage
        }
      })

    if (activityError) {
      console.error('Error logging activity:', activityError)
      // Don't fail the payment process if activity logging fails
    }

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
          amount: paidAmount,
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
    console.log('Payment processed successfully, redirecting to:', `/proposal/view/${customerViewToken}`)
    redirect(`/proposal/view/${customerViewToken}?payment=success&stage=${paymentStage}`)

  } catch (error) {
    console.error('Error processing payment success:', error)
    
    // Use the token we got earlier, or try to fetch it again
    if (!customerViewToken) {
      const { data } = await supabase
        .from('proposals')
        .select('customer_view_token')
        .eq('id', proposal_id)
        .single()
      
      customerViewToken = data?.customer_view_token || proposal_id
    }
    
    redirect(`/proposal/view/${customerViewToken}?payment=error`)
  }
}
