import { createClient } from '@/lib/supabase/server'
import { notFound } from 'next/navigation'
import CustomerProposalView from './CustomerProposalView'

interface PageProps {
  params: Promise<{ token: string }>
}

export default async function CustomerProposalPage({ params }: PageProps) {
  const { token } = await params
  const supabase = await createClient()

  // Get proposal by token with ALL necessary fields
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

  // Sort proposal items by sort_order
  if (proposal.proposal_items) {
    proposal.proposal_items.sort((a: any, b: any) => (a.sort_order || 0) - (b.sort_order || 0))
  }

  return <CustomerProposalView proposal={proposal} token={token} />
}
