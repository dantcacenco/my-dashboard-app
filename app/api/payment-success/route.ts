import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

export async function GET(request: NextRequest) {
  console.log('Payment success route called')
  const searchParams = request.nextUrl.searchParams
  const proposalId = searchParams.get('proposal_id')
  const paymentStage = searchParams.get('payment_stage')
  const sessionId = searchParams.get('session_id')
  
  console.log('Payment params:', { proposalId, paymentStage, sessionId })
  
  if (!proposalId || !paymentStage) {
    console.error('Missing required params')
    return NextResponse.redirect(new URL('/proposals', request.url))
  }

  const supabase = await createClient()
  
  try {
    // Get the proposal to verify it exists
    const { data: proposal, error: fetchError } = await supabase
      .from('proposals')
      .select('*, customers(*)')
      .eq('id', proposalId)
      .single()
    
    if (fetchError) {
      console.error('Error fetching proposal:', fetchError)
      throw fetchError
    }
    
    if (!proposal) {
      console.error('Proposal not found:', proposalId)
      throw new Error('Proposal not found')
    }

    console.log('Found proposal:', proposal.id, 'with token:', proposal.customer_view_token)

    // Update payment status based on stage
    const updateData: any = {}
    const now = new Date().toISOString()
    
    switch(paymentStage) {
      case 'deposit':
        updateData.deposit_paid_at = now
        updateData.total_paid = proposal.deposit_amount || 0
        updateData.status = 'deposit paid'
        // Remove payment_stage - causes constraint violation
        break
      case 'roughin':
        updateData.progress_paid_at = now
        updateData.total_paid = (proposal.deposit_amount || 0) + (proposal.progress_payment_amount || 0)
        updateData.status = 'rough-in paid'
        // Remove payment_stage - causes constraint violation
        break
      case 'final':
        updateData.final_paid_at = now
        updateData.total_paid = proposal.total
        updateData.status = 'completed'
        // Remove payment_stage - causes constraint violation
        break
    }
    
    console.log('Updating proposal with:', updateData)
    
    // Update the proposal with payment info
    const { data: updatedProposal, error: updateError } = await supabase
      .from('proposals')
      .update(updateData)
      .eq('id', proposalId)
      .select()
      .single()
    
    if (updateError) {
      console.error('Error updating payment status:', updateError)
      throw updateError
    }
    
    console.log('Successfully updated proposal:', updatedProposal)
    
    // Log the payment (optional - create the payments table if it doesn't exist)
    const paymentAmount = paymentStage === 'deposit' ? proposal.deposit_amount :
                         paymentStage === 'roughin' ? proposal.progress_payment_amount :
                         proposal.final_payment_amount
    
    const { error: paymentLogError } = await supabase
      .from('payments')
      .insert({
        proposal_id: proposalId,
        amount: paymentAmount || 0,
        payment_type: 'stripe',
        payment_stage: paymentStage,
        stripe_session_id: sessionId,
        customer_id: proposal.customer_id,
        paid_at: now
      })
    
    if (paymentLogError) {
      console.error('Error logging payment (non-critical):', paymentLogError)
      // Don't throw here - payment table might not exist
    }
    
    // Build the redirect URL properly
    const baseUrl = process.env.NEXT_PUBLIC_BASE_URL || `https://${request.headers.get('host')}`
    const redirectUrl = `${baseUrl}/proposal/view/${proposal.customer_view_token}?payment=success`
    
    console.log('Redirecting to:', redirectUrl)
    
    return NextResponse.redirect(redirectUrl)
    
  } catch (error) {
    console.error('Payment success error:', error)
    // Try to redirect back to proposal if we have the token
    const { data: proposal } = await supabase
      .from('proposals')
      .select('customer_view_token')
      .eq('id', proposalId)
      .single()
    
    if (proposal?.customer_view_token) {
      const baseUrl = process.env.NEXT_PUBLIC_BASE_URL || `https://${request.headers.get('host')}`
      return NextResponse.redirect(`${baseUrl}/proposal/view/${proposal.customer_view_token}?payment=error`)
    }
    
    return NextResponse.redirect(new URL('/proposals?payment=error', request.url))
  }
}
