import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'

interface PageProps {
  searchParams: Promise<{ 
    session_id?: string
    proposal_id?: string
    stage?: string
  }>
}

export default async function PaymentSuccessPage({ searchParams }: PageProps) {
  const params = await searchParams
  const { proposal_id } = params
  
  if (!proposal_id) {
    redirect('/')
  }

  const supabase = await createClient()
  
  // Get the proposal to find its token
  const { data: proposal } = await supabase
    .from('proposals')
    .select('customer_view_token')
    .eq('id', proposal_id)
    .single()

  if (proposal?.customer_view_token) {
    // Redirect back to the proposal view
    redirect(`/proposal/view/${proposal.customer_view_token}`)
  } else {
    redirect('/')
  }
}
