import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

export async function GET(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams
  const proposalId = searchParams.get('proposal_id')
  const paymentStage = searchParams.get('payment_stage')
  const sessionId = searchParams.get('session_id')
  
  if (!proposalId || !paymentStage) {
    return NextResponse.redirect('/proposals')
  }

  const supabase = await createClient()
  
  try {
    // Get the proposal to verify it exists
    const { data: proposal } = await supabase
      .from('proposals')
      .select('*, customers(*)')
      .eq('id', proposalId)
      .single()
    
    if (!proposal) {
      throw new Error('Proposal not found')
    }

    // Update payment status based on stage
    const updateData: any = {}
    const now = new Date().toISOString()
    
    switch(paymentStage) {
      case 'deposit':
        updateData.deposit_paid_at = now
        updateData.total_paid = proposal.deposit_amount || 0
        updateData.status = 'deposit_paid'  // Update status
        break
      case 'roughin':
        updateData.progress_paid_at = now
        updateData.total_paid = (proposal.deposit_amount || 0) + (proposal.progress_payment_amount || 0)
        updateData.status = 'progress_paid'  // Update status
        break
      case 'final':
        updateData.final_paid_at = now
        updateData.total_paid = proposal.total
        updateData.status = 'final_paid'  // Update status
        break
    }
    
    // Update the proposal with payment info
    const { error: updateError } = await supabase
      .from('proposals')
      .update(updateData)
      .eq('id', proposalId)
    
    if (updateError) {
      console.error('Error updating payment status:', updateError)
    }
    
    // Log the payment
    await supabase
      .from('payments')
      .insert({
        proposal_id: proposalId,
        amount: proposal[`${paymentStage === 'roughin' ? 'progress' : paymentStage}_${paymentStage === 'deposit' ? '' : 'payment_'}amount`] || 0,
        payment_type: 'stripe',
        payment_stage: paymentStage,
        stripe_session_id: sessionId,
        customer_id: proposal.customer_id,
        paid_at: now
      })
    
    // Redirect back to proposal view
    if (proposal.customer_view_token) {
      return NextResponse.redirect(
        `${process.env.NEXT_PUBLIC_BASE_URL}/proposal/view/${proposal.customer_view_token}?payment=success`
      )
    }
    
    return NextResponse.redirect('/proposals?payment=success')
    
  } catch (error) {
    console.error('Payment success error:', error)
    return NextResponse.redirect('/proposals?payment=error')
  }
}
