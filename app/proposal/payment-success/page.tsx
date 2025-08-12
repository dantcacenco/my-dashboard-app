import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import PaymentSuccessView from './PaymentSuccessView'

export default async function PaymentSuccessPage({
  searchParams
}: {
  searchParams: { session_id?: string; proposal_id?: string }
}) {
  const supabase = await createClient()
  
  const proposalId = searchParams.proposal_id
  const sessionId = searchParams.session_id

  if (!proposalId) {
    redirect('/')
  }

  // Get proposal with customer info
  const { data: proposal } = await supabase
    .from('proposals')
    .select(`
      *,
      customers (
        id,
        name,
        email,
        phone,
        address
      )
    `)
    .eq('id', proposalId)
    .single()

  if (!proposal) {
    redirect('/')
  }

  // Auto-redirect to proposal after showing success
  return <PaymentSuccessView proposal={proposal} />
}
