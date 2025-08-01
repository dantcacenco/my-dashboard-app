import { createClient } from '@/lib/supabase/server'
import { notFound } from 'next/navigation'
import CustomerProposalView from './CustomerProposalView'

interface PageProps {
  params: Promise<{ token: string }>
}

export default async function CustomerViewProposalPage({ params }: PageProps) {
  const { token } = await params
  const supabase = await createClient()

  // Get the proposal by view token
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
        *
      )
    `)
    .eq('customer_view_token', token)
    .single()

  if (error || !proposal) {
    notFound()
  }

  // Log that customer viewed the proposal
  await supabase
    .from('proposal_activities')
    .insert({
      proposal_id: proposal.id,
      activity_type: 'viewed_by_customer',
      description: `Proposal viewed by customer`,
      metadata: {
        customer_email: proposal.customers[0]?.email,
        view_token: token,
        viewed_at: new Date().toISOString()
      }
    })

  // Update proposal status to 'viewed' if it was 'sent'
  if (proposal.status === 'sent') {
    await supabase
      .from('proposals')
      .update({ 
        status: 'viewed',
        first_viewed_at: new Date().toISOString()
      })
      .eq('id', proposal.id)
  }

  return <CustomerProposalView proposal={proposal} />
}
