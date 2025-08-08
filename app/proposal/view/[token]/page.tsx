import { createClient } from '@/lib/supabase/server'
import { notFound } from 'next/navigation'
import CustomerProposalView from './CustomerProposalView'

interface PageProps {
  params: Promise<{ token: string }>
}

export default async function CustomerProposalPage({ params }: PageProps) {
  const { token } = await params
  const supabase = await createClient()

  // Get proposal by customer view token - ALWAYS get fresh data
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
    console.error('Error fetching proposal:', error)
    notFound()
  }

  // Mark as viewed if first time
  if (!proposal.first_viewed_at) {
    await supabase
      .from('proposals')
      .update({ first_viewed_at: new Date().toISOString() })
      .eq('id', proposal.id)
  }

  return <CustomerProposalView proposal={proposal} />
}
