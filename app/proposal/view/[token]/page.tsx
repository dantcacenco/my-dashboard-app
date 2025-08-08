import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import CustomerProposalView from './CustomerProposalView'

export default async function ProposalViewPage({
  params
}: {
  params: Promise<{ token: string }>
}) {
  const { token } = await params
  const supabase = await createClient()

  // Fetch proposal by customer view token
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
      ),
      proposal_items (
        id,
        name,
        description,
        quantity,
        unit_price,
        total_price,
        is_addon,
        is_selected,
        sort_order
      )
    `)
    .eq('customer_view_token', token)
    .single()

  if (error || !proposal) {
    redirect('/')
  }

  return <CustomerProposalView proposal={proposal} />
}
