// In the payment success page, update the payment tracking:

// After successful payment verification, update the correct stage:
const paymentStage = session.metadata?.payment_stage || 'deposit'
const updateData: any = {
  payment_status: 'partial',
  payment_method: session.metadata?.payment_type || 'card',
  stripe_session_id: session_id,
}

// Update the correct timestamp based on stage
if (paymentStage === 'deposit') {
  updateData.deposit_paid_at = new Date().toISOString()
  updateData.deposit_amount = session.amount_total ? session.amount_total / 100 : 0
} else if (paymentStage === 'progress') {
  updateData.progress_paid_at = new Date().toISOString()
  updateData.progress_amount = session.amount_total ? session.amount_total / 100 : 0
} else if (paymentStage === 'final') {
  updateData.final_paid_at = new Date().toISOString()
  updateData.final_amount = session.amount_total ? session.amount_total / 100 : 0
  updateData.payment_status = 'paid' // Fully paid after final payment
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
    (paymentStage === 'deposit' ? (session.amount_total ? session.amount_total / 100 : 0) : 0) +
    (paymentStage === 'progress' ? (session.amount_total ? session.amount_total / 100 : 0) : 0) +
    (paymentStage === 'final' ? (session.amount_total ? session.amount_total / 100 : 0) : 0)
  
  updateData.total_paid = totalPaid
}

// Update current stage to next stage
if (paymentStage === 'deposit') {
  updateData.current_payment_stage = 'progress'
} else if (paymentStage === 'progress') {
  updateData.current_payment_stage = 'final'
} else if (paymentStage === 'final') {
  updateData.current_payment_stage = 'completed'
}

await supabase
  .from('proposals')
  .update(updateData)
  .eq('id', proposal_id)
