import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import PaymentSuccessView from './PaymentSuccessView'

interface PageProps {
  searchParams: Promise<{ session_id?: string; proposal_id?: string }>
}

export default async function PaymentSuccessPage({ searchParams }: PageProps) {
  const params = await searchParams
  const supabase = await createClient()
  
  const proposalId = params.proposal_id
  const sessionId = params.session_id

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
