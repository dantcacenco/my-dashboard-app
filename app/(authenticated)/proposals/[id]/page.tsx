import { createClient } from '@/lib/supabase/server'
import { notFound } from 'next/navigation'
import ProposalView from './ProposalView'

interface PageProps {
  params: Promise<{ id: string }>
}

export default async function ProposalPage({ params }: PageProps) {
  const { id } = await params
  const supabase = await createClient()

  // Get current user
  const { data: { user } } = await supabase.auth.getUser()
  
  if (!user) {
    return notFound()
  }

  // Get user profile
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  // Get proposal with ACTUAL column names from database
  const { data: proposal, error } = await supabase
    .from('proposals')
    .select(`
      *,
      customers!customer_id (
        id,
        name,
        email,
        phone,
        address
      ),
      proposal_items (
        id,
        proposal_id,
        pricing_item_id,
        name,
        description,
        quantity,
        unit_price,
        total_price,
        is_addon,
        is_selected,
        sort_order,
        created_at
      ),
      payment_stages (
        id,
        stage_name,
        percentage,
        amount,
        due_date
      )
    `)
    .eq('id', id)
    .single()

  if (error) {
    console.error('Error fetching proposal:', error)
    return (
      <div className="p-6">
        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <h2 className="text-red-800 font-semibold">Error loading proposal</h2>
          <p className="text-red-600 mt-2">Details: {error.message}</p>
          <p className="text-sm text-red-500 mt-1">Proposal ID: {id}</p>
        </div>
      </div>
    )
  }

  if (!proposal) {
    return notFound()
  }

  // Transform the data for ProposalView compatibility
  // ProposalView expects 'title' but database has 'name'
  // ProposalView expects 'item_type' but database has 'is_addon'
  if (proposal.proposal_items) {
    proposal.proposal_items = proposal.proposal_items.map((item: any) => ({
      ...item,
      title: item.name, // Map name to title
      item_type: item.is_addon ? 'add_on' : 'service' // Create item_type from is_addon
    }))
  }

  return (
    <ProposalView 
      proposal={proposal} 
      userRole={profile?.role || 'viewer'}
    />
  )
}
