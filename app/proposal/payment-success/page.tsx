import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import PaymentSuccessView from './PaymentSuccessView'

export default async function PaymentSuccessPage({
  searchParams
}: {
  searchParams: Promise<{ session_id?: string; proposal_id?: string }>
}) {
  const params = await searchParams
  const supabase = await createClient()

  if (!params.session_id || !params.proposal_id) {
    redirect('/')
  }

  // Get the proposal with all payment details
  const { data: proposal, error } = await supabase
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
    .eq('id', params.proposal_id)
    .single()

  if (error || !proposal) {
    console.error('Error fetching proposal:', error)
    redirect('/')
  }

  return (
    <PaymentSuccessView 
      proposal={proposal}
      sessionId={params.session_id}
    />
  )
}
