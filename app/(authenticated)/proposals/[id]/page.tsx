import { createClient } from '@/lib/supabase/server'
import { notFound } from 'next/navigation'
import ProposalView from './ProposalView'

interface PageProps {
  params: Promise<{ id: string }>
}

export default async function ProposalPage({ params }: PageProps) {
  const { id } = await params
  const supabase = await createClient()

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return notFound()

  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  // Get basic proposal first
  const { data: proposal, error: proposalError } = await supabase
    .from('proposals')
    .select('*')
    .eq('id', id)
    .single()

  if (proposalError || !proposal) {
    console.error('Error fetching proposal:', proposalError)
    return notFound()
  }

  // Get items separately (this works reliably)
  const { data: items } = await supabase
    .from('proposal_items')
    .select('*')
    .eq('proposal_id', id)
    .order('sort_order')

  // Get customer if exists
  let customer = null
  if (proposal.customer_id) {
    const { data: customerData } = await supabase
      .from('customers')
      .select('*')
      .eq('id', proposal.customer_id)
      .single()
    customer = customerData
  }

  // Get payment stages
  const { data: paymentStages } = await supabase
    .from('payment_stages')
    .select('*')
    .eq('proposal_id', id)
    .order('sort_order')

  // Combine everything with data transformation
  const fullProposal = {
    ...proposal,
    customers: customer,
    payment_stages: paymentStages || [],
    proposal_items: items?.map(item => ({
      ...item,
      title: item.name, // Map name to title for display
      item_type: item.is_addon ? 'add_on' : 'service' // Create item_type
    })) || []
  }

  return <ProposalView proposal={fullProposal} userRole={profile?.role || 'viewer'} />
}
